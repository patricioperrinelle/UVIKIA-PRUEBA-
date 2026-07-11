// lib/5_modulos/modulo_perfil_usuario/componentes/seccion_edicion_portfolio.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ VISUAL AÑADIDO
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class SeccionEdicionPortfolio extends StatelessWidget {
  final List<String> imagenes;
  final VoidCallback onAddTap;
  final Function(String) onRemoveTap;

  const SeccionEdicionPortfolio({
    Key? key,
    required this.imagenes,
    required this.onAddTap,
    required this.onRemoveTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:[
        // 🚨 Botón de Añadir (Desaparece si ya hay 5 fotos)
        if (imagenes.length < 5)
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: ColoresApp.cristalSuave, 
                borderRadius: DimensionesApp.radioTarjetas,
                border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3), width: 2), 
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Icon(Icons.add_a_photo, color: ColoresApp.primarioVerde.withOpacity(0.8), size: 28),
                  const SizedBox(height: 8),
                  Text('Añadir', style: TextStyle(color: ColoresApp.primarioVerde.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        
        // 🚨 Grilla de imágenes actuales con botón para eliminar
        ...imagenes.map((url) {
          bool isLocal = !url.startsWith('http');
          
          return Stack(
            children:[
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  borderRadius: DimensionesApp.radioTarjetas,
                  image: DecorationImage(
                    image: isLocal 
                        ? FileImage(File(url)) as ImageProvider
                        // 🚨 REEMPLAZADO: NetworkImage por CachedNetworkImageProvider
                        : CachedNetworkImageProvider(url), 
                    fit: BoxFit.cover
                  ),
                ),
              ),
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => onRemoveTap(url),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}