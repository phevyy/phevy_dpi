# phevy_dpi

**[Türkçe](#türkçe)** · **[English](#english)**

Discord için operatörden bağımsız DPI atlatma aracı. VPN değildir, ping etkilenmez.
ISP-agnostic DPI bypass for Discord. Not a VPN, no added latency.

---

## Türkçe

phevy, Türkiye'deki Discord engelini aşmak için yazılmış bir Windows uygulamasıdır.
VPN değildir: trafik başka bir sunucudan geçmez, doğrudan Discord'a gider. Sadece Discord
bağlantılarının ilk paketleri değiştirilir. Bu yüzden oyun pingi ve indirme hızı etkilenmez.

### İndir ve kur

1. [Releases](../../releases/latest) sayfasından `phevy_kurulum_X.exe` dosyasını indir.
2. Kurulumu çalıştır. "Windows Defender dışlaması ekle" seçeneğini işaretli bırak.
3. phevy'yi aç ve güç düğmesine bas. Uygulama ağını tarayıp çalışan yöntemi kendisi bulur.
4. Discord'u tamamen kapatıp yeniden aç.

Gereksinimler: Windows 10/11 (64 bit), yönetici izni.

> **Windows Defender uyarısı:** phevy, paketleri yönlendirmek için açık kaynaklı
> [WinDivert](https://github.com/basil00/WinDivert) sürücüsünü kullanır. Paketleri değiştirebildiği için
> Defender onu "HackTool" olarak işaretler. GoodbyeDPI ve zapret de aynı sürücüyü kullanır ve aynı uyarıyı
> alır. Defender kurulum dosyasını indirirken engellerse: Windows Güvenliği → Virüs ve tehdit koruması →
> Koruma geçmişi → ilgili kayıt → **İzin ver**.

### Nasıl çalışır?

| Katman | Sorun | Çözüm |
|---|---|---|
| DNS | Operatör DNS'i yanlış IP döndürür | Discord alan adlarına giden DNS sorguları yakalanır, DNS-over-HTTPS (1.1.1.1 / 8.8.8.8) ile cevaplanır |
| TLS (TCP 443) | DPI, ClientHello içindeki site adını (SNI) okuyup bağlantıyı keser | Önüne sahte bir ClientHello eklenir (otomatik TTL ile DPI'ya ulaşır, sunucuya ulaşmaz), gerçek paket bölünür |
| QUIC (UDP 443) | HTTP/3'ün site adı da okunabilir | Discord'a giden QUIC düşürülür, uygulama TCP'ye geçer |
| Ses (UDP) | Discord ses bağlantısının ilk paketi tanınıp engellenir | İlk paketten önce rastgele çöp paketler gönderilir |

Paket filtreleri sadece Discord trafiğini yakalar. Oyun ve diğer trafik sürücüden hiç geçmez.

**Operatörden bağımsız:** Her açılışta bulunulan ağda gerçek TLS bağlantılarıyla 14 yöntem sırayla
denenir. Çalışan ilk yöntem kaydedilir ve sonraki açılışta ilk o denenir. Uygulama çalışırken 5 dakikada
bir erişimi kontrol eder; erişim kesilirse yeniden tarar. Sahte paketin TTL değeri her bağlantı için,
sunucuya olan hop sayısından otomatik hesaplanır.

### Uygulama

- Ana sayfa: bağlan/kes, tarama ilerlemesi, kullanılan yöntem, DNS/TLS/ses sayaçları
- Loglar: canlı akış, filtre, arama, kopyala/kaydet. Tam log: `%APPDATA%\phevy_dpi\log.txt`
- Ayarlar: Windows açılışında başlat, otomatik bağlan, tepsiye küçült, ses düzeltmesi, yöntem seçimi, ek alan adları
- Sistem tepsisi simgesi: duruma göre renk değiştirir (gri / mor / yeşil / kırmızı)

GoodbyeDPI, zapret veya başka bir WinDivert aracı aynı anda açık olmamalıdır.

### Konsol sürümü

`dist\phevy_dpi.exe` arayüzsüz, tek dosya bir sürümdür:

```
phevy_dpi.exe                       # otomatik
phevy_dpi.exe --scan                # kayıtlı yöntemi yok say, baştan tara
phevy_dpi.exe --strategy disorder   # elle seç
phevy_dpi.exe --list                # yöntemler
phevy_dpi.exe -v                    # ayrıntılı log
```

Ek alan adı eklemek için `%APPDATA%\phevy_dpi\domains.txt` dosyasına her satıra bir alan adı yazın.

### Derleme

Gereksinimler: Python 3.13 + PyInstaller, Flutter (Windows desteğiyle) + Visual Studio "Desktop development with C++", Inno Setup 6.

1. [WinDivert 2.2.2-A](https://github.com/basil00/WinDivert/releases/tag/v2.2.2) zip'ini indirin.
   İçindeki `x64\WinDivert.dll` ve `x64\WinDivert64.sys` dosyalarını `third_party\` klasörüne koyun.
2. `pip install pyinstaller`
3. `release.bat` → motor, uygulama ve `dist\installer\phevy_kurulum_X.exe`

Sadece motor: `build.bat` → `dist\phevy_dpi.exe` (konsol) ve `dist\phevy_engine\` (uygulamanın başlattığı penceresiz motor).
Sürüm numarası `installer\phevy.iss`, `flutter_app\pubspec.yaml`, `flutter_app\lib\app.dart` ve `phevy_dpi.py` dosyalarında birlikte güncellenmelidir.

Testler: `python -m unittest discover -s tests` ve `cd flutter_app && flutter test`.
Uygulama ile motor arasındaki protokol: [docs/IPC.md](docs/IPC.md). Protokol testi (yönetici izniyle):
`python tools\ipc_client.py dist\phevy_engine\phevy_engine.exe --debug`

### Proje yapısı

```
phevy/          Python motoru (WinDivert, DNS, TLS, strateji taraması, IPC)
phevy_dpi.py    Motorun giriş noktası (konsol ve --ipc modu)
flutter_app/    Windows masaüstü uygulaması (Flutter)
installer/      Inno Setup kurulum betiği
docs/IPC.md     Uygulama <-> motor protokolü
design/         Stitch arayüz tasarımları
```

### Lisans

[GPL-3.0](LICENSE). Kodu kullanabilir ve değiştirebilirsiniz; dağıttığınız sürümlerin kaynak kodunu da
GPL-3.0 ile açık paylaşmanız gerekir. Yazılım hiçbir garanti olmadan, olduğu gibi sunulur.
Üçüncü taraf bileşenler ve lisansları: [installer/THIRD_PARTY.txt](installer/THIRD_PARTY.txt).

---

## English

phevy is a Windows app for getting around the Discord block in Turkey. It is not a VPN: traffic is
not routed through another server, it goes straight to Discord. Only the first packets of Discord
connections are modified, so game ping and download speed are not affected.

### Download and install

1. Download `phevy_kurulum_X.exe` from [Releases](../../releases/latest).
2. Run the installer and leave "Windows Defender dışlaması ekle" (add Defender exclusion) checked.
3. Open phevy and press the power button. It scans your network and finds a working method on its own.
4. Fully quit and reopen Discord.

Requirements: Windows 10/11 (64-bit), administrator rights. The app UI is in Turkish.

> **Windows Defender warning:** phevy uses the open-source [WinDivert](https://github.com/basil00/WinDivert)
> driver to divert packets. Because it can modify packets, Defender flags it as a "HackTool". GoodbyeDPI and
> zapret use the same driver and get the same warning. If Defender blocks the installer download:
> Windows Security → Virus & threat protection → Protection history → the entry → **Allow**.

### How it works

| Layer | Problem | Fix |
|---|---|---|
| DNS | ISP DNS returns wrong IPs | DNS queries for Discord domains are intercepted and answered via DNS-over-HTTPS (1.1.1.1 / 8.8.8.8) |
| TLS (TCP 443) | DPI reads the hostname (SNI) in the ClientHello and kills the connection | A fake ClientHello is sent first (auto TTL: reaches the DPI, dies before the server), then the real one is split |
| QUIC (UDP 443) | HTTP/3 hostnames are readable too | QUIC to Discord is dropped so the app falls back to TCP |
| Voice (UDP) | The first packet of a Discord voice connection is recognized and blocked | Random junk packets are sent before the first packet |

The packet filters only capture Discord traffic. Game and other traffic never passes through the driver.

**ISP-agnostic:** On every start, 14 methods are tried in order with real TLS connections on the
current network. The first working one is saved and tried first next time. While running, access is
checked every 5 minutes and the network is rescanned if it breaks. The fake packet's TTL is computed per
connection from the hop count to the server.

### The app

- Home: connect/disconnect, scan progress, active method, DNS/TLS/voice counters
- Logs: live stream, filter, search, copy/save. Full log: `%APPDATA%\phevy_dpi\log.txt`
- Settings: start with Windows, auto-connect, minimize to tray, voice fix, method selection, extra domains
- Tray icon: changes color with state (gray / violet / green / red)

GoodbyeDPI, zapret or any other WinDivert tool must not run at the same time.

### Console version

`dist\phevy_dpi.exe` is a single-file version without a UI:

```
phevy_dpi.exe                       # automatic
phevy_dpi.exe --scan                # ignore saved method, rescan
phevy_dpi.exe --strategy disorder   # pick manually
phevy_dpi.exe --list                # list methods
phevy_dpi.exe -v                    # verbose log
```

To add domains, put one per line in `%APPDATA%\phevy_dpi\domains.txt`.

### Building

Requirements: Python 3.13 + PyInstaller, Flutter (with Windows support) + Visual Studio "Desktop development with C++", Inno Setup 6.

1. Download the [WinDivert 2.2.2-A](https://github.com/basil00/WinDivert/releases/tag/v2.2.2) zip and put
   `x64\WinDivert.dll` and `x64\WinDivert64.sys` into `third_party\`.
2. `pip install pyinstaller`
3. `release.bat` → engine, app and `dist\installer\phevy_kurulum_X.exe`

Engine only: `build.bat` → `dist\phevy_dpi.exe` (console) and `dist\phevy_engine\` (headless engine started by the app).
Bump the version in `installer\phevy.iss`, `flutter_app\pubspec.yaml`, `flutter_app\lib\app.dart` and `phevy_dpi.py` together.

Tests: `python -m unittest discover -s tests` and `cd flutter_app && flutter test`.
App ↔ engine protocol: [docs/IPC.md](docs/IPC.md). Protocol test (as administrator):
`python tools\ipc_client.py dist\phevy_engine\phevy_engine.exe --debug`

### Project layout

```
phevy/          Python engine (WinDivert, DNS, TLS, strategy scan, IPC)
phevy_dpi.py    Engine entry point (console and --ipc mode)
flutter_app/    Windows desktop app (Flutter)
installer/      Inno Setup script
docs/IPC.md     App <-> engine protocol (Turkish)
design/         Stitch UI designs
```

### License

[GPL-3.0](LICENSE). You may use and modify the code; versions you distribute must also be released as
source under GPL-3.0. The software is provided as is, without any warranty.
Third-party components and licenses: [installer/THIRD_PARTY.txt](installer/THIRD_PARTY.txt).
