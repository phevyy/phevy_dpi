import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  final AppController app;
  const SettingsScreen({super.key, required this.app});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _domainRe = RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$');
  final _domainCtrl = TextEditingController();
  String? _domainError;

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 3)));

  Future<void> _addDomain() async {
    final s = widget.app.settings;
    final d = _domainCtrl.text.trim().toLowerCase().replaceFirst(RegExp(r'^https?://'), '').split('/').first;
    if (!_domainRe.hasMatch(d)) {
      setState(() => _domainError = 'Geçerli bir alan adı girin (ör. discord.example)');
      return;
    }
    if (widget.app.engine.defaultDomains.contains(d) || s.extraDomains.contains(d)) {
      setState(() => _domainError = 'Bu alan adı zaten listede');
      return;
    }
    setState(() => _domainError = null);
    _domainCtrl.clear();
    await s.setExtraDomains([...s.extraDomains, d]);
    widget.app.reconnectIfConnected();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final s = app.settings;
    final e = app.engine;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Text('Ayarlar', style: T.headlineLg.copyWith(color: C.onSurface)),
          const SizedBox(width: 8),
          Pill(color: C.high, child: Text('Yapılandırma', style: T.monoXs.copyWith(color: C.primary))),
        ]),
        Text('İstemci ve bağlantı yapılandırması', style: T.bodySm.copyWith(color: C.onVariant)),
        const SizedBox(height: 12),
        _Section(
          title: 'SİSTEM & BAĞLANTI',
          trailing: const Icon(Icons.bolt, size: 16, color: C.tertiary),
          children: [
            _SwitchRow(
              title: 'Windows açılışında başlat',
              subtitle: 'Oturum açınca simge durumunda başlar (UAC sormadan)',
              value: s.autostart,
              onChanged: (v) async {
                final err = await s.setAutostart(v);
                if (err != null) _toast('Ayarlanamadı: $err');
              },
            ),
            _SwitchRow(
              title: 'Açılınca otomatik bağlan',
              subtitle: 'Uygulama açıldığında taramayı otomatik başlat',
              value: s.autoConnect,
              onChanged: s.setAutoConnect,
            ),
            _SwitchRow(
              title: 'Kapatınca simge durumuna küçült',
              subtitle: 'Kapat düğmesi pencereyi sistem tepsisine gizler',
              value: s.minimizeToTray,
              onChanged: s.setMinimizeToTray,
            ),
            _SwitchRow(
              title: 'Ses düzeltmesi',
              badge: 'UDP',
              subtitle: 'Discord ses kanalı engelini aşar',
              value: s.voiceFix,
              onChanged: (v) async {
                await s.setVoiceFix(v);
                app.reconnectIfConnected();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'YÖNTEM SEÇİMİ',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            const Dot(color: C.secondary, size: 6),
            const SizedBox(width: 4),
            Text('DPI atlatma', style: T.monoXs.copyWith(color: C.secondary)),
          ]),
          children: [
            _StrategyPicker(app: app),
            const SizedBox(height: 6),
            Text(
              e.mode == 'auto'
                  ? 'Otomatik modda phevy her ağda çalışan yöntemi kendisi bulur. Önerilen budur.'
                  : 'Elle seçilen yöntem test edilmeden kullanılır. Ağ değişirse çalışmayabilir.',
              style: T.bodySm.copyWith(color: C.onVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'ALAN ADLARI',
          subtitle: 'DPI atlatmanın uygulanacağı alan adları (alt alan adları dahil)',
          trailing: Pill(
            color: C.high,
            child: Text('${e.defaultDomains.length + s.extraDomains.length} alan adı',
                style: T.monoXs.copyWith(color: C.onVariant)),
          ),
          children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final d in s.extraDomains)
                _DomainChip(
                  domain: d,
                  onRemove: () async {
                    await s.setExtraDomains([...s.extraDomains]..remove(d));
                    app.reconnectIfConnected();
                  },
                ),
              for (final d in e.defaultDomains) _DomainChip(domain: d),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextField(
                  controller: _domainCtrl,
                  onSubmitted: (_) => _addDomain(),
                  style: T.mono.copyWith(color: C.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: C.lowest,
                    hintText: 'yeni-alan-adi.com',
                    hintStyle: T.mono.copyWith(color: C.muted),
                    errorText: _domainError,
                    errorStyle: T.bodySm.copyWith(color: C.error),
                    prefixIcon: const Icon(Icons.add_link, size: 16, color: C.muted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: C.primaryContainer),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 86,
                child: ActionButton(icon: Icons.add, label: 'Ekle', filled: true, onTap: _addDomain),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          color: C.container,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const IconBox(icon: Icons.shield, color: C.onSurface, bg: C.lowest, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Windows Defender', style: T.headlineSm.copyWith(color: C.onSurface)),
                  const SizedBox(width: 6),
                  const Dot(color: C.secondary, size: 6),
                ]),
                const SizedBox(height: 4),
                Text(
                  'phevy, paketleri yönlendirmek için WinDivert sürücüsünü kullanır. Defender bu sürücüyü '
                  '"HackTool" olarak işaretleyip silebilir; uygulama klasörünü dışlamalara eklemek gerekir.',
                  style: T.bodySm.copyWith(color: C.onVariant),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => app.showDefenderGuide(context),
                    icon: const Icon(Icons.open_in_new, size: 14, color: C.primary),
                    label: Text('Nasıl dışlama eklenir?', style: T.labelMd.copyWith(color: C.primary)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Dot(color: C.tertiary, size: 6),
          const SizedBox(width: 6),
          Text('phevy ${AppController.appVersion} • motor ${e.version ?? '?'}', style: T.monoXs.copyWith(color: C.onVariant)),
        ]),
        Center(
          child: TextButton(
            onPressed: () async {
              await s.resetToDefaults();
              e.setStrategy('auto');
              app.setVerboseLogs(false);
              app.reconnectIfConnected();
              _toast('Ayarlar varsayılanlara döndü');
            },
            child: Text('Varsayılanlara Sıfırla',
                style: T.bodySm.copyWith(color: C.onVariant, decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  const _Section({required this.title, this.subtitle, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: T.labelMd.copyWith(color: C.onVariant))),
            ?trailing,
          ]),
          if (subtitle != null) Text(subtitle!, style: T.bodySm.copyWith(color: C.onVariant)),
          const SizedBox(height: 8),
          ...children,
        ]),
      );
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.title, required this.subtitle, this.badge, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(title, style: T.headlineSm.copyWith(color: C.onSurface))),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Pill(color: C.tertiaryContainer, child: Text(badge!, style: T.monoXs.copyWith(color: C.onTertiary).w(FontWeight.w700))),
                ],
              ]),
              const SizedBox(height: 2),
              Text(subtitle, style: T.bodySm.copyWith(color: C.onVariant)),
            ]),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

class _StrategyPicker extends StatelessWidget {
  final AppController app;
  const _StrategyPicker({required this.app});

  @override
  Widget build(BuildContext context) {
    final e = app.engine;
    final current = e.mode;
    final desc = {for (final s in e.strategies) s.name: s.desc};
    return PopupMenuButton<String>(
      color: C.high,
      tooltip: '',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 340, maxHeight: 420),
      onSelected: e.setStrategy,
      itemBuilder: (_) => [
        _item('auto', 'Otomatik (önerilen)', 'Her ağda çalışan yöntemi kendisi bulur', current),
        const PopupMenuDivider(),
        for (final s in e.strategies) _item(s.name, s.name, s.desc, current),
      ],
      // PopupMenuButton tiklamayi kendisi yonetir; Hover sadece imlec ve gorunum icin.
      child: Hover(
        onTap: null,
        passthrough: true,
        builder: (h, _) => AnimatedContainer(
        duration: hoverDuration,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hoverColor(C.high, h),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.primary.withValues(alpha: h ? 0.45 : 0)),
        ),
        child: Row(children: [
          Icon(current == 'auto' ? Icons.auto_awesome : Icons.call_split, size: 18, color: C.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(current == 'auto' ? 'Otomatik (önerilen)' : current,
                  style: (current == 'auto' ? T.headlineSm : T.mono).copyWith(color: C.onSurface)),
              if (current != 'auto' && desc[current] != null)
                Text(desc[current]!, style: T.bodySm.copyWith(color: C.onVariant)),
            ]),
          ),
          if (current == 'auto')
            Pill(color: C.secondary.withValues(alpha: 0.15), child: Text('Dinamik', style: T.monoXs.copyWith(color: C.secondary))),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more, color: C.onVariant),
        ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(String value, String title, String sub, String current) => PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(value == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16, color: value == current ? C.primary : C.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: (value == 'auto' ? T.bodyMd : T.mono).copyWith(color: C.onSurface)),
              Text(sub, style: T.bodySm.copyWith(color: C.onVariant)),
            ]),
          ),
        ]),
      );
}

class _DomainChip extends StatelessWidget {
  final String domain;
  final VoidCallback? onRemove;
  const _DomainChip({required this.domain, this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: C.container, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(onRemove == null ? Icons.lock_outline : Icons.dns_outlined,
              size: 13, color: onRemove == null ? C.tertiary : C.secondary),
          const SizedBox(width: 5),
          Text(domain, style: T.monoXs.copyWith(color: C.onSurface)),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            Hover(
              onTap: onRemove,
              tooltip: 'Kaldır',
              builder: (h, _) => AnimatedContainer(
                duration: hoverDuration,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: h ? C.errorContainer : Colors.transparent, shape: BoxShape.circle),
                child: Icon(Icons.close, size: 12, color: h ? Colors.white : C.muted),
              ),
            ),
          ],
        ]),
      );
}
