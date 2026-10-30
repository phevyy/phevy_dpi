"""IPC protokolu icin test istemcisi (Flutter uygulamasinin yapacagini taklit eder).

Kullanim (yonetici PowerShell):
    python tools\\ipc_client.py                 # python motoru
    python tools\\ipc_client.py dist\\phevy_engine.exe
    python tools\\ipc_client.py --seconds 60 --debug
"""
import argparse
import ctypes
import json
import os
import subprocess
import sys
import threading
import time

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("engine", nargs="?", help="motor exe yolu (bos: python phevy_dpi.py)")
    ap.add_argument("--seconds", type=int, default=30, help="bagli kalma suresi")
    ap.add_argument("--debug", action="store_true")
    args = ap.parse_args()

    if not ctypes.windll.shell32.IsUserAnAdmin():
        print("UYARI: Bu pencere yonetici olarak calismiyor; motor 'admin_required' hatasi verecek.\n"
              "PowerShell'i sag tik -> 'Yonetici olarak calistir' ile acip tekrar deneyin.\n")

    cmd =[args.engine, "--ipc"] if args.engine else [sys.executable, os.path.join(ROOT, "phevy_dpi.py"), "--ipc"]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, encoding="utf-8")
    state = {"value": None}

    def reader():
        for line in proc.stdout:
            ev = json.loads(line)
            if ev["type"] == "state":
                state["value"] = ev["state"]
            if ev["type"] == "stats":
                print(f"  [stats] {ev}")
            elif ev["type"] == "log":
                print(f"  [log {ev['level']}] {ev['logger']}: {ev['msg']}")
            else:
                print(f"<- {ev}")

    threading.Thread(target=reader, daemon=True).start()

    def send(obj):
        print(f"-> {obj}")
        proc.stdin.write(json.dumps(obj) + "\n")
        proc.stdin.flush()

    if args.debug:
        send({"cmd": "set_log_level", "level": "DEBUG", "id": 1})
    send({"cmd": "bogus", "id": 2})
    send({"cmd": "connect", "id": 3})

    deadline = time.time() + 90
    while state["value"] not in ("connected", "error") and time.time() < deadline:
        time.sleep(0.2)
    if state["value"] == "connected":
        time.sleep(args.seconds)
        send({"cmd": "disconnect", "id": 4})
        time.sleep(2)
    # stdin'i kapat: motor kendini kapatmali
    proc.stdin.close()
    try:
        code = proc.wait(timeout=15)
        print(f"Motor cikti, kod {code}")
    except subprocess.TimeoutExpired:
        print("HATA: motor stdin kapaninca cikmadi")
        proc.kill()
        return 1
    return 0 if state["value"] in ("connected", "stopped") else 1


if __name__ == "__main__":
    sys.exit(main())
