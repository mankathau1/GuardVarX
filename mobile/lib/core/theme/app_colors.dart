import 'package:flutter/material.dart';

/// GuardVarX Theme Color Tokens
class AppColors {
  // Backgrounds & Surfaces
  static const Color background = Color(0xFF000000);
  static const Color secondaryBackground = Color(0xFF050505);
  static const Color surface = Color(0xFF101010);
  static const Color primarySurface = Color(0xFF101010);
  static const Color surfaceElevated = Color(0xFF141414);

  // Core Brand & Status Accents
  static const Color primaryBlue = Color(0xFF1683FF);
  static const Color cyan = Color(0xFF00D9FF);
  static const Color emergencyRed = Color(0xFFFF1744);
  static const Color successGreen = Color(0xFF00F59B);
  static const Color warningAmber = Color(0xFFFFAA00);
  static const Color purpleAccent = Color(0xFFA855F7); // Trusted contacts card

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFA1A1AA);
  static const Color mutedText = Color(0xFF71717A);

  // Glass Translucency Tokens
  static const Color glassSurface = Color(0x0FFFFFFF); // ~6% white
  static const Color elevatedGlassSurface = Color(0x17FFFFFF); // ~9% white
  static const Color glassBorder = Color(0x1FFFFFFF); // ~12% white
  static const Color glassBorderElevated = Color(0x33FFFFFF); // ~20% white
  static const Color glassBorderSubtle = Color(0x14FFFFFF); // ~8% white

  // Ambient Glows & Illuminated Borders
  static const Color blueGlow = Color(0x331683FF);
  static const Color cyanGlow = Color(0x3300D9FF);
  static const Color emergencyRedGlow = Color(0x4DFF1744);
  static const Color greenGlow = Color(0x3300F59B);
  static const Color amberGlow = Color(0x33FFAA00);
  static const Color purpleGlow = Color(0x33A855F7);

  // Dark Tinted Cards
  static const Color locationCardBackground = Color(0xFF07111E); // Deep midnight blue
  static const Color locationCardBorder = Color(0x331683FF);
  static const Color sosCardBackground = Color(0xFF19060A); // Deep red tinted glass
}
