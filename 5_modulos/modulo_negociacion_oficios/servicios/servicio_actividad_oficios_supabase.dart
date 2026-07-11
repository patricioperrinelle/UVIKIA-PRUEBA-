// lib/5_modulos/modulo_negociacion_oficios/servicios/servicio_actividad_oficios_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_oficio_trabajo.dart';
import '../../../3_modelos/modelo_puja.dart';

class ServicioActividadOficiosSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> eliminarTrabajoFisicamente(String trabajoId) async => 
      await _client.from('trabajos').delete().eq('id', trabajoId);

  static Future<void> archivarTrabajoCancelado(String trabajoId) async => 
      await _client.from('trabajos').update({
        'estado': 'cancelado',
        'estado_negociacion': 'cancelada_vista_cliente'
      }).eq('id', trabajoId);
      
  static Future<void> rechazarSolicitudDirecta(String trabajoId) async => 
      await _client.from('trabajos').update({'estado': 'cancelado'}).eq('id', trabajoId);
      
  static Future<void> eliminarPujaVisualmenteParaPro(String pujaId) async => 
      await _client.from('pujas').update({'mensaje': 'ELIMINADA_POR_PRO'}).eq('id', pujaId);

  static Future<void> marcarNotificacionBurbujaComoNoLeida(String trabajoId, String emisorId, String miId) async {
    try {
      await _client.from('pujas').update({'notificacion_leida_cliente': false}).eq('trabajo_id', trabajoId).eq('profesional_id', emisorId);
      await _client.from('pujas').update({'notificacion_leida_pro': false}).eq('trabajo_id', trabajoId).eq('profesional_id', miId);
    } catch (_) {}
  }

  static Future<Map<String, int>> obtenerMensajesNoLeidos(String usuarioId) async {
    final res = await _client.from('mensajes').select('trabajo_id').eq('leido', false).eq('receptor_id', usuarioId);
    Map<String, int> counts = {};
    for (var row in (res as List)) {
      final tId = row['trabajo_id']?.toString() ?? '';
      if (tId.isNotEmpty) counts[tId] = (counts[tId] ?? 0) + 1;
    }
    return counts;
  }

  static ModeloPuja _mapearPuja(Map<String, dynamic> pMap) {
    final perf = pMap['perfiles'] is Map ? Map<String, dynamic>.from(pMap['perfiles']) : <String, dynamic>{};
    return ModeloPuja.fromJson({
      'id': pMap['id']?.toString() ?? '',
      'profesionalId': pMap['profesional_id']?.toString() ?? '',
      'apodoProfesional': perf['apodo']?.toString() ?? 'Profesional',
      'avatarUrl': perf['foto_url']?.toString() ?? '',
      'rating': double.tryParse(perf['rating']?.toString() ?? '') ?? 0.0,
      'reviews': int.tryParse(perf['cantidad_resenas']?.toString() ?? '') ?? 0,
      'montoOfrecido': pMap['monto']?.toString() ?? '\$ 0',
      'estadoPuja': pMap['estado']?.toString() ?? 'esperando',
      'coordenadasLlegada': pMap['coordenadas_llegada']?.toString(),
      'checkinHora': pMap['checkin_hora']?.toString(),
      'rechazadoPorCliente': pMap['rechazado_por_cliente'] == true,
      'notificacionLeidaCliente': pMap['notificacion_leida_cliente'] == true,
      'notificacionLeidaPro': pMap['notificacion_leida_pro'] == true,
      'clienteCalificoPuja': pMap['cliente_califico_puja'] == true,
      'proCalificoPuja': pMap['pro_califico_puja'] == true,
      'codigo_checkin': pMap['codigo_checkin']?.toString(),
      'codigo_checkout': pMap['codigo_checkout']?.toString(),
      'puntualidad': double.tryParse(perf['puntualidad']?.toString() ?? '') ?? 0.0,
      'asistencia': double.tryParse(perf['asistencia']?.toString() ?? '') ?? 0.0,
      'jornadas_completadas': double.tryParse(perf['jornadas_completadas']?.toString() ?? '') ?? 0.0,
      'cancelaciones_pro': double.tryParse(perf['cancelaciones_pro']?.toString() ?? '') ?? 0.0,
      'score_confiabilidad_pro': double.tryParse(perf['score_confiabilidad_pro']?.toString() ?? '') ?? 0.0,
      'zona_trabajo': perf['zona_trabajo']?.toString() ?? '',
      'oficios': perf['oficios'] ?? [],
      'telefono': perf['telefono']?.toString() ?? '',
    });
  }

  static Future<List<ModeloOficioTrabajo>> obtenerPublicacionesClienteOficios(String clienteId, Map<String, int> unreadCounts) async {
    final res = await _client.from('trabajos')
        .select('*, pujas(*, perfiles!pujas_profesional_id_fkey(apodo, foto_url, rating, cantidad_resenas, puntualidad, asistencia, jornadas_completadas, cancelaciones_pro, score_confiabilidad_pro, zona_trabajo, telefono, oficios)), perfiles_solicitado:perfiles!trabajos_profesional_solicitado_id_fkey(apodo, foto_url, rating, cantidad_resenas, puntualidad, asistencia, jornadas_completadas, cancelaciones_pro, score_confiabilidad_pro, zona_trabajo, telefono, oficios)')
        .eq('cliente_id', clienteId) 
        .neq('dificultad', 'jornada')
        .neq('dificultad', 'catalogo')
        .neq('estado', 'eliminado') 
        .order('fecha_hora', ascending: false);

    return (res as List).map((row) {
      final rowMap = Map<String, dynamic>.from(row);
      final List<ModeloPuja> pujas = (rowMap['pujas'] as List? ??[/*vacio*/]).map((p) => _mapearPuja(Map<String, dynamic>.from(p))).toList();
      
      String proCounterpart = 'Buscando profesional...';
      String proAvatar = '';
      double proRating = 0.0;
      int proReviews = 0;
      String? idAsignado;

      try { idAsignado = pujas.firstWhere((b) => b.estadoPuja == 'aceptada').profesionalId; } catch (_) {}

      if (rowMap['profesional_solicitado_id'] != null && rowMap['perfiles_solicitado'] != null) {
        final proPerfil = Map<String, dynamic>.from(rowMap['perfiles_solicitado']);
        proCounterpart = 'Profesional: ${proPerfil['apodo'] ?? 'Anónimo'}';
        proAvatar = proPerfil['foto_url'] ?? '';
        proRating = double.tryParse(proPerfil['rating']?.toString() ?? '') ?? 0.0;
        proReviews = int.tryParse(proPerfil['cantidad_resenas']?.toString() ?? '') ?? 0;
      } else if (idAsignado != null && pujas.isNotEmpty) {
        try {
          final acceptedBid = pujas.firstWhere((b) => b.profesionalId == idAsignado);
          proCounterpart = 'Profesional: ${acceptedBid.apodoProfesional}';
          proAvatar = acceptedBid.avatarUrl;
          proRating = acceptedBid.rating;
          proReviews = acceptedBid.reviews;
        } catch (_) {}
      }

      rowMap['contraparteNombre'] = proCounterpart;
      rowMap['contraparteAvatar'] = proAvatar;
      rowMap['ratingContraparte'] = proRating;
      rowMap['reviewsContraparte'] = proReviews;
      rowMap['pujas'] = pujas.map((p) => p.toJson()).toList(); 
      rowMap['profesionalAsignadoId'] = idAsignado; 
      rowMap['mensajesNoLeidos'] = unreadCounts[rowMap['id'].toString()] ?? 0;
      rowMap['ownerId'] = rowMap['cliente_id']; 

      return ModeloOficioTrabajo.fromJson(rowMap); 
    }).toList();
  }

  static Future<List<ModeloOficioTrabajo>> obtenerPostulacionesProfesionalOficios(String profesionalId, Map<String, int> unreadCounts) async {
    final res = await _client.from('pujas')
        .select('*, trabajos(*, perfiles!trabajos_cliente_id_fkey(apodo, foto_url, rating, rating_cliente, cantidad_resenas, cantidad_resenas_cliente, recomendacion_trabajadores, trabajos_publicados, trabajadores_contratados, cancelaciones_cliente, zona_trabajo_cliente))')
        .eq('profesional_id', profesionalId).order('id', ascending: false);

    final List<ModeloOficioTrabajo> trabajosPostulados =[];
    for (var row in (res as List)) {
      final rowMap = Map<String, dynamic>.from(row); 
      
      if (rowMap['mensaje']?.toString() == 'ELIMINADA_POR_PRO') continue;

      final job = Map<String, dynamic>.from(rowMap['trabajos'] ?? {}); 
      final dif = job['dificultad']?.toString() ?? '';
      if (dif == 'jornada' || dif == 'catalogo') continue;

      final cli = Map<String, dynamic>.from(job['perfiles'] ?? {});
      
      final estadoOriginal = job['estado']?.toString() ?? 'abierto';
      final estadoTrabajo = estadoOriginal == 'eliminado' ? 'cancelado' : estadoOriginal;
      job['estado'] = estadoTrabajo;

      final estadoPuja = rowMap['estado']?.toString() ?? 'esperando';
      
      if (['asignado', 'en_curso', 'finalizado', 'cancelado'].contains(estadoTrabajo) &&['esperando', 'pendiente'].contains(estadoPuja)) continue;

      job['contraparteNombre'] = 'Cliente: ${cli['apodo'] ?? 'Anónimo'}';
      job['contraparteAvatar'] = cli['foto_url'] ?? '';
      
      job['ratingContraparte'] = (cli['rating_cliente'] as num?)?.toDouble() ?? (cli['rating'] as num?)?.toDouble() ?? 0.0;
      job['reviewsContraparte'] = (cli['cantidad_resenas_cliente'] as num?)?.toInt() ?? (cli['cantidad_resenas'] as num?)?.toInt() ?? 0;
      
      job['miOferta'] = rowMap['monto']?.toString();
      
      job['trabajos_publicados'] = (cli['trabajos_publicados'] as num?)?.toInt() ?? 0;
      job['trabajadores_contratados'] = (cli['trabajadores_contratados'] as num?)?.toInt() ?? 0;
      job['cancelaciones_cliente'] = (cli['cancelaciones_cliente'] as num?)?.toDouble() ?? 0.0;
      job['recomendacion_trabajadores'] = (cli['recomendacion_trabajadores'] as num?)?.toDouble() ?? 0.0;
      job['zona_trabajo_cliente'] = cli['zona_trabajo_cliente']?.toString() ?? '';
      
      job['estado_negociacion'] = estadoPuja; 
      job['estadoNegociacion'] = estadoPuja; 
      job['puja_id'] = rowMap['id'].toString();
      job['pujaId'] = rowMap['id'].toString();
      
      job['aceptoPrecioBase'] = rowMap['mensaje']?.toString() == 'Acepto precio base';
      job['profesionalAsignadoId'] = estadoPuja == 'aceptada' ? profesionalId : null;
      job['mensajesNoLeidos'] = unreadCounts[job['id'].toString()] ?? 0;
      job['ownerId'] = job['cliente_id'];
      
      if (rowMap['pro_califico_puja'] == true) {
        job['pro_califico'] = true;
      }
      if (rowMap['cliente_califico_puja'] == true) {
        job['cliente_califico'] = true;
      }

      trabajosPostulados.add(ModeloOficioTrabajo.fromJson(job)); 
    }
    return trabajosPostulados;
  }

  static Future<List<ModeloOficioTrabajo>> obtenerSolicitudesDirectasProfesionalOficios(String profesionalId, Map<String, int> unreadCounts) async {
    final res = await _client.from('trabajos')
        .select('*, perfiles!trabajos_cliente_id_fkey(apodo, foto_url, rating, rating_cliente, cantidad_resenas, cantidad_resenas_cliente, recomendacion_trabajadores, trabajos_publicados, trabajadores_contratados, cancelaciones_cliente, zona_trabajo_cliente)')
        .eq('profesional_solicitado_id', profesionalId)
        .neq('dificultad', 'jornada')
        .neq('dificultad', 'catalogo')
        .inFilter('estado',['abierto', 'asignado', 'en_curso', 'esperando_pin_salida', 'finalizado', 'finalizada', 'cancelado', 'eliminado'])
        .order('fecha_hora', ascending: false);

    return (res as List).map((row) {
      final rowMap = Map<String, dynamic>.from(row);
      final cli = Map<String, dynamic>.from(rowMap['perfiles'] ?? {});

      final estadoOriginal = rowMap['estado']?.toString() ?? 'abierto';
      rowMap['estado'] = estadoOriginal == 'eliminado' ? 'cancelado' : estadoOriginal;

      rowMap['contraparteNombre'] = 'Cliente: ${cli['apodo'] ?? 'Anónimo'}';
      rowMap['contraparteAvatar'] = cli['foto_url'] ?? '';
      
      rowMap['ratingContraparte'] = (cli['rating_cliente'] as num?)?.toDouble() ?? (cli['rating'] as num?)?.toDouble() ?? 0.0;
      rowMap['reviewsContraparte'] = (cli['cantidad_resenas_cliente'] as num?)?.toInt() ?? (cli['cantidad_resenas'] as num?)?.toInt() ?? 0;
      
      rowMap['trabajos_publicados'] = (cli['trabajos_publicados'] as num?)?.toInt() ?? 0;
      rowMap['trabajadores_contratados'] = (cli['trabajadores_contratados'] as num?)?.toInt() ?? 0;
      rowMap['cancelaciones_cliente'] = (cli['cancelaciones_cliente'] as num?)?.toDouble() ?? 0.0;
      rowMap['recomendacion_trabajadores'] = (cli['recomendacion_trabajadores'] as num?)?.toDouble() ?? 0.0;
      rowMap['zona_trabajo_cliente'] = cli['zona_trabajo_cliente']?.toString() ?? '';
      
      rowMap['profesionalAsignadoId'] =['asignado', 'en_curso', 'finalizado'].contains(rowMap['estado']) ? profesionalId : null;
      rowMap['mensajesNoLeidos'] = unreadCounts[rowMap['id'].toString()] ?? 0;
      rowMap['ownerId'] = rowMap['cliente_id'];

      return ModeloOficioTrabajo.fromJson(rowMap); 
    }).toList();
  }
}