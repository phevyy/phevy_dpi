"""IPv4/IPv6 + TCP/UDP paketlerini okuma ve yeniden kurma."""
import ipaddress
import struct

TCP = 6
UDP = 17
MASK32 = 0xFFFFFFFF


class Packet:
    __slots__ = ("buf", "v6", "ip_hl", "proto", "l4_hl")

    def __init__(self, data):
        buf = bytearray(data)
        ver = buf[0] >> 4
        if ver == 4:
            self.v6 = False
            self.ip_hl = (buf[0] & 0x0F) * 4
            self.proto = buf[9]
        elif ver == 6:
            # Uzanti basliklarini desteklemiyoruz; WinDivert filtreleri zaten tcp/udp seciyor.
            self.v6 = True
            self.ip_hl = 40
            self.proto = buf[6]
        else:
            raise ValueError("IP degil")
        if self.proto == TCP:
            self.l4_hl = (buf[self.ip_hl + 12] >> 4) * 4
        elif self.proto == UDP:
            self.l4_hl = 8
        else:
            raise ValueError(f"desteklenmeyen protokol {self.proto}")
        self.buf = buf

    # --- alanlar -----------------------------------------------------------
    @property
    def hdr_len(self):
        return self.ip_hl + self.l4_hl

    @property
    def payload(self):
        return bytes(self.buf[self.hdr_len:])

    @property
    def src_raw(self):
        return bytes(self.buf[8:24] if self.v6 else self.buf[12:16])

    @property
    def dst_raw(self):
        return bytes(self.buf[24:40] if self.v6 else self.buf[16:20])

    @property
    def src_ip(self):
        return str(ipaddress.ip_address(self.src_raw))

    @property
    def dst_ip(self):
        return str(ipaddress.ip_address(self.dst_raw))

    @property
    def sport(self):
        return struct.unpack_from("!H", self.buf, self.ip_hl)[0]

    @property
    def dport(self):
        return struct.unpack_from("!H", self.buf, self.ip_hl + 2)[0]

    @property
    def seq(self):
        return struct.unpack_from("!I", self.buf, self.ip_hl + 4)[0]

    @seq.setter
    def seq(self, v):
        struct.pack_into("!I", self.buf, self.ip_hl + 4, v & MASK32)

    @property
    def ack(self):
        return struct.unpack_from("!I", self.buf, self.ip_hl + 8)[0]

    @ack.setter
    def ack(self, v):
        struct.pack_into("!I", self.buf, self.ip_hl + 8, v & MASK32)

    @property
    def ttl(self):
        return self.buf[7] if self.v6 else self.buf[8]

    @ttl.setter
    def ttl(self, v):
        self.buf[7 if self.v6 else 8] = v

    def set_ip_id(self, v):
        if not self.v6:
            struct.pack_into("!H", self.buf, 4, v & 0xFFFF)

    @property
    def ip_id(self):
        return 0 if self.v6 else struct.unpack_from("!H", self.buf, 4)[0]

    @property
    def l4_checksum_offset(self):
        return self.ip_hl + (16 if self.proto == TCP else 6)

    # --- yeniden kurma ------------------------------------------------------
    def _fix_lengths(self):
        total = len(self.buf)
        if self.v6:
            struct.pack_into("!H", self.buf, 4, total - 40)
        else:
            struct.pack_into("!H", self.buf, 2, total)
        if self.proto == UDP:
            struct.pack_into("!H", self.buf, self.ip_hl + 4, total - self.ip_hl)

    def with_payload(self, payload, seq=None):
        p = Packet.__new__(Packet)
        p.v6, p.ip_hl, p.proto, p.l4_hl = self.v6, self.ip_hl, self.proto, self.l4_hl
        p.buf = bytearray(self.buf[:self.hdr_len]) + payload
        p._fix_lengths()
        if seq is not None:
            p.seq = seq
        return p

    def reply_with_payload(self, payload):
        """Kaynak/hedef adres ve portlari degistirilmis (cevap yonunde) yeni paket."""
        p = self.with_payload(payload)
        b = p.buf
        if self.v6:
            b[8:24], b[24:40] = self.buf[24:40], self.buf[8:24]
        else:
            b[12:16], b[16:20] = self.buf[16:20], self.buf[12:16]
        h = self.ip_hl
        b[h:h + 2], b[h + 2:h + 4] = self.buf[h + 2:h + 4], self.buf[h:h + 2]
        p.ttl = 64
        return p
