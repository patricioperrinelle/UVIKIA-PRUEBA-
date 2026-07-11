// lib/5_modulos/modulo_negociacion_oficios/controladores/controlador_negociacion.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/widgets.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../1_nucleo/utilidades/mixin_gestor_tickets.dart'; 
import '../servicios/servicio_negociacion_supabase.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/utilidades/calculador_penalizaciones.dart';
import 'controlador_actividad_oficios.dart'; 
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

export 'extension_negociacion_parseo.dart';
export 'extension_negociacion_ofertas.dart';
export 'extension_negociacion_ejecucion.dart';

enum EstadoNegociacion { abierto, asignado, enCurso, finalizado, cancelado, enDisputa }

class ControladorNegociacion extends ChangeNotifier with MixinGestorTickets, WidgetsBindingObserver {
  bool isLoading = true; 
  bool isProcessing = false;
  EstadoNegociacion estadoActual = EstadoNegociacion.abierto;
  
  late String miId;
  late bool soyElDueno;
  String contraparteIdFija = '';
  
  Map<String, dynamic> jobData = {};
  List<ModeloPuja> pujas = [];
  ModeloPuja? miPuja;
  
  String metodoPagoElegido = '';
  String precioFinalDelBd = '\$ 0';
  bool perdiElTrabajo = false;

  bool resenaCerradaEnRam = false;
  bool _isObserverAdded = false;

  Timer? _watchdogTimer; 
  Timer? _debounceTimer; 
  Timer? _reconnectTimer; 
  
  StreamSubscription? _suscripcionGlobal;
  RealtimeChannel? _suscripcionLiveSupabase;

  dynamic get idTrabajoReal => jobData['id'];
  void Function(String tipoEvento, [dynamic payload])? onRequerirAccionUI;

  String get contraparteNombre {
    if (soyElDueno && pujaAceptada != null) return pujaAceptada!.apodoProfesional;
    return jobData['contraparteNombre']?.toString() ?? 'Usuario';
  }

  String get contraparteAvatar {
    if (soyElDueno && pujaAceptada != null) return pujaAceptada!.avatarUrl;
    return jobData['contraparteAvatar']?.toString() ?? '';
  }

  double get ratingContraparte {
    if (soyElDueno && pujaAceptada != null) return pujaAceptada!.rating;
    return (jobData['ratingContraparte'] as num?)?.toDouble() ?? 0.0;
  }

  int get reviewsContraparte {
    if (soyElDueno && pujaAceptada != null) return pujaAceptada!.reviews;
    return (jobData['reviewsContraparte'] as num?)?.toInt() ?? 0;
  }

  String get telefonoContraparte {
    if (soyElDueno && pujaAceptada != null) return pujaAceptada!.telefono;
    return jobData['telefono']?.toString() ?? '';
  }

  bool esVistaMinimalista(bool esHistorial) {
    final estaActivo = estadoActual == EstadoNegociacion.asignado || estadoActual == EstadoNegociacion.enCurso || estadoActual == EstadoNegociacion.enDisputa;
    final isFrozen = estadoActual == EstadoNegociacion.finalizado || estadoActual == EstadoNegociacion.cancelado || esHistorial || perdiElTrabajo;
    return soyElDueno || estaActivo || isFrozen;
  }

  ModeloPuja? get pujaActiva => soyElDueno ? pujaAceptada : miPuja;

  bool get estaCanceladoOPerdido => estadoActual == EstadoNegociacion.cancelado || perdiElTrabajo;
  bool get esperandoConfirmacionPro => estadoActual == EstadoNegociacion.abierto && pujaActiva?.estadoPuja == 'esperando_confirmacion_pro';
  bool get esperandoPagoCliente => estadoActual == EstadoNegociacion.abierto && pujaActiva?.estadoPuja == 'esperando_pago_cliente';
  bool get requierePanelAccionesPro => estadoActual == EstadoNegociacion.abierto;
  bool get requierePanelAccionesFinales => estadoActual == EstadoNegociacion.asignado || estadoActual == EstadoNegociacion.enCurso || estadoActual == EstadoNegociacion.finalizado || estadoActual == EstadoNegociacion.enDisputa;
  bool get estaEnDisputa => estadoActual == EstadoNegociacion.enDisputa;

  bool tratoCerradoYCalificado(bool calificacionLocalExitosa) {
    return estadoActual == EstadoNegociacion.finalizado && (clienteCalifico || calificacionLocalExitosa);
  }

  String get estadoOperativoCiego {
    return jobData['estado_negociacion']?.toString() ?? jobData['estadoNegociacion']?.toString() ?? pujaActiva?.estadoPuja ?? '';
  }

  void actualizarUI() {
    Future.microtask(() { if (hasListeners) notifyListeners(); });
  }

  @override
  double get precioBaseAcordadoLimpio {
    if (pujaAceptada != null) return double.tryParse(pujaAceptada!.montoOfrecido.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    return double.tryParse(precioFinalDelBd.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  @override
  Future<void> guardarAdicionalesBd(List<Map<String, dynamic>> adicionales) async {
    GestorSesionGlobal.requerirAuth(() async {
      await ServicioNegociacionSupabase.actualizarAdicionales(idTrabajoReal, adicionales);
    });
  }

  bool get yaLlego {
    final bool gpsMarcado = soyElDueno ? (pujaAceptada?.coordenadasLlegada != null) : (miPuja?.coordenadasLlegada != null);
    return gpsMarcado || estadoActual == EstadoNegociacion.enCurso || estadoActual == EstadoNegociacion.finalizado;
  }
  
  bool get yaHizoCheckin => estadoActual == EstadoNegociacion.enCurso || estadoActual == EstadoNegociacion.finalizado || estadoActual == EstadoNegociacion.enDisputa;
  bool get completada => estadoActual == EstadoNegociacion.finalizado;
  bool get tratoFinalizado => estadoActual == EstadoNegociacion.finalizado;
  bool get tratoCancelado => estadoActual == EstadoNegociacion.cancelado;
  bool get clienteCalifico => resenaCerradaEnRam || jobData['cliente_califico'] == true || jobData['clienteCalifico'] == true;
  bool get proCalifico => resenaCerradaEnRam || jobData['pro_califico'] == true || jobData['proCalifico'] == true;

  ModeloPuja? get pujaAceptada {
    try { 
      return pujas.firstWhere((p) => 
        p.estadoPuja == 'esperando_confirmacion_pro' || 
        p.estadoPuja == 'esperando_pago_cliente' ||     
        p.estadoPuja == 'aceptada' || 
        p.estadoPuja == 'asignado' ||
        p.estadoPuja == 'en_curso' || 
        p.estadoPuja == 'esperando_pin_salida' || 
        p.estadoPuja == 'finalizada' || 
        p.estadoPuja == 'en_disputa' ||
        p.estadoPuja == 'cancelada_por_cliente' || 
        p.estadoPuja == 'cancelada_vista_pro' || 
        p.estadoPuja == 'cancelada_por_pro' ||       
        p.estadoPuja == 'cancelada_vista_cliente'    
      ); 
    } 
    catch (_) { return null; }
  }

  void _determinarContraparteFija() {
    contraparteIdFija = jobData['contraparte_id']?.toString() ?? '';
    
    if (contraparteIdFija.isEmpty || contraparteIdFija == 'null') {
      if (soyElDueno) {
        contraparteIdFija = pujaAceptada?.profesionalId ?? 
                            jobData['profesional_asignado_id']?.toString() ?? 
                            jobData['profesional_solicitado_id']?.toString() ?? '';
      } else {
        contraparteIdFija = jobData['ownerId']?.toString() ?? 
                            jobData['cliente_id']?.toString() ?? '';
      }
    }
  }

  Future<void> _cargarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('negociacion_cache_$idTrabajoReal');
      if (cacheStr != null && cacheStr.isNotEmpty) {
        final data = jsonDecode(cacheStr);
        if (data['jobData'] != null) {
          // 🛡️ SWR ABSOLUTO: La RAM sobreescribe ciegamente los datos "viejos" del enrutador.
          jobData = Map<String, dynamic>.from(data['jobData']);
          
          precioFinalDelBd = jobData['precio_final_acordado']?.toString() ?? jobData['price']?.toString() ?? '\$ 0';
          metodoPagoElegido = jobData['metodo_pago']?.toString() ?? '';
          _mapearEstadoStringAEnum(jobData['estado']?.toString() ?? 'abierto');
          
          dynamic adicData = jobData['adicionales_presupuesto'];
          if (adicData is String) { try { adicData = jsonDecode(adicData); } catch(_) { adicData = []; } }
          adicionalesPresupuesto = adicData is List ? List<Map<String, dynamic>>.from(adicData) : [];
        }
        if (data['pujas'] != null) {
          pujas = (data['pujas'] as List).map((p) => ModeloPuja.fromJson(p)).toList();
        }

        if (!soyElDueno) {
          try { miPuja = pujas.firstWhere((p) => p.profesionalId == miId); } catch (_) {}
        }
        
        if (pujaAceptada != null) {
          precioFinalDelBd = '\$ ${precioTotalConAdicionales.toStringAsFixed(0)}';
        }
      }
    } catch (e) {
      debugPrint('[SWR] Error leyendo disco local en Negociación: $e');
    }
  }

  // 🛡️ MÉTODO PÚBLICO: Permite a las extensiones disparar guardados inmediatos.
  Future<void> guardarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'jobData': jobData,
        'pujas': pujas.map((p) => p.toJson()).toList(),
      };
      await prefs.setString('negociacion_cache_$idTrabajoReal', jsonEncode(data));
    } catch (_) {}
  }

  void inicializar(Map<String, dynamic> data, String idUsuarioActual) {
    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }

    isLoading = true; 
    jobData = Map<String, dynamic>.from(data);
    miId = idUsuarioActual;
    soyElDueno = (jobData['ownerId']?.toString() ?? jobData['cliente_id']?.toString() ?? '') == miId;

    if (jobData['pujas'] != null) {
      try {
        pujas = (jobData['pujas'] as List).map((p) => ModeloPuja.fromJson(p)).toList();
      } catch (_) {}
    }

    _mapearEstadoStringAEnum(jobData['estado']?.toString() ?? 'abierto');
    _determinarContraparteFija();

    _cargarCacheSWR().then((_) {
      _determinarContraparteFija(); 

      if (!soyElDueno && miPuja == null) {
        final pujaIdFromData = jobData['pujaId']?.toString() ?? jobData['puja_id']?.toString() ?? '';
        final miOfertaFromData = jobData['miOferta']?.toString() ?? jobData['monto_ofrecido']?.toString() ?? '';
        if (pujaIdFromData.isNotEmpty || miOfertaFromData.isNotEmpty) {
          miPuja = ModeloPuja( id: pujaIdFromData.isNotEmpty ? pujaIdFromData : 'temp_$idTrabajoReal', profesionalId: miId, apodoProfesional: 'Yo', avatarUrl: '', rating: 0, reviews: 0, montoOfrecido: miOfertaFromData.isNotEmpty ? miOfertaFromData : '\$ 0', estadoPuja: jobData['estadoNegociacion']?.toString() ?? jobData['estado_puja']?.toString() ?? 'esperando' );
          if (pujas.isEmpty) pujas = [miPuja!];
        }
      }

      isLoading = false; 
      actualizarUI();
      
      Future.delayed(const Duration(milliseconds: 150), () {
        if (contraparteIdFija.isNotEmpty && estadoActual != EstadoNegociacion.abierto) {
          onRequerirAccionUI?.call('INICIALIZAR_CHAT', contraparteIdFija);
        }
      });

      cargarDatos(silencioso: true); 
      _iniciarMotorReactivoLocal();
    });
  }

  void marcarCalificacionLocalVisualmente() {
    if (soyElDueno) { jobData['cliente_califico'] = true; jobData['clienteCalifico'] = true; } 
    else {
      jobData['pro_califico'] = true; jobData['proCalifico'] = true;
      if (miPuja != null) miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'pro_califico_puja': true, 'proCalificoPuja': true});
    }
    actualizarUI();
    guardarCacheSWR(); 
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      cargarDatos(silencioso: true); 
      _iniciarMotorReactivoLocal(); 
    } else if (state == AppLifecycleState.paused) {
      _watchdogTimer?.cancel();
      _limpiarCanal(); 
    }
  }

  void _reiniciarWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 120), () {
      cargarDatos(silencioso: true);
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
        if (tabla == 'trabajos' && record['id'].toString() == idTrabajoReal.toString()) {
          jobData.addAll(record);
          if (record.containsKey('precio_final_acordado')) precioFinalDelBd = record['precio_final_acordado'].toString();
          if (record.containsKey('estado')) _mapearEstadoStringAEnum(record['estado'].toString());
          if (record.containsKey('adicionales_presupuesto')) {
            dynamic adicData = record['adicionales_presupuesto'];
            if (adicData is String) { try { adicData = jsonDecode(adicData); } catch(_) { adicData = []; } }
            adicionalesPresupuesto = adicData is List ? List<Map<String, dynamic>>.from(adicData) : [];
          }
          parcheAplicado = true;
        } else if (tabla == 'pujas' && record['trabajo_id'].toString() == idTrabajoReal.toString()) {
          final pujaId = record['id'].toString();
          final index = pujas.indexWhere((p) => p.id == pujaId);
          if (index != -1) {
            final pujaVieja = pujas[index];
            pujas[index] = ModeloPuja.fromJson({...pujaVieja.toJson(), ...record});
            if (miPuja?.id == pujaId) miPuja = pujas[index];
            parcheAplicado = true;
          }
        }
      }
    }

    if (parcheAplicado) {
      _determinarContraparteFija();
      actualizarUI();
      guardarCacheSWR(); 
      return; 
    }

    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      cargarDatos(silencioso: true);
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

  Future<void> _iniciarMotorReactivoLocal() async {
    await _limpiarCanal(); 

    _suscripcionLiveSupabase = Supabase.instance.client.channel('negociacion_live_$idTrabajoReal');

    _suscripcionLiveSupabase!
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'pujas', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'trabajo_id', value: idTrabajoReal.toString()), callback: _manejarEventoRealtime)
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'trabajos', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: idTrabajoReal.toString()), callback: _manejarEventoRealtime)
      .subscribe((RealtimeSubscribeStatus status, [Object? error]) { 
        if (status == RealtimeSubscribeStatus.subscribed) {
          _reiniciarWatchdog();
        } else if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
          if (_reconnectTimer?.isActive ?? false) return; 
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            cargarDatos(silencioso: true); 
            _iniciarMotorReactivoLocal(); 
          });
        }
      });

    _suscripcionGlobal?.cancel();
    try { _suscripcionGlobal = GestorSesionGlobal().streamEventos.listen((_) => cargarDatos(silencioso: true)); } catch (_) {}
  }

  void _mapearEstadoStringAEnum(String estado) {
    switch (estado) {
      case 'asignado': estadoActual = EstadoNegociacion.asignado; break;
      case 'en_curso': 
      case 'esperando_pin_salida': 
        estadoActual = EstadoNegociacion.enCurso; break;
      case 'finalizado': estadoActual = EstadoNegociacion.finalizado; break;
      case 'cancelado': estadoActual = EstadoNegociacion.cancelado; break;
      case 'en_disputa': estadoActual = EstadoNegociacion.enDisputa; break;
      default: estadoActual = EstadoNegociacion.abierto;
    }
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
    _suscripcionGlobal?.cancel();
    super.dispose();
  }

  Future<void> cargarDatos({bool silencioso = false}) async {
    if (!silencioso && miPuja == null && pujas.isEmpty) { isLoading = true; actualizarUI(); }
    try {
      final row = await ServicioNegociacionSupabase.obtenerTrabajoPorId(idTrabajoReal);
      final freshPujas = await ServicioNegociacionSupabase.obtenerPujas(idTrabajoReal);
      
      if (row == null || row.isEmpty) {
        throw Exception("Caída de red encubierta. Conservando memoria.");
      }

      if (freshPujas.isEmpty && pujas.isNotEmpty && (row['estado'] == 'asignado' || row['estado'] == 'en_curso' || row['estado'] == 'finalizado')) {
        throw Exception("Array de pujas corrupto por fallo de red.");
      }
      
      pujas = freshPujas;

      // Preserve local optimistic states
      final bool localClienteCalifico = jobData['cliente_califico'] == true || jobData['clienteCalifico'] == true;
      final bool localProCalifico = jobData['pro_califico'] == true || jobData['proCalifico'] == true;

      jobData.addAll(row);

      jobData['title'] = row['titulo'] ?? jobData['title'] ?? 'Trabajo';
      jobData['price'] = row['price'] ?? jobData['price'] ?? '\$ 0';
      
      // Restore optimistic states if DB hasn't caught up
      if (localClienteCalifico || row['cliente_califico'] == true) {
        jobData['cliente_califico'] = true;
        jobData['clienteCalifico'] = true;
      }
      if (localProCalifico || row['pro_califico'] == true) {
        jobData['pro_califico'] = true;
        jobData['proCalifico'] = true;
      }

      if (row['estado_negociacion'] != null) jobData['estado_negociacion'] = row['estado_negociacion']; 

      if (row['precio_final_acordado'] != null) precioFinalDelBd = row['precio_final_acordado'].toString();
      if (row['metodo_pago'] != null) metodoPagoElegido = row['metodo_pago'].toString();

      dynamic adicData = row['adicionales_presupuesto'];
      if (adicData is String) { try { adicData = jsonDecode(adicData); } catch(_) { adicData = []; } }
      adicionalesPresupuesto = adicData is List ? List<Map<String, dynamic>>.from(adicData) : [];

      if (pujaAceptada != null) precioFinalDelBd = '\$ ${precioTotalConAdicionales.toStringAsFixed(0)}';

      _mapearEstadoStringAEnum(row['estado']?.toString() ?? 'abierto');
      _determinarContraparteFija(); 
      
      procesarAlertasTickets(soyElDueno, (evento) => onRequerirAccionUI?.call(evento));
      
      if (soyElDueno && estadoActual == EstadoNegociacion.cancelado && jobData['estado_negociacion'] == 'cancelada_por_pro') {
          onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
            dominio: DominioApp.oficios,
            accion: TipoAccionCancelacion.avisoClienteCanceladoPorPro,
            actor: ActorCancelacion.cliente,
            onRepublicar: republicarTrabajoCliente,
            onEntendido: aceptarCancelacionCerrar,
          ));
      }
      
      if (!soyElDueno) {
        try { 
          final fetchedPuja = pujas.firstWhere((p) => p.profesionalId == miId); 
          if (miPuja == null || !miPuja!.id.startsWith('temp_')) miPuja = fetchedPuja;
          else if (fetchedPuja.id != miPuja!.id) miPuja = fetchedPuja;
        } catch (_) {}

        final bool fueCanceladoPorCliente = miPuja?.estadoPuja == 'cancelada_por_cliente' || 
                                            jobData['estado_negociacion'] == 'cancelada_por_cliente' || 
                                            jobData['estadoNegociacion'] == 'cancelada_por_cliente';
        
        final bool fueVistoPorPro = miPuja?.estadoPuja == 'cancelada_vista_pro' ||
                                    jobData['estado_negociacion'] == 'cancelada_vista_pro' || 
                                    jobData['estadoNegociacion'] == 'cancelada_vista_pro';

        final bool yoCancele = miPuja?.estadoPuja == 'cancelada_por_pro' || jobData['estado_negociacion'] == 'cancelada_por_pro';

        if (estadoActual != EstadoNegociacion.abierto && 
            miPuja?.estadoPuja != 'aceptada' && 
            miPuja?.estadoPuja != 'asignado' && 
            miPuja?.estadoPuja != 'en_curso' && 
            miPuja?.estadoPuja != 'esperando_pin_salida' && 
            miPuja?.estadoPuja != 'finalizada' && 
            miPuja?.estadoPuja != 'en_disputa' && 
            miPuja?.estadoPuja != 'esperando_confirmacion_pro' && 
            miPuja?.estadoPuja != 'esperando_pago_cliente' && 
            !fueCanceladoPorCliente && 
            !fueVistoPorPro && !yoCancele) {
          perdiElTrabajo = true;
        }

        if (yoCancele) {
           perdiElTrabajo = true; 
        }

        if (estadoActual == EstadoNegociacion.cancelado && fueCanceladoPorCliente && !fueVistoPorPro) {
           onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
             dominio: DominioApp.oficios,
             accion: TipoAccionCancelacion.avisoProCanceladoPorCliente,
             actor: ActorCancelacion.profesional,
             gananciaPro: gananciaProCancelacion,
             onEntendido: marcarCancelacionVistaPro,
           ));
        }
      }

      if (contraparteIdFija.isNotEmpty && estadoActual != EstadoNegociacion.abierto) {
         Future.delayed(const Duration(milliseconds: 100), () {
            onRequerirAccionUI?.call('INICIALIZAR_CHAT', contraparteIdFija);
         });
      }
      
      _reiniciarWatchdog();
      guardarCacheSWR(); 

    } catch (e) {
      debugPrint("[SWR] Fallo de red detectado. RAM protegida por la barrera.");
    } finally {
      isLoading = false; 
      actualizarUI();
    }
  }

  void abrirDisputaYMediar(String categoria, String solucionEsperada, String descripcion) {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; actualizarUI();
      try {
        final elOtro = soyElDueno ? pujaAceptada!.profesionalId : jobData['ownerId'].toString();
        await ServicioNegociacionSupabase.abrirDisputaYMediar(
          trabajoId: idTrabajoReal, 
          pujaId: pujaAceptada!.id, 
          reportadorId: miId, 
          reportadoId: elOtro, 
          categoria: categoria, 
          solucionEsperada: solucionEsperada, 
          descripcion: descripcion
        );
        estadoActual = EstadoNegociacion.enDisputa;
        if (miPuja != null) miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estado': 'en_disputa'});
        
        guardarCacheSWR();
        onRequerirAccionUI?.call('CERRAR_MODALES'); 
        onRequerirAccionUI?.call('NAVEGAR_SALA_MEDIACION', contraparteIdFija);
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'No se pudo procesar el reporte.');
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }

  void solicitarVerPoliticasCancelacion() {
    onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
      dominio: DominioApp.oficios,
      accion: TipoAccionCancelacion.verPoliticas,
      actor: soyElDueno ? ActorCancelacion.cliente : ActorCancelacion.profesional,
    ));
  }

  void solicitarCancelacionCliente() {
    try {
      final String fechaRaw = jobData['fecha_hora']?.toString() ?? jobData['fechaHora']?.toString() ?? jobData['date']?.toString() ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));

      final porcentajeRetencion = CalculadorPenalizaciones.calcularRetencionCliente(fechaSegura);
      final montoRetenido = CalculadorPenalizaciones.calcularMontoRetencion(precioTotalConAdicionales, porcentajeRetencion);

      onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
        dominio: DominioApp.oficios,
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

  void confirmarCancelacionClienteYReembolsar(double porcentajeRetencion) {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; actualizarUI();
      try {
        await ServicioNegociacionSupabase.cancelarTrabajoPorCliente(idTrabajoReal, pujaAceptada?.id);
        estadoActual = EstadoNegociacion.cancelado;
        jobData['estado_negociacion'] = 'cancelada_por_cliente'; 
        guardarCacheSWR();
        onRequerirAccionUI?.call('CERRAR_MODALES');
      } on PostgrestException catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error Base de Datos: ${e.message}');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error interno: ${e.toString()}');
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }

  double get gananciaProCancelacion {
    try {
      final String fechaRaw = jobData['fecha_hora']?.toString() ?? jobData['fechaHora']?.toString() ?? jobData['date']?.toString() ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));
      final distribucion = CalculadorPenalizaciones.calcularDistribucionCancelacion(fechaSegura, precioTotalConAdicionales);
      return distribucion['gananciaPro'] ?? 0.0;
    } catch (e) { return 0.0; }
  }

  void marcarCancelacionVistaPro() {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; actualizarUI();
      try {
        await ServicioNegociacionSupabase.marcarCancelacionVistaPorPro(idTrabajoReal, miPuja?.id);
        jobData['estado_negociacion'] = 'cancelada_vista_pro';
        jobData['estadoNegociacion'] = 'cancelada_vista_pro';
        if (miPuja != null) {
          miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estado': 'cancelada_vista_pro', 'estadoPuja': 'cancelada_vista_pro'});
        }
        guardarCacheSWR();
        ControladorActividadOficios().recargarSilenciosoGlobal();
      } on PostgrestException catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error Base de Datos: ${e.message}');
      } catch (e) {
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }

  void solicitarCancelacionPro() {
    try {
      final String fechaRaw = jobData['fecha_hora']?.toString() ?? jobData['fechaHora']?.toString() ?? jobData['date']?.toString() ?? '';
      DateTime? fechaPactada;
      if (fechaRaw.isNotEmpty) fechaPactada = DateTime.tryParse(fechaRaw);
      final fechaSegura = fechaPactada ?? DateTime.now().add(const Duration(days: 3));
      
      final puntos = CalculadorPenalizaciones.calcularPuntosPenalizacionPro(fechaSegura);
      
      onRequerirAccionUI?.call('MOSTRAR_MODAL_CANCELACION', CancelacionContexto(
        dominio: DominioApp.oficios,
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
      isProcessing = true; actualizarUI();
      try {
        await ServicioNegociacionSupabase.cancelarTrabajoPorPro(idTrabajoReal, miPuja!.id, miId, puntos);
        
        estadoActual = EstadoNegociacion.cancelado;
        jobData['estado_negociacion'] = 'cancelada_por_pro';
        if (miPuja != null) {
          miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estado': 'cancelada_por_pro', 'estadoPuja': 'cancelada_por_pro'});
        }
        perdiElTrabajo = true;
        guardarCacheSWR();
        ControladorActividadOficios().recargarSilenciosoGlobal();
        onRequerirAccionUI?.call('CERRAR_MODALES');
      } on PostgrestException catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error DB: ${e.message}');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error interno al cancelar.');
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }

  void republicarTrabajoCliente() {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; actualizarUI();
      try {
        await ServicioNegociacionSupabase.republicarTrabajo(idTrabajoReal);
        
        estadoActual = EstadoNegociacion.cancelado;
        jobData['estado_negociacion'] = 'cancelada_vista_cliente';
        guardarCacheSWR();
        ControladorActividadOficios().recargarSilenciosoGlobal();
        
        onRequerirAccionUI?.call('CERRAR_MODALES');
        onRequerirAccionUI?.call('MOSTRAR_MENSAJE_EXITO', '¡Trabajo republicado! Tienes una nueva tarjeta idéntica en tu muro.');
        
        onRequerirAccionUI?.call('CERRAR_PANTALLA');
      } on PostgrestException catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error DB: ${e.message}');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'No se pudo republicar.');
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }

  void aceptarCancelacionCerrar() {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true; actualizarUI();
      try {
        await ServicioNegociacionSupabase.aceptarCancelacionYCerrar(idTrabajoReal);
        jobData['estado_negociacion'] = 'cancelada_vista_cliente';
        guardarCacheSWR();
        ControladorActividadOficios().recargarSilenciosoGlobal();
        onRequerirAccionUI?.call('CERRAR_MODALES');
      } on PostgrestException catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error DB: ${e.message}');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'No se pudo actualizar.');
      } finally {
        isProcessing = false; actualizarUI();
      }
    });
  }
}