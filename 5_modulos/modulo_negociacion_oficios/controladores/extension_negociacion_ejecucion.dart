// lib/5_modulos/modulo_negociacion_oficios/controladores/extension_negociacion_ejecucion.dart
import 'package:uuid/uuid.dart';
import 'controlador_negociacion.dart';
import '../servicios/servicio_negociacion_supabase.dart';
import '../../../1_nucleo/servicios/servicio_gps_localizacion.dart';
import 'controlador_actividad_oficios.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../3_modelos/modelo_resena_payload.dart';

extension EjecucionNegociacion on ControladorNegociacion {
  
  Future<void> registrarLlegadaGPS(Function onGpsDisabled) async {
    isProcessing = true; actualizarUI();
    try {
      final pos = await ServicioGpsLocalizacion.obtenerCoordenadasActuales();
      final coords = '${pos.latitude}, ${pos.longitude}';
      
      final String genCheckin = miPuja?.codigoCheckin?.isNotEmpty == true ? miPuja!.codigoCheckin! : const Uuid().v4().substring(0, 6).toUpperCase();
      final String genCheckout = miPuja?.codigoCheckout?.isNotEmpty == true ? miPuja!.codigoCheckout! : const Uuid().v4().substring(0, 6).toUpperCase();

      await ServicioNegociacionSupabase.registrarLlegadaGPS(miPuja!.id, coords, genCheckin, genCheckout, jobData['cliente_id'] ?? jobData['ownerId'] ?? '', idTrabajoReal);
      miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'coordenadasLlegada': coords, 'coordenadas_llegada': coords, 'codigo_checkin': genCheckin, 'codigo_checkout': genCheckout});
      
      final int index = pujas.indexWhere((p) => p.id == miPuja!.id);
      if (index != -1) pujas[index] = miPuja!;
      
      actualizarUI();
    } catch (e) {
      if (e.toString().contains('gps_disabled') || e.toString().contains('permissions_denied')) { onGpsDisabled(); } 
      else { throw Exception('Error al obtener ubicación GPS.'); }
    } finally { 
      isProcessing = false; actualizarUI(); 
    }
  }

  Future<void> validarCheckInPro(String pinIngresado) async {
    if (miPuja?.codigoCheckin != pinIngresado.trim()) throw Exception('El PIN de llegada es incorrecto.');
    isProcessing = true; actualizarUI();
    try {
      await ServicioNegociacionSupabase.validarCheckIn(miPuja!.id, idTrabajoReal);
      estadoActual = EstadoNegociacion.enCurso;
      miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estadoPuja': 'en_curso', 'estado': 'en_curso'});
      actualizarUI();
    } finally {
      isProcessing = false; actualizarUI();
    }
  }

  Future<void> solicitarCheckOutPro() async {
    isProcessing = true; actualizarUI();
    try {
      await ServicioNegociacionSupabase.solicitarCheckOut(miPuja!.id, idTrabajoReal, contraparteIdFija);
      estadoActual = EstadoNegociacion.enCurso; // The UI updates using miPuja.estadoPuja
      miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estadoPuja': 'esperando_pin_salida', 'estado': 'esperando_pin_salida'});
      actualizarUI();
    } finally {
      isProcessing = false; actualizarUI();
    }
  }

  Future<void> validarCheckOutPro(String pinIngresado) async {
    if (miPuja?.codigoCheckout != pinIngresado.trim()) throw Exception('El PIN de salida es incorrecto.');
    isProcessing = true; actualizarUI();
    try {
      await ServicioNegociacionSupabase.validarCheckOut(miPuja!.id, idTrabajoReal);
      estadoActual = EstadoNegociacion.finalizado;
      miPuja = ModeloPuja.fromJson({...miPuja!.toJson(), 'estadoPuja': 'finalizada', 'estado': 'finalizada'});
      actualizarUI();
    } finally {
      isProcessing = false; actualizarUI();
    }
  }

  Future<void> abrirDisputa(String motivo, String descripcion) async {
    abrirDisputaYMediar(motivo, 'Intervención de Soporte', descripcion);
  }

  // 🛡️ REFACTOR: Se pasa el payload completo al servicio
  Future<void> finalizarYCalificar(ModeloPuja puja, ModeloResenaPayload payload, String miApodo, String miFoto) async {
    isProcessing = true; actualizarUI();
    try {
      jobData['cliente_califico'] = true;
      resenaCerradaEnRam = true;
      await ServicioNegociacionSupabase.enviarCalificacion(
        trabajoId: idTrabajoReal,
        evaluadorId: miId,
        evaluadoId: puja.profesionalId,
        evaluadorNombre: miApodo,
        evaluadorAvatar: miFoto,
        payload: payload,
        esCliente: true,
        pujaId: puja.id,
      );
      
      ControladorActividadOficios().blindarTrampaPorCalificacionExitosa(idTrabajoReal.toString());
    } catch (e) {
      onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error al calificar.');
    } finally {
      isProcessing = false; actualizarUI();
    }
  }

  // 🛡️ REFACTOR: Se pasa el payload completo al servicio
  Future<void> calificarComoProfesional(ModeloResenaPayload payload, String miApodo, String miFoto) async {
    isProcessing = true; actualizarUI();
    try {
      jobData['pro_califico'] = true;
      resenaCerradaEnRam = true;
      await ServicioNegociacionSupabase.enviarCalificacion(
        trabajoId: idTrabajoReal,
        evaluadorId: miId,
        evaluadoId: contraparteIdFija,
        evaluadorNombre: miApodo,
        evaluadorAvatar: miFoto,
        payload: payload,
        esCliente: false,
        pujaId: miPuja?.id,
      );
      
      ControladorActividadOficios().blindarTrampaPorCalificacionExitosa(idTrabajoReal.toString());
    } catch (e) {
      onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error al calificar.');
    } finally {
      isProcessing = false; actualizarUI();
    }
  }
}