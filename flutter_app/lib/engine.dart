// phevy motoru (phevy_engine.exe --ipc) ile konusan istemci. Protokol: ../docs/IPC.md
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum EngineState { stopped, starting, scanning, connected, error }

EngineState _parseState(String s) => switch (s) {
      'starting' => EngineState.starting,
      'scanning' => EngineState.scanning,
      'connected' => EngineState.connected,
      'error' => EngineState.error,
      _ => EngineState.stopped,
    };

class StrategyInfo {
  final String name;
  final String desc;
  const StrategyInfo(this.name, this.desc);
}

class LogEntry {
  final DateTime time;
  final String level; // DEBUG, INFO, WARNING, ERROR
  final String logger;
  final String msg;
  const LogEntry(this.time, this.level, this.logger, this.msg);

  int get severity => switch (level) { 'DEBUG' => 0, 'INFO' => 1, 'WARNING' => 2, _ => 3 };

  String format() {
    final t = time.toIso8601String().substring(11, 19);
    return '$t $level $logger: $msg';
  }
}

class Stats {
  final int dns, tls, voice, quicDrop;
  const Stats({this.dns = 0, this.tls = 0, this.voice = 0, this.quicDrop = 0});
}

class EngineClient extends ChangeNotifier {
  static const maxLogs = 5000;

  Process? _proc;
  bool _shuttingDown = false;
  int _nextId = 1;

  // hello
  String? version;
  bool? admin;
  String? logFile;
  List<StrategyInfo> strategies = const [];
  List<String> defaultDomains = const [];

  // state
  EngineState state = EngineState.stopped;
  String? code;
  String? message;
  String? strategy;
  String mode = 'auto';
  DateTime since = DateTime.now();

  // tarama
  String? trying;
  int tryCount = 0;

  Stats stats = const Stats();
  final List<LogEntry> logs = [];
  int logRevision = 0;

  bool get busy => state == EngineState.starting || state == EngineState.scanning;
  bool get running => _proc != null;

  /// Motor exe'sini bulur: uygulamanin yanindaki engine\ klasoru, yoksa PHEVY_ENGINE ortam degiskeni.
  static String? findEngine() {
    final env = Platform.environment['PHEVY_ENGINE'];
    if (env != null && File(env).existsSync()) return env;
    final dir = File(Platform.resolvedExecutable).parent.path;
    final p = '$dir\\engine\\phevy_engine.exe';
    return File(p).existsSync() ? p : null;
  }

  Future<void> start() async {
    final path = findEngine();
    if (path == null) {
      _localError('engine_missing', 'phevy_engine.exe bulunamadi');
      return;
    }
    try {
      final p = await Process.start(path, ['--ipc']);
      _proc = p;
      p.stdin.encoding = utf8;
      p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(_onLine);
      p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(
            (l) => _addLog(LogEntry(DateTime.now(), 'ERROR', 'engine.stderr', l)),
          );
      unawaited(p.exitCode.then(_onExit));
    } on ProcessException catch (e) {
      _localError('engine_missing', e.message);
    }
  }

  void _onExit(int code) {
    _proc = null;
    if (_shuttingDown) return;
    _addLog(LogEntry(DateTime.now(), 'ERROR', 'phevy.app', 'Motor beklenmedik sekilde kapandi (kod $code)'));
    _localError('engine_exited', 'Motor kapandi (kod $code)');
  }

  void _localError(String c, String m) {
    state = EngineState.error;
    code = c;
    message = m;
    strategy = null;
    since = DateTime.now();
    notifyListeners();
  }

  void _send(Map<String, Object?> cmd) {
    final p = _proc;
    if (p == null) return;
    cmd['id'] = _nextId++;
    p.stdin.writeln(jsonEncode(cmd));
  }

  Future<void> connect({required bool voiceFix, required List<String> extraDomains}) async {
    if (_proc == null) await start();
    _send({'cmd': 'connect', 'voice_fix': voiceFix, 'extra_domains': extraDomains});
  }

  void disconnect() => _send({'cmd': 'disconnect'});
  void rescan() => _send({'cmd': 'rescan'});
  void setStrategy(String name) => _send({'cmd': 'set_strategy', 'name': name});
  void setVerbose(bool v) => _send({'cmd': 'set_log_level', 'level': v ? 'DEBUG' : 'INFO'});

  /// Motoru temizce kapatir (surucu birakilir). Uygulamadan cikarken cagrilir.
  Future<void> shutdown() async {
    final p = _proc;
    if (p == null) return;
    _shuttingDown = true;
    _send({'cmd': 'quit'});
    await p.stdin.close().catchError((_) {});
    try {
      await p.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      p.kill();
    }
  }

  void clearLogs() {
    logs.clear();
    logRevision++;
    notifyListeners();
  }

  void _addLog(LogEntry e) {
    logs.add(e);
    if (logs.length > maxLogs) logs.removeRange(0, logs.length - maxLogs);
    logRevision++;
  }

  void _onLine(String line) {
    final Map<String, dynamic> ev;
    try {
      ev = jsonDecode(line) as Map<String, dynamic>;
    } on FormatException {
      return;
    }
    switch (ev['type']) {
      case 'hello':
        version = ev['version'] as String?;
        admin = ev['admin'] as bool?;
        logFile = ev['log_file'] as String?;
        strategies = [
          for (final s in (ev['strategies'] as List? ?? const []))
            StrategyInfo(s['name'] as String, s['desc'] as String),
        ];
        defaultDomains = [for (final d in (ev['default_domains'] as List? ?? const [])) d as String];
      case 'state':
        final next = _parseState(ev['state'] as String);
        if (next == EngineState.scanning && state != EngineState.scanning) {
          tryCount = 0;
          trying = null;
        }
        if (next != EngineState.connected) stats = const Stats();
        state = next;
        code = ev['code'] as String?;
        message = ev['message'] as String?;
        strategy = ev['strategy'] as String?;
        mode = ev['mode'] as String? ?? 'auto';
        since = DateTime.fromMillisecondsSinceEpoch(((ev['since'] as num) * 1000).round());
      case 'trying':
        trying = ev['strategy'] as String?;
        tryCount++;
      case 'stats':
        stats = Stats(
          dns: ev['dns'] as int? ?? 0,
          tls: ev['tls'] as int? ?? 0,
          voice: ev['voice'] as int? ?? 0,
          quicDrop: ev['quic_drop'] as int? ?? 0,
        );
      case 'log':
        _addLog(LogEntry(
          DateTime.fromMillisecondsSinceEpoch(((ev['ts'] as num) * 1000).round()),
          ev['level'] as String? ?? 'INFO',
          ev['logger'] as String? ?? '',
          ev['msg'] as String? ?? '',
        ));
      default:
        return;
    }
    notifyListeners();
  }
}
