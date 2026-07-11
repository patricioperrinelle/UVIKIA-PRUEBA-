// lib/5_modulos/modulo_servicios_catalogo/servicios/servicio_ejecucion_catalogo_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_resena_payload.dart'; // 🛡️ Import requerido

class ServicioEjecucionCatalogoSupabase {
  static final _supabase = Supabase.instance.client;

  static double _parseD(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseI(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  static Future<Map<String, dynamic>> obtenerReserva(String trabajoId, String miId) async {
    final respuesta = await _supabase
        .from('trabajos')
        .select('*, pujas(*)')
        .eq('id', trabajoId)
        .single();
        
    final rowMap = Map<String, dynamic>.from(respuesta);
    final clienteId = rowMap['cliente_id']?.toString() ?? '';
    final proId = rowMap['profesional_asignado_id']?.toString() ?? '';
    
    final soyPro = miId != clienteId;
    final contraparteId = soyPro ? clienteId : proId;

    if (contraparteId.isNotEmpty) {
      try {
        final perfil = await _supabase
            .from('perfiles')
            .select('apodo, foto_url, rating, rating_cliente, cantidad_resenas, cantidad_resenas_cliente, trabajos_publicados, trabajadores_contratados, cancelaciones_cliente, recomendacion_trabajadores, puntualidad, asistencia, jornadas_completadas, cancelaciones_pro, score_confiabilidad_pro')
            .eq('id', contraparteId)
            .maybeSingle();

        if (perfil != null) {
          rowMap['contraparteNombre'] = '${soyPro ? "Cliente" : "Profesional"}: ${perfil['apodo'] ?? "Usuario"}';
          rowMap['contraparteAvatar'] = perfil['foto_url'] ?? '';
          
          if (soyPro) {
            rowMap['ratingContraparte'] = _parseD(perfil['rating_cliente']) > 0 ? _parseD(perfil['rating_cliente']) : _parseD(perfil['rating']);
            rowMap['reviewsContraparte'] = _parseI(perfil['cantidad_resenas_cliente']) > 0 ? _parseI(perfil['cantidad_resenas_cliente']) : _parseI(perfil['cantidad_resenas']);
            
            rowMap['trabajos_publicados'] = _parseI(perfil['trabajos_publicados']);
            rowMap['trabajadores_contratados'] = _parseI(perfil['trabajadores_contratados']);
            rowMap['cancelaciones_cliente'] = _parseD(perfil['cancelaciones_cliente']);
            rowMap['recomendacion_trabajadores'] = _parseD(perfil['recomendacion_trabajadores']);
          } else {
            rowMap['ratingContraparte'] = _parseD(perfil['rating']);
            rowMap['reviewsContraparte'] = _parseI(perfil['cantidad_resenas']);

            rowMap['puntualidad'] = _parseD(perfil['puntualidad']);
            rowMap['asistencia'] = _parseD(perfil['asistencia']);
            rowMap['jornadas_completadas'] = _parseI(perfil['jornadas_completadas']);
            rowMap['cancelaciones_pro'] = _parseD(perfil['cancelaciones_pro']);
            rowMap['score_confiabilidad_pro'] = _parseD(perfil['score_confiabilidad_pro']);
          }
        }
      } catch (_) {}
    }

    return rowMap;
  }

  static Future<Map<String, dynamic>> obtenerPinesCrudos(String trabajoId) async {
    try { return await _supabase.from('trabajos').select('codigo_checkin, codigo_checkout').eq('id', trabajoId).single(); } 
    catch (_) { return {}; }
  }

  static Future<void> registrarLlegada(String trabajoId, String coordenadas) async {
    await _supabase.from('trabajos').update({ 'estado': 'esperando_pin_llegada', 'coordenadas_llegada': coordenadas }).eq('id', trabajoId);
  }

  static Future<void> marcarTareaFinalizada(String trabajoId) async {
    await _supabase.from('trabajos').update({ 'estado': 'esperando_pin_salida' }).eq('id', trabajoId);
  }

  static Future<bool> validarPin(String trabajoId, String tipoPin) async {
    final nuevoEstado = tipoPin == 'llegada' ? 'en_curso' : 'finalizado';
    await _supabase.from('trabajos').update({'estado': nuevoEstado}).eq('id', trabajoId);
    return true;
  }

  static Future<void> actualizarAdicionales(dynamic trabajoId, List<Map<String, dynamic>> adicionales) async {
    await _supabase.from('trabajos').update({'adicionales_presupuesto': adicionales}).eq('id', trabajoId);
  }

  // 🛡️ DATA-MISER: El método que faltaba para guardar las reseñas de Catálogo
  static Future<void> finalizarYCalificar({
    required dynamic trabajoId,
    required String evaluadorId,
    required String evaluadoId,
    required String evaluadorNombre,
    required String evaluadorAvatar,
    required ModeloResenaPayload payload,
    required bool esCliente
  }) async {
    // 1. Cerrar trampa
    final columnaUpdate = esCliente ? 'cliente_califico' : 'pro_califico';
    await _supabase.from('trabajos').update({columnaUpdate: true}).eq('id', trabajoId.toString());

    // 2. Insertar reseña real
    await _supabase.from('resenas').insert({
      'trabajo_id': trabajoId.toString(),
      'evaluador_id': evaluadorId,
      'evaluado_id': evaluadoId,
      'evaluador_nombre': evaluadorNombre,
      'evaluador_avatar': evaluadorAvatar,
      'rating': payload.rating,
      'comentario': payload.comentario,
      'rol_evaluado': payload.rolEvaluado,
    });

    // 3. Recalcular estrellas
    try {
      final colResenas = esCliente ? 'cantidad_resenas' : 'cantidad_resenas_cliente'; 
      final colRating = esCliente ? 'rating' : 'rating_cliente';

      final perfil = await _supabase.from('perfiles').select('$colResenas, $colRating').eq('id', evaluadoId).maybeSingle();
      if (perfil != null) {
        double ratingActual = (perfil[colRating] as num?)?.toDouble() ?? 0.0;
        int resenasActuales = (perfil[colResenas] as num?)?.toInt() ?? 0;
        int nuevasResenas = resenasActuales + 1;
        double nuevoRating = double.parse((((ratingActual * resenasActuales) + payload.rating) / nuevasResenas).toStringAsFixed(1));
        
        await _supabase.from('perfiles').update({
          colRating: nuevoRating,
          colResenas: nuevasResenas
        }).eq('id', evaluadoId);
      }
    } catch (_) {}
  }

  static Future<void> cancelarTrabajoPorCliente(dynamic trabajoId) async {
    await _supabase.from('trabajos').update({
      'estado': 'cancelado', 
      'estado_negociacion': 'cancelada_por_cliente'
    }).eq('id', trabajoId.toString()).select(); 
  }

  static Future<void> marcarCancelacionVistaPorPro(dynamic trabajoId) async {
    await _supabase.from('trabajos').update({
      'estado_negociacion': 'cancelada_vista_pro',
    }).eq('id', trabajoId.toString()).select();
  }

  static Future<void> cancelarTrabajoPorPro(dynamic trabajoId, String proId, String clienteId, int puntosPerdidos) async {
    await _supabase.rpc('penalizar_profesional', params: {
      'p_profesional_id': proId,
      'p_puntos_perdidos': puntosPerdidos
    });

    await _supabase.from('trabajos').update({
      'estado': 'cancelado',
      'estado_negociacion': 'cancelada_por_pro'
    }).eq('id', trabajoId.toString()).select();

    await _supabase.from('notificaciones').insert({
      'usuario_id': clienteId, 
      'trabajo_id': trabajoId.toString(), 
      'titulo': '🚨 Reserva Cancelada', 
      'mensaje': 'El profesional tuvo un imprevisto y canceló el servicio. Ha sido penalizado.', 
      'tipo': 'alerta'
    });
  }

  static Future<void> marcarCancelacionVistaPorCliente(dynamic trabajoId) async {
    await _supabase.from('trabajos').update({
      'estado_negociacion': 'cancelada_vista_cliente',
    }).eq('id', trabajoId.toString()).select();
  }
}