// lib/5_modulos/modulo_gestion_jornadas/controladores/extension_jornadas_ejecucion.dart

import 'controlador_jornadas.dart';
import '../servicios/servicio_gestion_jornadas_supabase.dart';
import '../../../1_nucleo/servicios/servicio_gps_localizacion.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../3_modelos/modelo_resena_payload.dart';
import 'controlador_actividad_jornadas.dart';

extension EjecucionJornadas on ControladorJornadas {
  
  Future<void> validarCheckInPro(ModeloPuja p, String pinIngresado) async {
    if (p.codigoCheckin != pinIngresado.trim()) { 
      notificarUI('El PIN de llegada es incorrecto.', esError: true); 
      return; 
    }
    isProcessing = true; actualizarUI(); 
    try {
      await ServicioGestionJornadasSupabase.validarCheckInPro(p.id, trabajoId, clienteId, miId);
      miPuja = ModeloPuja.fromJson({...p.toJson(), 'estadoPuja': 'en_curso'});
      actualizarUI();
      ControladorActividadJornadas().recargarSilenciosoGlobal();
      notificarUI('✅ Check-In exitoso. Jornada en curso.');
    } catch (e) {
      notificarUI('Error de conexión.', esError: true);
    } finally {
      isProcessing = false; actualizarUI();
    }
  }

  Future<void> solicitarCheckOutPro() async {
    isProcessing = true; actualizarUI();
    try {
      await ServicioGestionJornadasSupabase.solicitarCheckOutPro(miPuja!.id, trabajoId, clienteId);
      miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estadoPuja': 'esperando_pin_salida'});
      actualizarUI();
      ControladorActividadJornadas().recargarSilenciosoGlobal();
    } catch (e) {
      notificarUI('Error de conexión.', esError: true);
    } finally {
      isProcessing = false; actualizarUI();
    }
  }

  Future<void> validarCheckOutPro(ModeloPuja p, String pinIngresado) async {
    if (p.codigoCheckout != pinIngresado.trim()) { 
      notificarUI('El PIN de salida es incorrecto.', esError: true); 
      return; 
    }
    isProcessing = true; actualizarUI();
    try {
      await ServicioGestionJornadasSupabase.validarCheckOutPro(p.id, trabajoId, clienteId, miId);
      miPuja = ModeloPuja.fromJson({...p.toJson(), 'estadoPuja': 'finalizada'});
      
      actualizarUI();
      ControladorActividadJornadas().recargarSilenciosoGlobal();
      notificarUI('🏁 Check-Out validado. Tu turno finalizó.');
    } catch (e) {
      notificarUI('Error de conexión.', esError: true);
    } finally {
      isProcessing = false; actualizarUI();
    }
  }

  Future<void> registrarLlegadaGPS(Function onGpsDisabled) async {
    isProcessing = true; actualizarUI();
    try {
      final pos = await ServicioGpsLocalizacion.obtenerCoordenadasActuales();
      await ServicioGestionJornadasSupabase.registrarLlegadaGPS(miPuja!.id, '${pos.latitude}, ${pos.longitude}', clienteId, trabajoId);
      miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'coordenadasLlegada': '${pos.latitude}, ${pos.longitude}'});
      actualizarUI();
      notificarUI('Llegada registrada. Pídele el PIN al cliente para confirmar.');
    } catch (e) {
      if (e.toString().contains('gps_disabled') || e.toString().contains('permissions_denied')) {
        onGpsDisabled(); 
      } else {
        notificarUI('Error al obtener ubicación.', esError: true);
      }
    } finally { 
      isProcessing = false; actualizarUI(); 
    }
  }

  // 🛡️ REFACTOR MÓDULO MEDIACIÓN: Ya no necesitamos el viejo 'abrirDisputa' aquí, 
  // porque el controlador principal de Jornadas ahora usa la tubería inteligente 
  // 'abrirDisputaYMediar' que programamos antes. Dejo el bloque vacío por si se 
  // importa en otra pantalla antigua para no romper nada, pero derivando al nuevo flujo.
  Future<void> abrirDisputa(ModeloPuja p, String motivo, String descripcion, bool soyCliente) async {
     abrirDisputaYMediar(p, motivo, 'Intervención de Soporte', descripcion);
  }

  Future<void> finalizarYCalificar(ModeloPuja p, ModeloResenaPayload payload, String nombre, String avatar) async {
    isProcessing = true; actualizarUI();
    try { 
      await ServicioGestionJornadasSupabase.finalizarYCalificarProfesional(pujaId: p.id, trabajoId: trabajoId, evaluadorId: miId, evaluadoId: p.profesionalId, evaluadorNombre: nombre, evaluadorAvatar: avatar, payload: payload); 
      ControladorActividadJornadas().recargarSilenciosoGlobal(); 
      await cargarDatosSilencioso(); 
      notificarUI('¡Trato cerrado exitosamente!'); 
    } finally { 
      isProcessing = false; actualizarUI(); 
    }
  }

  Future<void> calificarComoProfesional(ModeloResenaPayload payload, String nombre, String avatar) async {
    isProcessing = true; actualizarUI();
    try { 
      await ServicioGestionJornadasSupabase.insertarResenaProfesional(trabajoId: trabajoId, pujaId: miPuja!.id, evaluadorId: miId, evaluadoId: clienteId, evaluadorNombre: nombre, evaluadorAvatar: avatar, payload: payload); 
      ControladorActividadJornadas().blindarTrampaPorCalificacionExitosa(trabajoId.toString()); 
      notificarUI('¡Gracias por evaluar al cliente!'); 
    } finally { 
      isProcessing = false; actualizarUI(); 
    }
  }
}