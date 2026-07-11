// lib/5_modulos/modulo_servicios_catalogo/servicios/servicio_actividad_catalogo_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_reserva_catalogo.dart';
import '../../../3_modelos/modelo_puja.dart';

class ServicioActividadCatalogoSupabase {
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
    });
  }

  static Future<List<ModeloReservaCatalogo>> obtenerPublicacionesClienteCatalogo(String clienteId, Map<String, int> unreadCounts) async {
    final res = await _client.from('trabajos')
        .select('*, pujas(*, perfiles!profesional_id(apodo, foto_url, rating, cantidad_resenas)), perfiles_solicitado:perfiles!profesional_solicitado_id(apodo, foto_url, rating, cantidad_resenas)')
        .eq('cliente_id', clienteId) 
        .eq('dificultad', 'catalogo')
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

      if (idAsignado == null && rowMap['dificultad'] == 'catalogo') {
        idAsignado = rowMap['profesional_asignado_id']?.toString() ?? rowMap['profesionalAsignadoId']?.toString();
      }

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
      } else if (idAsignado != null && rowMap['dificultad'] == 'catalogo') {
        proCounterpart = 'Profesional Asignado';
      }

      rowMap['contraparteNombre'] = proCounterpart;
      rowMap['contraparteAvatar'] = proAvatar;
      rowMap['ratingContraparte'] = proRating;
      rowMap['reviewsContraparte'] = proReviews;
      rowMap['pujas'] = pujas.map((p) => p.toJson()).toList(); 
      rowMap['profesionalAsignadoId'] = idAsignado; 
      rowMap['mensajesNoLeidos'] = unreadCounts[rowMap['id'].toString()] ?? 0;
      rowMap['ownerId'] = rowMap['cliente_id']; 

      return ModeloReservaCatalogo.fromJson(rowMap); 
    }).toList();
  }

  static Future<List<ModeloReservaCatalogo>> obtenerVentasCatalogoProfesional(String profesionalId, Map<String, int> unreadCounts) async {
    final res = await _client.from('trabajos')
        .select('*, perfiles:cliente_id(apodo, foto_url, rating, rating_cliente, cantidad_resenas, cantidad_resenas_cliente)')
        .eq('profesional_asignado_id', profesionalId)
        .eq('dificultad', 'catalogo')
        .inFilter('estado', ['asignado', 'abierto', 'aceptada', 'esperando_pin_llegada', 'en_curso', 'esperando_pin_salida', 'finalizado', 'finalizada', 'cancelado', 'eliminado', 'contratado', 'esperando_confirmacion_pro'])
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
      
      rowMap['mensajesNoLeidos'] = unreadCounts[rowMap['id'].toString()] ?? 0;
      rowMap['profesionalAsignadoId'] = profesionalId; 
      rowMap['ownerId'] = rowMap['cliente_id'];

      return ModeloReservaCatalogo.fromJson(rowMap); 
    }).toList();
  }
}
