// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/tarjeta_feed_vista_previa.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../2_tema/colores_app.dart';
import '../../../../3_modelos/modelo_servicio_catalogo.dart';

class TarjetaFeedVistaPrevia extends StatelessWidget {
  final String titulo;
  final String modalidad;
  final String duracion;
  final String zona;
  final File? fotoPortada;
  final String? urlPortada; // 🚨 NUEVO: Soporte para fotos de red
  final List<ModeloNivelServicio> planesElegidos;
  final double ratingProfesional;
  final int reviewsProfesional;

  const TarjetaFeedVistaPrevia({
    Key? key,
    required this.titulo,
    required this.modalidad,
    required this.duracion,
    required this.zona,
    this.fotoPortada,
    this.urlPortada,
    required this.planesElegidos,
    required this.ratingProfesional,
    required this.reviewsProfesional,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    final planesMostrar = planesElegidos.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: esOscuro ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esOscuro ? Colors.white12 : Colors.grey.shade200),
        boxShadow: esOscuro ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // 🚨 SOPORTE DUAL (Archivo Local vs URL de Red)
                  child: fotoPortada != null
                      ? Image.file(fotoPortada!, width: 110, height: 130, fit: BoxFit.cover)
                      : (urlPortada != null && urlPortada!.isNotEmpty)
                          ? Image.network(urlPortada!, width: 110, height: 130, fit: BoxFit.cover)
                          : Container(width: 110, height: 130, color: esOscuro ? Colors.grey[800] : Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: titulo.isEmpty ? 'Título del servicio' : titulo,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, height: 1.2),
                                  ),
                                  const WidgetSpan(child: SizedBox(width: 4)),
                                  const WidgetSpan(child: Icon(Icons.verified, color: ColoresApp.terciarioMorado, size: 16)),
                                ],
                              ),
                            ),
                          ),
                          Icon(Icons.favorite_border_rounded, color: Colors.grey.shade400, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      Text('Tu Negocio / Perfil', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(ratingProfesional.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface)),
                          Text(' ($reviewsProfesional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _construirPillGris(modalidad == 'a_domicilio' ? Icons.home_outlined : Icons.storefront_outlined, modalidad == 'a_domicilio' ? 'A domicilio' : 'En local', esOscuro),
                          _construirPillGris(Icons.access_time, duracion, esOscuro),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 14),
                          const SizedBox(width: 4),
                          Expanded(child: Text(zona, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (planesMostrar.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: esOscuro ? Colors.white12 : Colors.grey.shade200))
              ),
              child: Row(
                children: planesMostrar.asMap().entries.map((entry) {
                  int idx = entry.key;
                  ModeloNivelServicio plan = entry.value;
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: idx < planesMostrar.length - 1 ? (esOscuro ? Colors.white12 : Colors.grey.shade200) : Colors.transparent))
                      ),
                      child: Column(
                        children: [
                          Text(plan.nombre, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tema.colorScheme.onSurface), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('\$${plan.precioFijo.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirPillGris(IconData icono, String texto, bool esOscuro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: esOscuro ? Colors.white24 : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}