import 'package:flutter/material.dart';

class AppTheme {
  // Barevná paleta
  static const Color primaryColor = Color(0xFF9333EA); // Hlavní fialová
  static const Color primaryLight = Color(0xFFAB68EE); // Světlejší fialová
  static const Color accentColor = Color(0xFF14B8A6); // Akcentová tyrkysová
  static const Color backgroundDark = Color(0xFF090914); // Tmavé pozadí
  static const Color surfaceDark = Color(0xFF11111E); // Tmavý povrch
  static const Color cardDark = Color(0xFF16162A); // Tmavá karta
  
  // Pro kompatibilitu s novými obrazovkami
  static const Color backgroundColor = backgroundDark;
  static const Color cardColor = cardDark;
  static const Color successColor = Color(0xFF10B981); // Zelená pro úspěch
  static const Color errorColor = Color(0xFFEF4444); // Červená pro chyby
  static const Color warningColor = Color(0xFFF59E0B); // Žlutá pro varování

  // Gradienty
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF7928CA)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, Color(0xFF0891B2)],
  );

  // Stíny
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.2),
      blurRadius: 15,
      offset: const Offset(0, 5),
      spreadRadius: -5,
    ),
  ];

  // Hlavní téma
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryColor,
    canvasColor: backgroundDark,
    cardColor: cardDark,
    shadowColor: Colors.black.withOpacity(0.4),
    splashColor: primaryColor.withOpacity(0.1),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      background: backgroundDark,
      surface: surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
      error: errorColor,
    ),
    fontFamily: 'Inter',

    // Typografie
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.5),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white60, height: 1.5),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Bottom Navigation Bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      selectedIconTheme: IconThemeData(size: 24),
      unselectedIconTheme: IconThemeData(size: 22),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    // Tlačítka
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey.shade800;
            }
            return primaryColor;
          },
        ),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevation: MaterialStateProperty.all(0),
        textStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primaryLight),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        overlayColor: MaterialStateProperty.all(primaryColor.withOpacity(0.05)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primaryColor),
        side: MaterialStateProperty.all(
          const BorderSide(color: primaryColor, width: 1.5),
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        overlayColor: MaterialStateProperty.all(primaryColor.withOpacity(0.05)),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      splashColor: Colors.white.withOpacity(0.2),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(8),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      errorStyle: const TextStyle(color: errorColor, fontSize: 12),
      suffixIconColor: Colors.white70,
      prefixIconColor: Colors.white70,
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        },
      ),
      side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        },
      ),
      trackColor: MaterialStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.shade800;
        },
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
      space: 24,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceDark,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white70),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actionTextColor: primaryColor,
    ),

    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: Colors.white10,
      circularTrackColor: Colors.white10,
      refreshBackgroundColor: surfaceDark,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: Colors.black.withOpacity(0.3),
      disabledColor: Colors.grey.shade800,
      selectedColor: primaryColor.withOpacity(0.7),
      secondarySelectedColor: accentColor.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(fontSize: 14, color: Colors.white),
      secondaryLabelStyle: const TextStyle(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      brightness: Brightness.dark,
    ),
  );
}
