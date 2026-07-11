// lib/5_modulos/modulo_gestion_jornadas/servicios/servicio_gestion_jornadas_supabase.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../3_modelos/modelo_resena_payload.dart';
import '../../../1_nucleo/estado_global/gestor_cache_lectura.dart';

class ServicioGestionJornadasSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static Stream<Map<String, dynamic>?> streamTrabajoPorIdSWR(dynamic trabajoId) {
    return GestorCacheLectura.ejecutarSWR<Map<String, dynamic>?>(
      cacheKey: 'cache_jornada_trabajo_$trabajoId',
      redFetcher: () => obtenerTrabajoPorId(trabajoId),
      serializer: (data) => data, 
      deserializer: (data) => data as Map<String, dynamic>?,
    );
  }

  static Stream<List<ModeloPuja>> streamPujasJornadaSWR(dynamic trabajoId) {
    return GestorCacheLectura.ejecutarSWR<List<ModeloPuja>>(
      cacheKey: 'cache_jornada_pujas_$trabajoId',
      redFetcher: () => obtenerPujasJornada(trabajoId),
      serializer: (list) => list.map((p) => p.toJson()).toList(), 
      deserializer: (jsonList) => (jsonList as List).map((j) => ModeloPuja.fromJson(j)).toList(),
    );
  }

  static String _obtenerUrlPublicaSegura(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http')) return path;
    return _client.storage.from('imagenes').getPublicUrl(path);
  }

  static Future<Map<String, dynamic>?> obtenerTrabajoPorId(dynamic trabajoId) async {
    try {
      final res = await _client.from('trabajos').select('*, perfiles!trabajos_cliente_id_fkey(apodo, foto_url, rating, rating_cliente, cantidad_resenas, cantidad_resenas_cliente, telefono, trabajos_publicados, trabajadores_contratados, cancelaciones_cliente, recomendacion_trabajadores, zona_trabajo)').eq('id', trabajoId).maybeSingle();
      
      if (res != null) {
        String baseDesc = res['descripcion']?.toString() ?? '';
        String mappedPrice = res['precio']?.toString() ?? '\$ 0';
        String mappedLocalidad = res['localidad']?.toString() ?? '';
        String mappedUbicacionExacta = res['ubicacion_exacta']?.toString() ?? '';
        String mappedRequisitos = res['requisitos']?.toString() ?? '';
        List<String> mappedImages =[];
        
        if (res['imagenes'] != null && res['imagenes'] is List) mappedImages = (res['imagenes'] as List).map((e) => _obtenerUrlPublicaSegura(e.toString())).toList();
        
        try {
          if (baseDesc.trim().startsWith('{')) {
            final mapped = jsonDecode(baseDesc);
            if (mapped is Map) {
              baseDesc = mapped['desc']?.toString() ?? baseDesc;
              if (mapped['price'] != null) mappedPrice = mapped['price'].toString();
              if (mapped['localidad'] != null) mappedLocalidad = mapped['localidad'].toString();
              if (mapped['ubicacion_exacta'] != null) mappedUbicacionExacta = mapped['ubicacion_exacta'].toString();
              if (mappedRequisitos.isEmpty && mapped['requisitos'] != null) mappedRequisitos = mapped['requisitos'].toString();
              if (mappedImages.isEmpty && mapped['images'] != null && mapped['images'] is List) mappedImages = (mapped['images'] as List).map((e) => _obtenerUrlPublicaSegura(e.toString())).toList();
            }
          }
        } catch (_) {}
        
        final perf = res['perfiles'] as Map<String, dynamic>? ?? {};
        
        return {
          ...res, 
          'title': res['titulo'], 
          'description': baseDesc, 
          'requisitos': mappedRequisitos, 
          'price': mappedPrice, 
          'images': mappedImages, 
          'location': mappedLocalidad, 
          'ubicacion_exacta': mappedUbicacionExacta, 
          'date': res['fecha_hora'], 
          'estado': res['estado'], 
          'ownerId': res['cliente_id'], 
          'counterpart': perf['apodo'] ?? 'Usuario', 
          'avatarUrl': _obtenerUrlPublicaSegura(perf['foto_url']?.toString()), 
          'rating': (perf['rating_cliente'] as num?)?.toDouble() ?? (perf['rating'] as num?)?.toDouble() ?? 0.0, 
          'reviews': (perf['cantidad_resenas_cliente'] as num?)?.toInt() ?? (perf['cantidad_resenas'] as num?)?.toInt() ?? 0, 
          'telefono_contraparte': perf['telefono'] ?? '', 
          'telefono_contacto': res['telefono_contacto'] ?? '', 
          'pro_califico': res['pro_califico'] ?? false, 
          'cliente_califico': res['cliente_califico'] ?? false, 
          'trabajos_publicados': perf['trabajos_publicados'] ?? 0, 
          'trabajadores_contratados': perf['trabajadores_contratados'] ?? 0, 
          'cancelaciones_cliente': perf['cancelaciones_cliente'] != null ? (perf['cancelaciones_cliente'] as num).toDouble() : 0.0, 
          'recomendacion_trabajadores': perf['recomendacion_trabajadores'] != null ? (perf['recomendacion_trabajadores'] as num).toDouble() : 0.0, 
          'zona_trabajo_cliente': perf['zona_trabajo'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('[ServicioJornadas] Fallo silencioso evitado: $e');
    }
    return null;
  }

  static Future<List<ModeloPuja>> obtenerPujasJornada(dynamic trabajoId) async {
    final res = await _client.from('pujas').select('*, perfiles!profesional_id(id, apodo, foto_url, rating, cantidad_resenas, puntualidad, asistencia, jornadas_completadas, cancelaciones_pro, score_confiabilidad_pro, zona_trabajo, oficios)').eq('trabajo_id', trabajoId).order('id', ascending: false);
    return (res as List).map((row) {
      final perf = row['perfiles'] as Map<String, dynamic>? ?? {};
      return ModeloPuja.fromJson({
        ...row, 'profesionalId': row['profesional_id'], 'apodoProfesional': perf['apodo'], 'avatarUrl': _obtenerUrlPublicaSegura(perf['foto_url']?.toString()), 'rating': perf['rating'], 'reviews': perf['cantidad_resenas'], 'montoOfrecido': row['monto'], 'estadoPuja': row['estado'], 'mensaje': row['mensaje'], 'coordenadasLlegada': row['coordenadas_llegada'], 'checkinHora': row['checkin_hora'], 'rechazadoPorCliente': row['rechazado_por_cliente'], 'notificacionLeidaCliente': row['notificacion_leida_cliente'], 'notificacionLeidaPro': row['notificacion_leida_pro'], 'codigo_checkin': row['codigo_checkin'], 'codigo_checkout': row['codigo_checkout'], 'puntualidad': perf['puntualidad'], 'asistencia': perf['asistencia'], 'jornadas_completadas': perf['jornadas_completadas'], 'cancelaciones_pro': perf['cancelaciones_pro'], 'score_confiabilidad_pro': perf['score_confiabilidad_pro'], 'zona_trabajo': perf['zona_trabajo'], 'oficios': perf['oficios'], 
      });
    }).toList();
  }

  static Future<void> marcarPujaLeidaCliente(dynamic pujaId) async { await _client.from('pujas').update({'notificacion_leida_cliente': true}).eq('id', pujaId); }
  static Future<void> marcarPujaLeidaPro(dynamic pujaId) async { await _client.from('pujas').update({'notificacion_leida_pro': true}).eq('id', pujaId); }
  static Future<void> insertarPujaJornada({required dynamic trabajoId, required String profesionalId, required String monto, required String duenoId}) async { await _client.from('pujas').insert({'trabajo_id': trabajoId, 'profesional_id': profesionalId, 'monto': monto, 'mensaje': 'Postulación a jornada eventual', 'estado': 'esperando'}); }
  static Future<void> retirarPuja(dynamic pujaId) async { await _client.from('pujas').delete().eq('id', pujaId); }
  
  // 🛡️ DATA-MISER: Todas las mutaciones exigen .select() para evitar fallos silenciosos por políticas RLS
  static Future<void> eliminarPujaVisualmenteParaCliente(dynamic pujaId) async { await _client.from('pujas').update({'mensaje': 'ELIMINADA_POR_CLIENTE'}).eq('id', pujaId).select(); }

  static Future<void> contratarProfesional(dynamic pujaId, String proId, String clienteId, dynamic trabajoId) async {
    await _client.from('pujas').update({'estado': 'esperando_confirmacion_pro', 'notificacion_leida_pro': false}).eq('id', pujaId).select();
    await _client.from('notificaciones').insert({'usuario_id': proId, 'trabajo_id': trabajoId.toString(), 'titulo': '¡Has sido seleccionado!', 'mensaje': 'El cliente quiere contratarte. Confirma tu disponibilidad para que pueda realizar el pago.', 'tipo': 'sistema'});
  }

  static Future<void> aceptarContratacionPro(dynamic pujaId, String proId, String clienteId, dynamic trabajoId) async {
    await _client.from('pujas').update({'estado': 'esperando_pago_cliente', 'notificacion_leida_cliente': false}).eq('id', pujaId).select();
    await _client.from('notificaciones').insert({'usuario_id': clienteId, 'trabajo_id': trabajoId.toString(), 'titulo': '¡Profesional Disponible!', 'mensaje': 'El profesional confirmó su disponibilidad. Realiza el pago para asegurar la jornada.', 'tipo': 'sistema'});
  }

  static Future<void> confirmarPagoYLiberarTurno(dynamic pujaId, String proId, String clienteId, dynamic trabajoId, String codigoCheckin, String codigoCheckout) async {
    await _client.from('pujas').update({'estado': 'aceptada', 'mensaje': 'CONFIRMADO_PRO', 'notificacion_leida_cliente': false, 'notificacion_leida_pro': false, 'contrato_timestamp': DateTime.now().toUtc().toIso8601String(), 'codigo_checkin': codigoCheckin, 'codigo_checkout': codigoCheckout}).eq('id', pujaId).select();
    await _client.from('notificaciones').insert({'usuario_id': proId, 'trabajo_id': trabajoId.toString(), 'titulo': '¡Jornada Confirmada!', 'mensaje': 'El cliente ha realizado el pago. El chat y la ubicación se han liberado.', 'tipo': 'sistema'});
  }

  static Future<void> rechazarContratacionPro(dynamic pujaId, String clienteId, dynamic trabajoId) async {
    await _client.from('pujas').update({'estado': 'rechazada_por_pro', 'notificacion_leida_cliente': false}).eq('id', pujaId).select();
    await _client.from('notificaciones').insert({'usuario_id': clienteId, 'trabajo_id': trabajoId.toString(), 'titulo': 'Profesional no disponible', 'mensaje': 'El profesional que seleccionaste rechazó la contratación. Puedes elegir a otro postulante.', 'tipo': 'alerta'});
  }

  static Future<void> registrarLlegadaGPS(dynamic pujaId, String coordenadas, String clienteId, dynamic trabajoId) async {
    await _client.from('pujas').update({'coordenadas_llegada': coordenadas, 'notificacion_leida_cliente': false}).eq('id', pujaId).select();
    await _client.from('notificaciones').insert({'usuario_id': clienteId, 'trabajo_id': trabajoId.toString(), 'titulo': '📍 ¡Profesional en el lugar!', 'mensaje': 'El profesional ya está en el lugar. Debes proporcionarle el PIN de llegada para confirmar su asistencia.', 'tipo': 'sistema'});
  }

  static Future<void> validarCheckInPro(dynamic pujaId, dynamic trabajoId, String clienteId, String proId) async {
    await _client.from('pujas').update({'estado': 'en_curso', 'notificacion_leida_cliente': false, 'checkin_hora': DateTime.now().toUtc().toIso8601String()}).eq('id', pujaId).select();
    await _client.from('trabajos').update({'estado': 'en_curso', 'inicio_tarea': DateTime.now().toUtc().toIso8601String()}).eq('id', trabajoId.toString()).select();
    await _client.from('notificaciones').insert({'usuario_id': clienteId, 'trabajo_id': trabajoId.toString(), 'titulo': '✅ Jornada Iniciada', 'mensaje': 'La jornada fue iniciada correctamente.', 'tipo': 'sistema'});
    await _client.from('notificaciones').insert({'usuario_id': proId, 'trabajo_id': trabajoId.toString(), 'titulo': '✅ Check-In Validado', 'mensaje': 'Tu llegada fue registrada y la jornada está en curso.', 'tipo': 'sistema'});
  }

  static Future<void> solicitarCheckOutPro(dynamic pujaId, dynamic trabajoId, String clienteId) async {
    await _client.from('pujas').update({'estado': 'esperando_pin_salida', 'notificacion_leida_cliente': false}).eq('id', pujaId).select();
    await _client.from('trabajos').update({'estado': 'esperando_pin_salida'}).eq('id', trabajoId.toString()).select();
    await _client.from('notificaciones').insert({'usuario_id': clienteId, 'trabajo_id': trabajoId.toString(), 'titulo': '🏁 Trabajo finalizado', 'mensaje': 'El profesional terminó. Entrégale el PIN de finalización.', 'tipo': 'sistema'});
  }

  static Future<void> validarCheckOutPro(dynamic pujaId, dynamic trabajoId, String clienteId, String proId) async {
    await _client.from('pujas').update({'estado': 'finalizada', 'notificacion_leida_cliente': false, 'checkout_hora': DateTime.now().toUtc().toIso8601String()}).eq('id', pujaId).select();
    await _client.from('trabajos').update({'estado': 'finalizado', 'fin_tarea': DateTime.now().toUtc().toIso8601String()}).eq('id', trabajoId.toString()).select();
    await _client.from('notificaciones').insert({'usuario_id': clienteId, 'trabajo_id': trabajoId.toString(), 'titulo': '🏁 Turno Finalizado', 'mensaje': 'El turno del profesional finalizó. ¡Es tu turno de calificarlo!', 'tipo': 'sistema'});
    await _client.from('notificaciones').insert({'usuario_id': proId, 'trabajo_id': trabajoId.toString(), 'titulo': '🏁 Turno Cerrado', 'mensaje': 'Salida registrada correctamente. ¡Califica al cliente!', 'tipo': 'sistema'});
  }

  static Future<void> desestimarProfesionalContratado(dynamic pujaId, String proId, String clienteId, double comisionReembolso, dynamic trabajoId) async {
    final cliRes = await _client.from('perfiles').select('cancelaciones_cliente').eq('id', clienteId).single();
    int cancelaciones = (cliRes['cancelaciones_cliente'] as num?)?.toInt() ?? 0;
    
    await _client.from('perfiles').update({'cancelaciones_cliente': cancelaciones + 1}).eq('id', clienteId).select();
    await _client.from('pujas').update({'estado': 'desestimada', 'rechazado_por_cliente': true, 'notificacion_leida_pro': false}).eq('id', pujaId).select();
    await _client.from('notificaciones').insert({'usuario_id': proId, 'trabajo_id': trabajoId.toString(), 'titulo': 'Asignación Cancelada', 'mensaje': 'El cliente desestimó tu contrato y afectó sus métricas. Por favor, califica tu experiencia.', 'tipo': 'alerta'});
  }

  static Future<void> abrirDisputaYMediar({
    required dynamic trabajoId, 
    required String pujaId, 
    required String reportadorId, 
    required String reportadoId, 
    required String categoria, 
    required String solucionEsperada, 
    required String descripcion,
    required bool soyCliente
  }) async {
    await _client.from('pujas').update({
      'estado': 'en_disputa', 
      'mensaje': 'EN MEDIACIÓN',
      'notificacion_leida_pro': soyCliente ? false : true, 
      'notificacion_leida_cliente': !soyCliente ? false : true
    }).eq('id', pujaId).select();
    
    try { 
      await _client.from('disputas').insert({
        'trabajo_id': trabajoId.toString(), 
        'puja_id': pujaId.toString(), 
        'reportador_id': reportadorId, 
        'reportado_id': reportadoId, 
        'categoria': categoria, 
        'solucion_esperada': solucionEsperada, 
        'descripcion': descripcion, 
        'estado': 'esperando_respuesta',
        'historial_mediacion': [
          {
            "accion": "Reporte abierto por categoría: $categoria", 
            "fecha": DateTime.now().toUtc().toIso8601String()
          }
        ]
      }); 
    } catch (_) {}

    await _client.from('notificaciones').insert({
      'usuario_id': reportadoId, 
      'trabajo_id': trabajoId.toString(), 
      'titulo': '⚠️ Centro de Resolución', 
      'mensaje': 'La contraparte ha iniciado una mediación. Ingresa al trabajo para revisar su petición.', 
      'tipo': 'alerta'
    });
  }

  static Future<void> finalizarYCalificarProfesional({required dynamic pujaId, required dynamic trabajoId, required String evaluadorId, required String evaluadoId, required String evaluadorNombre, required String evaluadorAvatar, required ModeloResenaPayload payload}) async {
    await _client.from('pujas').update({'estado': 'finalizada', 'notificacion_leida_pro': false, 'cliente_califico_puja': true}).eq('id', pujaId).select();
    
    await _client.from('resenas').insert({
      'trabajo_id': trabajoId.toString(), 
      'evaluador_id': evaluadorId, 
      'evaluado_id': evaluadoId, 
      'evaluador_nombre': evaluadorNombre, 
      'evaluador_avatar': evaluadorAvatar, 
      'rating': payload.rating, 
      'comentario': payload.comentario,
      'rol_evaluado': payload.rolEvaluado
    });
    
    try {
      final proRes = await _client.from('perfiles').select('jornadas_completadas, puntualidad, recomendacion_clientes, rating, cantidad_resenas').eq('id', evaluadoId).maybeSingle();
      int jornadasCompletadas = (proRes?['jornadas_completadas'] as num?)?.toInt() ?? 0;
      double recomendacionAnterior = (proRes?['recomendacion_clientes'] as num?)?.toDouble() ?? 100.0;
      double puntualidadAnterior = (proRes?['puntualidad'] as num?)?.toDouble() ?? 100.0;
      double currentRating = (proRes?['rating'] as num?)?.toDouble() ?? 0.0;
      int currentReviews = (proRes?['cantidad_resenas'] as num?)?.toInt() ?? 0;
      int newReviews = currentReviews + 1;
      double newRating = double.parse((((currentRating * currentReviews) + payload.rating) / newReviews).toStringAsFixed(1));
      double nuevaPuntualidad = payload.esPuntualORespetuoso ? (puntualidadAnterior >= 98 ? 100 : puntualidadAnterior + 2) : (puntualidadAnterior - 5);
      double nuevaRecomendacion = payload.esRecomendadoOClaro ? (recomendacionAnterior >= 98 ? 100 : recomendacionAnterior + 2) : (recomendacionAnterior - 5);
      await _client.from('perfiles').update({'rating': newRating, 'cantidad_resenas': newReviews, 'jornadas_completadas': jornadasCompletadas + 1, 'puntualidad': nuevaPuntualidad.clamp(0.0, 100.0), 'recomendacion_clientes': nuevaRecomendacion.clamp(0.0, 100.0)}).eq('id', evaluadoId).select();
    } catch (_) {}
    
    try {
      final pujasRestantes = await _client.from('pujas').select('id, estado, cliente_califico_puja').eq('trabajo_id', trabajoId);
      bool quedanActivos = false;
      for(var p in pujasRestantes) {
        if (p['id'].toString() == pujaId.toString()) continue; 
        final st = p['estado'];
        if (st == 'esperando_confirmacion_pro' || st == 'aceptada' || st == 'en_curso') {
            quedanActivos = true; break;
        }
        if (st == 'finalizada' && p['cliente_califico_puja'] != true) {
            quedanActivos = true; break;
        }
      }
      if (!quedanActivos) await _client.from('trabajos').update({'estado': 'finalizado', 'cliente_califico': true}).eq('id', trabajoId).select();
    } catch (_) {}

    await _client.from('notificaciones').insert({'usuario_id': evaluadoId, 'trabajo_id': trabajoId.toString(), 'titulo': '¡Turno Evaluado!', 'mensaje': 'El cliente evaluó tu turno. ¡Es tu turno de evaluarlo!', 'tipo': 'sistema'});
  }

  static Future<void> insertarResenaProfesional({required dynamic trabajoId, required dynamic pujaId, required String evaluadorId, required String evaluadoId, required String evaluadorNombre, required String evaluadorAvatar, required ModeloResenaPayload payload}) async {
    await _client.from('resenas').insert({
      'trabajo_id': trabajoId.toString(), 
      'evaluador_id': evaluadorId, 
      'evaluado_id': evaluadoId, 
      'evaluador_nombre': evaluadorNombre, 
      'evaluador_avatar': evaluadorAvatar, 
      'rating': payload.rating, 
      'comentario': payload.comentario,
      'rol_evaluado': payload.rolEvaluado
    });
    
    try {
       final cliRes = await _client.from('perfiles').select('trabajadores_contratados, recomendacion_trabajadores, rating, cantidad_resenas').eq('id', evaluadoId).maybeSingle();
       int contratados = (cliRes?['trabajadores_contratados'] as num?)?.toInt() ?? 0;
       double recAnterior = (cliRes?['recomendacion_trabajadores'] as num?)?.toDouble() ?? 100.0;
       double currentRating = (cliRes?['rating'] as num?)?.toDouble() ?? 0.0;
       int currentReviews = (cliRes?['cantidad_resenas'] as num?)?.toInt() ?? 0;
       int newReviews = currentReviews + 1;
       double newRating = double.parse((((currentRating * currentReviews) + payload.rating) / newReviews).toStringAsFixed(1));
       double nuevaRec = (payload.esPuntualORespetuoso && payload.esRecomendadoOClaro) ? (recAnterior >= 98 ? 100 : recAnterior + 2) : (recAnterior - 5);
       await _client.from('perfiles').update({'rating': newRating, 'cantidad_resenas': newReviews, 'trabajadores_contratados': contratados + 1, 'recomendacion_trabajadores': nuevaRec.clamp(0.0, 100.0)}).eq('id', evaluadoId).select();
    } catch (_) {}
    await _client.from('pujas').update({'pro_califico_puja': true}).eq('id', pujaId).select();
  }

  static Future<void> cancelarPujaPorCliente(dynamic trabajoId, String pujaId) async {
    await _client.from('pujas').update({
      'estado': 'cancelada_por_cliente',
      'notificacion_leida_pro': false
    }).eq('id', pujaId).select();

    try {
      final pujasRestantes = await _client.from('pujas').select('id, estado').eq('trabajo_id', trabajoId.toString());
      bool quedanActivos = false;
      for (var p in pujasRestantes) {
        if (p['id'].toString() == pujaId) continue;
        final st = p['estado'];
        if (st == 'esperando_confirmacion_pro' || st == 'aceptada' || st == 'en_curso' || st == 'finalizada') {
          quedanActivos = true; 
          break;
        }
      }
      if (!quedanActivos) {
        await _client.from('trabajos').update({
          'estado': 'cancelado' 
        }).eq('id', trabajoId.toString()).select();
      }
    } catch (_) {}
  }

  static Future<void> marcarCancelacionVistaPorPro(String pujaId) async {
    await _client.from('pujas').update({
      'estado': 'cancelada_vista_pro',
    }).eq('id', pujaId).select();
  }

  static Future<void> cancelarTrabajoPorPro(dynamic pujaId, dynamic trabajoId, String clienteId, String proId, int puntosPerdidos) async {
    await _client.rpc('penalizar_profesional', params: {
      'p_profesional_id': proId,
      'p_puntos_perdidos': puntosPerdidos
    });

    await _client.from('pujas').update({
      'estado': 'cancelada_por_pro',
      'notificacion_leida_cliente': false
    }).eq('id', pujaId).select();

    await _client.from('notificaciones').insert({
      'usuario_id': clienteId, 
      'trabajo_id': trabajoId.toString(), 
      'titulo': '🚨 Profesional Canceló', 
      'mensaje': 'Un profesional tuvo un imprevisto y canceló su asistencia. Tu jornada sigue activa.', 
      'tipo': 'alerta'
    });
  }
}