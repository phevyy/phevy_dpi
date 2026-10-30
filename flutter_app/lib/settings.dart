// Uygulama ayarlari (shared_preferences). Yontem secimi motorun kendi ayarinda tutulur.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _taskName = 'phevy';

  late SharedPreferences _p;

  bool onboardingDone = false;
  bool autostart = false;
  bool autoConnect = true;
  bool minimizeToTray = true;
  bool voiceFix = true;
  bool verboseLogs = false;
  List<String> extraDomains = [];

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    onboardingDone = _p.getBool('onboardingDone') ?? false;
    autoConnect = _p.getBool('autoConnect') ?? true;
    minimizeToTray = _p.getBool('minimizeToTray') ?? true;
    voiceFix = _p.getBool('voiceFix') ?? true;
    verboseLogs = _p.getBool('verboseLogs') ?? false;
    extraDomains = _p.getStringList('extraDomains') ?? [];
    // Gercek durum Gorev Zamanlayici'dan okunur (kullanici elle silmis olabilir).
    autostart = await _taskExists();
  }

  Future<void> setOnboardingDone() async {
    onboardingDone = true;
    await _p.setBool('onboardingDone', true);
    notifyListeners();
  }

  Future<void> setAutoConnect(bool v) => _setBool('autoConnect', v, () => autoConnect = v);
  Future<void> setMinimizeToTray(bool v) => _setBool('minimizeToTray', v, () => minimizeToTray = v);
  Future<void> setVoiceFix(bool v) => _setBool('voiceFix', v, () => voiceFix = v);
  Future<void> setVerboseLogs(bool v) => _setBool('verboseLogs', v, () => verboseLogs = v);

  Future<void> _setBool(String key, bool v, VoidCallback apply) async {
    apply();
    notifyListeners();
    await _p.setBool(key, v);
  }

  Future<void> setExtraDomains(List<String> v) async {
    extraDomains = v;
    notifyListeners();
    await _p.setStringList('extraDomains', v);
  }

  Future<void> resetToDefaults() async {
    await setAutoConnect(true);
    await setMinimizeToTray(true);
    await setVoiceFix(true);
    await setVerboseLogs(false);
    await setExtraDomains([]);
  }

  /// Windows acilisinda yonetici izniyle (UAC sormadan) baslatmak icin Gorev Zamanlayici gorevi.
  /// Hata olursa mesaji dondurur.
  Future<String?> setAutostart(bool v) async {
    final ProcessResult r;
    if (v) {
      final exe = Platform.resolvedExecutable;
      r = await Process.run('schtasks', [
        '/Create', '/F', '/TN', _taskName, '/SC', 'ONLOGON', '/RL', 'HIGHEST',
        '/TR', '"$exe" --autostart',
      ]);
    } else {
      r = await Process.run('schtasks', ['/Delete', '/F', '/TN', _taskName]);
    }
    autostart = await _taskExists();
    notifyListeners();
    if (r.exitCode != 0 && autostart != v) return '${r.stderr}'.trim();
    return null;
  }

  Future<bool> _taskExists() async {
    final r = await Process.run('schtasks', ['/Query', '/TN', _taskName]);
    return r.exitCode == 0;
  }
}
