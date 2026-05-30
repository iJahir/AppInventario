import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme (Default)
  static const Color azulOscuroFondo = Color(0xFF0D1117);
  static const Color tarjetaOscura = Color(0xFF161B22);
  static const Color grisTexto = Color(0xFF8B949E);
  static const Color azulPrincipal = Color(0xFF3A7BD5);
  static const Color moradoPrincipal = Color(0xFFA770EF);
  static const Color white = Colors.white;

  // Light Theme
  static const Color fondoClaro = Color(0xFFF8F9FA);
  static const Color tarjetaClara = Colors.white;
  static const Color textoOscuro = Color(0xFF161B22);

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? azulOscuroFondo 
      : fondoClaro;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? tarjetaOscura 
      : tarjetaClara;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? Colors.white 
      : textoOscuro;
  }

  static Color getSubtextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? grisTexto 
      : Colors.black54;
  }
}
