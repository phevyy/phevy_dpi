"""Paket yakalama donguleri: DNS, TCP (TLS ClientHello) ve UDP (Discord ses / QUIC).

Filtreler sadece ilgili paketleri yakalar; oyun trafigi ve diger baglantilarin
paketleri suruculerden gecmez, bu yuzden pinge etkisi yoktur.
"""
import logging
import os
import threading
from concurrent.futures import ThreadPoolExecutor

from . import dnsmsg, tls
from . import windivert as wd
from .packet import Packet
from .strategies import BY_NAME

log = logging.getLogger("phevy.engine")

FILTER_DNS = "outbound and !loopback and udp.DstPort == 53"
FILTER_TCP = ("outbound and !loopback and tcp.DstPort == 443 and tcp.PayloadLength > 5"
              " and tcp.Payload[0] == 0x16 and tcp.Payload[5] == 0x01")
# Discord ses "IP Discovery" istegi (74 bayt, 0x0001 0x0046 ile baslar) ve QUIC Initial paketleri
FILTER_UDP = ("outbound and !loopback and udp and ("
              "(udp.PayloadLength == 74 and udp.Payload32[0] == 0x00010046) or "
              "(udp.DstPort == 443 and udp.PayloadLength >= 1200"
              " and udp.Payload[0] >= 0xC0 and udp.Payload[0] <= 0xCF))")

# Sunucudan gelen SYN-ACK'lerin TTL'sinden sunucuya kac hop oldugunu ogreniyoruz (sadece dinleme).
FILTER_SYNACK = "inbound and !loopback and tcp.SrcPort == 443 and tcp.Syn and tcp.Ack"

FAKE_SNI = "www.google.com"
UDP_FAKE_COUNT = 2
# Sahte paket sunucudan AUTOTTL_DELTA hop once olmeli: DPI'yi gecer, sunucuya ulasmaz.
AUTOTTL_DELTA = 2
AUTOTTL_MIN = 3
AUTOTTL_FALLBACK = 4


class Engine:
    def __init__(self, resolver, voice_fix=True):
        self.resolver = resolver
        self.voice_fix = voice_fix
        self.strategy = BY_NAME["none"]
        self.stats = {"dns": 0, "tls": 0, "voice": 0, "quic_drop": 0}
        self.hops = {}
        self._handles = []
        self._threads = []
        self._pool = ThreadPoolExecutor(max_workers=8, thread_name_prefix="doh")
        self._fake_hello = tls.build_client_hello(FAKE_SNI)

    @staticmethod
    def check_filters():
        for f in (FILTER_DNS, FILTER_TCP, FILTER_UDP, FILTER_SYNACK):
            err = wd.check_filter(f)
            if err:
                raise wd.WinDivertError(f"Filtre hatası: {err} -> {f}")

    def set_strategy(self, strategy):
        self.strategy = strategy
        log.debug("Strateji: %s", strategy.name)

    def start(self):
        for filt, loop, flags in ((FILTER_DNS, self._dns_loop, 0), (FILTER_TCP, self._tcp_loop, 0),
                                  (FILTER_UDP, self._udp_loop, 0),
                                  (FILTER_SYNACK, self._synack_loop, wd.FLAG_SNIFF)):
            h = wd.Handle(filt, flags=flags)
            self._handles.append(h)
            t = threading.Thread(target=self._run, args=(loop, h, flags & wd.FLAG_SNIFF), daemon=True,
                                 name=loop.__name__)
            t.start()
            self._threads.append(t)

    def stop(self):
        for h in self._handles:
            h.close()
        for t in self._threads:
            t.join(timeout=2)
        self._pool.shutdown(wait=False, cancel_futures=True)

    def _run(self, loop, h, sniff):
        while True:
            try:
                item = h.recv()
            except wd.WinDivertError as e:
                log.error("%s: %s", loop.__name__, e)
                return
            if item is None:
                return
            buf, addr = item
            try:
                loop(h, buf, addr)
            except Exception:
                # Bir pakette hata olursa paketi oldugu gibi gecir, baglanti kopmasin.
                log.exception("Paket işlenemedi, olduğu gibi gönderiliyor")
                if not sniff:
                    h.send(buf, addr)

    # --- SYN-ACK (hop sayisi) -------------------------------------------------
    def _synack_loop(self, h, buf, addr):
        pkt = Packet(buf)
        ttl = pkt.ttl
        initial = 64 if ttl <= 64 else 128 if ttl <= 128 else 255
        if len(self.hops) > 4096:
            self.hops.clear()
        self.hops[pkt.src_ip] = initial - ttl

    # --- DNS ----------------------------------------------------------------
    def _dns_loop(self, h, buf, addr):
        pkt = Packet(buf)
        q = dnsmsg.parse_query(pkt.payload)
        if q is None or not self.resolver.is_target(q.name):
            h.send(buf, addr, recalc=False)
            return
        self.stats["dns"] += 1
        self._pool.submit(self._answer_dns, h, pkt, addr, q)

    def _answer_dns(self, h, pkt, addr, q):
        if q.qtype == dnsmsg.QTYPE_A:
            ips = self.resolver.resolve(q.name)
            if not ips:
                h.send(pkt.buf, addr)  # DoH yoksa normal DNS'e birak
                return
        else:
            ips = []  # AAAA/HTTPS vb. bos cevap -> IPv4 kullanilsin
        reply = pkt.reply_with_payload(dnsmsg.build_response(q, ips))
        raddr = addr.copy()
        raddr.outbound = False
        h.send(reply.buf, raddr)
        log.debug("DNS %s (tip %d) -> %s", q.name, q.qtype, ips)

    # --- TCP / TLS -------------------------------------------------------------
    def _tcp_loop(self, h, buf, addr):
        pkt = Packet(buf)
        payload = pkt.payload
        sni, sni_off, sni_len = tls.find_sni(payload)
        if sni is not None:
            target = self.resolver.is_target(sni)
        else:
            target = pkt.dst_ip in self.resolver.target_ips
        st = self.strategy
        if not target or st.name == "none":
            h.send(buf, addr, recalc=False)
            return
        self.stats["tls"] += 1
        log.debug("TLS %s -> %s [%s]", sni, pkt.dst_ip, st.name)

        out = []
        if st.fake:
            fk = pkt.with_payload(self._fake_hello)
            if st.fake == "badseq":
                fk.seq = pkt.seq - 10000
                fk.ack = pkt.ack - 66000
            elif st.fake == "ttl":
                fk.ttl = st.fake_ttl
            elif st.fake == "autottl":
                hops = self.hops.get(pkt.dst_ip)
                fk.ttl = max(AUTOTTL_MIN, hops - AUTOTTL_DELTA) if hops else AUTOTTL_FALLBACK
                log.debug("autottl: %s hop=%s -> sahte TTL %d", pkt.dst_ip, hops, fk.ttl)
            out.append((fk, st.fake == "badsum"))

        segs = []
        prev = 0
        for pos in st.positions(len(payload), sni_off, sni_len) + [len(payload)]:
            segs.append(pkt.with_payload(payload[prev:pos], seq=pkt.seq + prev))
            prev = pos
        if st.disorder:
            segs.reverse()
        out += [(s, False) for s in segs]

        ip_id = pkt.ip_id
        for i, (p, badsum) in enumerate(out):
            p.set_ip_id(ip_id + i)
            a = addr.copy()
            wd.calc_checksums(p.buf, a)
            if badsum:
                off = p.l4_checksum_offset
                p.buf[off] ^= 0xFF
            h.send(p.buf, a, recalc=False)

    # --- UDP ----------------------------------------------------------------
    def _udp_loop(self, h, buf, addr):
        pkt = Packet(buf)
        if pkt.dport == 443 and len(buf) - pkt.hdr_len >= 1200:
            # QUIC: Discord'a giden HTTP/3'u dusur, uygulama hemen TCP'ye gecer.
            if pkt.dst_ip in self.resolver.target_ips:
                self.stats["quic_drop"] += 1
                return
            h.send(buf, addr, recalc=False)
            return
        if self.voice_fix:
            # Ses baglantisinin ilk paketinden once rastgele cop paketler: DPI akisi taniyamaz,
            # Discord ses sunucusu gecersiz paketleri yok sayar.
            self.stats["voice"] += 1
            log.debug("Ses bağlantısı -> %s:%d", pkt.dst_ip, pkt.dport)
            for _ in range(UDP_FAKE_COUNT):
                junk = pkt.with_payload(os.urandom(64))
                h.send(junk.buf, addr.copy())
        h.send(buf, addr, recalc=False)
