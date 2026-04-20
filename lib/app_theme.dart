import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — medical teal/blue
  static const Color primary = Color(0xFF1A8FBF);
  static const Color primaryDark = Color(0xFF0D6A93);
  static const Color primaryLight = Color(0xFF5BB8DC);
  static const Color accent = Color(0xFF4DD0E1);
  static const Color accentSoft = Color(0xFFB2EBF2);
  static const Color background = Color(0xFFF0F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFE8F4F8);
  static const Color textPrimary = Color(0xFF0D2B3E);
  static const Color textSecondary = Color(0xFF4A7A8A);
  static const Color textHint = Color(0xFF9BBECE);
  static const Color success = Color(0xFF26A69A);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color cardShadow = Color(0x1A1A8FBF);

  // ── Sensor specific colors ──────────────────────────────
  static const Color tempColor      = Color(0xFFFF7043); // DHT22 temp
  static const Color humidityColor  = Color(0xFF29B6F6); // DHT22 humidity
  static const Color heartColor     = Color(0xFFEC407A); // MAX30102 HR
  static const Color weightColor    = Color(0xFF66BB6A); // HX711
  static const Color gasColor       = Color(0xFFFFCA28); // MQ5
  static const Color lightColor     = Color(0xFFFFEE58); // TLPCF8591T
  static const Color spo2Color      = Color(0xFF7E57C2); // MAX30102 SpO2
  static const Color movColor       = Color(0xFF26C6DA); // MPU6050

  // ── Gradients ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D6A93), Color(0xFF1A8FBF), Color(0xFF26B6D4)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Color(0xFFF0F8FB)],
  );
}

class AppTextStyles {
  static const String fontFamily = 'Nunito';
  static const String font = 'Nunito'; // alias used in dashboard files

  static TextStyle display(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: fontFamily, fontSize: size, fontWeight: w, color: c);

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700,
    color: Colors.white, letterSpacing: 0.5,
  );

  // Used in dashboard sensor cards
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
  static const TextStyle cardValue = TextStyle(
    fontFamily: fontFamily, fontSize: 26, fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );
  static const TextStyle cardUnit = TextStyle(
    fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.accentSoft, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.accentSoft, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
          fontFamily: AppTextStyles.fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
    );
  }
}