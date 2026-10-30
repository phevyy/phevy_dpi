# phevy_dpi

Discord için operatörden bağımsız DPI atlatma aracı. VPN değildir: trafik yine doğrudan
Discord'a gider, sadece her bağlantının ilk paketi değiştirilir. Bu yüzden ping etkilenmez.

## Ne yapar?

| Katman | Sorun | Çözüm |
|---|---|---|
| DNS | Operatör DNS'i yanlış IP döndürür | Discord alan adlarına giden DNS sorguları yakalanır, DNS-over-HTTPS (1.1.1.1 / 8.8.8.8) ile cevaplanır |
| TLS (TCP 443) | DPI, ClientHello içindeki SNI'yi (`discord.com`) okuyup bağlantıyı keser | ClientHello bölünür / ters gönderilir / önüne sahte bir hello eklenir |
| QUIC (UDP 443) | HTTP/3 SNI'si de okunabilir | Discord'a giden QUIC düşürülür, uygulama TCP'ye geçer |
| Ses (UDP) | Discord ses "IP Discovery" paketi tanınıp engellenir | İlk paketten önce rastgele çöp paketler gönderilir |

Sadece Discord alan adları ve IP'leri etkilenir. Oyun ve diğer trafik sürücüden hiç geçmez.

## Operatörden bağımsız olması

Her açılışta bulunulan ağda gerçek TLS bağlantılarıyla (`discord.com`, `gateway.discord.gg`,
`cdn.discordapp.com`) yöntemler sırayla denenir. Çalışan ilk yöntem
`%APPDATA%\phevy_dpi\config.json` dosyasına kaydedilir ve sonraki açılışta ilk o denenir.
Çalışırken 5 dakikada bir kontrol yapılır. Erişim kesilirse yeniden taranır.

## Kullanım

```
phevy_dpi.exe                       # otomatik
phevy_dpi.exe --scan                # baştan tara
phevy_dpi.exe --strategy disorder   # elle seç
phevy_dpi.exe --list                # yöntemler
phevy_dpi.exe -v                    # ayrıntılı log
```

Ek alan adı eklemek için `%APPDATA%\phevy_dpi\domains.txt` dosyasına her satıra bir alan adı yazın.

GoodbyeDPI, zapret veya başka bir WinDivert aracı aynı anda açık olmamalıdır.

## Derleme

1. [WinDivert 2.2.2-A](https://github.com/basil00/WinDivert/releases/tag/v2.2.2) zip'ini indirin.
   Içindeki `x64\WinDivert.dll` ve `x64\WinDivert64.sys` dosyalarını `third_party\` klasörüne koyun.
2. `pip install pyinstaller`
3. `build.bat` → `dist\phevy_dpi.exe` (konsol) ve `dist\phevy_engine.exe` (uygulamanın başlattığı penceresiz motor)

Tam sürüm (motor + uygulama + kurulum dosyası): `release.bat` → `dist\installer\phevy_kurulum_X.exe`.
Inno Setup 6 gerekir. Sürüm numarası `installer\phevy.iss`, `flutter_app\pubspec.yaml`,
`flutter_app\lib\app.dart` ve `phevy_dpi.py` dosyalarında birlikte güncellenmelidir.

Uygulama ile motor arasındaki protokol: [docs/IPC.md](docs/IPC.md).
Protokol testi (yönetici izniyle): `python tools\ipc_client.py dist\phevy_engine.exe --debug`

Testler: `python -m unittest discover -s tests`

## Windows Defender uyarısı

WinDivert imzalı ve açık kaynaklı bir sürücüdür. Ancak paketleri değiştirebildiği için Defender
onu "HackTool / PUA" olarak işaretler. GoodbyeDPI ve zapret için de durum aynıdır. Çalıştırmak
için programın bulunduğu klasörü Defender dışlamalarına eklemek gerekir:
Windows Güvenliği → Virüs ve tehdit koruması → Ayarları yönet → Dışlamalar.
