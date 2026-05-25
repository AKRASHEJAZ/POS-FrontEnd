import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_end/theme/themeColor.dart';

class AppTheme {
  static const String fontFamily = 'Inter';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.mid,
      primary: AppColors.mid,
      secondary: AppColors.soft,
      surface: AppColors.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.light,
      fontFamily: fontFamily,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.deep,
      displayColor: AppColors.deep,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light,
        foregroundColor: AppColors.deep,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.deep,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.light,
        indicatorColor: AppColors.soft,
        selectedIconTheme: const IconThemeData(color: AppColors.light),
        unselectedIconTheme: IconThemeData(
          color: AppColors.deep.withValues(alpha: 0.65),
        ),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.deep,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.deep.withValues(alpha: 0.7),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.light,
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.deep,
        iconColor: AppColors.mid,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.deep.withValues(alpha: 0.45),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static TextStyle? title(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.deep,
          );

  static TextStyle? subtitle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.deep.withValues(alpha: 0.65),
          );

  static TextStyle? label(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.deep,
          );

  static TextStyle? body(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.deep,
          );

  /// Ensures custom [TextStyle]s use the app font (Inter).
  static TextStyle apply(TextStyle style) => GoogleFonts.inter(textStyle: style);
}
