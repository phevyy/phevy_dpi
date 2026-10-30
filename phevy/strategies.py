"""TCP desync stratejileri. Prober bunlari sirayla dener."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Strategy:
    name: str
    desc: str
    split: tuple = ()        # bolme noktalari: "sni" (SNI ortasi), "sni0" (SNI basi) veya sayi
    disorder: bool = False   # parcalari ters sirada gonder
    fake: str = ""           # "", "badseq", "badsum", "ttl", "autottl"
    fake_ttl: int = 0

    def positions(self, n, sni_off, sni_len):
        res = set()
        for s in self.split:
            if s == "sni":
                p = sni_off + sni_len // 2 if sni_off is not None else n // 2
            elif s == "sni0":
                p = sni_off if sni_off is not None else None
            else:
                p = int(s)
            if p and 0 < p < n:
                res.add(p)
        if not res and n > 1:
            res.add(1)
        return sorted(res)


STRATEGIES = [
    Strategy("none", "Hicbir sey yapma (DPI yok)"),
    Strategy("split", "ClientHello'yu SNI ortasindan bol", split=("sni",)),
    Strategy("multisplit", "1. bayttan ve SNI ortasindan bol", split=("1", "sni")),
    Strategy("disorder", "SNI'dan bol, parcalari ters gonder", split=("sni",), disorder=True),
    Strategy("multidisorder", "1 + SNI'dan bol, ters gonder", split=("1", "sni"), disorder=True),
    Strategy("fake-badseq", "Sahte hello (yanlis SEQ) + bol", split=("sni",), fake="badseq"),
    Strategy("fake-badsum", "Sahte hello (bozuk checksum) + bol", split=("sni",), fake="badsum"),
    Strategy("fake-badseq-disorder", "Sahte hello (yanlis SEQ) + ters bol", split=("1", "sni"),
             disorder=True, fake="badseq"),
    Strategy("fake-badsum-disorder", "Sahte hello (bozuk checksum) + ters bol", split=("1", "sni"),
             disorder=True, fake="badsum"),
    Strategy("fake-autottl", "Sahte hello (otomatik TTL) + bol", split=("sni",), fake="autottl"),
    Strategy("fake-autottl-disorder", "Sahte hello (otomatik TTL) + ters bol", split=("1", "sni"),
             disorder=True, fake="autottl"),
    Strategy("fake-ttl4","Sahte hello (TTL=4) + bol", split=("sni",), fake="ttl", fake_ttl=4),
    Strategy("fake-ttl6", "Sahte hello (TTL=6) + bol", split=("sni",), fake="ttl", fake_ttl=6),
    Strategy("fake-ttl8", "Sahte hello (TTL=8) + bol", split=("sni",), fake="ttl", fake_ttl=8),
]

BY_NAME = {s.name: s for s in STRATEGIES}
