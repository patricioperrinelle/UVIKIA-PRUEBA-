// lib/5_modulos/modulo_servicios_catalogo/componentes/carousel_imagenes.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../2_tema/colores_app.dart';

class CarouselImagenes extends StatefulWidget {
  final List<String> imagenes;
  const CarouselImagenes({Key? key, required this.imagenes}) : super(key: key);

  @override
  State<CarouselImagenes> createState() => _CarouselImagenesState();
}

class _CarouselImagenesState extends State<CarouselImagenes> {
  final PageController _controller = PageController();
  int _paginaActual = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagenes.isEmpty) return const SizedBox.shrink();
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _paginaActual = index;
              });
            },
            itemCount: widget.imagenes.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.imagenes[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        if (widget.imagenes.length > 1)
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imagenes.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _paginaActual == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: _paginaActual == index ? ColoresApp.primarioVerde : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
