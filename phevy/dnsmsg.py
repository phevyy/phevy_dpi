"""Basit DNS sorgu ayristirma ve cevap uretme."""
import socket
import struct
from collections import namedtuple

QTYPE_A = 1

Query = namedtuple("Query", "id flags name qtype qclass question")


def parse_query(msg):
    if len(msg) < 12:
        return None
    qid, flags, qd = struct.unpack_from("!HHH", msg)
    if flags & 0x8000 or qd != 1:
        return None
    labels = []
    i = 12
    while True:
        if i >= len(msg):
            return None
        ln = msg[i]
        i += 1
        if ln == 0:
            break
        if ln & 0xC0 or i + ln > len(msg):
            return None
        labels.append(msg[i:i + ln].decode("ascii", "replace"))
        i += ln
    if i + 4 > len(msg):
        return None
    qtype, qclass = struct.unpack_from("!HH", msg, i)
    i += 4
    return Query(qid, flags, ".".join(labels).lower(), qtype, qclass, bytes(msg[12:i]))


def build_response(q, ips, ttl=60):
    """A sorgusuna verilen IPv4 adresleriyle cevap; ips bossa NOERROR + bos cevap."""
    flags = 0x8180 | (q.flags & 0x0100)
    answers = b"".join(
        b"\xc0\x0c" + struct.pack("!HHIH", QTYPE_A, 1, ttl, 4) + socket.inet_aton(ip) for ip in ips
    )
    return struct.pack("!6H", q.id, flags, 1, len(ips), 0, 0) + q.question + answers
