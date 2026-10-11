import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.secondaryText,
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.cyan,
        surface: AppColors.primarySurface,
        error: AppColors.emergencyRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.primaryText,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        indicatorColor: AppColors.elevatedGlassSurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return GoogleFonts.inter(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.normal,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryBlue);
          }
          return const IconThemeData(color: AppColors.secondaryText);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
