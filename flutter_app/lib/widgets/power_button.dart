import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine.dart';
import '../theme.dart';

/// Ana sayfadaki buyuk guc dugmesi. Durumlar: kapali (gri), tarama (donen mor/camgobegi halka),
/// bagli (yesil nabiz), hata (kirmizi).
class PowerButton extends StatefulWidget {
  final EngineState state;
  final VoidCallback onTap;
  const PowerButton({super.key, required this.state, required this.onTap});

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  bool _pressed = false;
  bool _hover = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final busy = s == EngineState.starting || s == EngineState.scanning;
    final (Color accent, String label, IconData icon) = switch (s) {
      EngineState.connected => (C.tertiary, 'BAĞLI', Icons.power_settings_new),
      EngineState.error => (C.error, 'HATA', Icons.power_settings_new),
      EngineState.stopped => (C.muted, 'KAPALI', Icons.power_settings_new),
      _ => (C.secondary, s == EngineState.starting ? 'BAŞLIYOR' : 'TARANIYOR', Icons.sync),
    };

    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
          return Stack(alignment: Alignment.center, children: [
            // Ortam isiltisi
            if (s != EngineState.stopped)
              Container(
                width: 176,
                height: 176,
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: s == EngineState.connected ? 0.12 + 0.12 * pulse : 0.16),
                    blurRadius: 48,
                    spreadRadius: 8,
                  ),
                ]),
              ),
            // Dis halka
            SizedBox(
              width: 168,
              height: 168,
              child: CustomPaint(painter: _RingPainter(state: s, accent: accent, t: t, pulse: pulse)),
            ),
            // Dugme
            GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              onTap: widget.onTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hover = true),
                onExit: (_) => setState(() => _hover = false),
                child: AnimatedScale(
                  scale: _pressed ? 0.95 : (_hover ? 1.04 : 1),
                  duration: const Duration(milliseconds: 140),
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: s == EngineState.error
                            ? const [Color(0xFF8A0F18), Color(0xFF3A0A10), C.lowest]
                            : [Color.alphaBlend(accent.withValues(alpha: s == EngineState.stopped ? 0.05 : 0.18), C.high), C.container, C.lowest],
                      ),
                      boxShadow: [
                        const BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 8)),
                        if (_hover) BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 28),
                      ],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: s == EngineState.stopped ? 0.08 : 0.18),
                          boxShadow: s == EngineState.stopped
                              ? null
                              : [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 20)],
                        ),
                        child: busy
                            ? Transform.rotate(angle: t * 2 * math.pi, child: Icon(icon, size: 42, color: accent))
                            : Icon(icon, size: 42, color: accent),
                      ),
                      const SizedBox(height: 6),
                      Text(label, style: T.labelMd.copyWith(color: accent.withValues(alpha: 0.9))),
                    ]),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final EngineState state;
  final Color accent;
  final double t;
  final double pulse;
  _RingPainter({required this.state, required this.accent, required this.t, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = state == EngineState.stopped ? C.highest.withValues(alpha: 0.6) : accent.withValues(alpha: 0.15);
    canvas.drawCircle(c, r, base);

    switch (state) {
      case EngineState.starting || EngineState.scanning:
        // Donen mor -> camgobegi yay
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: const [Color(0x00A078FF), C.primaryContainer, C.secondary],
            transform: GradientRotation(t * 2 * math.pi),
          ).createShader(rect);
        canvas.drawArc(rect, t * 2 * math.pi, math.pi * 1.4, false, p);
        final head = c + Offset(math.cos(t * 2 * math.pi + math.pi * 1.4), math.sin(t * 2 * math.pi + math.pi * 1.4)) * r;
        canvas.drawCircle(head, 5, Paint()..color = C.secondary);
      case EngineState.connected || EngineState.error:
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = accent.withValues(alpha: state == EngineState.connected ? 0.55 + 0.45 * pulse : 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
        canvas.drawCircle(c, r, p);
      case EngineState.stopped:
        break;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}
