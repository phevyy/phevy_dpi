"""WinDivert 2.2 icin minimal ctypes baglayicisi."""
import ctypes
import os
import sys

LAYER_NETWORK = 0
FLAG_SNIFF = 1
SHUTDOWN_BOTH = 3
MAX_PACKET = 0xFFFF

ERROR_NO_DATA = 232
ERROR_OPERATION_ABORTED = 995

_ERRORS = {
    2: "WinDivert64.sys bulunamadi (dll ile ayni klasorde olmali)",
    5: "Yonetici izni gerekli",
    87: "Gecersiz filtre/parametre",
    577: "Surucu imzasi dogrulanamadi",
    654: "Baska surumde bir WinDivert surucusu zaten yuklu (GoodbyeDPI/zapret acik mi?)",
    1060: "WinDivert servisi bulunamadi",
    1275: "Surucu engellendi (antivirus/Defender veya Secure Boot politikasi)",
    1753: "Base Filtering Engine servisi calismiyor",
}


class Address(ctypes.Structure):
    """WINDIVERT_ADDRESS (80 bayt). Bit alanlarini elle yonetiyoruz."""

    _fields_ = [
        ("timestamp", ctypes.c_int64),
        ("bits", ctypes.c_uint32),
        ("reserved2", ctypes.c_uint32),
        ("data", ctypes.c_uint8 * 64),
    ]

    OUTBOUND = 1 << 17
    IPV6 = 1 << 20

    @property
    def outbound(self):
        return bool(self.bits & self.OUTBOUND)

    @outbound.setter
    def outbound(self, value):
        if value:
            self.bits |= self.OUTBOUND
        else:
            self.bits &= ~self.OUTBOUND

    def copy(self):
        a = Address()
        ctypes.memmove(ctypes.byref(a), ctypes.byref(self), ctypes.sizeof(Address))
        return a


# Uygulamanin kendi mesajini gosterebilmesi icin Windows hata kodu -> sabit kod
_CODES = {
    2: "driver_missing",
    5: "admin_required",
    577: "driver_signature",
    654: "driver_conflict",
    1275: "driver_blocked",
    1753: "bfe_stopped",
}


class WinDivertError(OSError):
    def __init__(self, message, code="driver_error"):
        super().__init__(message)
        self.code = code


def _find_dll():
    roots = []
    if hasattr(sys, "_MEIPASS"):
        roots.append(sys._MEIPASS)
    here = os.path.dirname(os.path.abspath(__file__))
    roots += [here, os.path.join(here, "..", "third_party"), os.path.dirname(sys.executable)]
    for r in roots:
        p = os.path.abspath(os.path.join(r, "WinDivert.dll"))
        if os.path.isfile(p):
            return p
    raise WinDivertError("WinDivert.dll bulunamadi. third_party klasorune koyun.", "driver_missing")


_dll = None


def _lib():
    global _dll
    if _dll is None:
        dll = ctypes.WinDLL(_find_dll(), use_last_error=True)
        dll.WinDivertOpen.restype = ctypes.c_void_p
        dll.WinDivertOpen.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_int16, ctypes.c_uint64]
        dll.WinDivertRecv.restype = ctypes.c_bool
        dll.WinDivertRecv.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint,
                                      ctypes.POINTER(ctypes.c_uint), ctypes.POINTER(Address)]
        dll.WinDivertSend.restype = ctypes.c_bool
        dll.WinDivertSend.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint,
                                      ctypes.POINTER(ctypes.c_uint), ctypes.POINTER(Address)]
        dll.WinDivertShutdown.restype = ctypes.c_bool
        dll.WinDivertShutdown.argtypes = [ctypes.c_void_p, ctypes.c_int]
        dll.WinDivertClose.restype = ctypes.c_bool
        dll.WinDivertClose.argtypes = [ctypes.c_void_p]
        dll.WinDivertHelperCalcChecksums.restype = ctypes.c_bool
        dll.WinDivertHelperCalcChecksums.argtypes = [ctypes.c_void_p, ctypes.c_uint,
                                                     ctypes.POINTER(Address), ctypes.c_uint64]
        dll.WinDivertHelperCompileFilter.restype = ctypes.c_bool
        dll.WinDivertHelperCompileFilter.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p,
                                                     ctypes.c_uint, ctypes.POINTER(ctypes.c_char_p),
                                                     ctypes.POINTER(ctypes.c_uint)]
        _dll = dll
    return _dll


def check_filter(filt):
    """Filtreyi derler; hata varsa (mesaj, konum) dondurur. Yonetici izni gerektirmez."""
    err = ctypes.c_char_p()
    pos = ctypes.c_uint()
    if _lib().WinDivertHelperCompileFilter(filt.encode(), LAYER_NETWORK, None, 0,
                                           ctypes.byref(err), ctypes.byref(pos)):
        return None
    return (err.value or b"?").decode(), pos.value


def calc_checksums(buf, addr):
    """bytearray uzerinde yerinde checksum hesaplar ve addr bayraklarini ayarlar."""
    cbuf = (ctypes.c_char * len(buf)).from_buffer(buf)
    _lib().WinDivertHelperCalcChecksums(cbuf, len(buf), ctypes.byref(addr), 0)


class Handle:
    def __init__(self, filt, priority=0, flags=0):
        lib = _lib()
        h = lib.WinDivertOpen(filt.encode(), LAYER_NETWORK, priority, flags)
        if h is None or h == ctypes.c_void_p(-1).value:
            code = ctypes.get_last_error()
            raise WinDivertError(f"WinDivertOpen basarisiz ({code}): {_ERRORS.get(code, ctypes.FormatError(code))}",
                                 _CODES.get(code, "driver_error"))
        self._h = h
        self._buf = (ctypes.c_char * MAX_PACKET)()
        self._closed = False

    def recv(self):
        """(bytearray, Address) dondurur; handle kapatildiysa None."""
        addr = Address()
        n = ctypes.c_uint()
        if not _lib().WinDivertRecv(self._h, self._buf, MAX_PACKET, ctypes.byref(n), ctypes.byref(addr)):
            code = ctypes.get_last_error()
            if self._closed or code in (ERROR_NO_DATA, ERROR_OPERATION_ABORTED):
                return None
            raise WinDivertError(f"WinDivertRecv basarisiz ({code})")
        return bytearray(self._buf.raw[:n.value]), addr

    def send(self, buf, addr, recalc=True):
        if recalc:
            calc_checksums(buf, addr)
        cbuf = (ctypes.c_char * len(buf)).from_buffer(buf)
        return _lib().WinDivertSend(self._h, cbuf, len(buf), None, ctypes.byref(addr))

    def close(self):
        if not self._closed:
            self._closed = True
            _lib().WinDivertShutdown(self._h, SHUTDOWN_BOTH)
            _lib().WinDivertClose(self._h)
