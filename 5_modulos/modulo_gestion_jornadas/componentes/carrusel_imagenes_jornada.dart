// lib/5_modulos/modulo_gestion_jornadas/componentes/carrusel_imagenes_jornada.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ
import 'dart:io';
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/tarjetas/visor_imagen_pantalla_completa.dart';

class CarruselImagenesJornada extends StatefulWidget {
  final List<String> imagenes;
  final String categoria;

  const CarruselImagenesJornada({
    Key? key, 
    required this.imagenes, 
    this.categoria = 'Jornada'
  }) : super(key: key);

  @override
  State<CarruselImagenesJornada> createState() => _CarruselImagenesJornadaState();
}

class _CarruselImagenesJornadaState extends State<CarruselImagenesJornada> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        child: Center(child: Icon(Icons.event_available_rounded, color: esOscuro ? Colors.white24 : Colors.black12, size: 70)),
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
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final path = widget.imagenes[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisorImagenPantallaCompleta(
                        imagenes: widget.imagenes,
                        indiceInicial: index,
                      ),
                    ),
                  );
                },
                child: _construirImagen(path, esOscuro),
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
                  Icon(Icons.room_service_outlined, size: 16, color: esOscuro ? Colors.white : Colors.black),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imagenes.length, (i) {
                  final active = _currentIndex == i;
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
        ],
      ),
    );
  }

  Widget _construirImagen(String path, bool esOscuro) {
    if (path.startsWith('http')) {
      // 🚨 REEMPLAZADO CON CACHÉ
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: esOscuro ? Colors.white24 : Colors.black12)),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: esOscuro ? Colors.white24 : Colors.black12)),
    );
  }
}