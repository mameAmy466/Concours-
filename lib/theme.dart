import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const navy = Color(0xFF33403A);
  static const navyDark = Color(0xFF33403A);
  static const gold = Color(0xFF7D9481);
  static const goldSoft = Color(0xFFAEC0AC);
  static const cream = Color(0xFFF6F2E7);
  static const ink = Color(0xFF33403A);
  static const muted = Color(0xFF4F6355);
  static const card = Color(0xFFFFFBF4);
  static const sand = Color(0xFFDCD6C4);
  static const success = Color(0xFF4F6355);
  static const danger = Color(0xFF9B2C2C);
}

class AppFonts {
  static const sans = 'Outfit';
  static const serif = 'CormorantGaramond';
}

TextStyle outfit({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle displaySerif({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

class Breakpoints {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static double pagePadding(BuildContext context) =>
      isTablet(context) ? 28 : 16;

  static double maxContentWidth(BuildContext context) =>
      isWide(context) ? 1100 : double.infinity;
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.navy,
    onPrimary: AppColors.cream,
    secondary: AppColors.gold,
    onSecondary: AppColors.navy,
    tertiary: AppColors.goldSoft,
    onTertiary: AppColors.navy,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    onError: Colors.white,
    outline: AppColors.sand,
  );

  const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: 34,
      fontWeight: FontWeight.w600,
      color: AppColors.cream,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.navy,
      height: 1.15,
    ),
    headlineSmall: TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.navy,
    ),
    titleLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
    ),
    titleMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 16,
      height: 1.45,
      color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 14,
      height: 1.4,
      color: AppColors.muted,
    ),
    labelLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.sans,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.cream,
    dividerColor: AppColors.sand,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: AppColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.sans,
        color: AppColors.cream,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 12,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.goldSoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.navy : AppColors.muted,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return outfit(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.navy : AppColors.muted,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.navyDark,
      selectedIconTheme: const IconThemeData(color: AppColors.navy, size: 24),
      unselectedIconTheme:
          const IconThemeData(color: AppColors.cream, size: 22),
      selectedLabelTextStyle: outfit(
        color: AppColors.goldSoft,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: outfit(
        color: AppColors.cream.withValues(alpha: 0.75),
      ),
      indicatorColor: AppColors.goldSoft,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.sand),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.serif,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 15,
        height: 1.45,
        color: AppColors.muted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: outfit(color: AppColors.cream),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: AppColors.goldSoft,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: AppColors.cream,
      unselectedLabelColor: AppColors.cream.withValues(alpha: 0.55),
      labelStyle: outfit(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: outfit(fontWeight: FontWeight.w500, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.cream,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: outfit(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.navy, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.navy,
        textStyle: outfit(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.sand),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.6),
      ),
      labelStyle: outfit(color: AppColors.muted),
      hintStyle: outfit(color: AppColors.muted.withValues(alpha: 0.7)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.cream,
      elevation: 4,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.cream
            : AppColors.sand;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.gold
            : AppColors.sand.withValues(alpha: 0.7);
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.navy,
      thumbColor: AppColors.navy,
      inactiveTrackColor: AppColors.sand,
      overlayColor: AppColors.goldSoft.withValues(alpha: 0.3),
      trackHeight: 4,
    ),
  );
}
