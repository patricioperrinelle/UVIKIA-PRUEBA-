// lib/5_modulos/modulo_explorar_feed/controladores/controlador_feed_oficios.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/servicio_feed_supabase.dart';
import '../../../3_modelos/modelo_oficio_trabajo.dart';
import '../../../1_nucleo/utilidades/mixin_paginacion_cursores.dart';
import 'controlador_feed_publicaciones.dart';

part 'extension_feed_oficios.dart';

class ControladorFeedOficios extends ChangeNotifier with MixinPaginacionCursores {
  static final ControladorFeedOficios instancia = ControladorFeedOficios._internal();

  bool _isRefreshOficios = true;
  int _generacionOficios = 0;

  late final MotorPaginacionAlpha<ModeloOficioTrabajo> _motorOficios;

  List<ModeloOficioTrabajo> get oficios => _motorOficios.elementos;
  ScrollController get scrollOficios => _motorOficios.scrollController;
  bool get isLoadingMoreOficios => _motorOficios.isLoadingMore;

  ControladorFeedOficios._internal() {
    _motorOficios = crearMotorPaginacion<ModeloOficioTrabajo>(fetchSiguientePagina: _fetchOficiosSiguientePagina);
  }

  void reiniciarMotor() {
    _generacionOficios++;
    _isRefreshOficios = true;
    _motorOficios.reiniciarMotor();
  }

  Future<void> ejecutarFetch() async {
    await _motorOficios.ejecutarFetch();
  }

  void setElementos(List<ModeloOficioTrabajo> elementos) {
    _motorOficios.elementos = elementos;
    notifyListeners();
  }

  void eliminarDeRAM(String id) {
    _motorOficios.elementos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Delegates for filters to keep extension clean
  String get provinciaFiltro => ControladorFeedPublicaciones.instancia.provinciaFiltro;
  String get localidadFiltro => ControladorFeedPublicaciones.instancia.localidadFiltro;
  String get categoriaFiltro => ControladorFeedPublicaciones.instancia.categoriaFiltro;
  String get palabraClave => ControladorFeedPublicaciones.instancia.palabraClave;
  String get misOficiosRealesCache => ControladorFeedPublicaciones.instancia.misOficiosRealesCache;
  Set<String> get misPostulacionesIds => ControladorFeedPublicaciones.instancia.misPostulacionesIds;
}
