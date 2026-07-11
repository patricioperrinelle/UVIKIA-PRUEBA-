// lib/5_modulos/modulo_actividad_alertas/servicios/servicio_actividad_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_notificacion.dart';

class ServicioActividadSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<ModeloNotificacion>> obtenerNotificaciones(String usuarioId) async {
    final res = await _client.from('notificaciones').select().eq('usuario_id', usuarioId).order('fecha_creacion', ascending: false);
    return (res as List).map((row) => ModeloNotificacion.fromJson(row)).toList();
  }

  static Future<void> borrarTodasLasNotificaciones(String usuarioId) async => await _client.from('notificaciones').delete().eq('usuario_id', usuarioId);
  static Future<void> borrarNotificacionUnica(String notifId) async => await _client.from('notificaciones').delete().eq('id', notifId);
  static Future<void> borrarMultiplesNotificaciones(List<String> ids) async => await _client.from('notificaciones').delete().inFilter('id', ids);
}
