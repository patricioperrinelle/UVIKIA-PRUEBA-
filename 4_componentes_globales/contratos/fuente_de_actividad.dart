import 'package:flutter/material.dart';
import '../../3_modelos/contratos/dominio_app.dart';
import '../../3_modelos/contratos/trabajo_contratable.dart';

abstract class FuenteDeActividad implements Listenable {
  DominioApp get dominio;
  
  // Metadatos visuales para la pestaña Cliente
  String get tituloActivoCliente;
  IconData get iconoActivoCliente;
  Color get colorTemaCliente;
  String get textoVacioCliente;

  // Metadatos visuales para la pestaña Profesional
  String get tituloActivoPro;
  IconData get iconoActivoPro;
  Color get colorTemaPro;
  String get textoVacioPro;

  Future<void> recargarDatosDesdeCero();
  void recargarSilenciosoGlobal();
  void marcarItemComoVisto(TrabajoContratable trabajo, bool esDueno);
  void eliminarRegistro(TrabajoContratable trabajo, bool esDueno);
  int calcularAlertasItem(TrabajoContratable trabajo, bool esDueno);
  Widget construirPantallaDetalle(TrabajoContratable trabajo, bool esHistorial);
  
  List<TrabajoContratable> obtenerActivosCliente();
  List<TrabajoContratable> obtenerFinalizadosCliente();
  List<TrabajoContratable> obtenerCanceladosCliente();
  
  List<TrabajoContratable> obtenerActivosPro();
  List<TrabajoContratable> obtenerFinalizadosPro();
  List<TrabajoContratable> obtenerCanceladosPro();
}

class RegistroFuentesActividad {
  static final List<FuenteDeActividad> _fuentes = [];

  static void registrar(FuenteDeActividad fuente) {
    if (!_fuentes.any((f) => f.dominio == fuente.dominio)) {
      _fuentes.add(fuente);
    }
  }

  static List<FuenteDeActividad> get fuentes => List.unmodifiable(_fuentes);

  static FuenteDeActividad? obtenerPorDominio(DominioApp dominio) {
    try {
      return _fuentes.firstWhere((f) => f.dominio == dominio);
    } catch (_) {
      return null;
    }
  }
}
