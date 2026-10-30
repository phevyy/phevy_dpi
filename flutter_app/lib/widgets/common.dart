import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';

/// Tiklanabilir alan: el imleci, uzerine gelme ve basma durumlarini builder'a verir.
/// Tum ozel dugmeler bunu kullanir ki uzerine gelince tiklanabilir olduklari anlasilsin.
class Hover extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget Function(bool hovered, bool pressed) builder;
  final String? tooltip;

  /// true: tiklamayi yakalamaz (ornegin PopupMenuButton icinde); sadece imlec ve gorunum.
  final bool passthrough;
  const Hover({super.key, required this.onTap, required this.builder, this.tooltip, this.passthrough = false});

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.passthrough;
    Widget child = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: widget.passthrough
          ? widget.builder(_hovered, false)
          : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.builder(enabled && _hovered, _pressed),
        ),
      ),
    );
    if (widget.tooltip != null) child = Tooltip(message: widget.tooltip!, child: child);
    return child;
  }
}

/// Uzerine gelinince zemini acan renk.
Color hoverColor(Color base, bool hovered, [double amount = 0.08]) =>
    hovered ? Color.alphaBlend(Colors.white.withValues(alpha: amount), base) : base;

const hoverDuration = Duration(milliseconds: 140);

/// Ozel baslik cubugu (32px yerine tasarimdaki 56px marka satiri). Pencere surukleme + kucult/kapat.
class TitleBar extends StatelessWidget {
  final String subtitle;
  final String? version;
  final VoidCallback onClose;
  const TitleBar({super.key, required this.subtitle, required this.version, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: C.lowest,
        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset('assets/icons/logo.png', width: 28, height: 28),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('phevy', style: T.headlineSm.copyWith(color: C.onSurface)),
                        const SizedBox(width: 6),
                        if (version != null)
                          Pill(
                            color: C.high,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Dot(color: C.tertiary, size: 6),
                              const SizedBox(width: 4),
                              Text('v$version', style: T.monoXs.copyWith(color: C.tertiary)),
                            ]),
                          ),
                      ]),
                      Text(subtitle, style: T.labelSm.copyWith(color: C.onVariant)),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: C.low, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              _WinButton(icon: Icons.remove, tooltip: 'Küçült', onTap: () => windowManager.minimize()),
              _WinButton(icon: Icons.close, tooltip: 'Kapat', onTap: onClose, danger: true),
            ]),
          ),
        ],
      ),
    );
  }
}

class _WinButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;
  const _WinButton({required this.icon, required this.tooltip, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => Hover(
        onTap: onTap,
        tooltip: tooltip,
        builder: (h, _) => AnimatedContainer(
          duration: hoverDuration,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: h ? (danger ? C.errorContainer : C.highest) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: h ? Colors.white : C.onVariant),
        ),
      );
}

class Dot extends StatelessWidget {
  final Color color;
  final double size;
  final bool glow;
  const Dot({super.key, required this.color, this.size = 8, this.glow = false});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)] : null,
        ),
      );
}

class Pill extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsets padding;
  const Pill({super.key, required this.color, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: child,
      );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final Border? border;
  const AppCard({super.key, required this.child, this.color = C.low, this.padding = const EdgeInsets.all(12), this.border});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: border),
        child: child,
      );
}

/// Kucuk ikon kutusu (tasarimdaki 28px yuvarlak koseli kare).
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  const IconBox({super.key, required this.icon, required this.color, required this.bg, this.size = 28});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: size * 0.6, color: color),
      );
}

class StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String caption;
  final Color valueColor;
  const StatCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.caption,
    this.valueColor = C.onSurface,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: C.low, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(label, style: T.labelSm.copyWith(color: C.onVariant))),
              Icon(icon, size: 15, color: iconColor),
            ]),
            const SizedBox(height: 4),
            Text(value, overflow: TextOverflow.ellipsis,
                style: T.mono.copyWith(color: valueColor).w(FontWeight.w700)),
            const SizedBox(height: 2),
            Text(caption, overflow: TextOverflow.ellipsis, style: T.monoXs.copyWith(color: C.onVariant)),
          ],
        ),
      );
}

/// Genis eylem dugmesi. filled: mor dolu (ana eylem), aksi halde koyu zemin.
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final Color? color;
  final Color? background;
  const ActionButton({super.key, required this.icon, required this.label, this.onTap, this.filled = false, this.color, this.background});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (filled ? C.onPrimary : C.secondary);
    final bg = background ?? (filled ? C.primary : C.container);
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Hover(
        onTap: onTap,
        builder: (h, _) => AnimatedContainer(
          duration: hoverDuration,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hoverColor(bg, h, filled ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(12),
            // Uzerine gelince vurgu renginde ince kenarlik + isilti
            border: Border.all(color: fg.withValues(alpha: h ? (filled ? 0.0 : 0.45) : 0.0)),
            boxShadow: [
              if (filled || h)
                BoxShadow(
                  color: (filled ? C.primaryContainer : fg).withValues(alpha: h ? 0.4 : (filled ? 0.25 : 0)),
                  blurRadius: h ? 24 : 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: T.headlineSm.copyWith(color: fg))),
          ]),
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const BottomNav({super.key, required this.index, required this.onChanged});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Ana Sayfa'),
    (Icons.terminal, Icons.terminal, 'Loglar'),
    (Icons.settings_outlined, Icons.settings, 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: C.lowest,
        boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 12, offset: Offset(0, -1))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: Hover(
                onTap: () => onChanged(i),
                builder: (h, _) {
                  final active = i == index;
                  final c = active ? C.primary : (h ? C.onSurface : C.onVariant);
                  return AnimatedContainer(
                    duration: hoverDuration,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: h && !active ? C.high : (active ? C.primary.withValues(alpha: 0.08) : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(active ? _items[i].$2 : _items[i].$1, size: 22, color: c),
                      const SizedBox(height: 2),
                      Text(_items[i].$3,
                          style: T.labelSm.copyWith(color: c).w(active ? FontWeight.w700 : FontWeight.w500)),
                    ]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

String formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}
