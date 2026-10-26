import 'package:flutter/material.dart';

/// "Storybook" design system: warm paper background, bright friendly
/// colours, rounded chunky shapes and the Nunito typeface, tuned to feel
/// inviting to Grade 4 readers while staying readable for teachers.
class AppTheme {
  static const String fontFamily = 'Nunito';

  // Core palette
  static const Color primaryColor = Color(0xFF3B5BDB); // story blue
  static const Color primaryDark = Color(0xFF2B44B0);
  static const Color secondaryColor = Color(0xFF4DABF7); // sky
  static const Color sunColor = Color(0xFFFFB020); // sunshine
  static const Color coralColor = Color(0xFFFF6B6B);
  static const Color mintColor = Color(0xFF20C997);
  static const Color grapeColor = Color(0xFF9775FA);

  static const Color backgroundColor = Color(0xFFFFF8EC); // paper
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF1F2A44);
  static const Color textSecondaryColor = Color(0xFF5F6B85);
  static const Color borderColor = Color(0xFFF0E4CF);

  // Reading levels: three clearly different hues (red / yellow / green) so the
  // levels are told apart at a glance, unlike the old two-orange scheme.
  static const Color levelFrustration = Color(0xFFFF6B6B);
  static const Color levelInstructional = Color(0xFFFFB020);
  static const Color levelIndependent = Color(0xFF2BB673);

  static const BorderRadius radiusS = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(24));

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B5BDB), Color(0xFF4DABF7)],
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF8A6A3B).withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static Color levelColor(String level) => switch (level) {
    'Independent' => levelIndependent,
    'Instructional' => levelInstructional,
    'Frustration' => levelFrustration,
    _ => textSecondaryColor,
  };

  static IconData levelIcon(String level) => switch (level) {
    'Independent' => Icons.rocket_launch_rounded,
    'Instructional' => Icons.auto_stories_rounded,
    'Frustration' => Icons.spa_rounded,
    _ => Icons.help_outline_rounded,
  };

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: sunColor,
      tertiary: mintColor,
      error: const Color(0xFFE03131),
      surface: cardColor,
    );

    const baseText = TextStyle(color: textPrimaryColor);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme:
          const TextTheme(
            displaySmall: TextStyle(fontWeight: FontWeight.w900),
            headlineMedium: TextStyle(fontWeight: FontWeight.w900),
            headlineSmall: TextStyle(fontWeight: FontWeight.w800),
            titleLarge: TextStyle(fontWeight: FontWeight.w800),
            titleMedium: TextStyle(fontWeight: FontWeight.w700),
            titleSmall: TextStyle(fontWeight: FontWeight.w700),
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14.5),
            labelLarge: TextStyle(fontWeight: FontWeight.w800),
          ).apply(
            bodyColor: textPrimaryColor,
            displayColor: textPrimaryColor,
            fontFamily: fontFamily,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusL,
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: radiusM),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: radiusM),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: radiusM),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: const RoundedRectangleBorder(borderRadius: radiusS),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sunColor,
        foregroundColor: textPrimaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: radiusM),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: textSecondaryColor, fontSize: 14.5),
        labelStyle: const TextStyle(
          color: textSecondaryColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: primaryColor,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusL),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: textPrimaryColor,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimaryColor,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: radiusM),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusM),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusM),
        iconColor: primaryColor,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        space: 1,
        thickness: 1.5,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withValues(alpha: 0.14),
        labelStyle: baseText.copyWith(
          fontFamily: fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(
          side: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: borderColor,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: primaryColor,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w800,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimaryColor,
          borderRadius: radiusS,
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static BoxDecoration get pageHeaderDecoration => const BoxDecoration(
    color: backgroundColor,
    border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: radiusL,
    border: Border.all(color: borderColor, width: 1.5),
    boxShadow: softShadow,
  );

  static TextStyle get pageTitleStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: textPrimaryColor,
  );

  static TextStyle get sectionTitleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: textPrimaryColor,
  );

  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
  );
}
