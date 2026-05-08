import 'package:flutter/material.dart';

class AppFontSizes {
  const AppFontSizes._();

  static const double pageTitle = 28;
  static const double sectionTitle = 20;
  static const double cardTitle = 16;
  static const double bodyText = 14;
  static const double smallMetadata = 12;
  static const double buttonText = 15;
  static const double statNumber = 22;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xffe5161d),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xfffbfaf8),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: AppFontSizes.pageTitle,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          fontSize: AppFontSizes.sectionTitle,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          fontSize: AppFontSizes.cardTitle,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(fontSize: AppFontSizes.bodyText, height: 1.25),
        labelSmall: TextStyle(fontSize: AppFontSizes.smallMetadata),
        labelLarge: TextStyle(
          fontSize: AppFontSizes.buttonText,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
