// lib/5_modulos/modulo_resolucion_conflictos/servicios/servicio_mediacion_supabase.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ServicioMediacionSupabase {
  static final _supabase = Supabase.instance.client;

  static String _obtenerUrlPublicaSegura(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http')) return path;
    return _supabase.storage.from('imagenes').getPublicUrl(path);
  }

  // Obtiene los datos del trabajo y la disputa activa en una sola llamada
  static Future<Map<String, dynamic>> obtenerDatosMediacion(String trabajoId) async {
    final trabajoRes = await _supabase.from('trabajos').select('*, perfiles!cliente_id(apodo, foto_url)').eq('id', trabajoId).single();
    final disputaRes = await _supabase.from('disputas').select().eq('trabajo_id', trabajoId).order('fecha_creacion', ascending: false).limit(1).maybeSingle();
    
    return {
      'trabajo': trabajoRes,
      'disputa': disputaRes,
    };
  }

  // El reportado acepta la solución (Ej: Acepta ir a reparar)
  static Future<void> aceptarSolucion(String disputaId, String trabajoId, String solucion) async {
    await _supabase.from('disputas').update({
      'estado': 'acuerdo_logrado',
      'historial_mediacion': _supabase.rpc('jsonb_array_append', params: {'_key': 'historial_mediacion', '_value': '{"accion": "Aceptó solución: $solucion", "fecha": "${DateTime.now().toUtc().toIso8601String()}"}'})
    }).eq('id', disputaId);
    
    // Si acuerdan reparar, devolvemos el trabajo a estado activo
    await _supabase.from('trabajos').update({'estado': 'en_curso', 'estado_negociacion': 'reparacion_acordada'}).eq('id', trabajoId);
  }

  // El reportado rechaza y eleva a soporte humano
  static Future<void> elevarASoporte(String disputaId, String motivoRechazo) async {
    await _supabase.from('disputas').update({
      'estado': 'escalado_soporte',
      'historial_mediacion': _supabase.rpc('jsonb_array_append', params: {'_key': 'historial_mediacion', '_value': '{"accion": "Rechazó reclamo: $motivoRechazo", "fecha": "${DateTime.now().toUtc().toIso8601String()}"}'})
    }).eq('id', disputaId);
  }
}