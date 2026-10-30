import os
import ssl
import struct
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from phevy import dnsmsg, tls  # noqa: E402
from phevy.packet import Packet  # noqa: E402
from phevy.resolver import DEFAULT_DOMAINS, Resolver  # noqa: E402
from phevy.strategies import BY_NAME  # noqa: E402


def real_client_hello(host):
    ctx = ssl.create_default_context()
    inc, out = ssl.MemoryBIO(), ssl.MemoryBIO()
    obj = ctx.wrap_bio(inc, out, server_hostname=host)
    try:
        obj.do_handshake()
    except ssl.SSLWantReadError:
        pass
    return out.read()


def ipv4_tcp(payload, seq=1000):
    ip = bytearray(struct.pack("!BBHHHBBH4s4s", 0x45, 0, 0, 1, 0x4000, 128, 6, 0,
                               bytes([192, 168, 1, 2]), bytes([162, 159, 128, 233])))
    tcp = struct.pack("!HHIIBBHHH", 50000, 443, seq, 77, 5 << 4, 0x18, 65535, 0, 0)
    p = Packet(bytes(ip) + tcp)
    return p.with_payload(payload)


class Tests(unittest.TestCase):
    def test_sni_real(self):
        hello = real_client_hello("gateway.discord.gg")
        sni, off, ln = tls.find_sni(hello)
        self.assertEqual(sni, "gateway.discord.gg")
        self.assertEqual(hello[off:off + ln], b"gateway.discord.gg")

    def test_sni_fake(self):
        sni, _, _ = tls.find_sni(tls.build_client_hello("www.google.com"))
        self.assertEqual(sni, "www.google.com")

    def test_sni_truncated(self):
        hello = real_client_hello("discord.com")
        _, off, _ = tls.find_sni(hello)
        self.assertEqual(tls.find_sni(hello[:off + 3]), (None, None, None))

    def test_split_reassembles(self):
        hello = real_client_hello("discord.com")
        pkt = ipv4_tcp(hello, seq=0xFFFFFF00)  # seq tasmasi
        _, off, ln = tls.find_sni(hello)
        st = BY_NAME["multidisorder"]
        pos = st.positions(len(hello), off, ln)
        self.assertEqual(pos, [1, off + ln // 2])
        segs, prev = [], 0
        for p in pos + [len(hello)]:
            segs.append(pkt.with_payload(hello[prev:p], seq=pkt.seq + prev))
            prev = p
        data = b"".join(s.payload for s in sorted(segs, key=lambda s: (s.seq - pkt.seq) & 0xFFFFFFFF))
        self.assertEqual(data, hello)
        for s in segs:
            self.assertEqual(struct.unpack_from("!H", s.buf, 2)[0], len(s.buf))

    def test_dns_roundtrip(self):
        q = b"\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x07discord\x03com\x00\x00\x01\x00\x01"
        parsed = dnsmsg.parse_query(q)
        self.assertEqual(parsed.name, "discord.com")
        r = dnsmsg.build_response(parsed, ["162.159.128.233", "162.159.135.232"])
        self.assertEqual(r[:2], b"\x12\x34")
        self.assertEqual(struct.unpack_from("!H", r, 6)[0], 2)
        self.assertTrue(r.endswith(bytes([162, 159, 135, 232])))

    def test_reply_swaps(self):
        pkt = ipv4_tcp(b"x")
        r = pkt.reply_with_payload(b"yy")
        self.assertEqual(r.src_raw, pkt.dst_raw)
        self.assertEqual(r.dport, pkt.sport)

    def test_targets(self):
        r = Resolver(DEFAULT_DOMAINS)
        self.assertTrue(r.is_target("cdn.discordapp.com"))
        self.assertTrue(r.is_target("rotterdam1234.discord.media"))
        self.assertFalse(r.is_target("notdiscord.com"))


if __name__ == "__main__":
    unittest.main()
