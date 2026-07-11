// lib/5_modulos/modulo_publicaciones/servicios/servicio_publicaciones_supabase.dart
import 'dart:io'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../1_nucleo/gestor_sincronizacion_offline.dart';
import '../../../1_nucleo/servicio_supabase_base.dart'; // <-- Importamos nuestro nuevo motor

class ServicioPublicacionesSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> insertarTrabajo(Map<String, dynamic> payload) async {
    try {
      final res = await _client.from('trabajos').insert(payload).select('id').maybeSingle();
      
      if (payload['profesional_solicitado_id'] != null && res != null) {
        await _client.from('notificaciones').insert({
          'usuario_id': payload['profesional_solicitado_id'],
          'trabajo_id': res['id'].toString(),
          'titulo': 'Nueva Solicitud Privada',
          'mensaje': 'Alguien te ha solicitado un presupuesto exclusivo.',
          'tipo': 'oferta',
        });
      }
    } catch (e) {
      await OfflineSyncManager().queueAction('publicar_trabajo', payload);
      throw Exception('El trabajo se guardó localmente y se subirá cuando haya conexión. ($e)');
    }
  }

  static Future<void> actualizarTrabajo(String trabajoId, String clienteId, Map<String, dynamic> payload) async {
    try {
      await _client.from('trabajos')
          .update(payload)
          .eq('id', trabajoId)
          .eq('cliente_id', clienteId);
    } catch (e) {
      throw Exception('Error al actualizar la publicación: $e');
    }
  }

  static Future<List<String>> subirMultiplesImagenes(List<String> pathsLocales) async {
    List<String> urlsSubidas = [];
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Usuario no autenticado.');

    for (int i = 0; i < pathsLocales.length; i++) {
      final file = File(pathsLocales[i]);
      if (!file.existsSync()) continue;

      // 🚨 USAMOS EL NUEVO MOTOR R2 COMPRIMIDO Y SEGURO
      final String publicUrl = await SupabaseService.uploadImage(
        file, 
        'perfiles/$uid/publicaciones'
      );
      
      if (publicUrl.isNotEmpty) {
        urlsSubidas.add(publicUrl);
      }
    }
    return urlsSubidas;
  }
}