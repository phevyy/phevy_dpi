import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  final AppController app;
  const OnboardingScreen({super.key, required this.app});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _autostart = false;
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    if (_autostart) await widget.app.settings.setAutostart(true);
    await widget.app.settings.setOnboardingDone();
    widget.app.connect();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        Row(children: [
          const Icon(Icons.bolt, size: 16, color: C.primary),
          const SizedBox(width: 6),
          Text('İLK KURULUM', style: T.labelMd.copyWith(color: C.onVariant)),
        ]),
        const SizedBox(height: 20),
        Center(
          child: Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(color: C.primaryContainer.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 4),
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/icons/logo.png', width: 64, height: 64),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('phevy', style: T.headlineLg.copyWith(color: C.onSurface, fontSize: 26)),
          const SizedBox(width: 6),
          Pill(color: C.high, child: Text('v${AppController.appVersion}', style: T.monoXs.copyWith(color: C.primary))),
        ]),
        const SizedBox(height: 4),
        Center(child: Text('Hoş Geldin', style: T.headlineMd.copyWith(color: C.onSurface))),
        const SizedBox(height: 4),
        Text(
          'Discord\'a ek sunucu ve ping olmadan, yazı ve sesiyle eriş.',
          textAlign: TextAlign.center,
          style: T.bodyMd.copyWith(color: C.onVariant),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pill(
              color: C.secondary.withValues(alpha: 0.12),
              child: Text('ÖNEMLİ', style: T.labelMd.copyWith(color: C.secondary)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: C.secondary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('phevy bir VPN değildir', style: T.headlineSm.copyWith(color: C.onSurface)),
            ]),
            const SizedBox(height: 10),
            const _Bullet(icon: Icons.bolt, text: 'Trafik doğrudan Discord sunucularına gider; başka bir sunucudan geçmez.'),
            const _Bullet(icon: Icons.speed, text: 'Sadece Discord bağlantılarının ilk paketlerine dokunulur; oyun pingi ve indirme hızı etkilenmez.'),
            const _Bullet(icon: Icons.visibility_outlined, text: 'IP adresin gizlenmez ve trafiğin şifrelenmez; amaç yalnızca DPI engelini aşmaktır.'),
          ]),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const IconBox(icon: Icons.shield, color: C.onSurface, bg: C.highest, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WinDivert Sürücüsü', style: T.headlineSm.copyWith(color: C.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'phevy paketleri bilgisayarında, açık kaynaklı WinDivert sürücüsüyle işler. Defender bu sürücüyü '
                  '"HackTool" diye işaretleyebilir; bu durumda uygulama klasörünü dışlamalara eklemen gerekir.',
                  style: T.bodySm.copyWith(color: C.onVariant),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => widget.app.showDefenderGuide(context),
                  child: Text('Nasıl yapılır?', style: T.labelMd.copyWith(color: C.primary)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ActionButton(icon: Icons.arrow_forward, label: _busy ? 'Başlatılıyor…' : 'Başla', filled: true, onTap: _busy ? null : _start),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _autostart = !_autostart),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Checkbox(
              value: _autostart,
              onChanged: (v) => setState(() => _autostart = v ?? false),
              activeColor: C.secondary,
              checkColor: C.lowest,
            ),
            Text('Windows ile birlikte otomatik başlat', style: T.bodySm.copyWith(color: C.onSurface)),
          ]),
        ),
        Text('İstediğin zaman Ayarlar\'dan değiştirebilirsin.',
            textAlign: TextAlign.center, style: T.labelSm.copyWith(color: C.muted)),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBox(icon: icon, color: C.tertiary, bg: C.highest, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: T.bodySm.copyWith(color: C.onSurface))),
        ]),
      );
}
