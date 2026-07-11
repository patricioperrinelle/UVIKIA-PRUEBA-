// lib/5_modulos/modulo_perfil_usuario/componentes/selector_imagen_perfil_editable.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ VISUAL AÑADIDO
import '../../../2_tema/colores_app.dart';

class SelectorImagenPerfilEditable extends StatelessWidget {
  final String imagenActual;
  final VoidCallback onTap;

  const SelectorImagenPerfilEditable({
    Key? key,
    required this.imagenActual,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children:[
            // 🚨 SQUIRCLE GRANDE
            Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), // Cuadrado redondeado
                color: Colors.white12,
                border: Border.all(color: ColoresApp.terciarioMorado, width: 3),
                image: imagenActual.isNotEmpty ? DecorationImage(
                  image: imagenActual.startsWith('http') 
                     // 🚨 REEMPLAZADO: NetworkImage por CachedNetworkImageProvider
                     ? CachedNetworkImageProvider(imagenActual) 
                     : FileImage(File(imagenActual)) as ImageProvider, 
                  fit: BoxFit.cover
                ) : null,
                boxShadow:[BoxShadow(color: ColoresApp.terciarioMorado.withOpacity(0.2), blurRadius: 20)],
              ),
              child: imagenActual.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white54) : null,
            ),
            // Overlay Oscuro con la Cámara
            Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), // Mismo radio
                color: Colors.black.withOpacity(0.4),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}