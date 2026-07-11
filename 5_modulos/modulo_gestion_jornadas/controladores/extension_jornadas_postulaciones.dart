// lib/5_modulos/modulo_gestion_jornadas/controladores/extension_jornadas_postulaciones.dart

import 'dart:math';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controlador_jornadas.dart';
import '../servicios/servicio_gestion_jornadas_supabase.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../1_nucleo/gestor_sincronizacion_offline.dart';
import 'controlador_actividad_jornadas.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart'; 

extension PostulacionesJornadas on ControladorJornadas {
  
  void postularse() { 
    if (GestorSesionGlobal().esInvitado) { GestorSesionGlobal.requerirAuth(() {}); return; }

    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    miPuja = ModeloPuja(id: 'temp_${DateTime.now().millisecondsSinceEpoch}', profesionalId: miId, apodoProfesional: 'Yo', avatarUrl: '', rating: 0, reviews: 0, montoOfrecido: sueldoNumerico.toString(), estadoPuja: 'esperando');
    pujas.insert(0, miPuja!); 
    guardarCacheSWR();
    actualizarUI(); 

    OfflineSyncManager.ejecutarBajoCapot(
      operacionRed: () async { 
        try {
          await ServicioGestionJornadasSupabase.insertarPujaJornada(trabajoId: trabajoId, profesionalId: miId, monto: sueldoNumerico.toString(), duenoId: clienteId); 
          ControladorActividadJornadas().recargarSilenciosoGlobal(); 
          await cargarDatosSilencioso(); 
        } on PostgrestException catch (e) {
          if (e.code == '23503' || e.message.toLowerCase().contains('not found')) {
            notificarUI('Esta publicación ya no está disponible o fue eliminada.', esError: true);
            await Future.delayed(const Duration(seconds: 2));
            onRequerirAccionUI?.call('cerrar_pantalla', true);
            return; 
          }
          throw e; 
        }
      },
      revertirEstado: () { 
        // 🚨 3. ROLLBACK
        pujas.removeWhere((p) => p.id.startsWith('temp')); 
        miPuja = null; 
        guardarCacheSWR();
        actualizarUI(); 
        notificarUI('Sin conexión. No se pudo postular.', esError: true); 
      }
    );
  }

  void retirarPostulacion() {
    if (GestorSesionGlobal().esInvitado || miPuja == null) return;
    
    final pujaGuardada = miPuja; 

    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    pujas.removeWhere((p) => p.id == miPuja!.id); 
    miPuja = null; 
    guardarCacheSWR();
    actualizarUI();
    onRequerirAccionUI?.call('cerrar_pantalla', null);

    OfflineSyncManager.ejecutarBajoCapot(
      operacionRed: () async { 
        if (!pujaGuardada!.id.startsWith('temp')) { await ServicioGestionJornadasSupabase.retirarPuja(pujaGuardada.id); }
        ControladorActividadJornadas().recargarSilenciosoGlobal(); 
      }, 
      revertirEstado: () { 
        // 🚨 3. ROLLBACK
        miPuja = pujaGuardada; 
        pujas.insert(0, miPuja!); 
        guardarCacheSWR();
        actualizarUI(); 
      }
    );
  }

  void contratarProfesional(ModeloPuja puja) {
    if (GestorSesionGlobal().esInvitado) { GestorSesionGlobal.requerirAuth(() {}); return; }

    final index = pujas.indexWhere((p) => p.id == puja.id);
    final pujaAnterior = ModeloPuja.fromJson(puja.toJson());
    
    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    if (index != -1) {
      pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estadoPuja': 'esperando_confirmacion_pro'});
      guardarCacheSWR();
      actualizarUI();
    }
    
    OfflineSyncManager.ejecutarBajoCapot(
      operacionRed: () async { 
        await ServicioGestionJornadasSupabase.contratarProfesional(puja.id, puja.profesionalId, clienteId, trabajoId); 
        ControladorActividadJornadas().recargarSilenciosoGlobal(); 
        cargarDatosSilencioso(); 
      }, 
      revertirEstado: () {
        // 🚨 3. ROLLBACK
        if (index != -1) {
          pujas[index] = pujaAnterior;
          guardarCacheSWR();
          actualizarUI();
        }
        cargarDatosSilencioso();
      }
    );
  }

  Future<void> aceptarContratacionPro() async {
    final completer = Completer<void>();
    if (GestorSesionGlobal().esInvitado || miPuja == null) { completer.complete(); return completer.future; }

    final index = pujas.indexWhere((p) => p.id == miPuja!.id);
    final pujaAnterior = ModeloPuja.fromJson(miPuja!.toJson());

    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estadoPuja': 'esperando_pago_cliente'});
    if (index != -1) pujas[index] = miPuja!;
    guardarCacheSWR();
    actualizarUI();

    try {
      // 2. RED (Silencioso)
      await ServicioGestionJornadasSupabase.aceptarContratacionPro(miPuja!.id, miId, clienteId, trabajoId);
      ControladorActividadJornadas().recargarSilenciosoGlobal();
      notificarUI('Disponibilidad confirmada. Esperando el pago del cliente.');
      completer.complete();
    } catch (e) {
      // 🚨 3. BARRERA DE ROLLBACK
      miPuja = pujaAnterior;
      if (index != -1) pujas[index] = pujaAnterior;
      guardarCacheSWR();
      actualizarUI();
      cargarDatosSilencioso();
      notificarUI('Error de red al aceptar.', esError: true);
      completer.completeError(e);
    } 
    return completer.future;
  }

  Future<void> confirmarPagoYLiberarTurno(ModeloPuja puja) async {
    final completer = Completer<void>();
    isProcessing = true; actualizarUI();
    
    final String genCheckin = (Random().nextInt(900000) + 100000).toString();
    final String genCheckout = (Random().nextInt(900000) + 100000).toString();

    final index = pujas.indexWhere((p) => p.id == puja.id);
    final pujaAnterior = ModeloPuja.fromJson(puja.toJson());

    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    if (index != -1) {
      pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estadoPuja': 'aceptada', 'mensaje': 'CONFIRMADO_PRO', 'codigo_checkin': genCheckin, 'codigo_checkout': genCheckout});
      guardarCacheSWR();
      actualizarUI();
    }

    try {
      // 2. RED Y GENERACIÓN DE PINES
      await ServicioGestionJornadasSupabase.confirmarPagoYLiberarTurno(puja.id, puja.profesionalId, clienteId, trabajoId, genCheckin, genCheckout);
      ControladorActividadJornadas().recargarSilenciosoGlobal();
      onRequerirAccionUI?.call('inicializar_chat', puja.profesionalId);
      notificarUI('¡Pago exitoso! El turno está confirmado y el chat liberado.', esError: false);
      completer.complete();
    } catch (e) {
      // 🚨 3. BARRERA DE ROLLBACK
      if (index != -1) pujas[index] = pujaAnterior;
      guardarCacheSWR();
      notificarUI('Error de red al confirmar la liberación.', esError: true);
      completer.completeError(e);
    } finally {
      isProcessing = false; actualizarUI(); cargarDatosSilencioso();
    }
    return completer.future;
  }

  Future<void> rechazarContratacionPro() async {
    final completer = Completer<void>();
    if (GestorSesionGlobal().esInvitado || miPuja == null) { completer.complete(); return completer.future; }
    
    final index = pujas.indexWhere((p) => p.id == miPuja!.id);
    final pujaAnterior = ModeloPuja.fromJson(miPuja!.toJson());

    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estadoPuja': 'rechazada_por_pro'});
    if (index != -1) pujas[index] = miPuja!;
    guardarCacheSWR();
    actualizarUI();

    try {
      // 2. RED
      await ServicioGestionJornadasSupabase.rechazarContratacionPro(miPuja!.id, clienteId, trabajoId);
      ControladorActividadJornadas().recargarSilenciosoGlobal();
      onRequerirAccionUI?.call('cerrar_pantalla', null);
      notificarUI('Has rechazado la solicitud.', esAdvertencia: true);
      completer.complete();
    } catch (e) {
      // 🚨 3. ROLLBACK
      miPuja = pujaAnterior;
      if (index != -1) pujas[index] = pujaAnterior;
      guardarCacheSWR();
      actualizarUI();
      cargarDatosSilencioso();
      notificarUI('Error al rechazar.', esError: true);
      completer.completeError(e);
    }
    return completer.future;
  }

  Future<void> rechazarPostulante(ModeloPuja puja) async {
    final completer = Completer<void>();
    if (GestorSesionGlobal().esInvitado) { completer.complete(); return completer.future; }
    
    final index = pujas.indexWhere((p) => p.id == puja.id);
    final pujaAnterior = ModeloPuja.fromJson(puja.toJson());

    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    if (index != -1) {
      pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'mensaje': 'ELIMINADA_POR_CLIENTE'});
      guardarCacheSWR();
      actualizarUI();
    }

    try { 
      // 2. RED
      await ServicioGestionJornadasSupabase.eliminarPujaVisualmenteParaCliente(puja.id); 
      ControladorActividadJornadas().recargarSilenciosoGlobal(); 
      completer.complete();
    } catch(e) {
      // 🚨 3. ROLLBACK
      if (index != -1) pujas[index] = pujaAnterior;
      guardarCacheSWR();
      actualizarUI();
      completer.completeError(e);
    } finally { 
      await cargarDatosSilencioso(); 
    }
    return completer.future;
  }

  Future<void> deshacerRechazoPostulante(ModeloPuja puja) async {}

  Future<void> desestimarProfesional(ModeloPuja p) async {
    final completer = Completer<void>();
    if (GestorSesionGlobal().esInvitado) { completer.complete(); return completer.future; }
    
    final index = pujas.indexWhere((puja) => puja.id == p.id);
    final pujaAnterior = ModeloPuja.fromJson(p.toJson());

    // 🛡️ 1. OPTIMISTIC UI ABSOLUTA (0ms)
    if (index != -1) {
      pujas[index] = ModeloPuja.fromJson({...pujas[index].toJson(), 'estadoPuja': 'desestimada', 'rechazadoPorCliente': true});
      guardarCacheSWR();
      actualizarUI();
    }

    try { 
      // 2. RED
      await ServicioGestionJornadasSupabase.desestimarProfesionalContratado(p.id, p.profesionalId, clienteId, sueldoNumerico * 0.05, trabajoId); 
      ControladorActividadJornadas().recargarSilenciosoGlobal(); 
      completer.complete();
    } catch(e) {
      // 🚨 3. ROLLBACK
      if (index != -1) pujas[index] = pujaAnterior;
      guardarCacheSWR();
      actualizarUI();
      completer.completeError(e);
    } finally { 
      await cargarDatosSilencioso(); 
    }
    return completer.future;
  }
}