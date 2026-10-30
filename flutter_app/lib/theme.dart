// Stitch tasarim sistemindeki (design/stitch/phevy_desktop_client/DESIGN.md) renk ve yazi tipleri.
import 'package:flutter/material.dart';

class C {
  static const surface = Color(0xFF0F131C);
  static const lowest = Color(0xFF0A0E16);
  static const low = Color(0xFF181C24);
  static const container = Color(0xFF1C2028);
  static const high = Color(0xFF262A33);
  static const highest = Color(0xFF31353E);
  static const onSurface = Color(0xFFDFE2EE);
  static const onVariant = Color(0xFFCBC3D7);
  static const muted = Color(0xFF958EA0);
  static const outline = Color(0xFF494454);
  static const primary = Color(0xFFD0BCFF);
  static const onPrimary = Color(0xFF3C0091);
  static const primaryContainer = Color(0xFFA078FF);
  static const secondary = Color(0xFF4CD7F6);
  static const tertiary = Color(0xFF4EDEA3);
  static const tertiaryContainer = Color(0xFF00A572);
  static const onTertiary = Color(0xFF003824);
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const amber = Color(0xFFF59E0B);
}

TextStyle _inter(double size, double height, FontWeight w, [double spacing = 0]) => TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      height: height / size,
      fontWeight: w,
      // Degisken yazi tipi: agirligi eksen uzerinden de veriyoruz.
      fontVariations: [FontVariation.weight(w.value.toDouble())],
      letterSpacing: spacing * size,
    );

TextStyle _mono(double size, double height, FontWeight w, [double spacing = 0]) => TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: size,
      height: height / size,
      fontWeight: w,
      fontVariations: [FontVariation.weight(w.value.toDouble())],
      letterSpacing: spacing * size,
    );

class T {
  static final headlineLg = _inter(22, 28, FontWeight.w700, -0.02);
  static final headlineMd = _inter(18, 24, FontWeight.w600, -0.015);
  static final headlineSm = _inter(15, 20, FontWeight.w600, -0.01);
  static final bodyMd = _inter(13, 18, FontWeight.w400);
  static final bodySm = _inter(12, 16, FontWeight.w400);
  static final labelMd = _inter(11, 14, FontWeight.w600, 0.04);
  static final labelSm = _inter(10, 12, FontWeight.w500, 0.02);
  static final mono = _mono(12, 16, FontWeight.w500, -0.01);
  static final monoXs = _mono(10, 12, FontWeight.w400);
}

extension StyleWeight on TextStyle {
  /// copyWith(fontWeight:) degisken yazi tipinin eksenini guncellemez; bu ikisini birlikte ayarlar.
  TextStyle w(FontWeight weight) =>
      copyWith(fontWeight: weight, fontVariations: [FontVariation.weight(weight.value.toDouble())]);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: C.surface,
    colorScheme: const ColorScheme.dark(
      surface: C.surface,
      primary: C.primary,
      onPrimary: C.onPrimary,
      secondary: C.secondary,
      tertiary: C.tertiary,
      error: C.error,
      onSurface: C.onSurface,
    ),
  );
  return base.copyWith(
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.primary),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: C.highest, borderRadius: BorderRadius.circular(6)),
      textStyle: T.bodySm.copyWith(color: C.onSurface),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.onPrimary : C.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.primary : C.highest),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(4),
      thumbColor: WidgetStateProperty.all(C.highest),
      radius: const Radius.circular(4),
    ),
  );
}
