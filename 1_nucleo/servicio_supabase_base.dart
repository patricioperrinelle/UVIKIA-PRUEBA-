// lib/1_nucleo/servicio_supabase_base.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utilidades_imagen.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;

  /// Sube una imagen a Cloudflare R2
  static Future<String> uploadImage(File imageFile, String folderPath) async {
    try {
      final File compressedFile = await UtilidadesImagen.comprimirImagen(imageFile);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.webp';

      final response = await client.functions.invoke(
        'generar-url-r2',
        body: {
          'action': 'upload', // 🚨 Indicamos que queremos SUBIR
          'folderPath': folderPath,
          'fileName': fileName,
        },
      );

      final data = response.data;
      if (data['error'] != null) throw Exception(data['error']);

      final String uploadUrl = data['uploadUrl']; 
      final String publicUrl = data['publicUrl']; 

      final bytes = await compressedFile.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/webp'},
        body: bytes,
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Error al subir a Cloudflare: ${uploadResponse.body}');
      }

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }

  /// 🚨 NUEVO: Elimina físicamente una imagen de Cloudflare R2
  static Future<void> deleteImage(String publicUrl) async {
    try {
      // Solo intentamos borrar si es una imagen nuestra de R2
      if (!publicUrl.contains('r2.dev')) return;

      final response = await client.functions.invoke(
        'generar-url-r2',
        body: {
          'action': 'delete', // 🚨 Indicamos que queremos BORRAR
          'fileUrl': publicUrl,
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      print('Aviso silencioso (Borrado R2 falló): ${e.toString()}');
      // No lanzamos la excepción para no interrumpir el flujo del usuario si falla un borrado
    }
  }
}