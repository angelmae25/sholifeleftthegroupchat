import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryDark     = Color(0xFF6B0F0F);
  static const Color primary         = Color(0xFF8B1A1A);
  static const Color primaryLight    = Color(0xFFB22222);
  static const Color accent          = Color(0xFFE8A000);
  static const Color accentLight     = Color(0xFFFFB830);
  static const Color surface         = Color(0xFFFAF7F5);
  static const Color cardBg          = Color(0xFFFFFFFF);
  static const Color sidebarBg       = Color(0xFF7A1010);
  static const Color textPrimary     = Color(0xFF1A0A0A);
  static const Color textSecondary   = Color(0xFF6B4040);
  static const Color textOnDark      = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFE8CCCC);
  static const Color divider         = Color(0xFFEDD5D5);
  static const Color inputBorder     = Color(0xFFDDBBBB);

  // Facebook dark palette
  static const Color fbDarkBg       = Color(0xFF18191A);
  static const Color fbDarkCard     = Color(0xFF242526);
  static const Color fbDarkInput    = Color(0xFF3A3B3C);
  static const Color fbDarkDivider  = Color(0xFF3E4042);
  static const Color fbDarkTextMain = Color(0xFFE4E6EB);
  static const Color fbDarkTextSub  = Color(0xFFB0B3B8);

  // Non-const helpers — call these in build() methods only
  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? fbDarkCard : Colors.white;

  static Color pageColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? fbDarkBg : surface;

  static Color inputFill(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? fbDarkInput : Colors.white;

  static Color textMain(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? fbDarkTextMain : textPrimary;

  static Color textSub(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? fbDarkTextSub : textSecondary;

  static Color borderCol(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? fbDarkDivider : inputBorder;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary, brightness: Brightness.light,
      primary: primary, secondary: accent, surface: surface, onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
      titleLarge:    GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge:     GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
      bodyMedium:    GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: inputBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: inputBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary, width: 2)),
      hintStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 13),
    ),
    cardTheme: CardThemeData(
      elevation: 2, color: cardBg,
      shadowColor: Color.fromRGBO(139, 26, 26, 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
      titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? primary : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? const Color(0x668B1A1A)
          : const Color(0x4D9E9E9E)),
    ),
    dividerColor: divider,
  );

  // ── DARK THEME — Facebook style ───────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary:    primary,    onPrimary:    Colors.white,
      primaryContainer: primaryDark, onPrimaryContainer: Colors.white,
      secondary:  accent,    onSecondary:  Colors.black,
      secondaryContainer: fbDarkInput, onSecondaryContainer: fbDarkTextMain,
      error: Colors.redAccent, onError: Colors.white,
      surface:    fbDarkCard, onSurface:   fbDarkTextMain,
      outline:    fbDarkDivider,
    ),
    scaffoldBackgroundColor: fbDarkBg,
    cardColor:   fbDarkCard,
    dividerColor: fbDarkDivider,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: fbDarkTextMain),
      titleLarge:    GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: fbDarkTextMain),
      bodyLarge:     GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: fbDarkTextMain),
      bodyMedium:    GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: fbDarkTextSub),
      labelSmall:    GoogleFonts.poppins(fontSize: 11, color: fbDarkTextSub),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: fbDarkInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: fbDarkDivider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: fbDarkDivider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryLight, width: 2)),
      hintStyle:  GoogleFonts.poppins(color: fbDarkTextSub, fontSize: 13),
      labelStyle: GoogleFonts.poppins(color: fbDarkTextSub, fontSize: 13),
    ),
    cardTheme: CardThemeData(
      elevation: 0, color: fbDarkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: fbDarkCard, foregroundColor: fbDarkTextMain, elevation: 0,
      titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: fbDarkTextMain),
      iconTheme: const IconThemeData(color: fbDarkTextMain),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: fbDarkCard),
    listTileTheme: const ListTileThemeData(
      tileColor: fbDarkCard, textColor: fbDarkTextMain, iconColor: fbDarkTextSub,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? accent : fbDarkTextSub),
      trackColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? const Color(0x80E8A000)
          : fbDarkInput),
    ),
    iconTheme: const IconThemeData(color: fbDarkTextMain),
    dialogTheme: DialogThemeData(
      backgroundColor: fbDarkCard,
      titleTextStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: fbDarkTextMain),
      contentTextStyle: GoogleFonts.poppins(fontSize: 14, color: fbDarkTextSub),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: fbDarkInput,
      contentTextStyle: TextStyle(color: fbDarkTextMain),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accentLight),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: fbDarkCard,
      selectedItemColor: accentLight,
      unselectedItemColor: fbDarkTextSub,
    ),
  );
}