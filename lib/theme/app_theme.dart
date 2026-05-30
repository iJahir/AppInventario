import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azulPrincipal,
        primary: AppColors.azulPrincipal,
        secondary: AppColors.moradoPrincipal,
        surface: AppColors.tarjetaOscura,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.azulOscuroFondo,
      cardColor: AppColors.tarjetaOscura,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azulPrincipal,
        primary: AppColors.azulPrincipal,
        secondary: AppColors.moradoPrincipal,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: Colors.white,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF161B22)),
        bodyMedium: TextStyle(color: Color(0xFF161B22)),
      ),
    );
  }
}
