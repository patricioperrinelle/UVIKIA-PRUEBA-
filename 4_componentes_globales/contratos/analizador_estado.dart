import 'package:flutter/material.dart';
import '../../3_modelos/contratos/dominio_app.dart';
import '../../3_modelos/contratos/trabajo_contratable.dart';

class PaqueteVisualTarjeta {
  final String estadoLabel;
  final Color estadoColor;
  final bool usarPuntito;
  final bool esPillBurbuja;
  final bool mostrarBasurero;
  final bool tacharTextos;
  final String textoFecha;
  final String textoHora;
  final String textoUbicacion;
  final String precioLimpio;
  final bool esTextoAdefinir;
  final IconData iconoFallo;

  PaqueteVisualTarjeta({
    required this.estadoLabel,
    required this.estadoColor,
    required this.usarPuntito,
    required this.esPillBurbuja,
    required this.mostrarBasurero,
    required this.tacharTextos,
    required this.textoFecha,
    required this.textoHora,
    required this.textoUbicacion,
    required this.precioLimpio,
    required this.esTextoAdefinir,
    required this.iconoFallo,
  });
}

abstract class AnalizadorEstado {
  DominioApp get dominio;
  PaqueteVisualTarjeta analizar({
    required TrabajoContratable trabajo,
    required bool esDueno,
    required String miId,
    required bool esHistorial,
  });
}

class RegistroAnalizadoresEstado {
  static final List<AnalizadorEstado> _analizadores = [];

  static void registrar(AnalizadorEstado analizador) {
    if (!_analizadores.any((a) => a.dominio == analizador.dominio)) {
      _analizadores.add(analizador);
    }
  }

  static List<AnalizadorEstado> get analizadores => List.unmodifiable(_analizadores);

  static AnalizadorEstado? obtenerPorDominio(DominioApp dominio) {
    try {
      return _analizadores.firstWhere((a) => a.dominio == dominio);
    } catch (_) {
      return null;
    }
  }
}
