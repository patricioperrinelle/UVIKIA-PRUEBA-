// lib/5_modulos/modulo_negociacion_oficios/componentes/carrusel_imagenes_trabajo.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/tarjetas/visor_imagen_pantalla_completa.dart';

class CarruselImagenesTrabajo extends StatefulWidget {
  final List<String> imagenes;
  final bool soyElDueno;
  final String categoria; 

  const CarruselImagenesTrabajo({
    Key? key,
    required this.imagenes,
    required this.soyElDueno,
    this.categoria = 'Oficio',
  }) : super(key: key);

  @override
  State<CarruselImagenesTrabajo> createState() => _CarruselImagenesTrabajoState();
}

class _CarruselImagenesTrabajoState extends State<CarruselImagenesTrabajo> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String path) {
    String cleanUrl = path.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", "").trim();
    
    if (cleanUrl.startsWith('http')) {
      // 🚨 REEMPLAZADO CON CACHÉ
      return CachedNetworkImage(
        imageUrl: cleanUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde, strokeWidth: 2)),
        errorWidget: (context, url, error) => Container(color: ColoresApp.fondoTarjetas, child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 48))),
      );
    }
    return Image.file(
      File(cleanUrl), 
      fit: BoxFit.cover, 
      errorBuilder: (_, __, ___) => Container(color: ColoresApp.fondoTarjetas, child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 48)))
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    if (widget.imagenes.isEmpty) {
      return Container(
        height: 280, 
        decoration: BoxDecoration(
          color: esOscuro ? const Color(0xFF1A1A1A) : Colors.grey[300],
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[Icon(widget.soyElDueno ? Icons.description_rounded : Icons.handshake_rounded, color: Colors.white24, size: 90)],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280, 
      child: Stack(
        children:[
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.imagenes.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final imagenesLimpias = widget.imagenes.map((e) => e.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", "").trim()).toList();
                  showDialog(
                    context: context,
                    builder: (ctx) => VisorImagenPantallaCompleta(
                      imagenes: imagenesLimpias,
                      indiceInicial: index,
                    ),
                  );
                },
                child: _buildImageWidget(widget.imagenes[index]),
              );
            },
          ),
          
          Positioned(
            bottom: 44, 
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: esOscuro ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const[
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children:[
                  Icon(Icons.handyman_rounded, size: 16, color: esOscuro ? Colors.white : Colors.black),
                  const SizedBox(width: 6),
                  Text(
                    widget.categoria, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: esOscuro ? Colors.white : Colors.black)
                  ),
                ],
              ),
            ),
          ),
          
          if (widget.imagenes.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imagenes.length, (i) {
                    final active = _currentImageIndex == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? ColoresApp.primarioVerde : (esOscuro ? Colors.white38 : Colors.black38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}