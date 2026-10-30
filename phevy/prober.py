"""Bulunulan agda hangi stratejinin calistigini otomatik bulur (operator bagimsiz)."""
import logging
import socket
import ssl
import time

from .strategies import STRATEGIES

log = logging.getLogger("phevy.probe")

TEST_HOSTS = ["discord.com", "gateway.discord.gg", "cdn.discordapp.com"]
CONTROL_HOST = "www.cloudflare.com"


class Cancelled(Exception):
    pass


def tls_check(resolver, host, timeout=4.0):
    """Gercek bir TLS el sikismasi + HTTP istegi. Basariliysa True."""
    ips = resolver.resolve(host)
    if not ips:
        return False
    ctx = ssl.create_default_context()
    try:
        with socket.create_connection((ips[0], 443), timeout=timeout) as raw:
            with ctx.wrap_socket(raw, server_hostname=host) as s:
                s.sendall(f"HEAD / HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\n\r\n".encode())
                return s.recv(16).startswith(b"HTTP/")
    except (OSError, ssl.SSLError) as e:
        log.debug("%s (%s): %s", host, ips[0], e)
        return False


def strategy_works(engine, strategy):
    engine.set_strategy(strategy)
    time.sleep(0.2)
    return all(tls_check(engine.resolver, h) for h in TEST_HOSTS)


def find_strategy(engine, preferred=None, on_try=None, cancel=None):
    """Once kayitli stratejiyi, sonra listeyi sirayla dener. Calisan ilk strateji ya da None."""
    if not tls_check(engine.resolver, CONTROL_HOST):
        raise ConnectionError("Internet baglantisi yok gibi gorunuyor (kontrol sitesine erisilemedi).")
    order = list(STRATEGIES)
    if preferred:
        order.sort(key=lambda s: s.name != preferred.name)
    for st in order:
        if cancel is not None and cancel.is_set():
            raise Cancelled()
        if on_try:
            on_try(st)
        if strategy_works(engine, st):
            return st
    return None
