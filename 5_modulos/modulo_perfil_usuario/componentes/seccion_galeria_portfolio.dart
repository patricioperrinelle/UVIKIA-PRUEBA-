// lib/5_modulos/modulo_perfil_usuario/componentes/seccion_galeria_portfolio.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class SeccionGaleriaPortfolio extends StatelessWidget {
  final List<String> imagenes;
  final Function(int)? onImageTap; 

  const SeccionGaleriaPortfolio({
    super.key,
    required this.imagenes,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imagenes.isEmpty) {
      return Container(
        padding: DimensionesApp.paddingPantalla,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColoresApp.cristalSuave,
          borderRadius: DimensionesApp.radioModales,
          border: Border.all(color: ColoresApp.bordeCristal),
        ),
        child: Column(
          children: const[
            Icon(Icons.photo_library_outlined, color: Colors.white24, size: 40),
            SizedBox(height: 10),
            Text('Sin fotos de portfolio aún.', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    final double itemWidth = (MediaQuery.of(context).size.width - 48 - 12) / 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: imagenes.asMap().entries.map((entry) {
        int idx = entry.key;
        String url = entry.value;
        bool isLocal = !url.startsWith('http');

        return GestureDetector(
          onTap: () => onImageTap?.call(idx),
          child: ClipRRect(
            borderRadius: DimensionesApp.radioTarjetas,
            child: Container(
              width: itemWidth,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: ColoresApp.bordeCristal, width: 1.5),
                color: ColoresApp.fondoTarjetas,
                // 🚨 REEMPLAZADO: Usamos CachedNetworkImageProvider en el DecorationImage
                image: DecorationImage(
                  image: isLocal ? FileImage(File(url)) as ImageProvider : CachedNetworkImageProvider(url),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children:[
                  Container(
                    color: Colors.black.withOpacity(0.2),
                    alignment: Alignment.center,
                    child: const Icon(Icons.zoom_out_map, color: Colors.white54, size: 32),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}