// lib/5_modulos/modulo_negociacion_oficios/controladores/extension_negociacion_ofertas.dart

import 'dart:async';
// import 'package:flutter/foundation.dart';
import 'controlador_negociacion.dart';
import '../servicios/servicio_negociacion_supabase.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../3_modelos/modelo_puja.dart';
import 'package:uuid/uuid.dart';

extension ExtensionNegociacionOfertas on ControladorNegociacion {
  
  Future<void> enviarModificarPresupuesto(String montoFormateado) async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      // 🛡️ CORRECCIÓN: Restauramos el Regex original para limpiar el string antes de parsearlo a double
      final double montoReal = double.tryParse(montoFormateado.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final String montoVisual = '\$ ${montoReal.toStringAsFixed(0)}';
      
      final String pujaId = miPuja?.id ?? 'temp_${idTrabajoReal}_$miId';
      final bool isNew = miPuja == null;
      final ModeloPuja? pujaAnterior = miPuja != null ? ModeloPuja.fromJson(miPuja!.toJson()) : null;

      // 🛡️ 1. OPTIMISTIC UI (0ms)
      if (isNew) {
         miPuja = ModeloPuja(id: pujaId, profesionalId: miId, apodoProfesional: 'Yo', avatarUrl: '', rating: 0, reviews: 0, montoOfrecido: montoVisual, estadoPuja: 'esperando');
         pujas.insert(0, miPuja!);
      } else {
         final int index = pujas.indexWhere((p) => p.id == pujaId);
         if (index != -1) {
           pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'monto': montoReal, 'montoOfrecido': montoVisual, 'estado': 'esperando', 'estadoPuja': 'esperando'});
           miPuja = pujas[index];
         }
      }
      
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED (Silencioso)
        if (isNew || pujaId.startsWith('temp_')) {
           await ServicioNegociacionSupabase.insertarPuja(idTrabajoReal, miId, montoReal);
           cargarDatos(silencioso: true);
        } else {
           await ServicioNegociacionSupabase.actualizarMontoPuja(pujaId, montoReal);
        }
        onRequerirAccionUI?.call('MOSTRAR_MENSAJE_EXITO', 'Presupuesto enviado exitosamente');
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        if (isNew) {
           pujas.removeWhere((p) => p.id == pujaId);
           miPuja = null;
        } else {
           final int index = pujas.indexWhere((p) => p.id == pujaId);
           if (index != -1 && pujaAnterior != null) {
              pujas[index] = pujaAnterior;
              miPuja = pujaAnterior;
           }
        }
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo de conexión. Se revirtieron los cambios.'));
      }
    });
    return completer.future;
  }

  Future<void> aceptarOferta(ModeloPuja puja, String metodoPago) async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      final String pujaId = puja.id;
      final EstadoNegociacion estadoAnterior = estadoActual;
      final ModeloPuja pujaAnterior = ModeloPuja.fromJson(puja.toJson());

      // 🛡️ 1. OPTIMISTIC UI
      final int index = pujas.indexWhere((p) => p.id == pujaId);
      if (index != -1) {
        pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estado': 'esperando_confirmacion_pro', 'estadoPuja': 'esperando_confirmacion_pro'});
      }
      estadoActual = EstadoNegociacion.abierto; 
      jobData['metodo_pago'] = metodoPago;
      
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED
        await ServicioNegociacionSupabase.solicitarConfirmacionPro(idTrabajoReal, pujaId, metodoPago);
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        estadoActual = estadoAnterior;
        if (index != -1) pujas[index] = pujaAnterior;
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo de conexión. Se revirtieron los cambios.'));
      }
    });
    return completer.future;
  }

  Future<void> aceptarTrabajoPro() async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      if (miPuja == null) { completer.completeError(Exception('No hay puja')); return; }
      final String pujaId = miPuja!.id;
      final ModeloPuja pujaAnterior = ModeloPuja.fromJson(miPuja!.toJson());

      // 🛡️ 1. OPTIMISTIC UI
      final int index = pujas.indexWhere((p) => p.id == pujaId);
      if (index != -1) {
        pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estado': 'esperando_pago_cliente', 'estadoPuja': 'esperando_pago_cliente'});
        miPuja = pujas[index];
      }
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED
        await ServicioNegociacionSupabase.actualizarEstadoPuja(pujaId, 'esperando_pago_cliente');
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        if (index != -1) pujas[index] = pujaAnterior;
        miPuja = pujaAnterior;
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo de conexión. Se revirtieron los cambios.'));
      }
    });
    return completer.future;
  }

  Future<void> rechazarTrabajoPro() async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      if (miPuja == null) { completer.completeError(Exception('No hay puja')); return; }
      final String pujaId = miPuja!.id;
      final ModeloPuja pujaAnterior = ModeloPuja.fromJson(miPuja!.toJson());

      // 🛡️ 1. OPTIMISTIC UI
      final int index = pujas.indexWhere((p) => p.id == pujaId);
      if (index != -1) {
        pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estado': 'rechazada_por_pro', 'estadoPuja': 'rechazada_por_pro'});
        miPuja = pujas[index];
      }
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED
        await ServicioNegociacionSupabase.rechazarTratoPorPro(pujaId);
        onRequerirAccionUI?.call('CERRAR_PANTALLA');
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        if (index != -1) pujas[index] = pujaAnterior;
        miPuja = pujaAnterior;
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo de conexión. Se revirtieron los cambios.'));
      }
    });
    return completer.future;
  }

  Future<void> ocultarPujaRechazada(ModeloPuja puja) async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      final String pujaId = puja.id;
      final ModeloPuja pujaAnterior = ModeloPuja.fromJson(puja.toJson());

      // 🛡️ 1. OPTIMISTIC UI
      final int index = pujas.indexWhere((p) => p.id == pujaId);
      if (index != -1) {
        pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'mensaje': 'ELIMINADA_POR_CLIENTE'});
      }
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED
        await ServicioNegociacionSupabase.eliminarPujaVisualmenteParaCliente(pujaId);
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        if (index != -1) pujas[index] = pujaAnterior;
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo al ocultar puja.'));
      }
    });
    return completer.future;
  }

  Future<void> rechazarOferta(ModeloPuja puja) async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      final String pujaId = puja.id;
      final ModeloPuja pujaAnterior = ModeloPuja.fromJson(puja.toJson());

      // 🛡️ 1. OPTIMISTIC UI
      final int index = pujas.indexWhere((p) => p.id == pujaId);
      if (index != -1) {
        pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estado': 'rechazada_por_cliente', 'estadoPuja': 'rechazada_por_cliente'});
      }
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED
        await ServicioNegociacionSupabase.actualizarEstadoPuja(pujaId, 'rechazada_por_cliente');
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        if (index != -1) pujas[index] = pujaAnterior;
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo al rechazar oferta.'));
      }
    });
    return completer.future;
  }

  Future<void> cancelarTrabajo() async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      if (miPuja == null) { completer.completeError(Exception('No hay puja')); return; }
      final String pujaId = miPuja!.id;
      final ModeloPuja pujaAnterior = ModeloPuja.fromJson(miPuja!.toJson());
      final bool isTemp = pujaId.startsWith('temp_');

      // 🛡️ 1. OPTIMISTIC UI
      final int index = pujas.indexWhere((p) => p.id == pujaId);
      if (index != -1) pujas.removeAt(index);
      miPuja = null;
      
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED
        if (!isTemp) await ServicioNegociacionSupabase.eliminarPuja(pujaId);
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        if (index != -1) pujas.insert(index, pujaAnterior);
        else pujas.add(pujaAnterior);
        miPuja = pujaAnterior;
        
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo de conexión. Se revirtieron los cambios.'));
      }
    });
    return completer.future;
  }

  // 🛡️ EL MÉTODO DEL MIDDLEWARE FINANCIERO QUE FALTABA (AGREGADO Y BLINDADO)
  Future<void> confirmarPagoYLiberarContrato() async {
    final completer = Completer<void>();
    GestorSesionGlobal.requerirAuth(() async {
      if (pujaAceptada == null) { completer.completeError(Exception('No hay puja aceptada')); return; }
      
      final String pujaId = pujaAceptada!.id;
      final EstadoNegociacion estadoAnterior = estadoActual;
      final ModeloPuja pujaAnterior = ModeloPuja.fromJson(pujaAceptada!.toJson());
      final Map<String, dynamic> jobDataAnterior = Map<String, dynamic>.from(jobData);

      final String genCheckin = const Uuid().v4().substring(0, 6).toUpperCase();
      final String genCheckout = const Uuid().v4().substring(0, 6).toUpperCase();
      
      // 🛡️ 1. OPTIMISTIC UI (0ms)
      final int index = pujas.indexWhere((p) => p.id == pujaId);
      if (index != -1) {
        pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estado': 'aceptada', 'estadoPuja': 'aceptada', 'codigo_checkin': genCheckin, 'codigo_checkout': genCheckout});
      }
      estadoActual = EstadoNegociacion.asignado;
      jobData['estado'] = 'asignado';
      jobData['estado_negociacion'] = 'asignado';
      
      guardarCacheSWR();
      actualizarUI();

      try {
        // 2. RED Y GENERACIÓN DE PINES
        await ServicioNegociacionSupabase.confirmarTratoPorPro(idTrabajoReal, pujaId, genCheckin, genCheckout);
        onRequerirAccionUI?.call('INICIALIZAR_CHAT', contraparteIdFija);
        cargarDatos(silencioso: true);
        completer.complete();
      } catch (e) {
        // 🚨 3. ROLLBACK
        estadoActual = estadoAnterior;
        jobData = jobDataAnterior;
        if (index != -1) pujas[index] = pujaAnterior;
        
        guardarCacheSWR();
        actualizarUI();
        cargarDatos(silencioso: true);
        completer.completeError(Exception('Fallo al confirmar el pago. Los fondos serán devueltos.'));
      }
    });
    return completer.future;
  }
}