"""Uygulama modu: stdin'den JSON komutlar, stdout'a JSON olaylar (satir basina bir nesne).

Protokol: docs/IPC.md
"""
import ctypes
import io
import json
import logging
import logging.handlers
import os
import sys
import threading
import time

from . import config
from .service import Service
from .strategies import STRATEGIES

PROTOCOL_VERSION = 1
# Servise iletilen komutlar ve kabul ettikleri parametreler
SERVICE_COMMANDS = {
    "connect": {"strategy", "voice_fix", "rescan", "extra_domains"},
    "disconnect": set(),
    "rescan": set(),
    "set_strategy": {"name"},
}
LEVELS = {"DEBUG": logging.DEBUG, "INFO": logging.INFO, "WARNING": logging.WARNING, "ERROR": logging.ERROR}

log = logging.getLogger("phevy.ipc")


class _Writer:
    def __init__(self, stream):
        self._s = stream
        self._lock = threading.Lock()

    def __call__(self, obj):
        line = json.dumps(obj, ensure_ascii=False) + "\n"
        with self._lock:
            try:
                self._s.write(line)
                self._s.flush()
            except (OSError, ValueError):
                pass  # uygulama kapandi


class _EventHandler(logging.Handler):
    def __init__(self, emit):
        super().__init__()
        self._emit = emit

    def emit(self, record):
        self._emit({"type": "log", "ts": record.created, "level": record.levelname,
                    "logger": record.name, "msg": record.getMessage()})


def _setup_logging(emit, level):
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)
    os.makedirs(config.CONFIG_DIR, exist_ok=True)
    fh = logging.handlers.RotatingFileHandler(config.LOG_FILE, maxBytes=1_000_000, backupCount=2,
                                              encoding="utf-8")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s"))
    root.addHandler(fh)
    eh = _EventHandler(emit)
    eh.setLevel(level)
    root.addHandler(eh)
    return eh


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except OSError:
        return False


def run(version):
    if sys.stdin is None or sys.stdout is None:
        return 2  # cift tiklanarak acildi; bu mod sadece uygulama tarafindan baslatilir
    # Pencere modunda derlenince sys.stdout/stdin ust surecin borulari olur; UTF-8'e zorla.
    out = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", newline="\n")
    inp = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8")
    emit = _Writer(out)
    handler = _setup_logging(emit, logging.INFO)

    service = Service(emit)
    emit({"type": "hello", "version": version, "protocol": PROTOCOL_VERSION,
          "admin": is_admin(), "log_file": config.LOG_FILE,
          "strategies": [{"name": s.name, "desc": s.desc} for s in STRATEGIES]})
    emit(service.snapshot())
    log.info("phevy motoru %s basladi", version)

    for line in inp:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
            cmd = msg.pop("cmd")
            req_id = msg.pop("id", None)
        except (ValueError, KeyError, AttributeError):
            emit({"type": "result", "id": None, "ok": False, "error": "Gecersiz komut"})
            continue
        ok, error = True, None
        if cmd in SERVICE_COMMANDS:
            unknown = set(msg) - SERVICE_COMMANDS[cmd]
            if unknown:
                ok, error = False, f"Bilinmeyen parametre: {', '.join(sorted(unknown))}"
            else:
                service.submit(cmd, **msg)
        elif cmd == "get_state":
            emit(service.snapshot())
        elif cmd == "set_log_level":
            level = LEVELS.get(str(msg.get("level", "")).upper())
            if level is None:
                ok, error = False, "Gecersiz seviye"
            else:
                handler.setLevel(level)
        elif cmd == "quit":
            break
        else:
            ok, error = False, f"Bilinmeyen komut: {cmd}"
        emit({"type": "result", "id": req_id, "cmd": cmd, "ok": ok, "error": error})

    # stdin kapandi (uygulama kapandi/coktu) ya da quit: suruculeri birakip cik.
    log.info("Motor kapaniyor")
    service.close()
    time.sleep(0.1)
    return 0
