// lib/4_componentes_globales/tarjetas/visor_imagen_pantalla_completa.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ VISUAL

class VisorImagenPantallaCompleta extends StatelessWidget {
  final List<String> imagenes;
  final int indiceInicial;

  const VisorImagenPantallaCompleta({
    Key? key,
    required this.imagenes,
    this.indiceInicial = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PageController controlador = PageController(initialPage: indiceInicial);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children:[
          // Fondo negro semitransparente que se cierra al tocarlo
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withOpacity(0.95)),
          ),
          
          // Carrusel de imágenes
          PageView.builder(
            controller: controlador,
            itemCount: imagenes.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final url = imagenes[index];
              final isLocal = !url.startsWith('http');
              
              return InteractiveViewer(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      // 🚨 REEMPLAZADO: Usamos CachedNetworkImageProvider
                      image: isLocal 
                          ? FileImage(File(url)) as ImageProvider 
                          : CachedNetworkImageProvider(url),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Botón de cerrar (X) arriba a la derecha
          Positioned(
            top: 10,
            right: 20,
            child: SafeArea(
              top: true,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}