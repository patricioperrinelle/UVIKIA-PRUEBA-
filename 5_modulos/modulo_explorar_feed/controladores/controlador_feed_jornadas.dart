// lib/5_modulos/modulo_explorar_feed/controladores/controlador_feed_jornadas.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/servicio_feed_supabase.dart';
import '../../../3_modelos/modelo_jornada.dart';
import '../../../1_nucleo/utilidades/mixin_paginacion_cursores.dart';
import 'controlador_feed_publicaciones.dart';

part 'extension_feed_jornadas.dart';

class ControladorFeedJornadas extends ChangeNotifier with MixinPaginacionCursores {
  static final ControladorFeedJornadas instancia = ControladorFeedJornadas._internal();

  bool _isRefreshJornadas = true;
  int _generacionJornadas = 0;

  late final MotorPaginacionAlpha<ModeloJornada> _motorJornadas;

  List<ModeloJornada> get jornadas => _motorJornadas.elementos;
  ScrollController get scrollJornadas => _motorJornadas.scrollController;
  bool get isLoadingMoreJornadas => _motorJornadas.isLoadingMore;

  ControladorFeedJornadas._internal() {
    _motorJornadas = crearMotorPaginacion<ModeloJornada>(fetchSiguientePagina: _fetchJornadasSiguientePagina);
  }

  void reiniciarMotor() {
    _generacionJornadas++;
    _isRefreshJornadas = true;
    _motorJornadas.reiniciarMotor();
  }

  Future<void> ejecutarFetch() async {
    await _motorJornadas.ejecutarFetch();
  }

  void setElementos(List<ModeloJornada> elementos) {
    _motorJornadas.elementos = elementos;
    notifyListeners();
  }

  void eliminarDeRAM(String id) {
    _motorJornadas.elementos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Delegates for filters to keep extension clean
  String get provinciaFiltro => ControladorFeedPublicaciones.instancia.provinciaFiltro;
  String get localidadFiltro => ControladorFeedPublicaciones.instancia.localidadFiltro;
  String get categoriaFiltro => ControladorFeedPublicaciones.instancia.categoriaFiltro;
  String get palabraClave => ControladorFeedPublicaciones.instancia.palabraClave;
  Set<String> get misPostulacionesIds => ControladorFeedPublicaciones.instancia.misPostulacionesIds;
}
