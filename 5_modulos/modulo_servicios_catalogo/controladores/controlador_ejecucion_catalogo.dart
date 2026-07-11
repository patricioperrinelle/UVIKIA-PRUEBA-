// lib/5_modulos/modulo_servicios_catalogo/controladores/controlador_ejecucion_catalogo.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/servicios/servicio_gps_localizacion.dart';
import '../../../1_nucleo/utilidades/mixin_gestor_tickets.dart'; 
import '../../../1_nucleo/utilidades/calculador_penalizaciones.dart';
import '../../../3_modelos/modelo_reserva_catalogo.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../../../3_modelos/modelo_resena_payload.dart'; 
import '../../../3_modelos/modelo_puja.dart'; 
import '../../../3_modelos/modelo_perfil.dart'; 
import '../servicios/servicio_ejecucion_catalogo_supabase.dart';
import '../controladores/controlador_actividad_catalogo.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

class ControladorEjecucionCatalogo extends ChangeNotifier with MixinGestorTickets, WidgetsBindingObserver {
  final Map<String, dynamic> jobDataInicial;
  
  late String idReserva;
  late String clienteId;
  late String profesionalId;

  Map<String, dynamic> datosCrudosContraparte = {};

  ModeloReservaCatalogo? reservaActiva;
  ModeloServicioCatalogo? servicioAsociado;
  bool isCargando = false; 
  bool isProcesandoAccion = false;
  
  bool clienteCalificoLocal = false;
  bool proCalificoLocal = false;

  void Function(String tipoEvento,[dynamic payload])? onRequerirAccionUI;

  Timer? _vigilanteTiempo;
  Timer? _watchdogTimer; 
  Timer? _debounceTimer; 
  Timer? _reconnectTimer; 
  
  StreamSubscription? _suscripcionGlobal;
  RealtimeChannel? _suscripcionLiveSupabase;

  bool enCaminoAutomatico = false; 

  @override
  double get precioBaseAcordadoLimpio {
    return double.tryParse(reservaActiva?.precio.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0.0;
  }

  @override
  Future<void> guardarAdicionalesBd(List<Map<String, dynamic>> adicionales) async {
    GestorSesionGlobal.requerirAuth(() async {
      await ServicioEjecucionCatalogoSupabase.actualizarAdicionales(idReserva, adicionales);
    });
  }

  bool get soyElProfesional {
    final miId = GestorSesionGlobal().miIdUsuario;
    return profesionalId == miId;
  }

  bool get esEnLocal => reservaActiva?.descripcion.contains('Modalidad: en_local') ?? false;
  bool get soyElQueViaja => esEnLocal ? !soyElProfesional : soyElProfesional;
  bool get yaLlego => reservaActiva?.estado == 'esperando_pin_llegada' || enCurso || esperandoPinSalida || completada;
  bool get enCurso => reservaActiva?.estado == 'en_curso' || esperandoPinSalida || completada;
  bool get esperandoPinSalida => reservaActiva?.estado == 'esperando_pin_salida';
  bool get completada => reservaActiva?.estado == 'finalizado' || reservaActiva?.estado == 'finalizada';

  String get codigoCheckin => jobDataInicial['codigo_checkin']?.toString() ?? '------';
  String get codigoCheckout => jobDataInicial['codigo_checkout']?.toString() ?? '------';
  String get metodoPago => reservaActiva?.metodoPago ?? 'efectivo';

  String get contraparteNombreLimpio {
    if (reservaActiva == null) return 'Usuario';
    String nombre = reservaActiva!.contraparteNombre.replaceAll('Cliente: ', '').replaceAll('Profesional: ', '');
    if (nombre.isEmpty || nombre == 'null') {
      nombre = jobDataInicial['contraparteNombre']?.toString().replaceAll('Cliente: ', '').replaceAll('Profesional: ', '') ?? 'Usuario';
    }
    return nombre;
  }

  ModeloPuja get generarPujaFantasmaCalificacion {
    if (reservaActiva == null) throw Exception('No hay reserva activa');
    return ModeloPuja.fromJson({
      'id': 'puja_falsa_catalogo',
      'profesional_id': soyElProfesional ? clienteId : profesionalId,
      'estado': 'finalizado',
      'monto': reservaActiva!.precio,
      'perfiles': {
        'apodo': contraparteNombreLimpio,
        'foto_url': reservaActiva!.contraparteAvatar,
        'rating': reservaActiva!.ratingContraparte,
        'cantidad_resenas': reservaActiva!.reviewsContraparte,
      }
    });
  }

  double _parseD(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _parseI(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  ModeloPuja get generarPujaContraparteMock {
    String avatar = reservaActiva?.contraparteAvatar ?? '';
    if (avatar.isEmpty) avatar = jobDataInicial['contraparteAvatar'] ?? '';
    
    double rating = _parseD(reservaActiva?.ratingContraparte);
    if (rating == 0.0) rating = _parseD(jobDataInicial['ratingContraparte']);

    int reviews = _parseI(reservaActiva?.reviewsContraparte);
    if (reviews == 0) reviews = _parseI(jobDataInicial['reviewsContraparte']);

    return ModeloPuja.fromJson({
      'id': 'mock_${profesionalId}',
      'profesionalId': profesionalId,
      'apodoProfesional': contraparteNombreLimpio,
      'avatarUrl': avatar,
      'rating': rating,
      'reviews': reviews,
      'estadoPuja': reservaActiva?.estado ?? 'aceptada',
      'montoOfrecido': reservaActiva?.precio ?? '0',
      'mensaje': 'Asignación Directa',
      
      'puntualidad': _parseD(datosCrudosContraparte['puntualidad']),
      'asistencia': _parseD(datosCrudosContraparte['asistencia']),
      'jornadas_completadas': _parseI(datosCrudosContraparte['jornadas_completadas']),
      'cancelaciones_pro': _parseD(datosCrudosContraparte['cancelaciones_pro']),
      'score_confiabilidad_pro': _parseD(datosCrudosContraparte['score_confiabilidad_pro']),
    });
  }

  ModeloPerfil get generarPerfilContraparteMock {
    String avatar = reservaActiva?.contraparteAvatar ?? '';
    if (avatar.isEmpty) avatar = jobDataInicial['contraparteAvatar'] ?? '';
    
    double rating = _parseD(reservaActiva?.ratingContraparte);
    if (rating == 0.0) rating = _parseD(jobDataInicial['ratingContraparte']);

    int reviews = _parseI(reservaActiva?.reviewsContraparte);
    if (reviews == 0) reviews = _parseI(jobDataInicial['reviewsContraparte']);

    return ModeloPerfil.fromJson({
      'id': clienteId, 
      'apodo': contraparteNombreLimpio, 
      'foto_url': avatar, 
      'rating_cliente': rating, 
      'cantidad_resenas_cliente': reviews,
      
      'trabajos_publicados': _parseI(datosCrudosContraparte['trabajos_publicados']),
      'trabajadores_contratados': _parseI(datosCrudosContraparte['trabajadores_contratados']),
      'cancelaciones_cliente': _parseD(datosCrudosContraparte['cancelaciones_cliente']),
      'recomendacion_trabajadores': _parseD(datosCrudosContraparte['recomendacion_trabajadores']),
    });
  }

  String get fechaReservaFormateada {
    final f = DateTime.tryParse(reservaActiva?.fechaHora ?? '') ?? DateTime.now();
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }

  String get horarioReservaFormateado {
    final f = DateTime.tryParse(reservaActiva?.fechaHora ?? '') ?? DateTime.now();
    final hF = DateTime.tryParse(reservaActiva?.horaFin ?? '') ?? f.add(const Duration(hours: 1));
    return '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')} a ${hF.hour.toString().padLeft(2, '0')}:${hF.minute.toString().padLeft(2, '0')} hs';
  }

  String get ubicacionLimpia {
    return reservaActiva?.ubicacionExacta.replaceAll('||', ' ') ?? '';
  }

  Future<void> _cargarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('catalogo_cache_$idReserva');
      if (cacheStr != null && cacheStr.isNotEmpty) {
        final data = jsonDecode(cacheStr);
        if (data['reservaActiva'] != null) {
          reservaActiva = ModeloReservaCatalogo.fromJson(data['reservaActiva']);
          clienteCalificoLocal = reservaActiva!.clienteCalifico;
          proCalificoLocal = reservaActiva!.proCalifico;
          adicionalesPresupuesto = reservaActiva!.adicionalesPresupuesto;
        }
        if (data['datosCrudosContraparte'] != null) {
          datosCrudosContraparte = Map<String, dynamic>.from(data['datosCrudosContraparte']);
        }
        if (data['codigo_checkin'] != null) {
          jobDataInicial['codigo_checkin'] = data['codigo_checkin'];
        }
        if (data['codigo_checkout'] != null) {
          jobDataInicial['codigo_checkout'] = data['codigo_checkout'];
        }
        if (data['servicioAsociado'] != null) {
          servicioAsociado = ModeloServicioCatalogo.fromJson(Map<String, dynamic>.from(data['servicioAsociado']));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SWR] Error leyendo disco local en Catálogo: $e');
    }
  }

  Future<void> _guardarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'reservaActiva': reservaActiva?.toJson(),
        'datosCrudosContraparte': datosCrudosContraparte, 
        'codigo_checkin': jobDataInicial['codigo_checkin'],
        'codigo_checkout': jobDataInicial['codigo_checkout'],
        'servicioAsociado': servicioAsociado?.toJson(),
      };
      await prefs.setString('catalogo_cache_$idReserva', jsonEncode(data));
    } catch (_) {}
  }

  ControladorEjecucionCatalogo(this.jobDataInicial) {
    WidgetsBinding.instance.addObserver(this); 

    idReserva = jobDataInicial['id'].toString();
    clienteId = (jobDataInicial['ownerId'] ?? jobDataInicial['cliente_id'] ?? '').toString();
    profesionalId = (jobDataInicial['profesionalAsignadoId'] ?? jobDataInicial['profesional_asignado_id'] ?? '').toString();
    
    datosCrudosContraparte = jobDataInicial; 
    reservaActiva = ModeloReservaCatalogo.fromJson(jobDataInicial);
    clienteCalificoLocal = reservaActiva!.clienteCalifico;
    proCalificoLocal = reservaActiva!.proCalifico;
    
    adicionalesPresupuesto = reservaActiva?.adicionalesPresupuesto ?? [];

    _cargarCacheSWR().then((_) {
      cargarReservaDesdeRed(silencioso: true);
      _iniciarMotorReactivoLocal(); 
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      cargarReservaDesdeRed(silencioso: true);
      _iniciarMotorReactivoLocal(); 
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 🚨 FIX: Microtask para evitar Deadlock (App Freeze) al abrir MercadoPago
      Future.microtask(() {
        _watchdogTimer?.cancel();
        _limpiarCanal(); 
      });
    }
  }

  void _reiniciarWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 120), () {
      cargarReservaDesdeRed(silencioso: true);
    });
  }

  void _manejarEventoRealtime(dynamic payload) {
    _reiniciarWatchdog();

    bool parcheAplicado = false;
    final tipoEvento = payload.eventType.toString().toLowerCase();

    if (tipoEvento.contains('update') && reservaActiva != null) {
      final record = payload.newRecord as Map<String, dynamic>?;
      final tabla = payload.table.toString();

      if (record != null && tabla == 'trabajos' && record['id'].toString() == idReserva) {
        reservaActiva = ModeloReservaCatalogo.fromJson({...reservaActiva!.toJson(), ...record});
        
        if (record.containsKey('cliente_califico')) clienteCalificoLocal = record['cliente_califico'] == true;
        if (record.containsKey('pro_califico')) proCalificoLocal = record['pro_califico'] == true;
        if (record.containsKey('adicionales_presupuesto')) adicionalesPresupuesto = reservaActiva!.adicionalesPresupuesto;

        parcheAplicado = true;
      }
    }

    if (parcheAplicado) {
      notifyListeners();
      _guardarCacheSWR(); 
      return; 
    }

    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      cargarReservaDesdeRed(silencioso: true);
    });
  }

  Future<void> _limpiarCanal() async {
    if (_suscripcionLiveSupabase != null) {
      try {
        await _suscripcionLiveSupabase!.unsubscribe();
        await Supabase.instance.client.removeChannel(_suscripcionLiveSupabase!);
      } catch (e) {}
      _suscripcionLiveSupabase = null;
    }
  }

  void _iniciarMotorReactivoLocal() async {
    await _limpiarCanal(); 

    _suscripcionLiveSupabase = Supabase.instance.client.channel('catalogo_live_$idReserva');

    _suscripcionLiveSupabase!
      .onPostgresChanges(
        event: PostgresChangeEvent.all, 
        schema: 'public', 
        table: 'trabajos', 
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: idReserva), 
        callback: _manejarEventoRealtime
      )
      .subscribe((RealtimeSubscribeStatus status, [Object? error]) { 
        if (status == RealtimeSubscribeStatus.subscribed) {
          _reiniciarWatchdog();
        } else if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
          if (_reconnectTimer?.isActive ?? false) return; 
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            cargarReservaDesdeRed(silencioso: true); 
            _iniciarMotorReactivoLocal();
          });
        }
      });

    _suscripcionGlobal?.cancel();
    try { 
      _suscripcionGlobal = GestorSesionGlobal().streamEventos.listen((_) => cargarReservaDesdeRed(silencioso: true)); 
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watchdogTimer?.cancel();
    _debounceTimer?.cancel();
    _reconnectTimer?.cancel();
    _limpiarCanal(); 
    _vigilanteTiempo?.cancel();
    _suscripcionGlobal?.cancel();            
    super.dispose();
  }

  Future<void> cargarReservaDesdeRed({bool silencioso = false}) async {
    if (!silencioso) { isCargando = true; notifyListeners(); }
    try {
      final miId = GestorSesionGlobal().miIdUsuario;
      final resFresca = await ServicioEjecucionCatalogoSupabase.obtenerReserva(idReserva, miId);
      
      datosCrudosContraparte = resFresca; 
      reservaActiva = ModeloReservaCatalogo.fromJson(resFresca);

      clienteId = (resFresca['cliente_id'] ?? resFresca['ownerId'] ?? clienteId).toString();
      profesionalId = (resFresca['profesional_asignado_id'] ?? resFresca['profesionalAsignadoId'] ?? profesionalId).toString();

      final String? servicioId = resFresca['servicio_catalogo_id']?.toString() ?? jobDataInicial['servicio_catalogo_id']?.toString() ?? reservaActiva?.servicioCatalogoId;
      if (servicioId != null && servicioId.isNotEmpty) {
        try {
          final resServicio = await Supabase.instance.client
              .from('servicios_catalogo')
              .select()
              .eq('id', servicioId)
              .maybeSingle();
          if (resServicio != null) {
            servicioAsociado = ModeloServicioCatalogo.fromJson(resServicio);
            _guardarCacheSWR();
          }
        } catch (err) {
          debugPrint('Error cargando servicio asociado: $err');
        }
      }
      
      clienteCalificoLocal = reservaActiva!.clienteCalifico;
      proCalificoLocal = reservaActiva!.proCalifico;

      final resCruda = await ServicioEjecucionCatalogoSupabase.obtenerPinesCrudos(idReserva);
      if (resCruda.isNotEmpty) {
        jobDataInicial['codigo_checkin'] = resCruda['codigo_checkin'];
        jobDataInicial['codigo_checkout'] = resCruda['codigo_checkout'];
      }

      adicionalesPresupuesto = reservaActiva!.adicionalesPresupuesto;
      
      procesarAlertasTickets(!soyElProfesional, (evento) => onRequerirAccionUI?.call(evento));

      _evaluarTimelineInstantanea();
      _iniciarVigilanteTimeline();
      
      _reiniciarWatchdog(); 
      _guardarCacheSWR(); 

      final bool fueCanceladoPorCliente = reservaActiva?.estado == 'cancelado' && reservaActiva?.estadoNegociacion == 'cancelada_por_cliente';
      if (soyElProfesional && fueCanceladoPorCliente) {
         onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
           dominio: DominioApp.catalogo,
           accion: TipoAccionCancelacion.avisoProCanceladoPorCliente,
           actor: ActorCancelacion.profesional,
           gananciaPro: gananciaProCancelacion,
           onEntendido: marcarCancelacionVistaPro,
         ));
      }

      final bool fueCanceladoPorPro = reservaActiva?.estado == 'cancelado' && reservaActiva?.estadoNegociacion == 'cancelada_por_pro';
      if (!soyElProfesional && fueCanceladoPorPro) {
         onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
           dominio: DominioApp.catalogo,
           accion: TipoAccionCancelacion.avisoClienteCanceladoPorPro,
           actor: ActorCancelacion.cliente,
           onEntendido: aceptarCancelacionCerrar,
         ));
      }

    } catch (e) {
      debugPrint('[SWR] Fallo silencioso en Catálogo. Preservando RAM visual.');
    } finally {
      isCargando = false; 
      notifyListeners();
    }
  }

  void _evaluarTimelineInstantanea() {
    if (reservaActiva == null || reservaActiva!.estado != 'aceptada') return;
    final fechaPactada = DateTime.tryParse(reservaActiva!.fechaHora);
    if (fechaPactada != null) {
      if (fechaPactada.difference(DateTime.now()).inMinutes <= 40) enCaminoAutomatico = true;
    }
  }

  void _iniciarVigilanteTimeline() {
    _vigilanteTiempo?.cancel();
    _vigilanteTiempo = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (reservaActiva == null || reservaActiva!.estado != 'aceptada' || enCaminoAutomatico) { timer.cancel(); return; }
      final fechaPactada = DateTime.tryParse(reservaActiva!.fechaHora);
      if (fechaPactada != null) {
        if (fechaPactada.difference(DateTime.now()).inMinutes <= 40) {
          enCaminoAutomatico = true; notifyListeners(); 
        }
      }
    });
  }

  Future<void> registrarLlegadaSatelital(Function(String) onError) async {
    GestorSesionGlobal.requerirAuth(() async {
      _setProcesando(true);
      try {
        final pos = await ServicioGpsLocalizacion.obtenerCoordenadasActuales();
        await ServicioEjecucionCatalogoSupabase.registrarLlegada(idReserva, '${pos.latitude},${pos.longitude}');
        await cargarReservaDesdeRed(); 
      } catch (e) { onError('No pudimos obtener tu ubicación. Revisa tu GPS.'); } finally { _setProcesando(false); }
    });
  }

  Future<void> registrarTareaFinalizada(Function(String) onError) async {
    GestorSesionGlobal.requerirAuth(() async {
      _setProcesando(true);
      try {
        await ServicioEjecucionCatalogoSupabase.marcarTareaFinalizada(idReserva);
        await cargarReservaDesdeRed();
      } catch (e) { onError('Falla de red al marcar la tarea como finalizada.'); } finally { _setProcesando(false); }
    });
  }

  Future<void> procesarPinCheckin(String pin, Function(String) onError) async {
    GestorSesionGlobal.requerirAuth(() async {
      if (pin != codigoCheckin) { onError('El PIN ingresado no coincide.'); return; }
      _setProcesando(true);
      try { await ServicioEjecucionCatalogoSupabase.validarPin(idReserva, 'llegada'); await cargarReservaDesdeRed(); } 
      catch (e) { onError('Falla de red al registrar el PIN.'); } finally { _setProcesando(false); }
    });
  }

  Future<void> procesarPinCheckout(String pin, Function(String) onError) async {
    GestorSesionGlobal.requerirAuth(() async {
      if (pin != codigoCheckout) { onError('El PIN de finalización no coincide.'); return; }
      _setProcesando(true);
      try { await ServicioEjecucionCatalogoSupabase.validarPin(idReserva, 'salida'); await cargarReservaDesdeRed(); } 
      catch (e) { onError('Falla de red al finalizar.'); } finally { _setProcesando(false); }
    });
  }

  Future<void> abrirNavegadorGPS() async {
    if (reservaActiva != null && reservaActiva!.ubicacionExacta.isNotEmpty) {
      await ServicioGpsLocalizacion.abrirEnMapa(reservaActiva!.ubicacionExacta.replaceAll('||', ' '));
    }
  }

  void marcarCalificacionLocalVisualmente(bool esCliente) {
    if (esCliente) clienteCalificoLocal = true; else proCalificoLocal = true;
    notifyListeners();
    _guardarCacheSWR(); 
  }

  // 🛡️ DATA-MISER: Reparación del Agujero Negro del Catálogo.
  Future<void> finalizarYCalificar(ModeloResenaPayload payload, String autorNombre, String autorAvatar, bool esCliente) async {
    GestorSesionGlobal.requerirAuth(() async {
      _setProcesando(true);
      try {
        final miId = GestorSesionGlobal().miIdUsuario;
        final evaluadoId = soyElProfesional ? clienteId : profesionalId;
        
        await ServicioEjecucionCatalogoSupabase.finalizarYCalificar(
          trabajoId: idReserva,
          evaluadorId: miId,
          evaluadoId: evaluadoId,
          evaluadorNombre: autorNombre,
          evaluadorAvatar: autorAvatar,
          payload: payload,
          esCliente: esCliente
        );
        
        marcarCalificacionLocalVisualmente(esCliente);
        ControladorActividadCatalogo().blindarTrampaPorCalificacionExitosa(idReserva);
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'No se pudo guardar la calificación.');
      } finally {
        _setProcesando(false);
      }
    });
  }

  void _setProcesando(bool valor) { isProcesandoAccion = valor; notifyListeners(); }

  void solicitarCancelacionCliente() {
    try {
      final String fechaRaw = reservaActiva?.fechaHora ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));

      final porcentajeRetencion = CalculadorPenalizaciones.calcularRetencionCliente(fechaSegura);
      final montoRetenido = CalculadorPenalizaciones.calcularMontoRetencion(precioTotalConAdicionales, porcentajeRetencion);

      onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
        dominio: DominioApp.catalogo,
        accion: TipoAccionCancelacion.advertenciaCliente,
        actor: ActorCancelacion.cliente,
        porcentajeRetencion: porcentajeRetencion,
        montoRetenido: montoRetenido,
        onConfirmar: () => confirmarCancelacionClienteYReembolsar(porcentajeRetencion),
      ));
    } catch (e) {
      onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Ocurrió un problema al calcular la retención.');
    }
  }

  void solicitarVerPoliticasCancelacion() {
    onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
      dominio: DominioApp.catalogo,
      accion: TipoAccionCancelacion.verPoliticas,
      actor: soyElProfesional ? ActorCancelacion.profesional : ActorCancelacion.cliente,
    ));
  }

  void confirmarCancelacionClienteYReembolsar(double porcentajeRetencion) {
    GestorSesionGlobal.requerirAuth(() async {
      _setProcesando(true);
      try {
        await ServicioEjecucionCatalogoSupabase.cancelarTrabajoPorCliente(idReserva);
        reservaActiva = ModeloReservaCatalogo.fromJson({...reservaActiva!.toJson(), 'estado': 'cancelado', 'estadoNegociacion': 'cancelada_por_cliente'});
        _guardarCacheSWR();
        onRequerirAccionUI?.call('CERRAR_MODALES');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error interno al cancelar.');
      } finally {
        _setProcesando(false);
      }
    });
  }

  double get gananciaProCancelacion {
    try {
      final String fechaRaw = reservaActiva?.fechaHora ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));
      
      final distribucion = CalculadorPenalizaciones.calcularDistribucionCancelacion(fechaSegura, precioTotalConAdicionales);
      return distribucion['gananciaPro'] ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void marcarCancelacionVistaPro() {
    GestorSesionGlobal.requerirAuth(() async {
      _setProcesando(true);
      try {
        await ServicioEjecucionCatalogoSupabase.marcarCancelacionVistaPorPro(idReserva);
        reservaActiva = ModeloReservaCatalogo.fromJson({...reservaActiva!.toJson(), 'estadoNegociacion': 'cancelada_vista_pro'});
        _guardarCacheSWR();
        ControladorActividadCatalogo().recargarSilenciosoGlobal();
      } catch (e) {
      } finally {
        _setProcesando(false);
      }
    });
  }

  void solicitarCancelacionPro() {
    try {
      final String fechaRaw = reservaActiva?.fechaHora ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));
      
      final puntos = CalculadorPenalizaciones.calcularPuntosPenalizacionPro(fechaSegura);
      
      onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
        dominio: DominioApp.catalogo,
        accion: TipoAccionCancelacion.advertenciaPro,
        actor: ActorCancelacion.profesional,
        puntosPenalizacion: puntos,
        onConfirmar: () => confirmarCancelacionPro(puntos),
      ));
    } catch (e) {
      onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error al calcular penalización.');
    }
  }

  void confirmarCancelacionPro(int puntos) {
    GestorSesionGlobal.requerirAuth(() async {
      _setProcesando(true);
      try {
        await ServicioEjecucionCatalogoSupabase.cancelarTrabajoPorPro(idReserva, profesionalId, clienteId, puntos);
        reservaActiva = ModeloReservaCatalogo.fromJson({...reservaActiva!.toJson(), 'estado': 'cancelado', 'estadoNegociacion': 'cancelada_por_pro'});
        _guardarCacheSWR();
        ControladorActividadCatalogo().recargarSilenciosoGlobal();
        onRequerirAccionUI?.call('CERRAR_MODALES');
      } on PostgrestException catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error DB: ${e.message}');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error interno al cancelar.');
      } finally {
        _setProcesando(false);
      }
    });
  }

  void aceptarCancelacionCerrar() {
    GestorSesionGlobal.requerirAuth(() async {
      _setProcesando(true);
      try {
        await ServicioEjecucionCatalogoSupabase.marcarCancelacionVistaPorCliente(idReserva);
        reservaActiva = ModeloReservaCatalogo.fromJson({...reservaActiva!.toJson(), 'estadoNegociacion': 'cancelada_vista_cliente'});
        _guardarCacheSWR();
        ControladorActividadCatalogo().recargarSilenciosoGlobal();
        onRequerirAccionUI?.call('CERRAR_MODALES');
      } on PostgrestException catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error DB: ${e.message}');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error interno.');
      } finally {
        _setProcesando(false);
      }
    });
  }
}