// lib/5_modulos/modulo_explorar_feed/controladores/controlador_feed_publicaciones.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/servicio_feed_supabase.dart';
import '../../../3_modelos/modelo_jornada.dart';
import '../../../3_modelos/modelo_oficio_trabajo.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/utilidades/mixin_paginacion_cursores.dart';
import '../../../1_nucleo/utilidades/mixin_gestor_filtros.dart';
import 'controlador_feed_jornadas.dart';
import 'controlador_feed_oficios.dart';

part 'extension_feed_favoritos.dart'; 

class ControladorFeedPublicaciones extends ChangeNotifier with MixinPaginacionCursores, MixinGestorFiltros {
  
  static final ControladorFeedPublicaciones instancia = ControladorFeedPublicaciones._internal();

  bool isLoading = true; 
  Set<String> misPostulacionesIds = {};
  String _misOficiosRealesCache = ''; 

  DateTime _ultimaRecarga = DateTime.now();

  Set<String> misTrabajosGuardadosIds = {};
  List<ModeloOficioTrabajo> oficiosGuardadosCompletos = [];
  List<ModeloJornada> jornadasGuardadasCompletas = [];

  List<ModeloOficioTrabajo> get oficios => ControladorFeedOficios.instancia.oficios;
  List<ModeloJornada> get jornadas => ControladorFeedJornadas.instancia.jornadas;

  ScrollController get scrollOficios => ControladorFeedOficios.instancia.scrollOficios;
  ScrollController get scrollJornadas => ControladorFeedJornadas.instancia.scrollJornadas;
  
  bool get isLoadingMoreOficios => ControladorFeedOficios.instancia.isLoadingMoreOficios;
  bool get isLoadingMoreJornadas => ControladorFeedJornadas.instancia.isLoadingMoreJornadas;

  String get misOficiosRealesCache => _misOficiosRealesCache;

  ControladorFeedPublicaciones._internal();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void dispararBusquedaAntiWipeout() {
    ControladorFeedOficios.instancia.reiniciarMotor();
    ControladorFeedJornadas.instancia.reiniciarMotor();
    isLoading = true;
    notifyListeners();
    
    Future.wait([
      ControladorFeedOficios.instancia.ejecutarFetch(),
      ControladorFeedJornadas.instancia.ejecutarFetch(),
    ]).then((_) {
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> cargarFeeds(BuildContext context, {bool isRefreshManual = false}) async {
    final gestor = context.read<GestorSesionGlobal>();
    final miId = gestor.miIdUsuario;
    final List<String> listaTags = gestor.perfilUsuario?.perfilProfesional?.tagsOficios ?? [];
    _misOficiosRealesCache = listaTags.join(',');

    final ahora = DateTime.now();
    final minutosPasados = ahora.difference(_ultimaRecarga).inMinutes;
    final bool cacheVencido = minutosPasados >= 15; 

    if (!isRefreshManual && (oficios.isNotEmpty || jornadas.isNotEmpty)) {
      if (!cacheVencido) {
        sincronizarInteraccionesLocales(context);
        return; 
      } else {
        _ultimaRecarga = ahora;
        sincronizarInteraccionesLocales(context);
        _ejecutarSWRBackgroundSinScroll(miId);
        return;
      }
    }

    _ultimaRecarga = ahora;

    if (isLoading && oficios.isEmpty && jornadas.isEmpty) {
      provinciaFiltro = gestor.perfilUsuario?.ciudad ?? '';
      localidadFiltro = gestor.perfilUsuario?.localidad ?? '';
    }

    await _cargarDesdeCacheLocal();
    _fetchSilenciosoBajoCapot(miId);
  }

  Future<void> _cargarDesdeCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oficiosCache = prefs.getString('feed_oficios_cache');
      final jornadasCache = prefs.getString('feed_jornadas_cache');
      final postulacionesCache = prefs.getStringList('feed_postulaciones_ids');

      if (postulacionesCache != null) misPostulacionesIds = postulacionesCache.toSet();
      
      if (oficiosCache != null) {
        final list = (jsonDecode(oficiosCache) as List).map((e) => ModeloOficioTrabajo.fromJson(e)).toList();
        list.removeWhere((t) => t.estado != 'abierto' || misPostulacionesIds.contains(t.id));
        ControladorFeedOficios.instancia.setElementos(list);
      }
      if (jornadasCache != null) {
        final list = (jsonDecode(jornadasCache) as List).map((e) => ModeloJornada.fromJson(e)).toList();
        list.removeWhere((t) => t.estado != 'abierto' || misPostulacionesIds.contains(t.id));
        ControladorFeedJornadas.instancia.setElementos(list);
      }

      await _cargarCacheFavoritosLocal();

      sincronizarObjetosFavoritosDesdeFeed(oficios, false);
      sincronizarObjetosFavoritosDesdeFeed(jornadas, true);

      if (oficios.isNotEmpty || jornadas.isNotEmpty || oficiosGuardadosCompletos.isNotEmpty || jornadasGuardadasCompletas.isNotEmpty) {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) { debugPrint('SWR-Titan: Error leyendo caché del feed: $e'); }
  }

  Future<void> _fetchSilenciosoBajoCapot(String miId) async {
    try {
      misPostulacionesIds = await ServicioFeedSupabase.obtenerMisPostulacionesIds(miId);
      
      Set<String>? idsVigentes;
      try {
        idsVigentes = await ServicioFeedSupabase.obtenerMisTrabajosGuardadosIds(miId); 
      } catch (e) {
        debugPrint('SWR-Titan: Red caída, omitiendo purga de favoritos para proteger caché local. $e');
      }
      
      if (idsVigentes != null) {
        purgarFantasmasFavoritos(idsVigentes);
      }
      
      ControladorFeedOficios.instancia.reiniciarMotor();
      ControladorFeedJornadas.instancia.reiniciarMotor();
      
      await Future.wait([
        ControladorFeedOficios.instancia.ejecutarFetch(),
        ControladorFeedJornadas.instancia.ejecutarFetch(),
      ]);

      sincronizarObjetosFavoritosDesdeFeed(oficios, false);
      sincronizarObjetosFavoritosDesdeFeed(jornadas, true);

      isLoading = false;
      notifyListeners();
      _guardarCacheLocal();
    } catch (e) { debugPrint('Error fetch feed silencioso: $e'); }
  }

  Future<void> _guardarCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oficiosPagina1 = oficios.take(20).toList();
      final jornadasPagina1 = jornadas.take(20).toList();
      await prefs.setString('feed_oficios_cache', jsonEncode(oficiosPagina1.map((e) => e.toJson()).toList()));
      await prefs.setString('feed_jornadas_cache', jsonEncode(jornadasPagina1.map((e) => e.toJson()).toList()));
      await prefs.setStringList('feed_postulaciones_ids', misPostulacionesIds.toList());
    } catch (_) {}
  }
  
  Future<void> sincronizarInteraccionesLocales(BuildContext context) async {
    final miId = context.read<GestorSesionGlobal>().miIdUsuario;
    if (miId.isEmpty) return;

    try {
      final postulacionesActualizadas = await ServicioFeedSupabase.obtenerMisPostulacionesIds(miId);
      final favoritosActualizados = await ServicioFeedSupabase.obtenerMisTrabajosGuardadosIds(miId);

      misPostulacionesIds = postulacionesActualizadas;

      ControladorFeedOficios.instancia.oficios.removeWhere((t) => misPostulacionesIds.contains(t.id));
      ControladorFeedJornadas.instancia.jornadas.removeWhere((t) => misPostulacionesIds.contains(t.id));

      purgarFantasmasFavoritos(favoritosActualizados);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('feed_postulaciones_ids', misPostulacionesIds.toList());

      notifyListeners();
    } catch (e) {
      debugPrint('SWR-Titan: Error en sincronización silenciosa: $e');
    }
  }

  Future<void> _ejecutarSWRBackgroundSinScroll(String miId) async {
    try {
      final oficiosFrescos = await ControladorFeedOficios.instancia.obtenerPagina1OficiosSilenciosa();
      final jornadasFrescas = await ControladorFeedJornadas.instancia.obtenerPagina1JornadasSilenciosa();

      _parchearListaOficiosEnRAM(ControladorFeedOficios.instancia.oficios, oficiosFrescos);
      _parchearListaJornadasEnRAM(ControladorFeedJornadas.instancia.jornadas, jornadasFrescas);

      sincronizarObjetosFavoritosDesdeFeed(oficios, false);
      sincronizarObjetosFavoritosDesdeFeed(jornadas, true);

      notifyListeners();
      _guardarCacheLocal();

    } catch (e) {
      debugPrint('SWR-Titan: Error en SWR Background: $e');
    }
  }

  void _parchearListaOficiosEnRAM(List<ModeloOficioTrabajo> listaActual, List<ModeloOficioTrabajo> listaFresca) {
    if (listaFresca.isEmpty) return;
    for (var i = listaFresca.length - 1; i >= 0; i--) {
      final fresco = listaFresca[i];
      final indexActual = listaActual.indexWhere((e) => e.id == fresco.id);
      
      if (indexActual != -1) {
        listaActual[indexActual] = fresco;
      } else {
        listaActual.insert(0, fresco);
      }
    }
  }

  void _parchearListaJornadasEnRAM(List<ModeloJornada> listaActual, List<ModeloJornada> listaFresca) {
    if (listaFresca.isEmpty) return;
    for (var i = listaFresca.length - 1; i >= 0; i--) {
      final fresco = listaFresca[i];
      final indexActual = listaActual.indexWhere((e) => e.id == fresco.id);
      
      if (indexActual != -1) {
        listaActual[indexActual] = fresco;
      } else {
        listaActual.insert(0, fresco);
      }
    }
  }

  void eliminarTrabajoDeRAM(String id) {
    ControladorFeedOficios.instancia.eliminarDeRAM(id);
    ControladorFeedJornadas.instancia.eliminarDeRAM(id);
    notifyListeners();
  }
}
