import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'engine.dart';
import 'screens/home.dart';
import 'screens/logs.dart';
import 'screens/onboarding.dart';
import 'screens/settings_screen.dart';
import 'settings.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Uygulama durumu ve eylemleri: motor, ayarlar, tepsi simgesi, pencere.
class AppController extends ChangeNotifier with TrayListener, WindowListener {
  static const appVersion = '0.2.0';

  final engine = EngineClient();
  final settings = AppSettings();
  int tab = 0;
  EngineState? _trayState;

  Future<void> init() async {
    await settings.load();
    engine.addListener(_onEngine);
    settings.addListener(notifyListeners);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    trayManager.addListener(this);
    await _updateTray();
    await engine.start();
    if (settings.verboseLogs) engine.setVerbose(true);
    if (settings.onboardingDone && settings.autoConnect) connect();
  }

  void _onEngine() {
    if (engine.state != _trayState) _updateTray();
    notifyListeners();
  }

  // --- eylemler ----------------------------------------------------------------
  void goTo(int i) {
    tab = i;
    notifyListeners();
  }

  void connect() => engine.connect(voiceFix: settings.voiceFix, extraDomains: settings.extraDomains);

  void toggle() {
    switch (engine.state) {
      case EngineState.stopped || EngineState.error:
        connect();
      default:
        engine.disconnect();
    }
  }

  /// Ses duzeltmesi / alan adlari degisince calisan baglantiyi yeni ayarlarla yeniden kurar.
  void reconnectIfConnected() {
    if (engine.state == EngineState.connected || engine.busy) connect();
  }

  void setVerboseLogs(bool v) {
    settings.setVerboseLogs(v);
    engine.setVerbose(v);
  }

  Future<void> relaunchAsAdmin() async {
    await Process.start('powershell.exe', [
      '-NoProfile', '-WindowStyle', 'Hidden', '-Command',
      'Start-Process -FilePath "${Platform.resolvedExecutable}" -Verb RunAs',
    ]);
    await quit();
  }

  Future<void> quit() async {
    await engine.shutdown();
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> handleClose() async {
    if (settings.minimizeToTray) {
      await windowManager.hide();
    } else {
      await quit();
    }
  }

  void showDefenderGuide(BuildContext context) {
    final dir = File(Platform.resolvedExecutable).parent.path;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.high,
        title: Text('Defender dışlaması ekleme', style: T.headlineMd.copyWith(color: C.onSurface)),
        content: SizedBox(
          width: 340,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (i, step) in const [
              'Aşağıdaki düğmeyle Windows Güvenliği\'ni aç.',
              '"Virüs ve tehdit koruması ayarları" altında "Ayarları yönet"e tıkla.',
              'En altta "Dışlamalar" → "Dışlama ekle veya kaldır" → "Dışlama ekle" → "Klasör".',
              'Aşağıdaki klasörü seç.',
              'Defender dosyaları zaten sildiyse "Koruma geçmişi"nden geri yükle ya da uygulamayı yeniden kur.',
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. $step', style: T.bodySm.copyWith(color: C.onSurface)),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.lowest, borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Expanded(child: SelectableText(dir, style: T.monoXs.copyWith(color: C.secondary))),
                IconButton(
                  tooltip: 'Kopyala',
                  icon: const Icon(Icons.copy, size: 16, color: C.onVariant),
                  onPressed: () => Clipboard.setData(ClipboardData(text: dir)),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(
              'WinDivert açık kaynaklıdır (github.com/basil00/WinDivert). Paketleri değiştirebildiği için '
              'Defender onu "HackTool" olarak sınıflandırır; GoodbyeDPI ve zapret de aynı sürücüyü kullanır.',
              style: T.labelSm.copyWith(color: C.muted),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: C.primary, foregroundColor: C.onPrimary),
            onPressed: () => launchUrl(Uri.parse('windowsdefender://threatsettings')),
            icon: const Icon(Icons.shield_outlined, size: 16),
            label: const Text('Windows Güvenliği\'ni aç'),
          ),
        ],
      ),
    );
  }

  // --- tepsi -------------------------------------------------------------------
  Future<void> _updateTray() async {
    final s = engine.state;
    _trayState = s;
    final (icon, tip) = switch (s) {
      EngineState.connected => ('tray_on', 'phevy • Bağlı (${engine.strategy ?? ''})'),
      EngineState.error => ('tray_error', 'phevy • Hata'),
      EngineState.stopped => ('tray_off', 'phevy • Kapalı'),
      _ => ('tray_busy', 'phevy • Taranıyor…'),
    };
    await trayManager.setIcon('assets/icons/$icon.ico');
    await trayManager.setToolTip(tip);
    final on = s == EngineState.connected || engine.busy;
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'phevy\'yi göster'),
      MenuItem.separator(),
      MenuItem(key: 'toggle', label: on ? 'Bağlantıyı kes' : 'Bağlan'),
      MenuItem(key: 'rescan', label: 'Yeniden tara', disabled: s != EngineState.connected),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Çıkış'),
    ]));
  }

  @override
  void onTrayIconMouseDown() => showWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        showWindow();
      case 'toggle':
        toggle();
      case 'rescan':
        engine.rescan();
      case 'quit':
        quit();
    }
  }

  @override
  void onWindowClose() => handleClose();
}

class PhevyApp extends StatelessWidget {
  final AppController app;
  const PhevyApp({super.key, required this.app});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'phevy',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: ListenableBuilder(listenable: app, builder: (context, _) => _Shell(app: app)),
      );
}

class _Shell extends StatelessWidget {
  final AppController app;
  const _Shell({required this.app});

  static const _titles = ['Ana Sayfa', 'Loglar', 'Ayarlar'];

  @override
  Widget build(BuildContext context) {
    final onboarding = !app.settings.onboardingDone;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: Column(children: [
          TitleBar(
            subtitle: onboarding ? 'Kurulum' : _titles[app.tab],
            version: AppController.appVersion,
            onClose: app.handleClose,
          ),
          Expanded(
            child: onboarding
                ? OnboardingScreen(app: app)
                : IndexedStack(index: app.tab, children: [
                    HomeScreen(app: app),
                    LogsScreen(app: app),
                    SettingsScreen(app: app),
                  ]),
          ),
          if (!onboarding) BottomNav(index: app.tab, onChanged: app.goTo),
        ]),
      ),
    );
  }
}
