//lib\constants\app_colors.dart
import 'package:flutter/material.dart';

/// App color palette based on R-Sync brand identity (from assets/icons/ico.png):
/// Teal (#178697), Orange (#EC651C), Dark Gray (#2D3641),
/// enriched with a harmonious square/tetradic palette (Indigo #5C6BC0 & Emerald #10B981).
class AppColors {
  // Brand Core Colors
  static const Color teal = Color(0xFF178697);
  static const Color tealLight = Color(0xFF38B2C6);
  static const Color tealDark = Color(0xFF0F5A66);
  static const Color tealContainer = Color(0xFFE0F4F7);
  static const Color tealContainerDark = Color(0xFF0E3942);

  static const Color orange = Color(0xFFEC651C);
  static const Color orangeLight = Color(0xFFFF853F);
  static const Color orangeDark = Color(0xFFB5460B);
  static const Color orangeContainer = Color(0xFFFFECE2);
  static const Color orangeContainerDark = Color(0xFF4A1F08);

  static const Color darkGray = Color(0xFF2D3641);
  static const Color darkGrayLight = Color(0xFF3E4A59);
  static const Color darkGrayLighter = Color(0xFF556477);

  // Square / Tetradic Harmonious Accents
  static const Color indigo = Color(0xFF5C6BC0);
  static const Color indigoContainer = Color(0xFFE8EAF6);
  static const Color indigoContainerDark = Color(0xFF282B4E);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldContainer = Color(0xFFD1FAE5);
  static const Color emeraldContainerDark = Color(0xFF064E3B);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF4F7F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF14191F);
  static const Color darkSurface = Color(0xFF1E2630);
  static const Color darkCard = Color(0xFF242D37);
  static const Color darkBorder = Color(0xFF323D4B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Relay-Specific Gradients
  static const LinearGradient relay1Gradient = LinearGradient(
    colors: [Color(0xFF178697), Color(0xFF22A3B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient relay2Gradient = LinearGradient(
    colors: [Color(0xFFEC651C), Color(0xFFFF7A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradientDark = LinearGradient(
    colors: [Color(0xFF1E2630), Color(0xFF14191F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F7F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
