import 'package:flutter/material.dart';

import '../app.dart';
import '../engine.dart';
import '../messages.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/power_button.dart';

class HomeScreen extends StatelessWidget {
  final AppController app;
  const HomeScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final e = app.engine;
    final s = e.state;
    final connected = s == EngineState.connected;
    final err = s == EngineState.error ? errorInfo(e.code) : null;
    final warning = connected ? warningText(e.code) : null;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _StatusStrip(engine: e),
        const SizedBox(height: 12),
        _Hero(app: app),
        if (connected) ...[
          const SizedBox(height: 12),
          _MethodStrip(engine: e),
        ],
        if (warning != null) ...[
          const SizedBox(height: 12),
          AppCard(
            color: C.amber.withValues(alpha: 0.12),
            border: Border.all(color: C.amber.withValues(alpha: 0.4)),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: C.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(warning, style: T.bodySm.copyWith(color: C.onSurface))),
            ]),
          ),
        ],
        if (err != null) ...[
          const SizedBox(height: 12),
          _ErrorCard(app: app, info: err),
        ],
        const SizedBox(height: 12),
        _StatsRow(engine: e),
        const SizedBox(height: 12),
        _Actions(app: app),
        const SizedBox(height: 10),
        _Footer(engine: e),
      ],
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final EngineClient engine;
  const _StatusStrip({required this.engine});

  @override
  Widget build(BuildContext context) {
    final (Color c, String text, String chip) = switch (engine.state) {
      EngineState.connected => (C.tertiary, 'Aktif • ${engine.strategy ?? ''}', 'Çalışıyor'),
      EngineState.scanning => (C.secondary, 'Yöntem taraması', 'Keşif'),
      EngineState.starting => (C.secondary, 'Sürücü yükleniyor', 'Başlıyor'),
      EngineState.error => (C.error, 'Çalışmıyor', 'Hata'),
      EngineState.stopped => (C.muted, 'Hazır • DPI atlatma pasif', 'Beklemede'),
    };
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Dot(color: c, glow: engine.state != EngineState.stopped),
        const SizedBox(width: 8),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: T.mono.copyWith(color: c))),
        Pill(
          color: C.high,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield_outlined, size: 12, color: c),
            const SizedBox(width: 4),
            Text(chip, style: T.labelSm.copyWith(color: C.onVariant)),
          ]),
        ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  final AppController app;
  const _Hero({required this.app});

  @override
  Widget build(BuildContext context) {
    final e = app.engine;
    final (String title, String subtitle, Color titleColor) = switch (e.state) {
      EngineState.connected => ('Bağlantı Aktif', 'Discord trafiği DPI engelinden geçiriliyor', C.onSurface),
      EngineState.scanning => ('Yöntem Aranıyor', 'Ağın için çalışan DPI atlatma yöntemi test ediliyor', C.secondary),
      EngineState.starting => ('Başlatılıyor…', 'WinDivert sürücüsü yükleniyor', C.secondary),
      EngineState.error => ('Bağlantı Hatası', errorInfo(e.code).title, C.error),
      EngineState.stopped => ('Bağlantı Kapalı', 'Discord\'a erişmek için düğmeye bas', C.onVariant),
    };
    final dotColor = switch (e.state) {
      EngineState.connected => C.tertiary,
      EngineState.error => C.error,
      EngineState.stopped => C.muted,
      _ => C.secondary,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.low, C.surface]),
      ),
      child: Column(children: [
        PowerButton(state: e.state, onTap: app.toggle),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(title, style: T.headlineMd.copyWith(color: titleColor))),
          const SizedBox(width: 6),
          Dot(color: dotColor, glow: e.state != EngineState.stopped),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center, style: T.bodySm.copyWith(color: C.onVariant)),
        const SizedBox(height: 10),
        if (e.state == EngineState.scanning) _ScanProgress(engine: e),
        if (e.state == EngineState.stopped || e.state == EngineState.error)
          Pill(
            color: C.container,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.tune, size: 14, color: C.onVariant),
              const SizedBox(width: 6),
              Text('Seçili: ', style: T.bodySm.copyWith(color: C.onVariant)),
              Text(e.mode == 'auto' ? 'Otomatik' : e.mode, style: T.mono.copyWith(color: C.primary)),
            ]),
          ),
      ]),
    );
  }
}

class _ScanProgress extends StatelessWidget {
  final EngineClient engine;
  const _ScanProgress({required this.engine});

  @override
  Widget build(BuildContext context) {
    final total = engine.strategies.isEmpty ? 1 : engine.strategies.length;
    final done = engine.tryCount.clamp(0, total);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: C.container, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.terminal, size: 14, color: C.primary),
          const SizedBox(width: 6),
          Text('Deneniyor: ', style: T.mono.copyWith(color: C.onVariant)),
          Expanded(
            child: Text(engine.trying ?? 'bağlantı kontrolü', overflow: TextOverflow.ellipsis,
                style: T.mono.copyWith(color: C.secondary).w(FontWeight.w700)),
          ),
          Pill(color: C.high, child: Text('$done/$total', style: T.monoXs.copyWith(color: C.onVariant))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [
            Container(height: 6, color: C.highest),
            FractionallySizedBox(
              widthFactor: done / total,
              child: Container(
                height: 6,
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.primary, C.secondary, C.tertiary])),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MethodStrip extends StatelessWidget {
  final EngineClient engine;
  const _MethodStrip({required this.engine});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(engine.since);
    return AppCard(
      color: C.container,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        IconBox(icon: Icons.hub, color: C.primary, bg: C.primaryContainer.withValues(alpha: 0.2)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(engine.mode == 'auto' ? 'YÖNTEM • OTOMATİK' : 'YÖNTEM • ELLE', style: T.labelSm.copyWith(color: C.onVariant)),
            Text(engine.strategy ?? '-', overflow: TextOverflow.ellipsis, style: T.mono.copyWith(color: C.secondary)),
          ]),
        ),
        const IconBox(icon: Icons.schedule, color: C.onVariant, bg: C.highest),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('SÜRE', style: T.labelSm.copyWith(color: C.onVariant)),
          Text(formatDuration(elapsed), style: T.mono.copyWith(color: C.onSurface)),
        ]),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final EngineClient engine;
  const _StatsRow({required this.engine});

  @override
  Widget build(BuildContext context) {
    final on = engine.state == EngineState.connected;
    String v(int n) => on ? '$n' : '--';
    return Row(children: [
      Expanded(
        child: StatCard(label: 'DNS', icon: Icons.dns_outlined, iconColor: C.secondary,
            value: v(engine.stats.dns), caption: 'DoH ile çözülen'),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: StatCard(label: 'Bağlantı', icon: Icons.sensors, iconColor: C.primary,
            value: v(engine.stats.tls), caption: 'Discord TLS'),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: StatCard(label: 'Ses', icon: Icons.graphic_eq, iconColor: C.tertiary,
            value: v(engine.stats.voice), caption: 'ses oturumu',
            valueColor: on && engine.stats.voice > 0 ? C.tertiary : C.onSurface),
      ),
    ]);
  }
}

class _ErrorCard extends StatelessWidget {
  final AppController app;
  final ErrorInfo info;
  const _ErrorCard({required this.app, required this.info});

  @override
  Widget build(BuildContext context) {
    final e = app.engine;
    return Container(
      decoration: BoxDecoration(
        color: C.low,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: C.error, width: 4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const IconBox(icon: Icons.gpp_bad_outlined, color: C.error, bg: C.errorContainer, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(info.title, style: T.headlineSm.copyWith(color: C.onSurface)),
              const SizedBox(height: 4),
              if (e.code != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: C.lowest, borderRadius: BorderRadius.circular(4)),
                  child: Text(e.code!, style: T.monoXs.copyWith(color: C.error)),
                ),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text(info.body, style: T.bodySm.copyWith(color: C.onVariant)),
        if (e.message != null) ...[
          const SizedBox(height: 6),
          SelectableText(e.message!, style: T.monoXs.copyWith(color: C.muted)),
        ],
        if (info.action == ErrorAction.relaunchAdmin) ...[
          const SizedBox(height: 10),
          ActionButton(icon: Icons.admin_panel_settings_outlined, label: 'Yönetici Olarak Yeniden Başlat',
              onTap: app.relaunchAsAdmin, background: C.errorContainer, color: Colors.white),
        ],
        if (info.action == ErrorAction.defenderGuide) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => app.showDefenderGuide(context),
              icon: const Icon(Icons.open_in_new, size: 16, color: C.secondary),
              label: Text('Dışlama Ekleme Kılavuzu', style: T.headlineSm.copyWith(color: C.secondary)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Actions extends StatelessWidget {
  final AppController app;
  const _Actions({required this.app});

  @override
  Widget build(BuildContext context) {
    return switch (app.engine.state) {
      EngineState.stopped =>
        ActionButton(icon: Icons.bolt, label: 'Bağlantıyı Başlat', filled: true, onTap: app.connect),
      EngineState.starting || EngineState.scanning =>
        ActionButton(icon: Icons.close, label: 'Taramayı İptal Et', color: C.error, onTap: app.engine.disconnect),
      EngineState.connected =>
        ActionButton(icon: Icons.cached, label: 'Yeniden tara', onTap: app.engine.rescan),
      EngineState.error => Row(children: [
          Expanded(
            flex: 3,
            child: ActionButton(icon: Icons.refresh, label: 'Tekrar Dene', filled: true, onTap: app.connect),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ActionButton(icon: Icons.terminal, label: 'Loglar', color: C.onSurface, onTap: () => app.goTo(1)),
          ),
        ]),
    };
  }
}

class _Footer extends StatelessWidget {
  final EngineClient engine;
  const _Footer({required this.engine});

  @override
  Widget build(BuildContext context) {
    final (Color c, String text) = switch (engine.state) {
      EngineState.connected => (C.tertiary, 'WinDivert 2.2 aktif • Trafik yönlendirilmiyor'),
      EngineState.error => (C.error, 'WinDivert sürücüsü çalışmıyor'),
      EngineState.stopped => (C.muted, 'Sadece Discord trafiğine dokunulur • Ping etkilenmez'),
      _ => (C.secondary, 'Paketler yerel sürücüde işleniyor'),
    };
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Dot(color: c, size: 6),
      const SizedBox(width: 6),
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: T.monoXs.copyWith(color: C.onVariant))),
    ]);
  }
}
