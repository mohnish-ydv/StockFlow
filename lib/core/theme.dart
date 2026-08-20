import 'package:flutter/material.dart';

/// StockFlow publish-ready commerce design system.
///
/// The visual system uses a quiet white canvas, a single confident cobalt brand
/// colour, soft neutral fields and restrained rounded geometry. Product imagery
/// and transaction content carry the hierarchy; decoration stays secondary.
class StockFlowTheme {
  // Core surfaces.
  static const ink = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const panel = Color(0xFFFFFFFF);
  static const panel2 = Color(0xFFF5F6F8);
  static const panel3 = Color(0xFFEEF2F8);

  // Brand.
  static const accent = Color(0xFF1769FF);
  static const accentStrong = Color(0xFF0B56E8);
  static const brandSoft = Color(0xFFEAF1FF);
  static const brandWash = Color(0xFFF3F7FF);

  // Support colours.
  static const blue = accent;
  static const blueSoft = brandSoft;
  static const gold = Color(0xFFA87516);
  static const amber = Color(0xFFB7791F);
  static const danger = Color(0xFFCF3F45);
  static const success = Color(0xFF17845C);

  // Text and boundaries.
  static const text = Color(0xFF111318);
  static const textSecondary = Color(0xFF4F5661);
  static const muted = Color(0xFF7A818C);
  static const line = Color(0xFFECEEF2);
  static const lineStrong = Color(0xFFDDE1E8);

  // Shared layout tokens.
  static const double pagePadding = 20;
  static const double sectionGap = 28;
  static const double radiusSmall = 12;
  static const double radius = 16;
  static const double radiusLarge = 22;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accentStrong,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      error: danger,
      outline: lineStrong,
      outlineVariant: line,
      surfaceContainerLowest: surface,
      surfaceContainerLow: panel2,
      surfaceContainer: panel3,
      surfaceContainerHigh: brandSoft,
    );

    const textTheme = TextTheme(
      displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.25, height: 1.04, color: text),
      headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.08, color: text),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -.65, height: 1.12, color: text),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.35, height: 1.18, color: text),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -.2, height: 1.25, color: text),
      titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, letterSpacing: -.08, height: 1.32, color: text),
      titleSmall: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3, color: text),
      bodyLarge: TextStyle(fontSize: 15.5, height: 1.46, color: text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.43, color: textSecondary),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: muted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -.05, color: text),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
      labelSmall: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      dividerColor: line,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleSpacing: pagePadding,
        titleTextStyle: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.45),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel2,
        hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: accentStrong, fontWeight: FontWeight.w600),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: danger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: const BorderSide(color: line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFC9D8F8),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -.05),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: lineStrong),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentStrong,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panel2,
        selectedColor: brandSoft,
        disabledColor: panel2,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: accentStrong, fontSize: 12, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: brandSoft,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 10.5,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? accentStrong : muted,
            )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: lineStrong,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: lineStrong, width: 1.4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : null),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    );
  }
}
