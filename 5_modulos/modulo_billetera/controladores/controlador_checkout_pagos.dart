// lib/5_modulos/modulo_billetera/controladores/controlador_checkout_pagos.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../servicios/servicio_checkout_supabase.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

class ControladorCheckoutPagos extends ChangeNotifier with WidgetsBindingObserver {
  bool isSubmitting = false;
  bool _disposed = false;

  Timer? _watchdogTimer;
  RealtimeChannel? _suscripcionLive;

  String? _llaveIdempotenciaActiva;
  VoidCallback? _onCompletadoCallback;
  Function(String)? _onFallidoCallback;
  VoidCallback? _onPendienteCallback; // NUEVA VARIABLE INYECTADA
  bool _isObserverAdded = false;

  ControladorCheckoutPagos() {
    WidgetsBinding.instance.addObserver(this);
    _isObserverAdded = true;
  }

  @override
  void dispose() {
    _disposed = true;
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _destruirWatchdog();
    _limpiarCanal();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void _destruirWatchdog() {
    if (_watchdogTimer != null && _watchdogTimer!.isActive) {
      _watchdogTimer!.cancel();
    }
    _watchdogTimer = null;
  }

  Future _limpiarCanal() async {
    if (_suscripcionLive != null) {
      try {
        await _suscripcionLive!.unsubscribe();
        await Supabase.instance.client.removeChannel(_suscripcionLive!);
      } catch (_) {}
      _suscripcionLive = null;
    }
  }


  /// Inicia la intención de pago abriendo el Posnet Virtual
  void procesarPago({
    required String trabajoId,
    required double monto,
    required String metodoPago,
    required Function(Map<String, dynamic> datosPasarela) onSuccess,
    required Function(String error) onError,
  }) {
    // 🛡️ DICTADURA DEL AUTH-GUARD
    GestorSesionGlobal.requerirAuth(() async {
      if (isSubmitting || _disposed) return;

      isSubmitting = true;
      notifyListeners();

      try {
        final usuarioId = GestorSesionGlobal().miIdUsuario;
        if (usuarioId.isEmpty) throw Exception('Acceso denegado: Sesión inválida.');

        // 🚨 INMUTABILIDAD DE IDEMPOTENCIA
        final String llaveIdempotencia = const Uuid().v4();

        final respuestaPasarela = await ServicioCheckoutSupabase.crearIntencionPago(
          usuarioId: usuarioId,
          trabajoId: trabajoId,
          monto: monto,
          llaveIdempotencia: llaveIdempotencia,
          metodoPago: metodoPago,
        );

        if (_disposed) return;

        // 🚨 ADAPTADOR AGNÓSTICO: Navegador Externo para evitar cierre de app
        final urlPago = respuestaPasarela['url_pago']?.toString();
        if (urlPago != null && urlPago.isNotEmpty) {
          try {
            final uri = Uri.parse(urlPago);
            final puedeAbrir = await canLaunchUrl(uri);
            if (!puedeAbrir) {
              throw Exception('El dispositivo no soporta o bloqueó la apertura del navegador seguro.');
            }
            
            // Abre en el navegador EXTERNO para que el sistema no mate la app por memoria
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            _destruirWatchdog();
            throw Exception('Error al abrir la pasarela de pago: $e');
          }
        }

        respuestaPasarela['llave_idempotencia'] = llaveIdempotencia;
        onSuccess(respuestaPasarela);
      } catch (e) {
        onError(e.toString().replaceAll('Exception: ', ''));
      } finally {
        if (!_disposed) {
          isSubmitting = false;
          notifyListeners();
        }
      }
    });
  }

  /// Inicia la escucha por Sockets del Webhook de la Pasarela
  void observarEstadoAsincrono({
    required String llaveIdempotencia,
    required VoidCallback onCompletado,
    required Function(String error) onFallido,
    required VoidCallback onPendiente,
  }) {
    _llaveIdempotenciaActiva = llaveIdempotencia;
    _onCompletadoCallback = onCompletado;
    _onFallidoCallback = onFallido;
    _onPendienteCallback = onPendiente;

    _iniciarMotorReactivoLocal();
  }

  /// 🚨 ARQUITECTURA REALTIME V3.2
  void _iniciarMotorReactivoLocal() async {
    if (_llaveIdempotenciaActiva == null || _disposed) return;

    await _limpiarCanal();
    if (_disposed) return;

    _suscripcionLive = Supabase.instance.client.channel('pago_$_llaveIdempotenciaActiva');

    _suscripcionLive!
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'wallet_transactions',
            filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'llave_idempotencia',
                value: _llaveIdempotenciaActiva!
            ),
            callback: _manejarEventoRealtime)
        .subscribe((RealtimeSubscribeStatus status, [Object? error]) {
      if (_disposed) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        _iniciarWatchdog(); // Arranca el salvavidas al conectarse
      }
    });
  }

  void _manejarEventoRealtime(PostgresChangePayload payload) {
    if (_disposed) return;
    _iniciarWatchdog(); 

    final record = payload.newRecord;
    if (record != null) {
      final estado = record['estado']?.toString();
      _evaluarEstado(estado);
    }
  }

  void _iniciarWatchdog() {
    _destruirWatchdog(); 
    if (_disposed) return;
    // 🚨 SALVAVIDAS GENUINO DE 120s
    _watchdogTimer = Timer(const Duration(seconds: 120), () async {
      if (_disposed) return;
      _destruirWatchdog();
      await _limpiarCanal();
      if (_disposed) return;
      _ejecutarFetchSilencioso(esTimeout: true);
    });
  }

  Future _ejecutarFetchSilencioso({bool esTimeout = false}) async {
    if (_llaveIdempotenciaActiva == null || _disposed) return;

    try {
      final estado = await ServicioCheckoutSupabase.verificarEstadoTransaccion(_llaveIdempotenciaActiva!);
      if (_disposed) return;
      _evaluarEstado(estado, esTimeout: esTimeout);
    } catch (e) {
      if (_disposed) return;
      if (esTimeout) {
        _onFallidoCallback?.call('Tiempo de espera agotado y error de conexión al validar.');
        _limpiarCallbacks();
      }
    }
  }

  void _evaluarEstado(String? estado, {bool esTimeout = false}) {
    if (_disposed) return;
    if (estado == 'completado') {
      _destruirWatchdog();
      _limpiarCanal();
      _onCompletadoCallback?.call();
      _limpiarCallbacks();
    } else if (estado == 'fallido' || estado == 'reembolsado' || estado == 'en_disputa') {
      _destruirWatchdog();
      _limpiarCanal();
      _onFallidoCallback?.call('La transacción fue rechazada, cancelada o bloqueada por la pasarela.');
      _limpiarCallbacks();
    } else if (esTimeout) {
      // Sigue pendiente después de 120s
      _onFallidoCallback?.call('Tiempo de espera agotado. Validaremos el pago en segundo plano.');
      _limpiarCallbacks();
    }
  }

  void _limpiarCallbacks() {
    _llaveIdempotenciaActiva = null;
    _onCompletadoCallback = null;
    _onFallidoCallback = null;
    _onPendienteCallback = null;
  }

  /// 🚨 CONSCIENCIA DE HARDWARE: LA TRAMPA DEL CICLO DE VIDA (Lifecycle Sync)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Usuario fue al InAppBrowser o minimizó la app. 
      // Delegamos la destrucción a la cola de eventos (microtask) para evitar Deadlocks (App Freeze).
      Future.microtask(() {
        if (_disposed) return;
        _destruirWatchdog();
        _limpiarCanal();
      });
    } else if (state == AppLifecycleState.resumed) {
      // El usuario regresó a la App.
      if (_llaveIdempotenciaActiva != null) {
        // Reconectamos el socket porque lo cerramos al pausar.
        _iniciarMotorReactivoLocal();
        
        // Esperamos 2 segundos por si Mercado Pago está terminando de procesar.
        Future.delayed(const Duration(seconds: 2), () {
          if (_disposed) return;
          if (_llaveIdempotenciaActiva != null) {
            _ejecutarFetchSilencioso().then((_) {
              if (_disposed) return;
              if (_llaveIdempotenciaActiva != null) {
                // 🚨 ABANDONO PACÍFICO: Sigue pendiente. NO destruimos el socket ciegamente. Delegamos la UI.
                _onPendienteCallback?.call();
              }
            });
          }
        });
      }
    }
  }
}