// lib/5_modulos/modulo_negociacion_oficios/servicios/servicio_negociacion_supabase.dart

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../3_modelos/modelo_resena_payload.dart'; 

class ServicioNegociacionSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static String _obtenerUrlPublicaSegura(String? path) {
    if (path == null || path.trim().isEmpty || path == 'null') return '';
    final limpio = path.trim();
    if (limpio.startsWith('http') || limpio.startsWith('/') || limpio.startsWith('file://')) return limpio;
    return _client.storage.from('imagenes').getPublicUrl(limpio);
  }

  static Future<Map<String, dynamic>?> obtenerTrabajoPorId(dynamic trabajoId) async {
    final res = await _client
        .from('trabajos')
        .select('*, perfiles!trabajos_cliente_id_fkey(apodo, foto_url, rating, rating_cliente, cantidad_resenas, cantidad_resenas_cliente, trabajos_publicados, trabajadores_contratados, cancelaciones_cliente, recomendacion_trabajadores, zona_trabajo, telefono)')
        .eq('id', trabajoId.toString())
        .maybeSingle();

    if (res != null) {
      String baseDesc = res['descripcion']?.toString() ?? '';
      String mappedRequisitos = res['requisitos']?.toString() ?? '';
      String mappedPrice = res['precio']?.toString() ?? '\$ 0';
      String mappedLocalidad = res['localidad']?.toString() ?? '';
      String mappedUbicacion = res['ubicacion_exacta']?.toString() ?? '';
      List<String> mappedImages = [];

      try {
        if (baseDesc.trim().startsWith('{')) {
          final mapped = jsonDecode(baseDesc);
          if (mapped is Map) {
            baseDesc = mapped['desc']?.toString() ?? baseDesc;
            mappedPrice = mapped['price']?.toString() ?? mappedPrice;
            mappedUbicacion = mapped['ubicacion_exacta']?.toString() ?? mappedUbicacion;
            mappedLocalidad = mapped['localidad']?.toString() ?? mappedLocalidad;
            if (mappedRequisitos.isEmpty) mappedRequisitos = mapped['requisitos']?.toString() ?? '';
            if (mapped['images'] != null && mapped['images'] is List) {
              mappedImages = (mapped['images'] as List).map((e) => _obtenerUrlPublicaSegura(e.toString())).toList();
            }
          }
        }
      } catch (_) {}

      final perf = res['perfiles'] as Map<String, dynamic>? ?? {};
      if (res['perfiles'] != null) {
        res['perfiles']['foto_url'] = _obtenerUrlPublicaSegura(res['perfiles']['foto_url']?.toString());
      }
      
      if (mappedImages.isEmpty && res['imagenes'] != null && res['imagenes'] is List) {
         mappedImages = (res['imagenes'] as List).map((e) => _obtenerUrlPublicaSegura(e.toString())).toList();
      }

      return {
        ...res,
        'title': res['titulo'] ?? 'Trabajo',
        'description': baseDesc,
        'requisitos': mappedRequisitos,
        'price': mappedPrice,
        'location': mappedLocalidad,
        'ubicacion_exacta': mappedUbicacion,
        'images': mappedImages,
        'date': res['fecha_hora'],
        
        'contraparteNombre': perf['apodo']?.toString() ?? '',
        'contraparteAvatar': perf['foto_url']?.toString() ?? '',
        'ratingContraparte': (perf['rating_cliente'] as num?)?.toDouble() ?? (perf['rating'] as num?)?.toDouble() ?? 0.0,
        'reviewsContraparte': (perf['cantidad_resenas_cliente'] as num?)?.toInt() ?? (perf['cantidad_resenas'] as num?)?.toInt() ?? 0,
        
        'rating': (perf['rating_cliente'] as num?)?.toDouble() ?? (perf['rating'] as num?)?.toDouble() ?? 0.0, 
        'reviews': (perf['cantidad_resenas_cliente'] as num?)?.toInt() ?? (perf['cantidad_resenas'] as num?)?.toInt() ?? 0, 

        'trabajos_publicados': perf['trabajos_publicados'] ?? 0,
        'trabajadores_contratados': perf['trabajadores_contratados'] ?? 0,
        'cancelaciones_cliente': perf['cancelaciones_cliente'] != null ? (perf['cancelaciones_cliente'] as num).toDouble() : 0.0,
        'recomendacion_trabajadores': perf['recomendacion_trabajadores'] != null ? (perf['recomendacion_trabajadores'] as num).toDouble() : 0.0,
        'zona_trabajo_cliente': perf['zona_trabajo'] ?? '',
        'telefono': perf['telefono'] ?? '',
        'adicionales_presupuesto': res['adicionales_presupuesto'],
      };
    }
    return res;
  }

  static Future<List<ModeloPuja>> obtenerPujas(dynamic trabajoId) async {
    final res = await _client
        .from('pujas')
        .select('*, perfiles!pujas_profesional_id_fkey(id, apodo, foto_url, oficios, rating, cantidad_resenas, puntualidad, asistencia, jornadas_completadas, cancelaciones_pro, score_confiabilidad_pro, zona_trabajo, telefono)')
        .eq('trabajo_id', trabajoId.toString())
        .order('id', ascending: false);

    return (res as List).map((row) {
      final perf = row['perfiles'] as Map<String, dynamic>? ?? {};
      return ModeloPuja.fromJson({
        ...row,
        'profesionalId': row['profesional_id'], 
        'apodoProfesional': perf['apodo']?.toString() ?? 'Profesional', 
        'avatarUrl': _obtenerUrlPublicaSegura(perf['foto_url']?.toString()),
        'rating': (perf['rating'] as num?)?.toDouble() ?? 0.0, 
        'reviews': (perf['cantidad_resenas'] as num?)?.toInt() ?? 0, 
        'montoOfrecido': row['monto'], 
        'estadoPuja': row['estado'],
        'mensaje': row['mensaje'], 
        'puntualidad': (perf['puntualidad'] as num?)?.toDouble() ?? 0.0, 
        'asistencia': (perf['asistencia'] as num?)?.toDouble() ?? 0.0,
        'jornadas_completadas': (perf['jornadas_completadas'] as num?)?.toDouble() ?? 0.0, 
        'cancelaciones_pro': (perf['cancelaciones_pro'] as num?)?.toDouble() ?? 0.0, 
        'score_confiabilidad_pro': (perf['score_confiabilidad_pro'] as num?)?.toDouble() ?? 0.0,
        'zona_trabajo': perf['zona_trabajo']?.toString() ?? '', 
        'oficios': perf['oficios'] ?? [], 
        'telefono': perf['telefono']?.toString() ?? '',
      });
    }).toList();
  }

  static Future<void> actualizarAdicionales(dynamic trabajoId, List<Map<String, dynamic>> adicionales) async {
    await _client.from('trabajos').update({'adicionales_presupuesto': adicionales}).eq('id', trabajoId.toString());
  }

  static Future<void> insertarPuja(dynamic trabajoId, String profesionalId, double monto) async {
    await _client.from('pujas').insert({
      'trabajo_id': trabajoId.toString(), 
      'profesional_id': profesionalId, 
      'monto': monto, 
      'mensaje': 'Propuesta de profesional', 
      'estado': 'esperando'
    });
  }

  static Future<void> actualizarMontoPuja(String pujaId, double nuevoMonto) async {
    await _client.from('pujas').update({'monto': nuevoMonto, 'estado': 'esperando'}).eq('id', pujaId);
  }

  static Future<void> eliminarPuja(String pujaId) async {
    await _client.from('pujas').delete().eq('id', pujaId);
  }
  
  static Future<void> actualizarEstadoTrabajo(dynamic trabajoId, String nuevoEstado) async {
    await _client.from('trabajos').update({'estado': nuevoEstado}).eq('id', trabajoId.toString());
  }
  
  static Future<void> actualizarEstadoPuja(String pujaId, String nuevoEstado) async {
    await _client.from('pujas').update({'estado': nuevoEstado}).eq('id', pujaId);
  }

  static Future<void> solicitarConfirmacionPro(dynamic trabajoId, String pujaId, String metodoPago) async {
    await _client.from('trabajos').update({'metodo_pago': metodoPago}).eq('id', trabajoId.toString());
    await _client.from('pujas').update({'estado': 'esperando_confirmacion_pro'}).eq('id', pujaId);
  }

  static Future<void> confirmarTratoPorPro(dynamic trabajoId, String pujaId, String pinIn, String pinOut) async {
    await _client.from('trabajos').update({'estado': 'asignado'}).eq('id', trabajoId.toString()).select();
    await _client.from('pujas').update({
      'estado': 'aceptada', 
      'mensaje': 'CONFIRMADO_PRO',
      'notificacion_leida_cliente': false, 
      'notificacion_leida_pro': false, 
      'contrato_timestamp': DateTime.now().toUtc().toIso8601String(), 
      'codigo_checkin': pinIn, 
      'codigo_checkout': pinOut
    }).eq('id', pujaId).select();
    
    // Notificación opcional (como en Jornadas)
    try {
      final pujaRes = await _client.from('pujas').select('profesional_id').eq('id', pujaId).maybeSingle();
      if (pujaRes != null && pujaRes['profesional_id'] != null) {
        await _client.from('notificaciones').insert({
          'usuario_id': pujaRes['profesional_id'], 
          'trabajo_id': trabajoId.toString(), 
          'titulo': '¡Trabajo Confirmado!', 
          'mensaje': 'El cliente ha realizado el pago. El chat y la ubicación se han liberado.', 
          'tipo': 'sistema'
        });
      }
    } catch (_) {}
  }

  static Future<void> rechazarTratoPorPro(String pujaId) async {
    await _client.from('pujas').update({'estado': 'rechazada_por_pro'}).eq('id', pujaId);
  }

  static Future<void> eliminarPujaVisualmenteParaCliente(String pujaId) async {
    await _client.from('pujas').update({'mensaje': 'ELIMINADA_POR_CLIENTE'}).eq('id', pujaId);
  }

  static Future<void> registrarLlegadaGPS(String pujaId, String coordenadas, String pinIn, String pinOut, String clienteId, dynamic trabajoId) async {
    await _client.from('pujas').update({
      'coordenadas_llegada': coordenadas,
      'codigo_checkin': pinIn,
      'codigo_checkout': pinOut,
      'notificacion_leida_cliente': false
    }).eq('id', pujaId);

    try {
      await _client.from('notificaciones').insert({
        'usuario_id': clienteId,
        'trabajo_id': trabajoId.toString(),
        'titulo': '📍 ¡Profesional en el lugar!',
        'mensaje': 'El profesional ya está en el lugar. Debes proporcionarle el PIN de llegada para confirmar su asistencia.',
        'tipo': 'sistema'
      });
    } catch (_) {}
  }

  static Future<void> validarCheckIn(String pujaId, dynamic trabajoId) async {
    await _client.from('pujas').update({'estado': 'en_curso', 'checkin_hora': DateTime.now().toUtc().toIso8601String()}).eq('id', pujaId);
    await _client.from('trabajos').update({'estado': 'en_curso', 'inicio_tarea': DateTime.now().toUtc().toIso8601String()}).eq('id', trabajoId.toString());
  }

  static Future<void> solicitarCheckOut(String pujaId, dynamic trabajoId, String clienteId) async {
    await _client.from('pujas').update({'estado': 'esperando_pin_salida'}).eq('id', pujaId);
    await _client.from('trabajos').update({'estado': 'esperando_pin_salida'}).eq('id', trabajoId.toString());
    await _client.from('notificaciones').insert({'usuario_id': clienteId, 'trabajo_id': trabajoId.toString(), 'titulo': '🏁 Trabajo finalizado', 'mensaje': 'El profesional terminó. Entrégale el PIN de finalización.', 'tipo': 'sistema'});
  }

  static Future<void> validarCheckOut(String pujaId, dynamic trabajoId) async {
    await _client.from('pujas').update({'estado': 'finalizada', 'checkout_hora': DateTime.now().toUtc().toIso8601String()}).eq('id', pujaId);
    await _client.from('trabajos').update({'estado': 'finalizado', 'fin_tarea': DateTime.now().toUtc().toIso8601String()}).eq('id', trabajoId.toString());
  }

  static Future<void> abrirDisputaYMediar({
    required dynamic trabajoId, 
    required String pujaId, 
    required String reportadorId, 
    required String reportadoId, 
    required String categoria, 
    required String solucionEsperada, 
    required String descripcion
  }) async {
    await _client.from('pujas').update({'estado': 'en_disputa', 'mensaje': 'EN MEDIACIÓN'}).eq('id', pujaId);
    await _client.from('trabajos').update({'estado': 'en_disputa'}).eq('id', trabajoId.toString());
    
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
      'mensaje': 'La contraparte ha iniciado una mediación. Ingresa al trabajo para revisar su petición o escalar el caso a soporte.', 
      'tipo': 'alerta'
    });
  }

  static Future<void> enviarCalificacion({
    required dynamic trabajoId, 
    required String evaluadorId, 
    required String evaluadoId, 
    required String evaluadorNombre, 
    required String evaluadorAvatar, 
    required ModeloResenaPayload payload, 
    required bool esCliente,
    String? pujaId,
  }) async {
    final columnaUpdate = esCliente ? 'cliente_califico' : 'pro_califico';
    await _client.from('trabajos').update({columnaUpdate: true}).eq('id', trabajoId.toString());

    if (pujaId != null) {
      final colPuja = esCliente ? 'cliente_califico_puja' : 'pro_califico_puja';
      await _client.from('pujas').update({colPuja: true}).eq('id', pujaId);
    }

    await _client.from('resenas').insert({
      'trabajo_id': trabajoId.toString(),
      'evaluador_id': evaluadorId,
      'evaluado_id': evaluadoId,
      'evaluador_nombre': evaluadorNombre,
      'evaluador_avatar': evaluadorAvatar,
      'rating': payload.rating,
      'comentario': payload.comentario,
      'rol_evaluado': payload.rolEvaluado,
    });

    try {
      final colResenas = esCliente ? 'cantidad_resenas' : 'cantidad_resenas_cliente'; 
      final colRating = esCliente ? 'rating' : 'rating_cliente';

      final perfil = await _client.from('perfiles').select('$colResenas, $colRating').eq('id', evaluadoId).maybeSingle();
      if (perfil != null) {
        double ratingActual = (perfil[colRating] as num?)?.toDouble() ?? 0.0;
        int resenasActuales = (perfil[colResenas] as num?)?.toInt() ?? 0;
        int nuevasResenas = resenasActuales + 1;
        double nuevoRating = double.parse((((ratingActual * resenasActuales) + payload.rating) / nuevasResenas).toStringAsFixed(1));
        
        await _client.from('perfiles').update({
          colRating: nuevoRating,
          colResenas: nuevasResenas
        }).eq('id', evaluadoId);
      }
    } catch (_) {}
  }

  static Future<void> cancelarTrabajoPorCliente(dynamic trabajoId, String? pujaId) async {
    await _client.from('trabajos').update({'estado': 'cancelado'}).eq('id', trabajoId.toString()).select(); 
    if (pujaId != null && !pujaId.startsWith('temp_')) { 
      await _client.from('pujas').update({'estado': 'cancelada_por_cliente'}).eq('id', pujaId).select();
    }
  }

  static Future<void> marcarCancelacionVistaPorPro(dynamic trabajoId, String? pujaId) async {
    if (pujaId != null && !pujaId.startsWith('temp_')) {
      await _client.from('pujas').update({'estado': 'cancelada_vista_pro'}).eq('id', pujaId).select();
    }
  }

  static Future<void> cancelarTrabajoPorPro(dynamic trabajoId, String pujaId, String proId, int puntosPerdidos) async {
    await _client.rpc('penalizar_profesional', params: {
      'p_profesional_id': proId,
      'p_puntos_perdidos': puntosPerdidos
    });

    await _client.from('pujas').update({
      'estado': 'cancelada_por_pro'
    }).eq('id', pujaId).select();

    await _client.from('trabajos').update({
      'estado': 'cancelado',
      'estado_negociacion': 'cancelada_por_pro'
    }).eq('id', trabajoId.toString()).select();
  }

  static Future<void> republicarTrabajo(dynamic trabajoId) async {
    final original = await _client.from('trabajos').select().eq('id', trabajoId.toString()).single();

    final clon = Map<String, dynamic>.from(original);
    clon.remove('id');         
    clon.remove('created_at'); 
    
    clon['estado'] = 'abierto';
    clon['estado_negociacion'] = 'abierto';
    clon['profesional_asignado_id'] = null;
    clon['precio_final_acordado'] = null;
    clon['metodo_pago'] = 'transferencia';
    clon['cliente_califico'] = false;
    clon['pro_califico'] = false;
    clon['inicio_tarea'] = null;
    clon['fin_tarea'] = null;
    clon['adicionales_presupuesto'] = [];

    await _client.from('trabajos').insert(clon);

    await _client.from('trabajos').update({
        'estado_negociacion': 'cancelada_vista_cliente'
    }).eq('id', trabajoId.toString());
  }

  static Future<void> aceptarCancelacionYCerrar(dynamic trabajoId) async {
    await _client.from('trabajos').update({
      'estado_negociacion': 'cancelada_vista_cliente'
    }).eq('id', trabajoId.toString()).select();
  }
}