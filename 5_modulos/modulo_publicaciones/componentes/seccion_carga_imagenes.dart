// lib/5_modulos/modulo_publicaciones/componentes/seccion_carga_imagenes.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ VISUAL AÑADIDO
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/modales_y_alertas/bottom_sheet_selector_imagen.dart';

class SeccionCargaImagenes extends StatelessWidget {
  final List<String> imagenes;
  final Function(ImageSource) onAgregar;
  final Function(int) onEliminar;

  const SeccionCargaImagenes({
    super.key, // Sintaxis moderna de Dart
    required this.imagenes,
    required this.onAgregar,
    required this.onEliminar,
  });

  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Para que el SafeArea del componente global funcione bien
      builder: (ctx) => BottomSheetSelectorImagen(
        titulo: 'Añadir imágenes del trabajo', // Aprovechamos el nuevo parámetro
        onCameraTap: () { 
          Navigator.pop(ctx); 
          onAgregar(ImageSource.camera); 
        },
        onGalleryTap: () { 
          Navigator.pop(ctx); 
          onAgregar(ImageSource.gallery); 
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    if (imagenes.isEmpty) {
      return Container(
        width: double.infinity, 
        height: 200,
        decoration: BoxDecoration(
          color: esOscuro ? ColoresApp.cristalSuave : Colors.black.withOpacity(0.04),
          borderRadius: DimensionesApp.radioTarjetas, 
          border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12)
        ), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.camera_alt, size: 50, color: tema.textTheme.bodySmall?.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => onAgregar(ImageSource.camera), 
                  icon: Icon(Icons.camera, color: tema.colorScheme.onSurface),
                  label: Text('Cámara', style: TextStyle(color: tema.colorScheme.onSurface))
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => onAgregar(ImageSource.gallery), 
                  icon: Icon(Icons.image, color: tema.colorScheme.onSurface), 
                  label: Text('Galería', style: TextStyle(color: tema.colorScheme.onSurface))
                ),
              ],
            )
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(
            imagenes.length < 5 ? imagenes.length + 1 : imagenes.length,
            (index) {
              if (index == imagenes.length) {
                return GestureDetector(
                  onTap: () => _mostrarOpciones(context),
                  child: Container(
                    width: 150, 
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: esOscuro ? ColoresApp.cristalSuave : Colors.black.withOpacity(0.04),
                      borderRadius: DimensionesApp.radioTarjetas, 
                      border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12)
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: <Widget>[
                        Icon(Icons.add_a_photo, size: 40, color: tema.textTheme.bodySmall?.color),
                        const SizedBox(height: 8), 
                        Text('Agregar', style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold))
                      ]
                    ),
                  ),
                );
              }
              
              final isLocal = !imagenes[index].startsWith('http');
              return Container(
                width: 250, 
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: DimensionesApp.radioTarjetas, 
                      child: isLocal 
                          ? Image.file(File(imagenes[index]), fit: BoxFit.cover)
                          // 🚨 REEMPLAZADO: Image.network por CachedNetworkImage
                          : CachedNetworkImage(imageUrl: imagenes[index], fit: BoxFit.cover)
                    ),
                    Positioned(
                      top: 8, 
                      right: 8, 
                      child: GestureDetector(
                        onTap: () => onEliminar(index), 
                        child: Container(
                          padding: const EdgeInsets.all(4), 
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle), 
                          child: const Icon(Icons.close, color: Colors.white, size: 20)
                        )
                      )
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}