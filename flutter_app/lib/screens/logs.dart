import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../engine.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LogsScreen extends StatefulWidget {
  final AppController app;
  const LogsScreen({super.key, required this.app});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  int _filter = 0; // 0 tumu, 1 uyari+, 2 hata
  String _query = '';
  bool _autoScroll = true;
  final _scroll = ScrollController();
  int _seenRevision = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<LogEntry> _visible(List<LogEntry> all) {
    final minSev = [0, 2, 3][_filter];
    final q = _query.toLowerCase();
    return [
      for (final l in all)
        if (l.severity >= minSev && (q.isEmpty || l.msg.toLowerCase().contains(q) || l.logger.contains(q))) l,
    ];
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));

  Future<void> _save(List<LogEntry> rows) async {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name = 'phevy_log_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.txt';
    final loc = await getSaveLocation(suggestedName: name, acceptedTypeGroups: const [
      XTypeGroup(label: 'Metin', extensions: ['txt']),
    ]);
    if (loc == null) return;
    await File(loc.path).writeAsString(rows.map((l) => l.format()).join('\r\n'));
    _toast('Kaydedildi: ${loc.path}');
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.app.engine;
    final rows = _visible(e.logs);
    if (_autoScroll && e.logRevision != _seenRevision) {
      _seenRevision = e.logRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        AppCard(
          child: Column(children: [
            Row(children: [
              Dot(color: e.running ? C.tertiary : C.error, glow: e.running),
              const SizedBox(width: 6),
              Text('CANLI AKIŞ', style: T.labelMd.copyWith(color: C.onSurface)),
              const Spacer(),
              _ToggleChip(
                icon: Icons.south,
                label: 'Oto-kaydır',
                value: _autoScroll,
                onChanged: (v) => setState(() => _autoScroll = v),
              ),
              const SizedBox(width: 6),
              _ToggleChip(
                icon: Icons.bug_report_outlined,
                label: 'Ayrıntılı',
                value: widget.app.settings.verboseLogs,
                onChanged: widget.app.setVerboseLogs,
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _Segmented(
                labels: const ['Tümü', 'Uyarı+', 'Hata'],
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: T.bodySm.copyWith(color: C.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: C.lowest,
                      hintText: 'Ara… (discord, ttl)',
                      hintStyle: T.bodySm.copyWith(color: C.muted),
                      prefixIcon: const Icon(Icons.search, size: 16, color: C.muted),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: C.primaryContainer),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: C.lowest, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const BoxDecoration(
                  color: C.low,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(children: [
                  const Icon(Icons.terminal, size: 14, color: C.secondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text('phevy_engine / log.txt', style: T.monoXs.copyWith(color: C.onVariant))),
                  if (e.logFile != null)
                    Hover(
                      onTap: () => Process.run('explorer.exe', ['/select,', e.logFile!]),
                      builder: (h, _) => Text('Dosyayı göster',
                          style: T.monoXs.copyWith(
                            color: h ? C.onSurface : C.secondary,
                            decoration: h ? TextDecoration.underline : null,
                            decorationColor: C.onSurface,
                          )),
                    ),
                ]),
              ),
              Expanded(
                child: rows.isEmpty
                    ? Center(child: Text('Henüz log yok', style: T.bodySm.copyWith(color: C.muted)))
                    : Scrollbar(
                        controller: _scroll,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(8),
                          itemCount: rows.length,
                          itemBuilder: (_, i) => _LogRow(entry: rows[i]),
                        ),
                      ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: ActionButton(
              icon: Icons.copy,
              label: 'Kopyala',
              color: C.onSurface,
              onTap: () {
                Clipboard.setData(ClipboardData(text: rows.map((l) => l.format()).join('\n')));
                _toast('${rows.length} satır kopyalandı');
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: ActionButton(icon: Icons.save_outlined, label: 'Kaydet', onTap: () => _save(rows))),
          const SizedBox(width: 6),
          Expanded(
            child: ActionButton(icon: Icons.delete_sweep_outlined, label: 'Temizle', color: C.error, onTap: e.clearLogs),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('Gösterilen: ${rows.length} / Toplam: ${e.logs.length}', style: T.monoXs.copyWith(color: C.onVariant)),
        ]),
      ]),
    );
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (String label, Color fg, Color bg, Color text) = switch (entry.level) {
      'DEBUG' => ('AYRINTI', C.primary, C.primaryContainer.withValues(alpha: 0.18), C.onVariant),
      'WARNING' => ('UYARI', C.amber, C.amber.withValues(alpha: 0.15), C.amber),
      'ERROR' || 'CRITICAL' => ('HATA', Colors.white, C.errorContainer, C.error),
      _ => ('BİLGİ', C.secondary, C.secondary.withValues(alpha: 0.12), C.onSurface),
    };
    final t = entry.time;
    String two(int n) => n.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${two(t.hour)}:${two(t.minute)}:${two(t.second)}', style: T.monoXs.copyWith(color: C.muted, height: 1.6)),
        const SizedBox(width: 6),
        Container(
          width: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: T.monoXs.copyWith(color: fg).w(FontWeight.w700)),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(entry.msg, style: T.monoXs.copyWith(color: text, height: 1.5))),
      ]),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _Segmented({required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: C.lowest, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < labels.length; i++)
            Hover(
              onTap: () => onChanged(i),
              builder: (h, _) => AnimatedContainer(
                duration: hoverDuration,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: i == index ? C.primary : (h ? C.high : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(labels[i],
                    style: T.labelSm.copyWith(color: i == index ? C.onPrimary : (h ? C.onSurface : C.onVariant))),
              ),
            ),
        ]),
      );
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleChip({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Hover(
        onTap: () => onChanged(!value),
        builder: (h, _) => AnimatedContainer(
          duration: hoverDuration,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hoverColor(value ? C.high : C.lowest, h),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: (value ? C.primary : C.muted).withValues(alpha: h ? 0.5 : 0)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: value ? C.primary : C.muted),
            const SizedBox(width: 4),
            Text('$label: ${value ? 'Açık' : 'Kapalı'}', style: T.labelSm.copyWith(color: value ? C.primary : C.muted)),
          ]),
        ),
      );
}
