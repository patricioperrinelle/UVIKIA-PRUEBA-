// lib/5_modulos/modulo_chat_mensajes/servicios/servicio_chat_supabase.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicioChatSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  // 🚀 REPARADO: Se elimina el .stream() que causaba fugas.
  // Ahora usamos una consulta SQL estándar para la carga inicial y los fetches del Watchdog.
  static Future<List<Map<String, dynamic>>> obtenerHistorialMensajes(dynamic trabajoId) async {
    try {
      return await _client
          .from('mensajes')
          .select()
          .eq('trabajo_id', trabajoId)
          .order('fecha', ascending: false);
    } catch (e) {
      throw Exception('Error al descargar el historial de chat: $e');
    }
  }

  // 🚨 INDISPENSABLE EN JORNADAS: Receptor ID exigido
  static Future<void> enviarMensajeTexto({
    required dynamic trabajoId,
    required String emisorId,
    required String receptorId, 
    required String texto,
  }) async {
    final String textoLimpio = texto.trim();
    if (textoLimpio.isEmpty) return;
    if (textoLimpio.toUpperCase().startsWith('SYS_')) throw Exception('Comandos de sistema reservados.');

    try {
      await _client.from('mensajes').insert({
        'trabajo_id': trabajoId,
        'emisor_id': emisorId,
        'receptor_id': receptorId, 
        'texto': textoLimpio,
      });
    } catch (e) {
      throw Exception('Error al enviar el mensaje: $e');
    }
  }

  static Future<void> marcarMensajesComoLeidos({
    required dynamic trabajoId,
    required String miId,
    required String contraparteId,
  }) async {
    try {
      await _client.from('mensajes').update({'leido': true})
          .eq('trabajo_id', trabajoId)
          .eq('emisor_id', contraparteId)
          .eq('receptor_id', miId) 
          .eq('leido', false);
    } catch (e) {}
  }
}