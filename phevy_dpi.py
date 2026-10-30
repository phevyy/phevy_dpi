"""phevy_dpi - Discord icin operator bagimsiz DPI atlatma araci.

Kullanim:
    phevy_dpi.py              # konsol: agi test et, calisan yontemi bul, calis
    phevy_dpi.py --scan       # kayitli yontemi yok say, bastan tara
    phevy_dpi.py --strategy fake-autottl
    phevy_dpi.py --list
    phevy_dpi.py --ipc        # uygulama modu (stdin/stdout JSON, bkz. docs/IPC.md)
"""
import argparse
import ctypes
import logging
import os
import sys
import threading

from phevy.strategies import BY_NAME, STRATEGIES

VERSION = "0.2.0"


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except OSError:
        return False


def relaunch_as_admin():
    args = sys.argv[1:] if getattr(sys, "frozen", False) else [os.path.abspath(__file__)] + sys.argv[1:]
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(f'"{a}"' for a in args), None, 1)


def run_console(args):
    from phevy.service import AUTO, Service

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(asctime)s %(levelname)s %(name)s: %(message)s", datefmt="%H:%M:%S")
    done = threading.Event()

    def emit(ev):
        if ev["type"] == "state":
            if ev["state"] == "connected":
                print(f"\nHazır. Yöntem: {ev['strategy']}. Discord'u (yeniden) başlatabilirsin.")
                if ev["message"]:
                    print(f"! {ev['message']}")
                print("Bu pencere açık kaldığı sürece çalışır. Kapatmak için Ctrl+C.")
            elif ev["state"] == "error":
                print(f"HATA: {ev['message']}")
                done.set()
        elif ev["type"] == "trying":
            print(f"  deneniyor: {ev['strategy']:<22} {ev['desc']}")
        elif ev["type"] == "stats":
            logging.getLogger("phevy").debug("istatistik: %s", ev)

    print(f"phevy_dpi {VERSION}")
    service = Service(emit)
    service.submit("connect", strategy=args.strategy or AUTO, rescan=args.scan,
                   voice_fix=not args.no_voice_fix)
    try:
        while not done.wait(1):
            pass
        input("Çıkmak için Enter...")
    except KeyboardInterrupt:
        pass
    service.close()
    print("Durduruldu.")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Discord için DPI atlatma aracı")
    ap.add_argument("--scan", action="store_true", help="kayıtlı yöntemi yok say, baştan tara")
    ap.add_argument("--strategy", choices=list(BY_NAME), help="tarama yapmadan bu yöntemi kullan")
    ap.add_argument("--no-voice-fix", action="store_true", help="ses (UDP) düzeltmesini kapat")
    ap.add_argument("--list", action="store_true", help="yöntemleri listele")
    ap.add_argument("--ipc", action="store_true", help="uygulama modu (stdin/stdout JSON)")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()

    if args.ipc:
        # Yonetici izni ust surecten (uygulamadan) gelir; yoksa connect "error" durumuyla doner.
        from phevy import ipc
        return ipc.run(VERSION)

    if args.list:
        for s in STRATEGIES:
            print(f"{s.name:<22} {s.desc}")
        return 0

    if not is_admin():
        print("Yönetici izni gerekiyor, yeniden başlatılıyor...")
        relaunch_as_admin()
        return 0
    return run_console(args)


if __name__ == "__main__":
    sys.exit(main())
