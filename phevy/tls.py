"""TLS ClientHello icinden SNI bulma ve sahte ClientHello uretme."""
import os
import struct


def find_sni(payload):
    """(sni, sni_offset, sni_len) dondurur. Bulunamazsa (None, None, None).

    Paket kesik olabilir (buyuk ClientHello birden fazla TCP segmentine bolunur);
    SNI bu segmentte degilse None doner.
    """
    none = (None, None, None)
    n = len(payload)
    if n < 6 or payload[0] != 0x16 or payload[5] != 0x01:
        return none
    i = 5 + 4 + 2 + 32  # record hdr + handshake hdr + version + random
    if i >= n:
        return none
    i += 1 + payload[i]  # session id
    if i + 2 > n:
        return none
    i += 2 + struct.unpack_from("!H", payload, i)[0]  # cipher suites
    if i >= n:
        return none
    i += 1 + payload[i]  # compression
    if i + 2 > n:
        return none
    i += 2  # extensions toplam uzunlugu
    while i + 4 <= n:
        etype, elen = struct.unpack_from("!HH", payload, i)
        i += 4
        if etype == 0:
            # server_name_list(2) name_type(1) name_len(2) name
            if i + 5 > n:
                return none
            name_len = struct.unpack_from("!H", payload, i + 3)[0]
            off = i + 5
            if off + name_len > n:
                return none
            try:
                name = payload[off:off + name_len].decode("ascii").lower()
            except UnicodeDecodeError:
                return none
            return name, off, name_len
        i += elen
    return none


def _ext(t, data):
    return struct.pack("!HH", t, len(data)) + data


def build_client_hello(sni):
    """Gercekci gorunen bir TLS 1.3 ClientHello (DPI'yi kandirmak icin)."""
    host = sni.encode()
    exts = b"".join([
        _ext(0, struct.pack("!H", len(host) + 3) + b"\x00" + struct.pack("!H", len(host)) + host),
        _ext(23, b""),
        _ext(0xFF01, b"\x00"),
        _ext(10, struct.pack("!H", 6) + bytes.fromhex("001d00170018")),
        _ext(11, b"\x01\x00"),
        _ext(35, b""),
        _ext(16, struct.pack("!H", 12) + b"\x02h2\x08http/1.1"),
        _ext(13, struct.pack("!H", 16) + bytes.fromhex("04030804040105030805050108060601")),
        _ext(51, struct.pack("!H", 36) + b"\x00\x1d" + struct.pack("!H", 32) + os.urandom(32)),
        _ext(45, b"\x01\x01"),
        _ext(43, b"\x04\x03\x04\x03\x03"),
    ])
    ciphers = bytes.fromhex("130113021303c02bc02fc02cc030cca9cca8c013c014009c009d002f0035")
    body = (b"\x03\x03" + os.urandom(32) + b"\x20" + os.urandom(32)
            + struct.pack("!H", len(ciphers)) + ciphers + b"\x01\x00"
            + struct.pack("!H", len(exts)) + exts)
    hs = b"\x01" + len(body).to_bytes(3, "big") + body
    return b"\x16\x03\x01" + struct.pack("!H", len(hs)) + hs
