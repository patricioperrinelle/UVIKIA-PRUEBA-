// lib/1_nucleo/utilidades_imagen.dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class UtilidadesImagen {
  /// Reduce la foto a resolución móvil y la convierte a WebP (Ahorra 10GB en R2)
  static Future<File> comprimirImagen(File archivoCrudo) async {
    try {
      final directorioTemp = await getTemporaryDirectory();
      final nombreUnico = DateTime.now().millisecondsSinceEpoch.toString();
      final rutaDestino = '${directorioTemp.path}/$nombreUnico.webp';

      final XFile? resultado = await FlutterImageCompress.compressAndGetFile(
        archivoCrudo.absolute.path,
        rutaDestino,
        quality: 75, // Calidad óptima visual
        minWidth: 1280, // Límite de ancho
        minHeight: 1280, // Límite de alto
        format: CompressFormat.webp, // Formato súper ligero
      );

      if (resultado != null) {
        return File(resultado.path);
      }
      return archivoCrudo; // Si falla, devuelve la original para no crashear
    } catch (e) {
      return archivoCrudo; // Failsafe (Anti-crasheo)
    }
  }
}