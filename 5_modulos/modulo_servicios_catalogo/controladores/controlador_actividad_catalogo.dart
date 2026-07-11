// lib/5_modulos/modulo_servicios_catalogo/controladores/controlador_actividad_catalogo.dart

import 'dart:convert';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../3_modelos/modelo_reserva_catalogo.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';
import '../../../1_nucleo/gestor_sincronizacion_offline.dart';
import '../servicios/servicio_actividad_catalogo_supabase.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../4_componentes_globales/contratos/fuente_de_actividad.dart';
import '../../../2_tema/colores_app.dart';


class ControladorActividadCatalogo extends ChangeNotifier with WidgetsBindingObserver implements FuenteDeActividad {
  static final ControladorActividadCatalogo _instancia = ControladorActividadCatalogo._interno();
  factory ControladorActividadCatalogo() => _instancia;
  
  ControladorActividadCatalogo._interno() {
    WidgetsBinding.instance.addObserver(this);
  }

  static String? pantallaActivaId;
  static Widget Function(TrabajoContratable trabajo, bool esHistorial)? constructorPantallaDetalle;

  @override
  DominioApp get dominio => DominioApp.catalogo;

  @override
  String get tituloActivoCliente => 'Servicios contratados';
  @override
  IconData get iconoActivoCliente => Icons.shopping_bag_outlined;
  @override
  Color get colorTemaCliente => ColoresApp.primarioVerde;
  @override
  String get textoVacioCliente => 'No has comprado ningún servicio directo.';

  @override
  String get tituloActivoPro => 'Servicios vendidos';
  @override
  IconData get iconoActivoPro => Icons.receipt_long_rounded;
  @override
  Color get colorTemaPro => ColoresApp.terciarioMorado;
  @override
  String get textoVacioPro => 'Aún no te han contratado por el catálogo.';

  bool isLoading = true;
  bool _isFetchingActividad = false;
  bool _needsAnotherFetch = false;
  bool _trampaDisparada = false;

  Timer? _watchdogTimer; 
  Timer? _debounceTimer;
  Timer? _reconnectTimer; 
  
  RealtimeChannel? _trabajosChannel;
  RealtimeChannel? _pujasChannel;
  RealtimeChannel? _mensajesChannel;

  List<ModeloReservaCatalogo> comprasCatalogoActivasCliente = [];
  List<ModeloReservaCatalogo> historialFinalizadoCliente = [];
  List<ModeloReservaCatalogo> historialCanceladoCliente = [];

  List<ModeloReservaCatalogo> ventasCatalogoActivasPro = [];
  List<ModeloReservaCatalogo> historialFinalizadoPro = [];
  List<ModeloReservaCatalogo> historialCanceladoPro = [];

  int alertasTabCliente = 0;
  int alertasTabPro = 0;

  final Map<String, int> _bidsVistos = {};
  final Set<String> _accionesVistas = {};
  final Set<String> _escudoCalificadosLocales = {};

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    detenerMotorReactivo();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      recargarSilenciosoGlobal();
      iniciarMotorReactivo(); 
    } else if (state == AppLifecycleState.paused) {
      detenerMotorReactivo(); 
    }
  }

  void _reiniciarWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 120), () {
      recargarSilenciosoGlobal();
    });
  }

  void _manejarEventoRealtime(dynamic payload) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final tipoEvento = payload.eventType.toString().toLowerCase();
    final tabla = payload.table.toString();
    final record = tipoEvento == 'delete' ? payload.oldRecord : payload.newRecord;

    if (record == null) return;

    bool mePertenece = false;

    if (tabla == 'trabajos') {
      final oId = record['ownerId']?.toString() ?? record['cliente_id']?.toString() ?? '';
      final pAsig = record['profesional_asignado_id']?.toString() ?? '';
      final pSol = record['profesional_solicitado_id']?.toString() ?? '';
      
      if (oId == uid || pAsig == uid || pSol == uid) {
        mePertenece = true;
      }
    } else if (tabla == 'pujas') {
      if (record['profesional_id']?.toString() == uid) {
        mePertenece = true;
      }
    }

    if (!mePertenece) return;

    _reiniciarWatchdog();

    bool parcheAplicado = false;

    if (tipoEvento.contains('update') && payload.newRecord != null) {
      final newRec = payload.newRecord;
      
      parcheAplicado = _parchearEnLista(comprasCatalogoActivasCliente, newRec) || parcheAplicado;
      parcheAplicado = _parchearEnLista(ventasCatalogoActivasPro, newRec) || parcheAplicado;

      parcheAplicado = _parchearEnLista(historialFinalizadoCliente, newRec) || parcheAplicado;
      parcheAplicado = _parchearEnLista(historialCanceladoCliente, newRec) || parcheAplicado;
      parcheAplicado = _parchearEnLista(historialFinalizadoPro, newRec) || parcheAplicado;
      parcheAplicado = _parchearEnLista(historialCanceladoPro, newRec) || parcheAplicado;

      if (parcheAplicado) {
        final estadoNuevo = newRec['estado']?.toString();
        final estadoNegNuevo = newRec['estado_negociacion']?.toString();
        
        if (estadoNuevo == 'finalizado' || estadoNuevo == 'cancelado' || 
            estadoNegNuevo == 'cancelada_por_cliente' || estadoNegNuevo == 'cancelada_por_pro' || estadoNegNuevo == 'rechazada') {
            parcheAplicado = false; 
        } else {
            _ordenarTodasLasListas(); 
            _calcularBadgesTotales();
            notifyListeners();
            return; 
        }
      }
    }

    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      recargarSilenciosoGlobal();
    });
  }

  bool _parchearEnLista(List<ModeloReservaCatalogo> lista, Map<String, dynamic> record) {
    final recordId = record['id']?.toString();
    final trabajoId = record['trabajo_id']?.toString(); 
    
    int index = lista.indexWhere((t) => 
      (recordId != null && (t.id == recordId || t.pujaId == recordId)) ||
      (trabajoId != null && t.id == trabajoId)
    );

    if (index != -1) {
      final itemViejo = lista[index];
      final mapFusionado = {...itemViejo.toJson()};
      
      if (trabajoId != null && recordId != null && itemViejo.pujaId == recordId) {
          if (record.containsKey('estado')) mapFusionado['estado_negociacion'] = record['estado'];
          if (record.containsKey('monto')) mapFusionado['monto_ofrecido'] = record['monto'];
      } else {
          mapFusionado.addAll(record);
      }
      
      lista[index] = ModeloReservaCatalogo.fromJson(mapFusionado);
      return true;
    }
    return false;
  }

  bool _incrementarMensajeNoLeido(String trabajoId) {
    bool parcheado = false;
    final listas = [comprasCatalogoActivasCliente, ventasCatalogoActivasPro];
    
    for (var lista in listas) {
      int index = lista.indexWhere((t) => t.id == trabajoId);
      if (index != -1) {
         final map = {...lista[index].toJson()};
         map['mensajes_no_leidos'] = (map['mensajes_no_leidos'] as int? ?? 0) + 1;
         lista[index] = ModeloReservaCatalogo.fromJson(map);
         parcheado = true;
      }
    }
    return parcheado;
  }

  Future<void> detenerMotorReactivo() async {
    _watchdogTimer?.cancel();
    _debounceTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_trabajosChannel != null) {
      await _trabajosChannel!.unsubscribe();
      await Supabase.instance.client.removeChannel(_trabajosChannel!);
      _trabajosChannel = null;
    }
    if (_pujasChannel != null) {
      await _pujasChannel!.unsubscribe();
      await Supabase.instance.client.removeChannel(_pujasChannel!);
      _pujasChannel = null;
    }
    if (_mensajesChannel != null) {
      await _mensajesChannel!.unsubscribe();
      await Supabase.instance.client.removeChannel(_mensajesChannel!);
      _mensajesChannel = null;
    }
  }

  void _manejarEstadoSuscripcion(RealtimeSubscribeStatus status, [Object? error]) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      _reiniciarWatchdog();
    } else if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
      if (_reconnectTimer?.isActive ?? false) return;
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        recargarSilenciosoGlobal();
        iniciarMotorReactivo();
      });
    }
  }

  Future<void> iniciarMotorReactivo() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    
    await detenerMotorReactivo(); 

    _trabajosChannel = Supabase.instance.client.channel('public:trabajos_catalogo_$uid');
    _trabajosChannel!
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'trabajos', callback: _manejarEventoRealtime)
        .subscribe(_manejarEstadoSuscripcion); 

    _pujasChannel = Supabase.instance.client.channel('public:pujas_catalogo_$uid');
    _pujasChannel!
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'pujas', callback: _manejarEventoRealtime)
        .subscribe(_manejarEstadoSuscripcion); 

    _mensajesChannel = Supabase.instance.client.channel('public:mensajes_catalogo_$uid');
    _mensajesChannel!
        .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'mensajes', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'receptor_id', value: uid),
            callback: (payload) async {
              _reiniciarWatchdog();
              final record = payload.newRecord; 
              
              final trabajoId = record['trabajo_id'].toString();
              final emisorId = record['emisor_id'].toString();
              await ServicioActividadCatalogoSupabase.marcarNotificacionBurbujaComoNoLeida(trabajoId, emisorId, uid);
              
              if (_incrementarMensajeNoLeido(trabajoId)) {
                 _calcularBadgesTotales();
                 notifyListeners();
                 return;
              }
              
              if (_debounceTimer?.isActive ?? false) return;
              _debounceTimer = Timer(const Duration(milliseconds: 500), () => recargarSilenciosoGlobal());
            }
        ).subscribe(_manejarEstadoSuscripcion); 
  }

  void blindarTrampaPorCalificacionExitosa(String trabajoId) {
    final miId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _escudoCalificadosLocales.add('${trabajoId}_$miId');
    
    // Mover localmente para UI instántanea
    final i = comprasCatalogoActivasCliente.indexWhere((t) => t.id == trabajoId);
    if (i != -1) {
      final t = comprasCatalogoActivasCliente.removeAt(i);
      historialFinalizadoCliente.insert(0, t);
    }
    
    final j = ventasCatalogoActivasPro.indexWhere((t) => t.id == trabajoId);
    if (j != -1) {
      final t = ventasCatalogoActivasPro.removeAt(j);
      historialFinalizadoPro.insert(0, t);
    }
    
    _calcularBadgesTotales();
    notifyListeners();
    recargarSilenciosoGlobal();
  }

  @override
  void eliminarRegistro(TrabajoContratable trabajo, bool esDueno) {
    if (trabajo is ModeloReservaCatalogo) {
      _eliminarRegistroEspecifico(trabajo, esDueno);
    }
  }

  void _eliminarRegistroEspecifico(ModeloReservaCatalogo trabajo, bool esDueno) {
    _removerLocalmente(trabajo.id);
    notifyListeners();

    OfflineSyncManager.ejecutarBajoCapot(
      operacionRed: () async {
        if (esDueno) { 
          if (trabajo.tuvoContratoAlgunaVez) {
            await ServicioActividadCatalogoSupabase.archivarTrabajoCancelado(trabajo.id);
          } else {
            await ServicioActividadCatalogoSupabase.eliminarTrabajoFisicamente(trabajo.id);
          }
        } else {
          if (trabajo.profesionalSolicitadoId == Supabase.instance.client.auth.currentUser?.id && trabajo.pujaId == null) { 
            await ServicioActividadCatalogoSupabase.rechazarSolicitudDirecta(trabajo.id); 
          } else if (trabajo.pujaId != null) { 
            await ServicioActividadCatalogoSupabase.eliminarPujaVisualmenteParaPro(trabajo.pujaId!); 
          }
        }
      },
      revertirEstado: () => recargarDatosDesdeCero() 
    );
  }

  void _verificarYDispararTrampaGlobal() {
    if (_trampaDisparada) return;

    ModeloReservaCatalogo? atrapado;
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId == null) return;

    final todosActivos = [
      ...comprasCatalogoActivasCliente, ...ventasCatalogoActivasPro
    ];

    for (var t in todosActivos) {
      if (t.id.toString() == pantallaActivaId) continue;
      if (_escudoCalificadosLocales.contains('${t.id}_$miId')) continue;
      
      bool soyDueno = t.ownerId == miId;

      if (soyDueno) {
        if (t.estado == 'finalizado' && t.clienteCalifico == false) { 
          atrapado = t; break; 
        }
      } else {
        if ((t.estado == 'finalizado' || t.estadoNegociacion == 'finalizada') && t.proCalifico == false) { 
          atrapado = t; break; 
        }
      }
    }

    if (atrapado != null && navigatorKeyGlobal.currentState != null && constructorPantallaDetalle != null) {
      _trampaDisparada = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final route = MaterialPageRoute(
          builder: (_) => constructorPantallaDetalle!(atrapado!, false)
        );
        navigatorKeyGlobal.currentState!.push(route).then((_) { _trampaDisparada = false; });
      });
    }
  }

  Future<void> recargarDatosDesdeCero() async {
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId == null) return;
    iniciarMotorReactivo(); 
    if (comprasCatalogoActivasCliente.isEmpty && ventasCatalogoActivasPro.isEmpty) await _cargarDesdeCacheLocal(miId); 
    _fetchSilenciosoBajoCapot(miId);
  }

  @override
  void recargarSilenciosoGlobal() {
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId != null) _fetchSilenciosoBajoCapot(miId);
  }

  void _removerLocalmente(String id) {
    comprasCatalogoActivasCliente.removeWhere((t) => t.id == id);
    ventasCatalogoActivasPro.removeWhere((t) => t.id == id);
    historialFinalizadoCliente.removeWhere((t) => t.id == id); historialCanceladoCliente.removeWhere((t) => t.id == id);
    historialFinalizadoPro.removeWhere((t) => t.id == id); historialCanceladoPro.removeWhere((t) => t.id == id);
    _calcularBadgesTotales();
  }

  DateTime _obtenerFechaActividadMasReciente(ModeloReservaCatalogo trabajo) {
    DateTime fechaMaxima = DateTime.tryParse(trabajo.fechaCreacion) ?? DateTime(2000);
    for (var puja in trabajo.pujas) {
      DateTime fechaPuja = DateTime.tryParse(puja.fechaCreacion) ?? DateTime(2000);
      if (fechaPuja.isAfter(fechaMaxima)) {
        fechaMaxima = fechaPuja;
      }
    }
    return fechaMaxima;
  }

  void _ordenarCronologicamente(List<ModeloReservaCatalogo> lista) {
    lista.sort((a, b) {
      DateTime fechaA = _obtenerFechaActividadMasReciente(a);
      DateTime fechaB = _obtenerFechaActividadMasReciente(b);
      return fechaB.compareTo(fechaA);
    });
  }

  void _ordenarTodasLasListas() {
    _ordenarCronologicamente(comprasCatalogoActivasCliente);
    _ordenarCronologicamente(historialFinalizadoCliente);
    _ordenarCronologicamente(historialCanceladoCliente);

    _ordenarCronologicamente(ventasCatalogoActivasPro);
    _ordenarCronologicamente(historialFinalizadoPro);
    _ordenarCronologicamente(historialCanceladoPro);
  }

  Future<void> _cargarDesdeCacheLocal(String miId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('actividad_catalogo_cache_$miId');
      if (cacheStr != null && cacheStr.isNotEmpty) {
        final data = jsonDecode(cacheStr);
        List<ModeloReservaCatalogo> parseLista(String key) => (data[key] as List? ?? []).map((e) => ModeloReservaCatalogo.fromJson(e)).toList();

        comprasCatalogoActivasCliente = parseLista('comprasCatalogoActivasCliente');
        historialFinalizadoCliente = parseLista('historialFinalizadoCliente'); historialCanceladoCliente = parseLista('historialCanceladoCliente');
        ventasCatalogoActivasPro = parseLista('ventasCatalogoActivasPro');
        historialFinalizadoPro = parseLista('historialFinalizadoPro'); historialCanceladoPro = parseLista('historialCanceladoPro');

        _ordenarTodasLasListas(); 

        _calcularBadgesTotales(); isLoading = false; notifyListeners();
        _verificarYDispararTrampaGlobal();
      }
    } catch (_) {}
  }

  Future<void> _fetchSilenciosoBajoCapot(String miId) async {
    if (_isFetchingActividad) { _needsAnotherFetch = true; return; }
    _isFetchingActividad = true;

    try {
      final unreadCounts = await ServicioActividadCatalogoSupabase.obtenerMensajesNoLeidos(miId);
      
      final futures = await Future.wait([
        ServicioActividadCatalogoSupabase.obtenerPublicacionesClienteCatalogo(miId, unreadCounts),
        ServicioActividadCatalogoSupabase.obtenerVentasCatalogoProfesional(miId, unreadCounts), 
      ]);

      final misPublicaciones = futures[0];
      final ventasParsed = futures[1];

      // --- FILTROS CLIENTE ---
      final catalogoCliente = misPublicaciones;

      historialFinalizadoCliente = catalogoCliente.where((i) => ((i.estado == 'finalizado' || i.estado == 'finalizada') && i.clienteCalifico == true) || _escudoCalificadosLocales.contains('${i.id}_$miId')).toList();
      
      historialCanceladoCliente = catalogoCliente.where((i) => 
          i.estado == 'cancelado' && 
          i.tuvoContratoAlgunaVez && 
          i.estadoNegociacion != 'cancelada_por_pro' 
      ).toList();

      comprasCatalogoActivasCliente = catalogoCliente.where((i) =>
        !_escudoCalificadosLocales.contains('${i.id}_$miId') && (
        (i.estado != 'finalizado' && i.estado != 'finalizada' && i.estado != 'cancelado' && i.estado != 'checkout_bloqueado_temporal'
            && i.estado != 'pendiente_pago' && i.estado != 'expirada') ||
        (i.estado == 'cancelado' && !i.tuvoContratoAlgunaVez) ||
        ((i.estado == 'finalizado' || i.estado == 'finalizada') && i.clienteCalifico == false) ||
        (i.estado == 'cancelado' && i.estadoNegociacion == 'cancelada_por_pro')
        )
      ).toList();
      
      // --- FILTROS PROFESIONAL ---
      ventasCatalogoActivasPro = ventasParsed.where((i) => 
        !_escudoCalificadosLocales.contains('${i.id}_$miId') &&
        i.estadoNegociacion != 'cancelada_vista_pro' && 
        i.estadoNegociacion != 'cancelada_por_pro' &&
        i.estadoNegociacion != 'cancelada_vista_cliente' && 
        (i.estado != 'cancelado' || (i.estado == 'cancelado' && i.proCalifico == false)) && 
        !((i.estado == 'finalizado' || i.estado == 'finalizada') && i.proCalifico == true)
      ).toList();

      historialFinalizadoPro = ventasParsed.where((i) => ((i.estado == 'finalizado' || i.estado == 'finalizada') && i.proCalifico == true) || _escudoCalificadosLocales.contains('${i.id}_$miId')).toList();
      
      historialCanceladoPro = ventasParsed.where((i) => 
        i.estadoNegociacion == 'cancelada_vista_pro' || 
        i.estadoNegociacion == 'cancelada_por_pro' || 
        i.estadoNegociacion == 'cancelada_vista_cliente' || 
        (i.estado == 'cancelado' && (i.estadoNegociacion == 'cancelada_vista_pro' || i.estadoNegociacion == 'cancelada_por_pro' || i.estadoNegociacion == 'cancelada_vista_cliente'))
      ).toList();

      _ordenarTodasLasListas(); 

      _calcularBadgesTotales(); 
      _guardarCacheLocal(miId);
      _reiniciarWatchdog(); 
      _verificarYDispararTrampaGlobal();
      
    } catch (e) {
      debugPrint('[SQL] Error fetch silencioso en Historial Catálogo: $e');
    } finally {
      if (isLoading) {
        isLoading = false;
      }
      notifyListeners();

      _isFetchingActividad = false;
      if (_needsAnotherFetch) { _needsAnotherFetch = false; _fetchSilenciosoBajoCapot(miId); }
    }
  }

  Future<void> _guardarCacheLocal(String miId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'comprasCatalogoActivasCliente': comprasCatalogoActivasCliente.map((e) => e.toJson()).toList(),
        'historialFinalizadoCliente': historialFinalizadoCliente.map((e) => e.toJson()).toList(), 'historialCanceladoCliente': historialCanceladoCliente.map((e) => e.toJson()).toList(),
        'ventasCatalogoActivasPro': ventasCatalogoActivasPro.map((e) => e.toJson()).toList(),
        'historialFinalizadoPro': historialFinalizadoPro.map((e) => e.toJson()).toList(), 'historialCanceladoPro': historialCanceladoPro.map((e) => e.toJson()).toList(),
      };
      await prefs.setString('actividad_catalogo_cache_$miId', jsonEncode(data));
    } catch (_) {}
  }

  void _calcularBadgesTotales() {
    int cliente = 0;
    for (var i in comprasCatalogoActivasCliente) { cliente += calcularAlertasItem(i, true); }
    alertasTabCliente = cliente;

    int pro = 0;
    for (var i in ventasCatalogoActivasPro) { pro += calcularAlertasItem(i, false); }
    alertasTabPro = pro;
  }

  @override
  int calcularAlertasItem(TrabajoContratable trabajo, bool esDueno) {
    if (trabajo is ModeloReservaCatalogo) {
      return _calcularAlertasItemEspecifico(trabajo, esDueno);
    }
    return 0;
  }

  int _calcularAlertasItemEspecifico(ModeloReservaCatalogo item, bool esDueno) {
    if (item.dominio != DominioApp.catalogo) return 0;

    int count = item.mensajesNoLeidos;
    if (esDueno && item.estado == 'abierto') {
      int unseenBids = item.cantidadPujasTotales - (_bidsVistos[item.id] ?? 0);
      if (unseenBids > 0) count += unseenBids;
    }
    if (!esDueno && item.estadoNegociacion == 'seleccionado' && !_accionesVistas.contains(item.id)) count += 1;
    return count;
  }

  @override
  void marcarItemComoVisto(TrabajoContratable trabajo, bool esDueno) {
    if (trabajo is ModeloReservaCatalogo) {
      _marcarItemComoVistoEspecifico(trabajo, esDueno);
    }
  }

  void _marcarItemComoVistoEspecifico(ModeloReservaCatalogo item, bool esDueno) async {
    _bidsVistos[item.id] = item.cantidadPujasTotales; _accionesVistas.add(item.id); _calcularBadgesTotales(); notifyListeners();
    final miId = Supabase.instance.client.auth.currentUser?.id;
    final contraparte = esDueno ? (item.profesionalAsignadoId ?? '') : item.ownerId;
    if (miId != null && contraparte.isNotEmpty) {
      try { await Supabase.instance.client.from('mensajes').update({'leido': true}).eq('trabajo_id', item.id).eq('emisor_id', contraparte).eq('receptor_id', miId).eq('leido', false); } catch (_) {}
    }
  }

  @override
  Widget construirPantallaDetalle(TrabajoContratable trabajo, bool esHistorial) {
    if (trabajo is ModeloReservaCatalogo) {
      return constructorPantallaDetalle?.call(trabajo, esHistorial) ?? const SizedBox();
    }
    return const SizedBox();
  }

  @override
  List<TrabajoContratable> obtenerActivosCliente() => comprasCatalogoActivasCliente;

  @override
  List<TrabajoContratable> obtenerFinalizadosCliente() => historialFinalizadoCliente;

  @override
  List<TrabajoContratable> obtenerCanceladosCliente() => historialCanceladoCliente;

  @override
  List<TrabajoContratable> obtenerActivosPro() => ventasCatalogoActivasPro;

  @override
  List<TrabajoContratable> obtenerFinalizadosPro() => historialFinalizadoPro;

  @override
  List<TrabajoContratable> obtenerCanceladosPro() => historialCanceladoPro;
}
