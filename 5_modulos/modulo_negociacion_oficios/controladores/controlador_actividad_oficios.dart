// lib/5_modulos/modulo_negociacion_oficios/controladores/controlador_actividad_oficios.dart

import 'dart:convert';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../3_modelos/modelo_oficio_trabajo.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';
import '../../../1_nucleo/gestor_sincronizacion_offline.dart';
import '../servicios/servicio_actividad_oficios_supabase.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../4_componentes_globales/contratos/fuente_de_actividad.dart';
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';


class ControladorActividadOficios extends ChangeNotifier with WidgetsBindingObserver implements FuenteDeActividad {
  static final ControladorActividadOficios _instancia = ControladorActividadOficios._interno();
  factory ControladorActividadOficios() => _instancia;
  
  ControladorActividadOficios._interno() {
    WidgetsBinding.instance.addObserver(this);
  }

  static String? pantallaActivaId;
  static Widget Function(TrabajoContratable trabajo, bool esHistorial)? constructorPantallaDetalle;

  @override
  DominioApp get dominio => DominioApp.oficios;

  @override
  String get tituloActivoCliente => 'Oficios publicados';
  @override
  IconData get iconoActivoCliente => Icons.work_outline_rounded;
  @override
  Color get colorTemaCliente => ColoresApp.primarioVerde;
  @override
  String get textoVacioCliente => 'No tienes ofertas de oficios publicadas.';

  @override
  String get tituloActivoPro => 'Postulaciones a oficios';
  @override
  IconData get iconoActivoPro => Icons.work_outline_rounded;
  @override
  Color get colorTemaPro => ColoresApp.terciarioMorado;
  @override
  String get textoVacioPro => 'No tienes postulaciones activas a oficios.';

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

  List<ModeloOficioTrabajo> oficiosActivosCliente = [];
  List<ModeloOficioTrabajo> propuestasDirectasActivasCliente = [];
  List<ModeloOficioTrabajo> historialFinalizadoCliente = [];
  List<ModeloOficioTrabajo> historialCanceladoCliente = [];

  List<ModeloOficioTrabajo> solicitudesDirectasActivasPro = [];
  List<ModeloOficioTrabajo> postulacionesOficiosActivasPro = [];
  List<ModeloOficioTrabajo> historialFinalizadoPro = [];
  List<ModeloOficioTrabajo> historialCanceladoPro = [];

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
      } else {
        final tId = record['id']?.toString();
        if (tId != null) {
          final existeEnMisListasPro = [...postulacionesOficiosActivasPro, ...solicitudesDirectasActivasPro].any((t) => t.id == tId);
          if (existeEnMisListasPro) mePertenece = true;
        }
      }
    } else if (tabla == 'pujas') {
      if (record['profesional_id']?.toString() == uid) {
        mePertenece = true;
      } else {
        final tId = record['trabajo_id']?.toString();
        if (tId != null) {
          final existeEnMisListasCliente = [...oficiosActivosCliente, ...propuestasDirectasActivasCliente].any((t) => t.id == tId);
          if (existeEnMisListasCliente) mePertenece = true;
        }
      }
    }

    if (!mePertenece) return;

    _reiniciarWatchdog();

    bool parcheAplicado = false;

    if (tipoEvento.contains('update') && payload.newRecord != null) {
      final newRec = payload.newRecord;
      
      parcheAplicado = _parchearEnLista(oficiosActivosCliente, newRec) || parcheAplicado;
      parcheAplicado = _parchearEnLista(propuestasDirectasActivasCliente, newRec) || parcheAplicado;
      parcheAplicado = _parchearEnLista(solicitudesDirectasActivasPro, newRec) || parcheAplicado;
      parcheAplicado = _parchearEnLista(postulacionesOficiosActivasPro, newRec) || parcheAplicado;

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

  bool _parchearEnLista(List<ModeloOficioTrabajo> lista, Map<String, dynamic> record) {
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
      
      lista[index] = ModeloOficioTrabajo.fromJson(mapFusionado);
      return true;
    }
    return false;
  }

  bool _incrementarMensajeNoLeido(String trabajoId) {
    bool parcheado = false;
    final listas = [oficiosActivosCliente, propuestasDirectasActivasCliente, solicitudesDirectasActivasPro, postulacionesOficiosActivasPro];
    
    for (var lista in listas) {
      int index = lista.indexWhere((t) => t.id == trabajoId);
      if (index != -1) {
         final map = {...lista[index].toJson()};
         map['mensajes_no_leidos'] = (map['mensajes_no_leidos'] as int? ?? 0) + 1;
         lista[index] = ModeloOficioTrabajo.fromJson(map);
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

    _trabajosChannel = Supabase.instance.client.channel('public:trabajos_oficios_$uid');
    _trabajosChannel!
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'trabajos', callback: _manejarEventoRealtime)
        .subscribe(_manejarEstadoSuscripcion); 

    _pujasChannel = Supabase.instance.client.channel('public:pujas_oficios_$uid');
    _pujasChannel!
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'pujas', callback: _manejarEventoRealtime)
        .subscribe(_manejarEstadoSuscripcion); 

    _mensajesChannel = Supabase.instance.client.channel('public:mensajes_oficios_$uid');
    _mensajesChannel!
        .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'mensajes', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'receptor_id', value: uid),
            callback: (payload) async {
               _reiniciarWatchdog();
               final record = payload.newRecord; 
               
               final trabajoId = record['trabajo_id'].toString();
               final emisorId = record['emisor_id'].toString();
               await ServicioActividadOficiosSupabase.marcarNotificacionBurbujaComoNoLeida(trabajoId, emisorId, uid);
               
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
    recargarSilenciosoGlobal();
  }

  @override
  void eliminarRegistro(TrabajoContratable trabajo, bool esDueno) {
    if (trabajo is ModeloOficioTrabajo) {
      _eliminarRegistroEspecifico(trabajo, esDueno);
    }
  }

  void _eliminarRegistroEspecifico(ModeloOficioTrabajo trabajo, bool esDueno) {
    _removerLocalmente(trabajo.id);
    notifyListeners();

    OfflineSyncManager.ejecutarBajoCapot(
      operacionRed: () async {
        if (esDueno) { 
          if (trabajo.tuvoContratoAlgunaVez) {
            await ServicioActividadOficiosSupabase.archivarTrabajoCancelado(trabajo.id);
          } else {
            await ServicioActividadOficiosSupabase.eliminarTrabajoFisicamente(trabajo.id);
          }
        } else {
          if (trabajo.profesionalSolicitadoId == Supabase.instance.client.auth.currentUser?.id && trabajo.pujaId == null) { 
            await ServicioActividadOficiosSupabase.rechazarSolicitudDirecta(trabajo.id); 
          } else if (trabajo.pujaId != null) { 
            await ServicioActividadOficiosSupabase.eliminarPujaVisualmenteParaPro(trabajo.pujaId!); 
          }
        }
      },
      revertirEstado: () => recargarDatosDesdeCero() 
    );
  }

  void _verificarYDispararTrampaGlobal() {
    if (_trampaDisparada) return;

    ModeloOficioTrabajo? atrapado;
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId == null) return;

    final todosActivos = [
      ...oficiosActivosCliente, ...propuestasDirectasActivasCliente,
      ...solicitudesDirectasActivasPro, ...postulacionesOficiosActivasPro
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
    if (oficiosActivosCliente.isEmpty && postulacionesOficiosActivasPro.isEmpty) await _cargarDesdeCacheLocal(miId); 
    _fetchSilenciosoBajoCapot(miId);
  }

  @override
  void recargarSilenciosoGlobal() {
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId != null) _fetchSilenciosoBajoCapot(miId);
  }

  void _removerLocalmente(String id) {
    oficiosActivosCliente.removeWhere((t) => t.id == id);
    propuestasDirectasActivasCliente.removeWhere((t) => t.id == id);
    solicitudesDirectasActivasPro.removeWhere((t) => t.id == id);
    postulacionesOficiosActivasPro.removeWhere((t) => t.id == id);
    historialFinalizadoCliente.removeWhere((t) => t.id == id); historialCanceladoCliente.removeWhere((t) => t.id == id);
    historialFinalizadoPro.removeWhere((t) => t.id == id); historialCanceladoPro.removeWhere((t) => t.id == id);
    _calcularBadgesTotales();
  }

  DateTime _obtenerFechaActividadMasReciente(ModeloOficioTrabajo trabajo) {
    DateTime fechaMaxima = DateTime.tryParse(trabajo.fechaCreacion) ?? DateTime(2000);
    for (var puja in trabajo.pujas) {
      DateTime fechaPuja = DateTime.tryParse(puja.fechaCreacion) ?? DateTime(2000);
      if (fechaPuja.isAfter(fechaMaxima)) {
        fechaMaxima = fechaPuja;
      }
    }
    return fechaMaxima;
  }

  void _ordenarCronologicamente(List<ModeloOficioTrabajo> lista) {
    lista.sort((a, b) {
      DateTime fechaA = _obtenerFechaActividadMasReciente(a);
      DateTime fechaB = _obtenerFechaActividadMasReciente(b);
      return fechaB.compareTo(fechaA);
    });
  }

  void _ordenarTodasLasListas() {
    _ordenarCronologicamente(oficiosActivosCliente);
    _ordenarCronologicamente(propuestasDirectasActivasCliente);
    _ordenarCronologicamente(historialFinalizadoCliente);
    _ordenarCronologicamente(historialCanceladoCliente);

    _ordenarCronologicamente(solicitudesDirectasActivasPro);
    _ordenarCronologicamente(postulacionesOficiosActivasPro);
    _ordenarCronologicamente(historialFinalizadoPro);
    _ordenarCronologicamente(historialCanceladoPro);
  }

  Future<void> _cargarDesdeCacheLocal(String miId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('actividad_oficios_cache_$miId');
      if (cacheStr != null && cacheStr.isNotEmpty) {
        final data = jsonDecode(cacheStr);
        List<ModeloOficioTrabajo> parseLista(String key) => (data[key] as List? ?? []).map((e) => ModeloOficioTrabajo.fromJson(e)).toList();

        oficiosActivosCliente = parseLista('oficiosActivosCliente');
        propuestasDirectasActivasCliente = parseLista('propuestasDirectasActivasCliente');
        historialFinalizadoCliente = parseLista('historialFinalizadoCliente'); historialCanceladoCliente = parseLista('historialCanceladoCliente');
        solicitudesDirectasActivasPro = parseLista('solicitudesDirectasActivasPro');
        postulacionesOficiosActivasPro = parseLista('postulacionesOficiosActivasPro');
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
      final unreadCounts = await ServicioActividadOficiosSupabase.obtenerMensajesNoLeidos(miId);
      
      final futures = await Future.wait([
        ServicioActividadOficiosSupabase.obtenerPublicacionesClienteOficios(miId, unreadCounts),
        ServicioActividadOficiosSupabase.obtenerPostulacionesProfesionalOficios(miId, unreadCounts),
        ServicioActividadOficiosSupabase.obtenerSolicitudesDirectasProfesionalOficios(miId, unreadCounts), 
      ]);

      final misPublicaciones = futures[0];
      final misPostulaciones = futures[1];
      final solicitudesDirectas = futures[2];

      // --- FILTROS CLIENTE ---
      final oficiosCliente = misPublicaciones;

      historialFinalizadoCliente = oficiosCliente.where((i) {
        final bool tienePujaFinalizada = i.pujas.any((p) => p.estadoPuja == 'finalizada');
        final bool esFinalizado = i.estado == 'finalizado' || i.estado == 'finalizada' || tienePujaFinalizada;
        return (esFinalizado && i.clienteCalifico == true) || _escudoCalificadosLocales.contains('${i.id}_$miId');
      }).toList();
      
      historialCanceladoCliente = oficiosCliente.where((i) => 
          i.estado == 'cancelado' && 
          i.tuvoContratoAlgunaVez && 
          i.estadoNegociacion != 'cancelada_por_pro' 
      ).toList();

      final activasYCanceladasSinContratoCliente = oficiosCliente.where((i) {
        if (_escudoCalificadosLocales.contains('${i.id}_$miId')) return false;
        final bool tienePujaFinalizada = i.pujas.any((p) => p.estadoPuja == 'finalizada');
        final bool esFinalizado = i.estado == 'finalizado' || i.estado == 'finalizada' || tienePujaFinalizada;

        return (!esFinalizado && i.estado != 'cancelado' && i.estado != 'checkout_bloqueado_temporal'
            && i.estado != 'pendiente_pago' && i.estado != 'expirada') ||
        (i.estado == 'cancelado' && !i.tuvoContratoAlgunaVez) ||
        (esFinalizado && i.clienteCalifico == false) ||
        (i.estado == 'cancelado' && i.estadoNegociacion == 'cancelada_por_pro');
      }).toList();

      oficiosActivosCliente = activasYCanceladasSinContratoCliente.where((i) => i.profesionalSolicitadoId == null).toList();
      propuestasDirectasActivasCliente = activasYCanceladasSinContratoCliente.where((i) => i.profesionalSolicitadoId != null).toList();
      
      // --- FILTROS PROFESIONAL ---
      final Map<String, ModeloOficioTrabajo> mapaDeduplicado = {};
      for (var t in solicitudesDirectas) { mapaDeduplicado[t.id] = t; }
      for (var t in misPostulaciones) { mapaDeduplicado[t.id] = t; }
      
      final todasLasVistasPro = mapaDeduplicado.values.toList();
      
      String _getMiEstadoPuja(ModeloOficioTrabajo t) { return t.estadoNegociacion ?? ''; }

      historialFinalizadoPro = todasLasVistasPro.where((i) {
        final miEstado = _getMiEstadoPuja(i);
        return ((i.estado == 'finalizado' || miEstado == 'finalizada') && i.proCalifico == true) || _escudoCalificadosLocales.contains('${i.id}_$miId');
      }).toList();
      
      historialCanceladoPro = todasLasVistasPro.where((i) {
        final miEstado = _getMiEstadoPuja(i);
        return miEstado == 'cancelada_vista_pro' || miEstado == 'cancelada_por_pro';
      }).toList();

      final activasYRechazadasPro = todasLasVistasPro.where((i) {
        if (_escudoCalificadosLocales.contains('${i.id}_$miId')) return false;
        final miEstado = _getMiEstadoPuja(i);
        if (miEstado == 'cancelada_vista_pro' || miEstado == 'cancelada_por_pro') return false;

        return (
          (i.estado != 'finalizado' && i.estado != 'cancelado' && miEstado != 'rechazada' && miEstado != 'rechazada_por_pro' && miEstado != 'cancelada' && miEstado != 'finalizada') ||
          ((i.estado == 'cancelado' || miEstado == 'rechazada' || miEstado == 'cancelada') && miEstado != 'cancelada_por_cliente' && i.profesionalAsignadoId != miId) ||
          ((i.estado == 'finalizado' || miEstado == 'finalizada') && i.proCalifico == false) ||
          (i.estado == 'cancelado' && miEstado == 'cancelada_por_cliente') 
        );
      }).toList();

      solicitudesDirectasActivasPro = activasYRechazadasPro.where((i) => i.profesionalSolicitadoId != null).toList();
      postulacionesOficiosActivasPro = activasYRechazadasPro.where((i) => i.profesionalSolicitadoId == null).toList();

      _ordenarTodasLasListas(); 

      _calcularBadgesTotales(); 
      _guardarCacheLocal(miId);
      _reiniciarWatchdog(); 
      _verificarYDispararTrampaGlobal();
      
    } catch (e) {
      debugPrint('[SQL] Error fetch silencioso en Historial Oficios: $e');
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
        'oficiosActivosCliente': oficiosActivosCliente.map((e) => e.toJson()).toList(),
        'propuestasDirectasActivasCliente': propuestasDirectasActivasCliente.map((e) => e.toJson()).toList(),
        'historialFinalizadoCliente': historialFinalizadoCliente.map((e) => e.toJson()).toList(), 'historialCanceladoCliente': historialCanceladoCliente.map((e) => e.toJson()).toList(),
        'solicitudesDirectasActivasPro': solicitudesDirectasActivasPro.map((e) => e.toJson()).toList(),
        'postulacionesOficiosActivasPro': postulacionesOficiosActivasPro.map((e) => e.toJson()).toList(),
        'historialFinalizadoPro': historialFinalizadoPro.map((e) => e.toJson()).toList(), 'historialCanceladoPro': historialCanceladoPro.map((e) => e.toJson()).toList(),
      };
      await prefs.setString('actividad_oficios_cache_$miId', jsonEncode(data));
    } catch (_) {}
  }

  void _calcularBadgesTotales() {
    int cliente = 0;
    for (var i in oficiosActivosCliente) { cliente += calcularAlertasItem(i, true); }
    for (var i in propuestasDirectasActivasCliente) { cliente += calcularAlertasItem(i, true); }
    alertasTabCliente = cliente;

    int pro = 0;
    for (var i in solicitudesDirectasActivasPro) { pro += calcularAlertasItem(i, false); }
    for (var i in postulacionesOficiosActivasPro) { pro += calcularAlertasItem(i, false); }
    alertasTabPro = pro;
  }

  @override
  int calcularAlertasItem(TrabajoContratable trabajo, bool esDueno) {
    if (trabajo is ModeloOficioTrabajo) {
      return _calcularAlertasItemEspecifico(trabajo, esDueno);
    }
    return 0;
  }

  int _calcularAlertasItemEspecifico(ModeloOficioTrabajo item, bool esDueno) {
    int count = item.mensajesNoLeidos;
    if (esDueno && item.estado == 'abierto') {
      int unseenBids = item.cantidadPujasTotales - (_bidsVistos[item.id] ?? 0);
      if (unseenBids > 0) count += unseenBids;
    }
    if (!esDueno && item.estadoNegociacion == 'seleccionado' && !_accionesVistas.contains(item.id)) count += 1;
    if (!esDueno && item.dificultad != 'jornada' && item.dificultad != 'catalogo' && item.dificultad != 'catalogo_publicacion' && item.estadoNegociacion != null && item.aceptoPrecioBase == false && item.estado == 'abierto' && !_accionesVistas.contains(item.id)) count += 1;
    return count;
  }

  @override
  void marcarItemComoVisto(TrabajoContratable trabajo, bool esDueno) {
    if (trabajo is ModeloOficioTrabajo) {
      _marcarItemComoVistoEspecifico(trabajo, esDueno);
    }
  }

  void _marcarItemComoVistoEspecifico(ModeloOficioTrabajo item, bool esDueno) async {
    _bidsVistos[item.id] = item.cantidadPujasTotales; _accionesVistas.add(item.id); _calcularBadgesTotales(); notifyListeners();
    final miId = Supabase.instance.client.auth.currentUser?.id;
    final contraparte = esDueno ? (item.profesionalAsignadoId ?? '') : item.ownerId;
    if (miId != null && contraparte.isNotEmpty) {
      try { await Supabase.instance.client.from('mensajes').update({'leido': true}).eq('trabajo_id', item.id).eq('emisor_id', contraparte).eq('receptor_id', miId).eq('leido', false); } catch (_) {}
    }
  }

  @override
  Widget construirPantallaDetalle(TrabajoContratable trabajo, bool esHistorial) {
    if (trabajo is ModeloOficioTrabajo) {
      return constructorPantallaDetalle?.call(trabajo, esHistorial) ?? const SizedBox();
    }
    return const SizedBox();
  }

  @override
  List<TrabajoContratable> obtenerActivosCliente() {
    return [...oficiosActivosCliente, ...propuestasDirectasActivasCliente];
  }

  @override
  List<TrabajoContratable> obtenerFinalizadosCliente() => historialFinalizadoCliente;

  @override
  List<TrabajoContratable> obtenerCanceladosCliente() => historialCanceladoCliente;

  @override
  List<TrabajoContratable> obtenerActivosPro() {
    return [...solicitudesDirectasActivasPro, ...postulacionesOficiosActivasPro];
  }

  @override
  List<TrabajoContratable> obtenerFinalizadosPro() => historialFinalizadoPro;

  @override
  List<TrabajoContratable> obtenerCanceladosPro() => historialCanceladoPro;
}
