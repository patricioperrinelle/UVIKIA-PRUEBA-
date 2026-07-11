// lib/5_modulos/modulo_gestion_jornadas/controladores/controlador_jornadas.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/widgets.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../servicios/servicio_gestion_jornadas_supabase.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../3_modelos/modelo_jornada.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/utilidades/calculador_penalizaciones.dart';
import 'controlador_actividad_jornadas.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

export 'extension_jornadas_parseo.dart';
export 'extension_jornadas_postulaciones.dart';
export 'extension_jornadas_ejecucion.dart';

class ControladorJornadas extends ChangeNotifier with WidgetsBindingObserver {
  void Function(String accion, dynamic payload)? onRequerirAccionUI;

  bool isLoading = true; 
  bool isProcessing = false;
  
  late dynamic trabajoId;
  late String miId;
  late bool soyElDueno;
  late String clienteId;
  late double sueldoNumerico;
  bool esHistorial = false; 
  
  List<ModeloPuja> pujas = [];
  ModeloPuja? miPuja;
  String? selectedChatProId; 
  bool scrollRealizado = false; 
  bool profesionalEnCamino = false; 
  bool _isObserverAdded = false; 

  Map<String, dynamic> jobDataExtendida = {}; 

  Timer? _watchdogTimer; 
  Timer? _debounceTimer; 
  Timer? _reconnectTimer; 

  StreamSubscription? suscripcionGlobal;
  RealtimeChannel? suscripcionLiveSupabase;

  bool _isFetchingSilencioso = false;
  bool _needsAnotherFetch = false;

  // 🛡️ ARQUITECTURA LIMPIA: Getters Semánticos (La UI ya no piensa).
  bool get esVistaInmersiva => !soyElDueno && !proContratado;
  
  bool get proContratado => !soyElDueno && (miPuja?.estadoPuja == 'esperando_confirmacion_pro' || miPuja?.estadoPuja == 'esperando_pago_cliente' || miPuja?.estadoPuja == 'aceptada' || miPuja?.estadoPuja == 'en_curso' || miPuja?.estadoPuja == 'esperando_pin_salida' || miPuja?.estadoPuja == 'finalizada' || miPuja?.estadoPuja == 'desestimada' || miPuja?.estadoPuja == 'en_disputa');
  
  bool get tratoFinalizado => jobDataExtendida['estado'] == 'finalizado';
  bool get miPujaDesestimada => miPuja?.estadoPuja == 'desestimada' || miPuja?.estadoPuja == 'rechazada_por_pro';
  bool get miPujaFinalizada => tratoFinalizado || miPuja?.estadoPuja == 'finalizada';
  bool get esperandoConfirmacionPro => miPuja?.estadoPuja == 'esperando_confirmacion_pro';
  bool get esperandoPagoCliente => miPuja?.estadoPuja == 'esperando_pago_cliente';
  bool get miPujaEnEjecucion => miPuja?.estadoPuja == 'aceptada' || miPuja?.estadoPuja == 'en_curso' || miPuja?.estadoPuja == 'en_disputa' || miPuja?.estadoPuja == 'esperando_pin_salida';

  String get tituloTrabajo => jobDataExtendida['title']?.toString() ?? jobDataExtendida['titulo']?.toString() ?? 'Jornada Eventual';

  double get counterpartRating {
    final rootRating = jobDataExtendida['rating_cliente']?.toString() ?? jobDataExtendida['ratingCliente']?.toString() ?? jobDataExtendida['rating']?.toString();
    if (rootRating != null && rootRating.isNotEmpty) return double.tryParse(rootRating) ?? 0.0;
    
    final perf = jobDataExtendida['perfiles'];
    if (perf is Map) {
      final perfRating = perf['rating_cliente']?.toString() ?? perf['rating']?.toString();
      if (perfRating != null && perfRating.isNotEmpty) return double.tryParse(perfRating) ?? 0.0;
    }
    return 0.0;
  }

  int get counterpartReviews {
    final rootRev = jobDataExtendida['cantidad_resenas_cliente']?.toString() ?? jobDataExtendida['cantidadResenasCliente']?.toString() ?? jobDataExtendida['reviews']?.toString() ?? jobDataExtendida['cantidad_resenas']?.toString();
    if (rootRev != null && rootRev.isNotEmpty) return int.tryParse(rootRev) ?? 0;
    
    final perf = jobDataExtendida['perfiles'];
    if (perf is Map) {
      final perfRev = perf['cantidad_resenas_cliente']?.toString() ?? perf['cantidad_resenas']?.toString();
      if (perfRev != null && perfRev.isNotEmpty) return int.tryParse(perfRev) ?? 0;
    }
    return 0;
  }

  void actualizarUI() {
    notifyListeners();
  }

  void notificarUI(String mensaje, {bool esError = false, bool esAdvertencia = false}) {
    onRequerirAccionUI?.call('mostrar_mensaje', {'mensaje': mensaje, 'esError': esError, 'esAdvertencia': esAdvertencia});
  }

  Future<void> _cargarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('jornadas_cache_$trabajoId');
      if (cacheStr != null && cacheStr.isNotEmpty) {
        final data = jsonDecode(cacheStr);
        if (data['jobDataExtendida'] != null) {
          // 🛡️ SWR ABSOLUTO: Sobreescribimos la memoria vieja
          jobDataExtendida = Map<String, dynamic>.from(data['jobDataExtendida']);
        }
        if (data['pujas'] != null) {
          pujas = (data['pujas'] as List).map((p) => ModeloPuja.fromJson(p)).toList();
        }
      }
    } catch (e) {
      debugPrint('[SWR] Error leyendo disco local en Jornadas: $e');
    }
  }

  // 🛡️ CORRECCIÓN SWR: Ahora es público para permitir el Optimistic UI en las extensiones
  Future<void> guardarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'jobDataExtendida': jobDataExtendida,
        'pujas': pujas.map((p) => p.toJson()).toList(),
      };
      await prefs.setString('jornadas_cache_$trabajoId', jsonEncode(data));
    } catch (_) {}
  }

  void inicializar(Map<String, dynamic> jobData, String idUsuario, {bool esHistorial = false, ModeloJornada? trabajoTipado}) {
    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }

    isLoading = true;
    trabajoId = jobData['id'] ?? trabajoTipado?.id; 
    miId = idUsuario;
    clienteId = jobData['ownerId']?.toString() ?? jobData['cliente_id']?.toString() ?? trabajoTipado?.ownerId ?? '';
    soyElDueno = clienteId == miId;
    this.esHistorial = esHistorial;
    final sueldoStr = jobData['price']?.toString() ?? trabajoTipado?.precio ?? '0';
    sueldoNumerico = double.tryParse(sueldoStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    jobDataExtendida = Map<String, dynamic>.from(jobData);

    if (jobDataExtendida['pujas'] != null) {
      try {
        pujas = (jobDataExtendida['pujas'] as List).map((p) => ModeloPuja.fromJson(p)).toList();
      } catch (_) {}
    }

    if (trabajoTipado != null) {
      final bool tieneDataPuja = trabajoTipado.pujaId != null || 
                                 trabajoTipado.miOferta != null || 
                                 jobData['puja_id'] != null || 
                                 jobData['estado_puja'] != null;

      if (!soyElDueno && tieneDataPuja) {
        miPuja = ModeloPuja(
          id: trabajoTipado.pujaId ?? jobData['puja_id'] ?? 'temp_$trabajoId',
          profesionalId: miId,
          apodoProfesional: '',
          avatarUrl: '',
          rating: 0,
          reviews: 0,
          montoOfrecido: trabajoTipado.miOferta ?? jobData['monto_ofrecido'] ?? '0',
          estadoPuja: trabajoTipado.estadoNegociacion ?? jobData['estado_puja'] ?? 'esperando',
          mensaje: '',
          coordenadasLlegada: jobData['coordenadas_llegada'], 
          checkinHora: jobData['checkin_hora'],
          checkoutHora: jobData['checkout_hora'],
          codigoCheckin: jobData['codigo_checkin'],
          codigoCheckout: jobData['codigo_checkout'],
          rechazadoPorCliente: (trabajoTipado.estadoNegociacion == 'rechazada') || (jobData['rechazado_por_cliente'] == true),
          clienteCalificoPuja: trabajoTipado.clienteCalifico || jobData['cliente_califico'] == true || jobData['clienteCalifico'] == true,
          proCalificoPuja: trabajoTipado.proCalifico || jobData['pro_califico'] == true || jobData['proCalifico'] == true,
        );
        if (pujas.isEmpty) pujas = [miPuja!];
        
        if (miPuja?.estadoPuja == 'aceptada' || miPuja?.estadoPuja == 'en_curso' || miPuja?.estadoPuja == 'finalizada') {
          profesionalEnCamino = true; 
        }
      }
    }
    
    // 🛡️ CORRECCIÓN SWR: Se eliminó el apagado síncrono del loader. Ahora espera a la RAM (0ms).
    _cargarCacheSWR().then((_) {
      isLoading = false;
      actualizarUI();
      _cargarDatosInstantaneos();
      _iniciarMotorReactivoLocal();
    });
  }

  void marcarCalificacionLocalVisualmente(String pujaId, bool esCliente) {
    if (esCliente) {
      final idx = pujas.indexWhere((p) => p.id == pujaId);
      if (idx != -1) {
        pujas[idx] = ModeloPuja.fromJson({...pujas[idx].toJson(), 'cliente_califico_puja': true, 'clienteCalificoPuja': true});
      }
    } else {
      if (miPuja != null) {
        miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'pro_califico_puja': true, 'proCalificoPuja': true});
      }
    }
    actualizarUI();
    guardarCacheSWR(); 
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      cargarDatosSilencioso();
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
      cargarDatosSilencioso();
    });
  }

  void _manejarEventoRealtime(dynamic payload) {
    _reiniciarWatchdog();

    bool parcheAplicado = false;
    final tipoEvento = payload.eventType.toString().toLowerCase();

    if (tipoEvento.contains('update')) {
      final record = payload.newRecord as Map<String, dynamic>?;
      final tabla = payload.table.toString();

      if (record != null) {
        if (tabla == 'trabajos' && record['id'].toString() == trabajoId.toString()) {
          jobDataExtendida.addAll(record);
          parcheAplicado = true;
        } else if (tabla == 'pujas' && record['trabajo_id'].toString() == trabajoId.toString()) {
          final pujaId = record['id'].toString();
          final index = pujas.indexWhere((p) => p.id == pujaId);
          if (index != -1) {
            pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), ...record});
            if (miPuja?.id == pujaId) miPuja = pujas[index];
            parcheAplicado = true;
          }
        }
      }
    }

    if (parcheAplicado) {
      actualizarUI();
      guardarCacheSWR(); 
      return; 
    }

    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      cargarDatosSilencioso();
    });
  }

  Future<void> _limpiarCanal() async {
    if (suscripcionLiveSupabase != null) {
      try {
        await suscripcionLiveSupabase!.unsubscribe();
        await Supabase.instance.client.removeChannel(suscripcionLiveSupabase!); 
      } catch (e) {}
      suscripcionLiveSupabase = null;
    }
  }

  void _iniciarMotorReactivoLocal() async {
    await _limpiarCanal(); 

    suscripcionLiveSupabase = Supabase.instance.client.channel('jornadas_live_$trabajoId');

    suscripcionLiveSupabase!
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'pujas', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'trabajo_id', value: trabajoId.toString()), callback: _manejarEventoRealtime)
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'trabajos', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: trabajoId.toString()), callback: _manejarEventoRealtime)
      .subscribe((RealtimeSubscribeStatus status, [Object? error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _reiniciarWatchdog();
        } else if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
          if (_reconnectTimer?.isActive ?? false) return; 
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            cargarDatosSilencioso(); 
            _iniciarMotorReactivoLocal(); 
          });
        }
      });

    suscripcionGlobal?.cancel();
    suscripcionGlobal = GestorSesionGlobal().streamEventos.listen((_) => cargarDatosSilencioso());
  }

  @override
  void dispose() { 
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(this); 
    }
    _watchdogTimer?.cancel();
    _debounceTimer?.cancel();
    _reconnectTimer?.cancel();
    _limpiarCanal(); 
    suscripcionGlobal?.cancel(); 
    super.dispose(); 
  }

  Future<void> _cargarDatosInstantaneos() async {
    if (!soyElDueno && miPuja == null) { 
      try { 
        miPuja = pujas.firstWhere((p) => p.profesionalId == miId);
        if (miPuja?.mensaje == 'CONFIRMADO_PRO') profesionalEnCamino = true;
        if (!miPuja!.notificacionLeidaPro) marcarNotificacionLeidaPro();
      } catch (_) { miPuja = null; } 
    }

    if (!soyElDueno && miPuja != null) {
      final bool fueCanceladoPorCliente = miPuja?.estadoPuja == 'cancelada_por_cliente';
      if (fueCanceladoPorCliente) {
         onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
           dominio: DominioApp.jornadas,
           accion: TipoAccionCancelacion.avisoProCanceladoPorCliente,
           actor: ActorCancelacion.profesional,
           gananciaPro: gananciaProCancelacion,
           onEntendido: () {
             onRequerirAccionUI?.call('CERRAR_MODALES', null);
             marcarCancelacionVistaPro();
           }
         ));
      }
    }
    
    cargarDatosSilencioso();
  }

  Future<void> marcarNotificacionLeidaCliente(String pujaId) async {
    try {
      final idx = pujas.indexWhere((p) => p.id == pujaId);
      if (idx != -1 && !pujas[idx].notificacionLeidaCliente) {
        final old = pujas[idx];
        pujas[idx] = ModeloPuja.fromJson({...old.toJson(), 'notificacionLeidaCliente': true});
        actualizarUI();
        guardarCacheSWR(); 
        await ServicioGestionJornadasSupabase.marcarPujaLeidaCliente(pujaId);
      }
    } catch (_) {}
  }

  Future<void> marcarNotificacionLeidaPro() async {
    if (miPuja != null && !miPuja!.notificacionLeidaPro) {
      try { await ServicioGestionJornadasSupabase.marcarPujaLeidaPro(miPuja!.id); } catch (_) {}
    }
  }

  Future<void> cargarDatosSilencioso() async {
    if (isProcessing) return;

    if (_isFetchingSilencioso) {
      _needsAnotherFetch = true;
      return;
    }
    
    _isFetchingSilencioso = true;
    
    try {
      final datosCompletos = await ServicioGestionJornadasSupabase.obtenerTrabajoPorId(trabajoId);
      if (datosCompletos != null) jobDataExtendida.addAll(datosCompletos);

      final nuevasPujas = await ServicioGestionJornadasSupabase.obtenerPujasJornada(trabajoId);
      _procesarNuevasPujas(nuevasPujas);
      
      _reiniciarWatchdog(); 
      guardarCacheSWR(); 
    } catch (e) {
      debugPrint('[SWR] Fallo silencioso en Jornadas. UI sobrevive con RAM.');
    } finally {
      isLoading = false; 
      actualizarUI();

      _isFetchingSilencioso = false;
      if (_needsAnotherFetch) {
        _needsAnotherFetch = false;
        cargarDatosSilencioso(); 
      }
    }
  }

  void _procesarNuevasPujas(List<ModeloPuja> nuevasPujas) {
    if (soyElDueno) {
      for (var nueva in nuevasPujas) {
        if (nueva.estadoPuja == 'finalizada') {
          final vieja = pujas.firstWhere((p) => p.id == nueva.id, orElse: () => nueva);
          if (vieja.estadoPuja == 'en_curso') {
            onRequerirAccionUI?.call('abrir_calificacion', nueva);
          }
        }
        if (nueva.estadoPuja == 'cancelada_por_pro' && !nueva.notificacionLeidaCliente) {
          onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
            dominio: DominioApp.jornadas,
            accion: TipoAccionCancelacion.avisoClienteCanceladoPorPro,
            actor: ActorCancelacion.cliente,
            onEntendido: () {
              onRequerirAccionUI?.call('CERRAR_MODALES', null);
              marcarNotificacionLeidaCliente(nueva.id);
            }
          ));
        }
      }
    }

    bool tengoPujaReal = nuevasPujas.any((p) => p.profesionalId == miId && !p.id.toString().startsWith('temp'));
    if (miPuja == null || !miPuja!.id.toString().startsWith('temp') || tengoPujaReal) {
      pujas = nuevasPujas;
      if (!soyElDueno) { 
        try { 
          miPuja = pujas.firstWhere((p) => p.profesionalId == miId); 
          if (miPuja?.mensaje == 'CONFIRMADO_PRO') profesionalEnCamino = true; 
          
          final bool fueCanceladoPorCliente = miPuja?.estadoPuja == 'cancelada_por_cliente';
          if (fueCanceladoPorCliente) {
             onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
               dominio: DominioApp.jornadas,
               accion: TipoAccionCancelacion.avisoProCanceladoPorCliente,
               actor: ActorCancelacion.profesional,
               gananciaPro: gananciaProCancelacion,
               onEntendido: () {
                 onRequerirAccionUI?.call('CERRAR_MODALES', null);
                 marcarCancelacionVistaPro();
               }
             ));
          }
        } catch (_) { } 
      }
    }
    
    if (soyElDueno && !scrollRealizado && pujas.isNotEmpty) { 
      scrollRealizado = true; 
      onRequerirAccionUI?.call('scroll_a_postulantes', null); 
    }
  }
  
  void seleccionarChatPro(String proId) { 
    selectedChatProId = (selectedChatProId == proId) ? null : proId; 
    actualizarUI(); 
  }

  void abrirDisputaYMediar(ModeloPuja pujaEspecifica, String categoria, String solucionEsperada, String descripcion) {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; actualizarUI();
      try {
        final elOtro = soyElDueno ? pujaEspecifica.profesionalId : clienteId;
        
        await ServicioGestionJornadasSupabase.abrirDisputaYMediar(
          trabajoId: trabajoId, 
          pujaId: pujaEspecifica.id, 
          reportadorId: miId, 
          reportadoId: elOtro, 
          categoria: categoria, 
          solucionEsperada: solucionEsperada, 
          descripcion: descripcion,
          soyCliente: soyElDueno
        );
        
        final idx = pujas.indexWhere((p) => p.id == pujaEspecifica.id);
        if (idx != -1) {
          pujas[idx] = ModeloPuja.fromJson({...pujas[idx].toJson(), 'estado': 'en_disputa'});
        }
        if (!soyElDueno && miPuja != null) {
          miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estado': 'en_disputa'});
        }

        guardarCacheSWR();
        onRequerirAccionUI?.call('CERRAR_MODALES', null); 
        onRequerirAccionUI?.call('NAVEGAR_SALA_MEDIACION', elOtro); 
      } catch (e) {
        notificarUI('No se pudo procesar el reporte.', esError: true);
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }

  void solicitarCancelacionCliente(ModeloPuja pujaElegida) {
    try {
      final String fechaRaw = jobDataExtendida['fecha_hora']?.toString() ?? jobDataExtendida['fechaHora']?.toString() ?? jobDataExtendida['date']?.toString() ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));
      
      final porcentajeRetencion = CalculadorPenalizaciones.calcularRetencionCliente(fechaSegura);
      final montoRetenido = CalculadorPenalizaciones.calcularMontoRetencion(sueldoNumerico, porcentajeRetencion);

      onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
        dominio: DominioApp.jornadas,
        accion: TipoAccionCancelacion.advertenciaCliente,
        actor: ActorCancelacion.cliente,
        porcentajeRetencion: porcentajeRetencion,
        montoRetenido: montoRetenido,
        onConfirmar: () => confirmarCancelacionClienteYReembolsar(pujaElegida.id, porcentajeRetencion),
      ));
    } catch (e) {
      notificarUI('Ocurrió un problema al calcular la retención.', esError: true);
    }
  }

  void solicitarVerPoliticasCancelacion() {
    onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
      dominio: DominioApp.jornadas,
      accion: TipoAccionCancelacion.verPoliticas,
      actor: soyElDueno ? ActorCancelacion.cliente : ActorCancelacion.profesional,
    ));
  }

  void confirmarCancelacionClienteYReembolsar(String pujaId, double porcentajeRetencion) {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; 
      actualizarUI();
      try {
        await ServicioGestionJornadasSupabase.cancelarPujaPorCliente(trabajoId, pujaId);
        
        final idx = pujas.indexWhere((p) => p.id == pujaId);
        if (idx != -1) {
          pujas[idx] = ModeloPuja.fromJson({...pujas[idx].toJson(), 'estado': 'cancelada_por_cliente', 'estadoPuja': 'cancelada_por_cliente'});
        }
        
        guardarCacheSWR();
        onRequerirAccionUI?.call('CERRAR_MODALES', null);
      } on PostgrestException catch (e) {
        notificarUI('Error Base de Datos: ${e.message}', esError: true);
      } catch (e) {
        notificarUI('Error interno al cancelar.', esError: true);
      } finally {
        isProcessing = false; 
        actualizarUI();
      }
    });
  }

  double get gananciaProCancelacion {
    try {
      final String fechaRaw = jobDataExtendida['fecha_hora']?.toString() ?? jobDataExtendida['fechaHora']?.toString() ?? jobDataExtendida['date']?.toString() ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));
      final distribucion = CalculadorPenalizaciones.calcularDistribucionCancelacion(fechaSegura, sueldoNumerico);
      return distribucion['gananciaPro'] ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void marcarCancelacionVistaPro() {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; 
      actualizarUI();
      try {
        await ServicioGestionJornadasSupabase.marcarCancelacionVistaPorPro(miPuja?.id ?? '');
        if (miPuja != null) {
          miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estado': 'cancelada_vista_pro', 'estadoPuja': 'cancelada_vista_pro'});
        }
        guardarCacheSWR();
        ControladorActividadJornadas().recargarSilenciosoGlobal();
      } on PostgrestException catch (e) {
        notificarUI('Error Base de Datos: ${e.message}', esError: true);
      } catch (e) {
        notificarUI('Error interno al confirmar vista.', esError: true);
      } finally {
        isProcessing = false; 
        actualizarUI();
      }
    });
  }

  void solicitarCancelacionPro() {
    try {
      final String fechaRaw = jobDataExtendida['fecha_hora']?.toString() ?? jobDataExtendida['fechaHora']?.toString() ?? jobDataExtendida['date']?.toString() ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));
      
      final puntos = CalculadorPenalizaciones.calcularPuntosPenalizacionPro(fechaSegura);
      
      onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
        dominio: DominioApp.jornadas,
        accion: TipoAccionCancelacion.advertenciaPro,
        actor: ActorCancelacion.profesional,
        puntosPenalizacion: puntos,
        onConfirmar: () => confirmarCancelacionPro(puntos),
      ));
    } catch (e) {
      notificarUI('Error al calcular penalización.', esError: true);
    }
  }

  void confirmarCancelacionPro(int puntos) {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; actualizarUI();
      try {
        await ServicioGestionJornadasSupabase.cancelarTrabajoPorPro(miPuja!.id, trabajoId, clienteId, miId, puntos);
        
        if (miPuja != null) {
          miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estado': 'cancelada_por_pro', 'estadoPuja': 'cancelada_por_pro'});
        }
        guardarCacheSWR();
        ControladorActividadJornadas().recargarSilenciosoGlobal();
        onRequerirAccionUI?.call('CERRAR_MODALES', null);
      } on PostgrestException catch (e) {
        notificarUI('Error DB: ${e.message}', esError: true);
      } catch (e) {
        notificarUI('Error interno al cancelar.', esError: true);
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }
}