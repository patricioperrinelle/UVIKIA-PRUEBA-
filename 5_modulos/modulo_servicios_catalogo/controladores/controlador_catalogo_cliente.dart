// lib/5_modulos/modulo_servicios_catalogo/controladores/controlador_catalogo_cliente.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../../../3_modelos/modelo_perfil.dart'; 
import '../servicios/servicio_catalogo_supabase.dart';
import 'controlador_disponibilidad_agenda.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/utilidades/mixin_paginacion_cursores.dart';

import '../../../1_nucleo/utilidades/mixin_gestor_filtros.dart';

part 'extension_catalogo_red.dart';
part 'extension_catalogo_checkout.dart';
part 'extension_catalogo_favoritos.dart'; 

class ControladorCatalogoCliente extends ChangeNotifier with MixinPaginacionCursores, MixinGestorFiltros {
  
  static final ControladorCatalogoCliente instancia = ControladorCatalogoCliente._internal();

  bool isLoadingCatalogo = true;
  bool _isRefresh = true;
  bool _esPrimeraCarga = true;
  
  DateTime _ultimaRecarga = DateTime.now();

  Set<String> misFavoritosIds = {};
  List<ModeloServicioCatalogo> serviciosGuardadosCompletos = [];

  int _generacion = 0;

  List<ModeloServicioCatalogo> get listaServiciosFiltrada => _motorCatalogo.elementos;
  
  ScrollController get scrollControllerPaginacion => _motorCatalogo.scrollController;
  bool get isLoadingMore => _motorCatalogo.isLoadingMore;

  final Map<String, Map<String, dynamic>> _cachePerfilesVendedores = {};

  late final MotorPaginacionAlpha<ModeloServicioCatalogo> _motorCatalogo;

  final TextEditingController notasController = TextEditingController(); 
  // Controllers para dirección detallada (mismo sistema que creador_servicio)
  final TextEditingController calleCtrl = TextEditingController();
  final TextEditingController numeroCtrl = TextEditingController();
  final TextEditingController localidadCtrl = TextEditingController();
  final TextEditingController barrioCtrl = TextEditingController();
  final TextEditingController paisCtrl = TextEditingController();
  String? provinciaSeleccionada;

  void onProvinciaChanged(String nuevaProvincia) {
    provinciaSeleccionada = nuevaProvincia;
    notifyListeners();
  }

  String get direccionConcatenada {
    return '${calleCtrl.text.trim()} ${numeroCtrl.text.trim()}, ${barrioCtrl.text.trim()}, ${localidadCtrl.text.trim()}, ${provinciaSeleccionada ?? ''}';
  }

  final TextEditingController direccionController = TextEditingController(); // Keep it if used elsewhere in fallback

  ModeloServicioCatalogo? servicioActivo;
  ModeloPerfil? perfilVendedor; 
  String idNivelSeleccionado = '';
  List<DateTime> diasDisponibles = [];
  DateTime fechaSeleccionada = DateTime.now();
  List<DateTime> horasHabilitadas = [];
  List<DateTime> todasLasHoras = [];
  DateTime? horaSeleccionada;
  bool isLoadingHoras = false;
  List<Map<String, dynamic>> extrasDisponibles = [];
  List<Map<String, String>> faqsDisponibles = [];
  bool isProcesandoCheckout = false;
  
  // 🚨 UUID TEMPORAL PARA COMPRA DIRECTA
  String? idReservaTemporalActiva;

  // 🆕 RESERVA PENDIENTE (Opción A: BD es fuente de verdad, solo se cachea en RAM por sesión).
  // Representa una reserva pendiente_pago NO vencida para el servicioActivo.
  Map<String, dynamic>? reservaPendienteServicioActivo;
  bool isLoadingReservaPendiente = false;

  // Getter de conveniencia para la UI (banner anti-duplicado).
  bool get tieneReservaPendienteActiva => reservaPendienteServicioActivo != null;

  // PUENTE PARA LA UI
  void actualizarUI() {
    notifyListeners();
  }

  ControladorCatalogoCliente._internal() {
    _generarDiasDisponibles();
    _motorCatalogo = crearMotorPaginacion<ModeloServicioCatalogo>(fetchSiguientePagina: _fetchSiguientePagina);
  }

  @override
  void dispose() {
    notasController.dispose(); 
    direccionController.dispose(); 
    calleCtrl.dispose();
    numeroCtrl.dispose();
    localidadCtrl.dispose();
    barrioCtrl.dispose();
    paisCtrl.dispose();
    super.dispose();
  }

  // 🚨 MÉTODO PARA DESTRUIR LA LLAVE SI EL PAGO FALLA
  void abortarCheckoutTemporal() {
    idReservaTemporalActiva = null;
    isProcesandoCheckout = false;
    notifyListeners();
  }

  // 🆕 Carga el estado real de la reserva pendiente desde la BD (única fuente de verdad).
  // Se llama al abrir el detalle del servicio. Si el usuario ya tiene una reserva
  // pendiente_pago (no vencida) para este servicio, la cachea en RAM para el banner.
  Future<void> cargarReservaPendienteDesdeBD(String servicioId, String clienteId) async {
    isLoadingReservaPendiente = true;
    actualizarUI();
    try {
      reservaPendienteServicioActivo = await ServicioCatalogoSupabase.verificarReservaPendiente(
        clienteId: clienteId,
        servicioId: servicioId,
      );
    } catch (_) {
      // 🛡️ Barrera anti-wipeout: si cae la red, dejamos null (no bloqueamos la UI).
      reservaPendienteServicioActivo = null;
    } finally {
      isLoadingReservaPendiente = false;
      actualizarUI();
    }
  }

  // 🆕 Limpia la RAM de la reserva pendiente (al cerrar el detalle o cambiar de servicio).
  void limpiarReservaPendienteRAM() {
    reservaPendienteServicioActivo = null;
  }

  @override
  void dispararBusquedaAntiWipeout() {
    _generacion++; 
    _isRefresh = true;
    _motorCatalogo.reiniciarMotor();
    
    isLoadingCatalogo = true;
    notifyListeners();
    
    _motorCatalogo.ejecutarFetch().then((_) {
      isLoadingCatalogo = false;
      notifyListeners();
    });
  }

  Future<void> cargarCatalogoPublico(BuildContext context, {bool isRefreshManual = false}) async {
    final gestor = context.read<GestorSesionGlobal>();
    final miId = gestor.miIdUsuario;

    final ahora = DateTime.now();
    final minutosPasados = ahora.difference(_ultimaRecarga).inMinutes;
    final bool cacheVencido = minutosPasados >= 15; 

    if (!isRefreshManual && _motorCatalogo.elementos.isNotEmpty) {
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

    if (_esPrimeraCarga) {
      provinciaFiltro = gestor.perfilUsuario?.ciudad ?? '';
      localidadFiltro = gestor.perfilUsuario?.localidad ?? '';
      _esPrimeraCarga = false;
    }

    await _cargarDesdeCacheLocal();

    if (miId.isNotEmpty) {
      Set<String>? idsVigentes;
      try {
        idsVigentes = await ServicioCatalogoSupabase.obtenerMisFavoritosIds(miId);
      } catch (e) {
        debugPrint('SWR-Titan: Red caída, omitiendo purga de catálogo. $e');
      }

      if (idsVigentes != null) {
        purgarFantasmasFavoritos(idsVigentes);
      }
    }

    _generacion++; 
    _isRefresh = true;
    _motorCatalogo.reiniciarMotor();
    
    _motorCatalogo.ejecutarFetch().then((_) {
      sincronizarObjetosFavoritosDesdeFeed(_motorCatalogo.elementos);
      isLoadingCatalogo = false;
      notifyListeners();
      _guardarCacheLocal();
    });
  }

  Future<void> _cargarDesdeCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('catalogo_feed_cache');

      await _cargarCacheFavoritosLocal();

      if (cacheStr != null) {
        _motorCatalogo.elementos = (jsonDecode(cacheStr) as List).map((e) => ModeloServicioCatalogo.fromJson(e)).toList();
        
        sincronizarObjetosFavoritosDesdeFeed(_motorCatalogo.elementos);

        if (_motorCatalogo.elementos.isNotEmpty || serviciosGuardadosCompletos.isNotEmpty) {
          isLoadingCatalogo = false;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _guardarCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pagina1 = _motorCatalogo.elementos.take(20).toList();
      await prefs.setString('catalogo_feed_cache', jsonEncode(pagina1.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
  
  Future<void> sincronizarInteraccionesLocales(BuildContext context) async {
    final miId = context.read<GestorSesionGlobal>().miIdUsuario;
    if (miId.isEmpty) return;

    try {
      final favoritosActualizados = await ServicioCatalogoSupabase.obtenerMisFavoritosIds(miId);
      purgarFantasmasFavoritos(favoritosActualizados);
      notifyListeners();
    } catch (e) {
      debugPrint('SWR-Titan: Error en sincronización silenciosa de catálogo: $e');
    }
  }

  Future<void> _ejecutarSWRBackgroundSinScroll(String miId) async {
    try {
      final frescos = await _obtenerPagina1CatalogoSilenciosa();
      _parchearListaEnRAM(_motorCatalogo.elementos, frescos);
      sincronizarObjetosFavoritosDesdeFeed(_motorCatalogo.elementos);

      notifyListeners();
      _guardarCacheLocal();
    } catch (e) {
      debugPrint('SWR-Titan: Error en SWR Background Catálogo: $e');
    }
  }

  void _parchearListaEnRAM(List<ModeloServicioCatalogo> listaActual, List<ModeloServicioCatalogo> listaFresca) {
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


}