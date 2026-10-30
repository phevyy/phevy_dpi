"""Baglan / kes / tara yasam dongusu. Konsol modu ve uygulama (IPC) modu bunu kullanir.

Durumlar: stopped -> starting -> scanning -> connected; hata olursa error.
Tum islemler tek bir is parcaciginda sirayla calisir; "disconnect" taramayi hemen iptal eder.
"""
import logging
import queue
import subprocess
import threading
import time

from . import config, prober
from . import windivert as wd
from .engine import Engine
from .resolver import Resolver, load_domains
from .strategies import BY_NAME

log = logging.getLogger("phevy.service")

AUTO = "auto"
FALLBACK_STRATEGY = "fake-autottl"
WATCHDOG_SECONDS = 300
STATS_SECONDS = 1.0


def flush_dns():
    subprocess.run(["ipconfig", "/flushdns"], capture_output=True,
                   creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))


class Service:
    def __init__(self, emit):
        """emit(dict): olaylari disari ileten fonksiyon (IPC'de stdout, konsolda print)."""
        self.emit = emit
        self.cfg = config.load_config()
        self.engine = None
        self.state = "stopped"
        self.message = None
        self.code = None
        self.since = time.time()
        self._cancel = threading.Event()
        self._closed = threading.Event()
        self._q = queue.Queue()
        threading.Thread(target=self._loop, daemon=True, name="service").start()
        threading.Thread(target=self._stats_loop, daemon=True, name="stats").start()
        threading.Thread(target=self._watchdog_loop, daemon=True, name="watchdog").start()

    # --- disaridan cagrilan --------------------------------------------------
    def submit(self, cmd, **kwargs):
        if cmd == "disconnect":
            self._cancel.set()
        self._q.put((cmd, kwargs))

    def close(self):
        self._cancel.set()
        self._q.put(("disconnect", {}))
        self._q.put(None)
        self._closed.wait(timeout=10)

    def snapshot(self):
        return {"type": "state", "state": self.state, "code": self.code, "message": self.message,
                "since": self.since,
                "strategy": self.engine.strategy.name if self.engine and self.state == "connected" else None,
                "mode": self.cfg.get("mode", AUTO)}

    # --- ic isleyis ------------------------------------------------------------
    def _set_state(self, state, message=None, code=None):
        self.state, self.message, self.code, self.since = state, message, code, time.time()
        self.emit(self.snapshot())

    def _loop(self):
        while True:
            item = self._q.get()
            if item is None:
                break
            cmd, kwargs = item
            try:
                getattr(self, "_do_" + cmd)(**kwargs)
            except prober.Cancelled:
                self._stop_engine()
                self._set_state("stopped")
            except wd.WinDivertError as e:
                log.error("%s", e)
                self._stop_engine()
                self._set_state("error", str(e), e.code)
            except ConnectionError as e:
                log.error("%s", e)
                self._stop_engine()
                self._set_state("error", str(e), "no_internet")
            except Exception as e:
                log.exception("Beklenmeyen hata")
                self._stop_engine()
                self._set_state("error", f"Beklenmeyen hata: {e}", "unknown")
        self._closed.set()

    def _stop_engine(self):
        if self.engine:
            self.engine.stop()
            self.engine = None

    def _do_connect(self, strategy=None, voice_fix=True, rescan=False, extra_domains=()):
        self._stop_engine()
        self._cancel.clear()
        if strategy:
            self.cfg["mode"] = strategy
            config.save_config(self.cfg)
        self._set_state("starting")
        domains = load_domains(config.EXTRA_DOMAINS_FILE) + [d.strip().lower() for d in extra_domains if d.strip()]
        Engine.check_filters()
        self.engine = Engine(Resolver(domains), voice_fix=voice_fix)
        self.engine.start()
        flush_dns()
        self._apply_mode(rescan)
        flush_dns()

    def _do_disconnect(self):
        was_running = self.engine is not None
        self._stop_engine()
        if was_running:
            flush_dns()
        if self.state != "stopped":
            self._set_state("stopped")

    def _do_rescan(self):
        if self.engine is None:
            return
        self._cancel.clear()
        try:
            self._apply_mode(rescan=True)
        except ConnectionError as e:
            # Internet anlik gittiyse motoru kapatma, mevcut yontemle devam et.
            log.warning("%s", e)
            self._set_state("connected", str(e), "rescan_no_internet")

    def _do_set_strategy(self, name):
        if name != AUTO and name not in BY_NAME:
            raise ValueError(f"Bilinmeyen yontem: {name}")
        self.cfg["mode"] = name
        config.save_config(self.cfg)
        if self.engine is not None:
            self._cancel.clear()
            self._apply_mode(rescan=False)

    def _apply_mode(self, rescan):
        mode = self.cfg.get("mode", AUTO)
        if mode != AUTO and mode in BY_NAME:
            self.engine.set_strategy(BY_NAME[mode])
            log.info("Elle secilen yontem: %s", mode)
            self._set_state("connected")
            return
        self._set_state("scanning")
        preferred = None if rescan else BY_NAME.get(self.cfg.get("strategy", ""))
        st = prober.find_strategy(self.engine, preferred, cancel=self._cancel, on_try=self._on_try)
        if st is None:
            st = BY_NAME[FALLBACK_STRATEGY]
            self.engine.set_strategy(st)
            log.warning("Hicbir yontem testten gecemedi, varsayilan %s kullaniliyor", st.name)
            self._set_state("connected", "Hicbir yontem testten gecemedi, varsayilan kullaniliyor",
                            "no_strategy_found")
            return
        self.cfg["strategy"] = st.name
        config.save_config(self.cfg)
        log.info("Calisan yontem bulundu: %s (%s)", st.name, st.desc)
        self._set_state("connected")

    def _on_try(self, st):
        log.info("Deneniyor: %s", st.name)
        self.emit({"type": "trying", "strategy": st.name, "desc": st.desc})

    def _stats_loop(self):
        while not self._closed.wait(STATS_SECONDS):
            eng = self.engine
            if eng is not None and self.state == "connected":
                self.emit({"type": "stats", "uptime": int(time.time() - self.since), **eng.stats})

    def _watchdog_loop(self):
        fails = 0
        while not self._closed.wait(WATCHDOG_SECONDS):
            eng = self.engine
            if eng is None or self.state != "connected":
                fails = 0
                continue
            if prober.tls_check(eng.resolver, "discord.com"):
                fails = 0
                continue
            fails += 1
            log.warning("Discord'a erisim kontrolu basarisiz (%d/2)", fails)
            if fails >= 2:
                fails = 0
                self.submit("rescan")
