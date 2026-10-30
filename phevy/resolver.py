"""DNS-over-HTTPS ile zehirlenmemis IP cozumleme + hedef alan adi listesi."""
import json
import logging
import os
import threading
import time
import urllib.parse
import urllib.request

log = logging.getLogger("phevy.dns")

DEFAULT_DOMAINS = [
    "discord.com", "discord.gg", "discordapp.com", "discordapp.net", "discord.media",
    "discordcdn.com", "discord.dev", "discord.new", "discord.gift", "discord.gifts",
    "discordstatus.com", "dis.gd", "discord.co", "discord.design", "discord.store",
    "discord.tools", "discordsays.com", "discord-activities.com", "discordactivities.com",
    "discordmerch.com", "discordpartygames.com",
]

DOH_SERVERS = [
    "https://1.1.1.1/dns-query?name={}&type=A",
    "https://8.8.8.8/resolve?name={}&type=A",
    "https://1.0.0.1/dns-query?name={}&type=A",
]


def load_domains(extra_file=None):
    domains = list(DEFAULT_DOMAINS)
    if extra_file and os.path.isfile(extra_file):
        with open(extra_file, encoding="utf-8") as f:
            for line in f:
                line = line.split("#", 1)[0].strip().lower()
                if line:
                    domains.append(line)
    return domains


class Resolver:
    def __init__(self, domains):
        self.domains = tuple(d.lower().strip(".") for d in domains)
        self._cache = {}
        self._lock = threading.Lock()
        self.target_ips = set()

    def is_target(self, name):
        name = name.lower().rstrip(".")
        return any(name == d or name.endswith("." + d) for d in self.domains)

    def resolve(self, name):
        """Ad icin IPv4 listesi; basarisizsa bos liste."""
        now = time.monotonic()
        with self._lock:
            hit = self._cache.get(name)
            if hit and hit[1] > now:
                return hit[0]
        for tmpl in DOH_SERVERS:
            try:
                req = urllib.request.Request(tmpl.format(urllib.parse.quote(name)),
                                             headers={"accept": "application/dns-json"})
                with urllib.request.urlopen(req, timeout=3) as r:
                    data = json.load(r)
            except Exception as e:  # sunucu erisilemezse siradakine gec
                log.debug("DoH %s hata: %s", tmpl, e)
                continue
            answers = [a for a in data.get("Answer", []) if a.get("type") == 1]
            ips = [a["data"] for a in answers]
            ttl = max(60, min((a.get("TTL", 300) for a in answers), default=300))
            with self._lock:
                self._cache[name] = (ips, now + ttl)
                if self.is_target(name):
                    self.target_ips.update(ips)
            log.debug("DoH %s -> %s", name, ips)
            return ips
        log.warning("DoH ile çözümlenemedi: %s", name)
        return []
