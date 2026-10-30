# phevy motoru IPC protokolü (v1)

Uygulama motoru `phevy_engine.exe --ipc` ile başlatır ve stdin/stdout borularıyla konuşur.

- Her satır bir JSON nesnesidir (UTF-8, `\n` ile biter).
- Uygulama → motor: **komutlar** (stdin).
- Motor → uygulama: **olaylar** (stdout). stdout'a protokol dışında hiçbir şey yazılmaz.
- Motor WinDivert sürücüsünü açabilmek için **yönetici izni** ister ve bu izni üst süreçten (uygulamadan) alır. Uygulama `requireAdministrator` manifest'iyle derlenmelidir.
- **stdin kapanırsa** (uygulama kapandı ya da çöktü) motor bağlantıyı keser ve çıkar. Sürücü takılı kalmaz.
- Tam loglar (DEBUG dahil) her zaman `%APPDATA%\phevy_dpi\log.txt` dosyasına da yazılır (1 MB × 3 dosya, dönüşümlü). Dosyanın yolu `hello` olayında gelir.

## Komutlar

`id` isteğe bağlıdır. Verilirse aynı `id` ile bir `result` olayı döner.

| Komut | Parametreler | Açıklama |
|---|---|---|
| `connect` | `strategy?`: `"auto"` veya yöntem adı · `rescan?`: bool · `voice_fix?`: bool (varsayılan true) · `extra_domains?`: string[] | Motoru başlatır. `auto` ise ağı tarar. `strategy` verilirse ayara kaydedilir. |
| `disconnect` | – | Durdurur. Devam eden taramayı hemen iptal eder. |
| `rescan` | – | Bağlıyken kayıtlı yöntemi yok sayıp baştan tarar. |
| `set_strategy` | `name`: `"auto"` veya yöntem adı | Modu değiştirip kaydeder. Bağlıysa hemen uygular. |
| `get_state` | – | Güncel `state` olayını yeniden gönderir. |
| `set_log_level` | `level`: `DEBUG` / `INFO` / `WARNING` / `ERROR` | stdout'a giden log seviyesini ayarlar (varsayılan INFO). Dosyadaki seviye değişmez. |
| `quit` | – | Bağlantıyı kesip çıkar. |

```json
{"cmd": "connect", "id": 1, "strategy": "auto"}
{"cmd": "disconnect", "id": 2}
```

`result` olayı komutun **kabul edildiğini** bildirir, bitip bitmediğini değil. Komutun sonucu `state` olaylarıyla gelir.

## Olaylar

### `hello`
Motor açılır açılmaz bir kez gönderilir.
`admin` false ise `connect` her zaman `admin_required` ile biter. Uygulama bunu baştan gösterebilir.
```json
{"type": "hello", "version": "0.2.0", "protocol": 1, "admin": true, "log_file": "C:\\...\\log.txt",
 "strategies": [{"name": "none", "desc": "..."}, {"name": "fake-autottl", "desc": "..."}]}
```

### `state`
Durum her değiştiğinde gönderilir. Ayrıca `get_state` ile de istenebilir.
```json
{"type": "state", "state": "connected", "code": null, "message": null,
 "since": 1793342222.59, "strategy": "fake-autottl", "mode": "auto"}
```

| Alan | Açıklama |
|---|---|
| `state` | `stopped` · `starting` · `scanning` · `connected` · `error` |
| `strategy` | Kullanılan yöntem. Sadece `connected` durumunda dolu. |
| `mode` | Kullanıcının seçimi: `auto` ya da yöntem adı |
| `since` | Bu duruma geçilen an (Unix zamanı, saniye) |
| `code` | Uygulamanın kendi Türkçe mesajını göstermesi için sabit kod (aşağıda) |
| `message` | Teknik açıklama. Log ve hata ayrıntısı için. |

**`code` değerleri**

| Kod | Durum | Önerilen mesaj |
|---|---|---|
| `admin_required` | error | Uygulama yönetici olarak çalışmıyor. |
| `driver_missing` | error | WinDivert dosyaları eksik. Büyük ihtimalle antivirüs sildi, uygulamayı yeniden kurun ve Defender dışlaması ekleyin. |
| `driver_blocked` | error | Sürücü engellendi (antivirüs, Defender ya da Bellek Bütünlüğü). |
| `driver_signature` | error | Sürücü imzası doğrulanamadı. |
| `driver_conflict` | error | Başka bir DPI aracı açık (GoodbyeDPI, zapret vb.). Kapatıp tekrar deneyin. |
| `bfe_stopped` | error | Windows "Base Filtering Engine" servisi çalışmıyor. |
| `driver_error` | error | Sürücü açılamadı. Ayrıntı `message` alanında. |
| `no_internet` | error | İnternet bağlantısı yok. |
| `unknown` | error | Beklenmeyen hata. Logları paylaşın. |
| `no_strategy_found` | connected | Hiçbir yöntem testten geçemedi, varsayılan yöntemle çalışıyor. Discord açılmayabilir. |
| `rescan_no_internet` | connected | Yeniden tarama sırasında internet yoktu, mevcut yöntemle devam ediliyor. |

### `trying`
Tarama sırasında denenen her yöntem için gönderilir.
```json
{"type": "trying", "strategy": "fake-badseq", "desc": "Sahte hello (yanlis SEQ) + bol"}
```

### `stats`
`connected` durumunda saniyede bir gönderilir. Sayaçlar bağlantı başından beri toplamdır.
```json
{"type": "stats", "uptime": 125, "dns": 14, "tls": 37, "voice": 2, "quic_drop": 0}
```

### `log`
```json
{"type": "log", "ts": 1793342222.59, "level": "INFO", "logger": "phevy.service", "msg": "..."}
```

### `result`
```json
{"type": "result", "id": 1, "cmd": "connect", "ok": true, "error": null}
```

## Örnek akış

```
<- hello
<- state stopped
-> {"cmd":"connect","id":1}
<- result id=1 ok
<- state starting
<- state scanning
<- trying none ... trying fake-autottl
<- state connected strategy=fake-autottl
<- stats (her saniye)
-> {"cmd":"disconnect","id":2}
<- result id=2 ok
<- state stopped
```

Test istemcisi: `python tools\ipc_client.py [dist\phevy_engine.exe] [--seconds 30] [--debug]`
