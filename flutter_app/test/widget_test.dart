import 'package:flutter_test/flutter_test.dart';
import 'package:phevy/engine.dart';
import 'package:phevy/messages.dart';

void main() {
  test('her hata kodu icin Turkce mesaj var', () {
    for (final code in [
      'admin_required', 'driver_missing', 'driver_blocked', 'driver_signature', 'driver_conflict',
      'bfe_stopped', 'no_internet', 'engine_missing', 'engine_exited', 'driver_error', 'unknown',
    ]) {
      expect(errorInfo(code).title, isNotEmpty, reason: code);
    }
    expect(warningText('no_strategy_found'), isNotNull);
  });

  test('log seviyeleri', () {
    final e = LogEntry(DateTime(2026), 'WARNING', 'phevy.x', 'mesaj');
    expect(e.severity, 2);
    expect(e.format(), contains('WARNING phevy.x: mesaj'));
  });
}
