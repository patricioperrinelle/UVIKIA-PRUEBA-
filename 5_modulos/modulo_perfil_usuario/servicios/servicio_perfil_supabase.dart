// lib/5_modulos/modulo_perfil_usuario/servicios/servicio_perfil_supabase.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../1_nucleo/servicio_supabase_base.dart'; 

class ServicioPerfilSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> obtenerPerfilConResenas(String uid) async {
    try {
      final perfilData = await _client
          .from('perfiles')
          .select('*') 
          .eq('id', uid)
          .maybeSingle();

      // 🛡️ CONSULTA EXACTA: Pide solo las columnas que existen en tu SQL. Ordena por 'fecha_creacion'.
      final resenasData = await _client
          .from('resenas')
          .select('id, trabajo_id, evaluador_id, evaluado_id, evaluador_nombre, evaluador_avatar, rating, comentario, fecha_creacion, rol_evaluado')
          .eq('evaluado_id', uid)
          .order('fecha_creacion', ascending: false);

      if (perfilData != null) {
        return {
          'perfil': perfilData,
          'resenas': resenasData,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener el perfil: $e');
    }
  }

  static Future<List<dynamic>> obtenerResenasPrivadas(String miId) async {
    try {
      // 🛡️ CONSULTA EXACTA: Ordena por 'fecha_creacion'.
      return await _client.from('resenas').select().eq('evaluado_id', miId).order('fecha_creacion', ascending: false);
    } catch (e) {
      throw Exception('Error al obtener reseñas privadas: $e');
    }
  }

  static Future<List<dynamic>> obtenerFavoritos(String miId) async {
    try {
      return await _client.from('favoritos').select('*, perfiles(*)').eq('cliente_id', miId);
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  static Future<void> activarModoProfesional(String uid) async {
    try {
      await _client.from('perfiles').update({'es_profesional': true}).eq('id', uid).select().single();
    } catch (e) {
      throw Exception('Error activando modo profesional: $e');
    }
  }

  static Future<void> actualizarPerfil(String uid, Map<String, dynamic> payload) async {
    try {
      await _client.from('perfiles').update(payload).eq('id', uid).select().single();
    } catch (e) {
      throw Exception('Error al actualizar el perfil en BD: $e');
    }
  }

  static Future<String> subirImagen(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return '';

      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('Usuario no autenticado.');

      final String publicUrl = await SupabaseService.uploadImage(file, 'perfiles/$uid/avatar');
      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir imagen a Cloudflare R2: $e');
    }
  }

  static Future<bool> toggleFavorito(String miId, String proId) async {
    try {
      final exists = await _client.from('favoritos').select().match({'cliente_id': miId, 'profesional_id': proId}).maybeSingle();
      if (exists != null) {
        await _client.from('favoritos').delete().match({'cliente_id': miId, 'profesional_id': proId});
        return false;
      } else {
        await _client.from('favoritos').insert({'cliente_id': miId, 'profesional_id': proId}).select().single();
        return true;
      }
    } catch (e) {
      throw Exception('Error al actualizar favoritos: $e');
    }
  }

  static Future<void> destacarResena(String uid, String resenaId) async {
    try {
      await _client.from('perfiles').update({'resena_destacada_id': resenaId}).eq('id', uid).select().single();
    } catch (e) {
      throw Exception('Error al destacar la reseña: $e');
    }
  }

  static Future<void> enviarDenuncia(String denuncianteId, String denunciadoId, String motivo) async {
    try {
      await _client.from('reportes').insert({
        'denunciante_id': denuncianteId,
        'denunciado_id': denunciadoId,
        'motivo': motivo,
      }).select().single();
    } catch (e) {
      throw Exception('Error al enviar la denuncia: $e');
    }
  }
}