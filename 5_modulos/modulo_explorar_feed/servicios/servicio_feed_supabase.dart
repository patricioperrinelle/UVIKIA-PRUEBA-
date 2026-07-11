// lib/5_modulos/modulo_explorar_feed/servicios/servicio_feed_supabase.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ServicioFeedSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> obtenerJornadasPaginadasV5({
    required String ciudad, required String localidad, required String categoria, required String keyword,
    required bool cursorEsCiudad, required bool cursorEsLocalidad, required double cursorRank,
    required String cursorFecha, required int cursorRotacion, required String cursorId, required int limit, 
  }) async {
    final res = await _client.rpc('obtener_feed_jornadas_v5', params: {
      'p_ciudad': ciudad, 'p_localidad': localidad, 'p_filtro_categoria': categoria, 'p_keyword': keyword,
      'p_cursor_es_ciudad': cursorEsCiudad, 'p_cursor_es_localidad': cursorEsLocalidad, 'p_cursor_rank': cursorRank,
      'p_cursor_fecha': cursorFecha, 'p_cursor_rotacion': cursorRotacion, 'p_cursor_id': cursorId, 'p_limit': limit, 
    });
    return await _inyectarPerfilesEnBatch(List<Map<String, dynamic>>.from(res));
  }

  static Future<List<Map<String, dynamic>>> obtenerOficiosPaginadosV5({
    required String ciudad, required String localidad, required String misOficios, required String categoria, required String keyword,
    required bool cursorEsOficio, required bool cursorEsCiudad, required bool cursorEsLocalidad, required double cursorRank,
    required String cursorFecha, required int cursorRotacion, required String cursorId, required int limit, 
  }) async {
    final res = await _client.rpc('obtener_feed_oficios_v5', params: {
      'p_ciudad': ciudad, 'p_localidad': localidad, 'p_mis_oficios': misOficios, 'p_filtro_categoria': categoria, 'p_keyword': keyword,
      'p_cursor_es_oficio': cursorEsOficio, 'p_cursor_es_ciudad': cursorEsCiudad, 'p_cursor_es_localidad': cursorEsLocalidad,
      'p_cursor_rank': cursorRank, 'p_cursor_fecha': cursorFecha, 'p_cursor_rotacion': cursorRotacion, 'p_cursor_id': cursorId, 'p_limit': limit, 
    });
    return await _inyectarPerfilesEnBatch(List<Map<String, dynamic>>.from(res));
  }

  static Future<List<Map<String, dynamic>>> obtenerProfesionalesPaginadosV5({
    required String ciudad, required String localidad, required String categoria, required String keyword,
    required bool cursorEsCiudad, required bool cursorEsLocalidad, required double cursorRank, required num cursorScore, 
    required num cursorEstrellas, required String cursorActividad, required int cursorRotacion, required String cursorId,
    required int limit, required String miId,
  }) async {
    final res = await _client.rpc('obtener_feed_profesionales_v5', params: {
      'p_ciudad': ciudad, 'p_localidad': localidad, 'p_filtro_categoria': categoria, 'p_keyword': keyword,
      'p_cursor_es_ciudad': cursorEsCiudad, 'p_cursor_es_localidad': cursorEsLocalidad, 'p_cursor_rank': cursorRank,
      'p_cursor_score': cursorScore, 'p_cursor_estrellas': cursorEstrellas, 'p_cursor_actividad': cursorActividad,
      'p_cursor_rotacion': cursorRotacion, 'p_cursor_id': cursorId, 'p_limit': limit, 
      'p_mi_id': miId.isEmpty ? '00000000-0000-0000-0000-000000000000' : miId,
    });
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> _inyectarPerfilesEnBatch(List<Map<String, dynamic>> trabajos) async {
    if (trabajos.isEmpty) return trabajos;
    try {
      final Set<String> ownerIds = {};
      for (var t in trabajos) {
        final oId = t['cliente_id']?.toString() ?? t['owner_id']?.toString() ?? t['usuario_id']?.toString() ?? '';
        if (oId.isNotEmpty) ownerIds.add(oId);
      }
      
      if (ownerIds.isEmpty) return trabajos;
      
      final resPerfiles = await _client.from('perfiles')
          .select('id, apodo, nombre, foto_url, avatar_url, promedio_estrellas, cantidad_resenas_cliente')
          .inFilter('id', ownerIds.toList());
          
      final Map<String, Map<String, dynamic>> mapaPerfiles = {};
      for (var p in (resPerfiles as List)) { 
        mapaPerfiles[p['id'].toString()] = p; 
      }
      
      for (var i = 0; i < trabajos.length; i++) {
        final oId = trabajos[i]['cliente_id']?.toString() ?? trabajos[i]['owner_id']?.toString() ?? trabajos[i]['usuario_id']?.toString() ?? '';
        if (mapaPerfiles.containsKey(oId)) {
          trabajos[i]['perfil'] = mapaPerfiles[oId];
        }
      }
    } catch (e) { 
      debugPrint('Data-Miser: Fallo Batch Inyección. $e'); 
    }
    return trabajos;
  }

  static Future<Set<String>> obtenerMisPostulacionesIds(String miId) async {
    if (miId.isEmpty) return {};
    try {
      final res = await _client.from('pujas').select('trabajo_id').eq('profesional_id', miId); 
      return (res as List).map((e) => e['trabajo_id'].toString()).toSet();
    } catch (_) { return {}; }
  }

  // lib/5_modulos/modulo_explorar_feed/servicios/servicio_feed_supabase.dart
  static Future<Set<String>> obtenerMisFavoritosIds(String miId) async {
    if (miId.isEmpty) return {};
    try {
      final res = await _client.from('favoritos').select('profesional_id').eq('cliente_id', miId);
      return (res as List).map((e) => e['profesional_id'].toString()).toSet();
    } catch (e) { 
      // 🛡️ BARRERA ANTI-WIPEOUT: Si falla la red, obligamos a que el catch devuelva un error para que la RAM sobreviva.
      throw Exception('Fallo de red al obtener profesionales favoritos. $e'); 
    }
  }

  static Future<void> toggleFavorito(String miId, String proId, bool isYaFavorito) async {
    if (miId.isEmpty) return; 
    if (isYaFavorito) {
      await _client.from('favoritos').delete().match({'cliente_id': miId, 'profesional_id': proId});
    } else {
      await _client.from('favoritos').insert({'cliente_id': miId, 'profesional_id': proId});
    }
  }

  // ----------------------------------------------------------------------
  // 🚀 MÉTODOS DE RED PARA TRABAJOS Y JORNADAS GUARDADAS (V5.8)
  // ----------------------------------------------------------------------

  static Future<Set<String>> obtenerMisTrabajosGuardadosIds(String miId) async {
    if (miId.isEmpty) return {};
    try {
      final res = await _client.from('trabajos_guardados').select('trabajo_id').eq('usuario_id', miId);
      return (res as List).map((e) => e['trabajo_id'].toString()).toSet();
    } catch (e) {
      // 🛡️ ANTI-WIPEOUT: Si hay error de red, lanzamos la excepción para NO devolver lista vacía.
      throw Exception('Fallo de red al obtener guardados. $e');
    }
  }

  static Future<void> toggleTrabajoGuardado(String miId, String trabajoId, bool isYaGuardado) async {
    if (miId.isEmpty) return;
    if (isYaGuardado) {
      await _client.from('trabajos_guardados').delete().match({'usuario_id': miId, 'trabajo_id': trabajoId});
    } else {
      await _client.from('trabajos_guardados').insert({'usuario_id': miId, 'trabajo_id': trabajoId});
    }
  }
}