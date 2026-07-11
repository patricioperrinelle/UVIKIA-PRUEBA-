// lib/2_tema/tema_global.dart

import 'package:flutter/material.dart';
import 'colores_app.dart';
import 'estilos_texto.dart';

// =================================================================
// TEMA GLOBAL DE LA APLICACIÓN (ThemeData)
// Configura los dos polos de la app: Oscuro y Claro.
// =================================================================

class TemaGlobal {
  // 🌙 MODO OSCURO (Usa las constantes originales de ColoresApp para retrocompatibilidad)
  static ThemeData obtenerTemaOscuro() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColoresApp.fondoPrincipal,
      primaryColor: ColoresApp.terciarioMorado,
      fontFamily: EstilosTextoApp.fuentePrincipal,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: ColoresApp.textoPrincipal),
        titleTextStyle: TextStyle(
          color: ColoresApp.textoPrincipal, 
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          fontFamily: EstilosTextoApp.fuentePrincipal
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresApp.fondoBuscador,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
        hintStyle: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      colorScheme: const ColorScheme.dark(
        primary: ColoresApp.primarioVerde,
        secondary: ColoresApp.secundarioCyan,
        surface: ColoresApp.fondoTarjetas,
        error: ColoresApp.errorRojo,
        onPrimary: Colors.black,
        onSurface: ColoresApp.textoPrincipal,
      ),

      textTheme: TextTheme(
        bodyMedium: EstilosTextoApp.cuerpoRegular.copyWith(color: ColoresApp.textoPrincipal),
        bodySmall: EstilosTextoApp.cuerpoPequeno.copyWith(color: ColoresApp.textoSecundario),
      ),
    );
  }

  // ☀️ MODO CLARO (Independiente, usa colores Hex directos para no romper los const del resto de la app)
  static ThemeData obtenerTemaClaro() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Gris perla claro
      primaryColor: ColoresApp.terciarioMorado,
      fontFamily: EstilosTextoApp.fuentePrincipal,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1D1D1F)), // Casi negro
        titleTextStyle: TextStyle(
          color: Color(0xFF1D1D1F), 
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          fontFamily: EstilosTextoApp.fuentePrincipal
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE5E5EA), // Inputs gris claro
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
        hintStyle: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      colorScheme: const ColorScheme.light(
        primary: ColoresApp.primarioVerde,
        secondary: ColoresApp.secundarioCyan,
        surface: Color(0xFFFFFFFF), // Tarjetas blancas
        error: ColoresApp.errorRojo,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1D1D1F), // Textos principales oscuros
      ),

      textTheme: TextTheme(
        bodyMedium: EstilosTextoApp.cuerpoRegular.copyWith(color: const Color(0xFF1D1D1F)),
        bodySmall: EstilosTextoApp.cuerpoPequeno.copyWith(color: const Color(0xFF86868B)), // Textos secundarios grises
      ),
    );
  }
}