// lib/2_tema/dimensiones_app.dart

import 'package:flutter/material.dart';

// =================================================================
// DIMENSIONES, RADIOS Y ESPACIADOS
// Centraliza márgenes y bordes para mantener proporción matemática.
// =================================================================

class DimensionesApp {
  // ── RADIOS DE BORDES ──
  static final BorderRadius radioPequeno = BorderRadius.circular(8.0);
  static final BorderRadius radioMedio = BorderRadius.circular(12.0);
  static final BorderRadius radioTarjetas = BorderRadius.circular(16.0); // El estándar actual
  static final BorderRadius radioModales = BorderRadius.circular(24.0);
  static final BorderRadius radioBoton = BorderRadius.circular(14.0);

  // ── PADDINGS GLOBALES ──
  static const EdgeInsets paddingPantalla = EdgeInsets.all(24.0);
  static const EdgeInsets paddingTarjetas = EdgeInsets.all(16.0);
  static const EdgeInsets paddingBotones = EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);
  static const EdgeInsets paddingInputs = EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0);

  // ── TAMAÑOS DE ÍCONOS ──
  static const double iconoPequeno = 16.0;
  static const double iconoMedio = 24.0;
  static const double iconoGrande = 32.0;
}