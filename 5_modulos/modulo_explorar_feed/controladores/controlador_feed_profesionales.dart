// lib/5_modulos/modulo_explorar_feed/controladores/controlador_feed_profesionales.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/servicio_feed_supabase.dart';
import '../../../3_modelos/modelo_perfil.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/utilidades/mixin_paginacion_cursores.dart';
import '../../../1_nucleo/utilidades/mixin_gestor_filtros.dart';

part 'extension_feed_profesionales_red.dart';
part 'extension_feed_profesionales_favoritos.dart'; 

class ControladorFeedProfesionales extends ChangeNotifier with MixinPaginacionCursores, MixinGestorFiltros {
  
  // 🚀 PATRÓN SINGLETON INMORTAL V5.9.3
  static final ControladorFeedProfesionales instancia = ControladorFeedProfesionales._internal();

  bool isLoading = true;
  bool _isRefresh = true;
  bool _esPrimeraCarga = true; 
  
  // ⏱️ El reloj que controla el tiempo (TTL)
  DateTime _ultimaRecarga = DateTime.now();

  // 🚀 V5.9: SISTEMA DE GUARDADO AISLADO (RAM)
  Set<String> favoritosIds = {};
  List<ModeloPerfil> profesionalesGuardadosCompletos = [];

  // 🛡️ ESCUDO ANTI-GHOST FETCH
  int _generacion = 0;

  // 🛡️ GETTER DEVUELTO A LA PUREZA ABSOLUTA
  List<ModeloPerfil> get profesionalesFiltrados => _motorProfesionales.elementos;

  ScrollController get scrollControllerPaginacion => _motorProfesionales.scrollController;
  bool get isLoadingMore => _motorProfesionales.isLoadingMore;

  late final MotorPaginacionAlpha<ModeloPerfil> _motorProfesionales;

  // 🛡️ Constructor Privado (Instanciación única en la vida de la app)
  ControladorFeedProfesionales._internal() {
    _motorProfesionales = crearMotorPaginacion<ModeloPerfil>(fetchSiguientePagina: _fetchSiguientePagina);
  }

  @override
  void dispose() {
    super.dispose(); 
  }

  // ----------------------------------------------------------------------

  @override
  void dispararBusquedaAntiWipeout() {
    _generacion++; // 🛡️ Invalida peticiones en camino
    _isRefresh = true;
    _motorProfesionales.reiniciarMotor();
    
    isLoading = true;
    notifyListeners();
    
    _motorProfesionales.ejecutarFetch().then((_) {
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> cargarDirectorio(BuildContext context, {bool isRefreshManual = false}) async {
    final gestor = context.read<GestorSesionGlobal>();
    final miId = gestor.miIdUsuario;
    
    // ⏱️ Calculamos cuántos minutos pasaron
    final ahora = DateTime.now();
    final minutosPasados = ahora.difference(_ultimaRecarga).inMinutes;
    final bool cacheVencido = minutosPasados >= 15; // TTL 15 minutos

    // 🛡️ ESCUDO SWR V5.9.3: ANTI-AMNESIA Y ANTI-JUMP
    if (!isRefreshManual && _motorProfesionales.elementos.isNotEmpty) {
      if (!cacheVencido) {
        // < 15 min: RAM Fresca. Parcheamos favoritos y abortamos red pesada.
        sincronizarInteraccionesLocales(context);
        return; 
      } else {
        // >= 15 min: Caché Vencida. 
        // 1. Actualizamos reloj
        _ultimaRecarga = ahora;
        // 2. Parcheamos likes/favoritos
        sincronizarInteraccionesLocales(context);
        // 3. Disparamos FETCH SWR EN BACKGROUND (Sin return, UI sigue viva sin loaders)
        _ejecutarSWRBackgroundSinScroll(miId);
        return;
      }
    }

    // Flujo Normal: Pull-to-Refresh o memoria inicial vacía
    _ultimaRecarga = ahora; 
    
    if (_esPrimeraCarga) {
      provinciaFiltro = gestor.perfilUsuario?.ciudad ?? '';
      localidadFiltro = gestor.perfilUsuario?.localidad ?? '';
      _esPrimeraCarga = false;
    }

    await _cargarDesdeCacheLocal();

    if (miId.isNotEmpty) {
      Set<String>? idsVigentes;
      try {
        idsVigentes = await ServicioFeedSupabase.obtenerMisFavoritosIds(miId);
      } catch (e) {
        debugPrint('SWR-Titan: Red caída, omitiendo purga de favoritos profesionales. $e');
      }

      if (idsVigentes != null) {
        purgarFantasmasFavoritos(idsVigentes);
      }
    }

    _generacion++; 
    _isRefresh = true;
    _motorProfesionales.reiniciarMotor();
    
    _motorProfesionales.ejecutarFetch().then((_) {
      sincronizarObjetosFavoritosDesdeFeed(_motorProfesionales.elementos);
      isLoading = false;
      notifyListeners();
      _guardarCacheLocal();
    });
  }

  Future<void> _cargarDesdeCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('directorio_pros_cache');
      
      await _cargarCacheFavoritosLocal();

      if (cacheStr != null) {
        _motorProfesionales.elementos = (jsonDecode(cacheStr) as List).map((e) => ModeloPerfil.fromJson(e)).toList();
        
        sincronizarObjetosFavoritosDesdeFeed(_motorProfesionales.elementos);

        if (_motorProfesionales.elementos.isNotEmpty || profesionalesGuardadosCompletos.isNotEmpty) {
          isLoading = false;
          notifyListeners();
        }
      }
    } catch (e) { debugPrint('SWR-Titan: Error caché profesionales $e'); }
  }

  Future<void> _guardarCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pagina1 = _motorProfesionales.elementos.take(20).toList(); 
      await prefs.setString('directorio_pros_cache', jsonEncode(pagina1.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
  
  // ----------------------------------------------------------------------
  // 🚀 V5.9.3 FIX: SINCRONIZACIÓN SILENCIOSA DE INTERACCIONES LOCALES
  // ----------------------------------------------------------------------
  Future<void> sincronizarInteraccionesLocales(BuildContext context) async {
    final miId = context.read<GestorSesionGlobal>().miIdUsuario;
    if (miId.isEmpty) return;

    try {
      final favoritosActualizados = await ServicioFeedSupabase.obtenerMisFavoritosIds(miId);
      purgarFantasmasFavoritos(favoritosActualizados);
      notifyListeners();
    } catch (e) {
      debugPrint('SWR-Titan: Error en sincronización silenciosa de profesionales: $e');
    }
  }

  // ----------------------------------------------------------------------
  // 🚀 V5.9.3 FIX: PARCHE SWR EN BACKGROUND (ANTI-JUMP ABSOLUTO)
  // ----------------------------------------------------------------------
  Future<void> _ejecutarSWRBackgroundSinScroll(String miId) async {
    try {
      // 1. Descarga la Página 1 pura y fresca de la BD
      final frescos = await _obtenerPagina1ProfesionalesSilenciosa();

      // 2. Ejecución Atómica del Parche en RAM
      _parchearListaEnRAM(_motorProfesionales.elementos, frescos);

      // 3. Resincronizar los corazones guardados
      sincronizarObjetosFavoritosDesdeFeed(_motorProfesionales.elementos);

      // 4. Actualizar UI sutilmente sin romper el Scroll
      notifyListeners();
      _guardarCacheLocal();
    } catch (e) {
      debugPrint('SWR-Titan: Error en SWR Background Profesionales: $e');
    }
  }

  void _parchearListaEnRAM(List<ModeloPerfil> listaActual, List<ModeloPerfil> listaFresca) {
    if (listaFresca.isEmpty) return;
    
    // Iteramos al revés para inyectar en índice 0 y mantener el orden cronológico
    for (var i = listaFresca.length - 1; i >= 0; i--) {
      final fresco = listaFresca[i];
      final indexActual = listaActual.indexWhere((e) => e.id == fresco.id);
      
      if (indexActual != -1) {
        // Reemplazo In-Place (Ej: Subió de estrellas o cambió la bio)
        listaActual[indexActual] = fresco;
      } else {
        // Novedad: Nuevo profesional registrado en la ciudad
        listaActual.insert(0, fresco);
      }
    }
  }


}