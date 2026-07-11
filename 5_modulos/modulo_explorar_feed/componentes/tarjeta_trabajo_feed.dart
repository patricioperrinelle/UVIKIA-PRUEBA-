// lib/5_modulos/modulo_explorar_feed/componentes/tarjeta_trabajo_feed.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🛡️ R2-GUARDIAN: Caché Visual Estricta
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';
import '../utilidades/calculador_tiempo_relativo.dart';

class TarjetaTrabajoFeed extends StatelessWidget {
  final TrabajoContratable trabajo;
  final bool yaOfertado; 
  final bool isDueno;
  final bool esModoCliente;
  final bool esGuardado; // 🚀 NUEVO PARÁMETRO V5.8
  final VoidCallback onTap;
  final VoidCallback onTapGuardar; // 🚀 NUEVO CANAL SÍNCRONO V5.8

  const TarjetaTrabajoFeed({
    Key? key,
    required this.trabajo,
    required this.yaOfertado,
    required this.isDueno,
    required this.esModoCliente,
    required this.esGuardado,
    required this.onTap,
    required this.onTapGuardar,
  }) : super(key: key);

  // 🛡️ QA-TERMINATOR: Parseo Defensivo de Fechas
  String _extraerHora(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return '';
    try {
      final d = DateTime.parse(fechaIso).toLocal();
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m hs'; 
    } catch(e) {
      return ''; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); 
    final textTheme = tema.textTheme;

    // 🛡️ QA-TERMINATOR: Fallbacks seguros para evitar "Null check operator"
    final String estadoSeguro = trabajo.estado ?? 'abierto';
    final String dificultadSegura = trabajo.dificultad ?? '1';
    final int pujasSeguras = trabajo.cantidadPujasTotales ?? 0;
    final String precioSeguro = trabajo.precio ?? '0';
    final String fechaCreacionSegura = trabajo.fechaCreacion ?? '';
    final String descripcionSegura = trabajo.descripcion ?? '';
    
    // Extracción segura de la primera imagen
    String primeraImagen = '';
    if (trabajo.imagenes != null && trabajo.imagenes.isNotEmpty) {
      primeraImagen = trabajo.imagenes.first.toString();
    }

    final bool estaAsignado = estadoSeguro == 'asignado' || estadoSeguro == 'en_curso' || estadoSeguro == 'finalizado';

    Color diffColor;
    if (dificultadSegura == '3') {
      diffColor = ColoresApp.errorRojo;
    } else if (dificultadSegura == '2') {
      diffColor = ColoresApp.advertenciaAmarillo;
    } else {
      diffColor = ColoresApp.primarioVerde;
    }

    String locText = trabajo.localidad ?? 'Ubicación reservada';
    
    // Limpiador Legacy
    if (locText.startsWith('Aprox.')) {
      final parts = locText.split('·');
      locText = parts.length > 1 ? parts[1].trim() : 'Ubicación reservada';
    }
    if (locText.isEmpty) locText = 'Ubicación reservada';

    String textoBadge;
    Color colorBadge;

    if (yaOfertado) {
      colorBadge = ColoresApp.primarioVerde;
      if (pujasSeguras > 1) {
        textoBadge = 'Te postulaste +${pujasSeguras - 1}';
      } else {
        textoBadge = 'Te postulaste';
      }
    } else {
      if (pujasSeguras == 0) {
        textoBadge = 'Sé el primero';
        colorBadge = Colors.black.withOpacity(0.7);
      } else {
        textoBadge = '$pujasSeguras postulados';
        colorBadge = ColoresApp.secundarioCyan.withOpacity(0.9);
      }
    }

    final String horario = _extraerHora(trabajo.fechaHora);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: estaAsignado ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: tema.cardColor,
            border: Border.all(color: tema.dividerColor.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:[
              Expanded(
                flex: 45,
                child: Stack(
                  fit: StackFit.expand,
                  children:[
                    _buildImagen(primeraImagen),
                    
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors:[Colors.black.withOpacity(0.8), Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorBadge,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(textoBadge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // 🛡️ LÓGICA EXCLUYENTE V5.8: MÍA vs BOTÓN DE GUARDADO
                    if (isDueno)
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: diffColor.withOpacity(0.5), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:[
                              Icon(Icons.bookmark_rounded, color: diffColor, size: 10),
                              const SizedBox(width: 4),
                              Text('MÍA', style: TextStyle(color: diffColor, fontSize: 9, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 6, left: 6,
                        child: GestureDetector(
                          onTap: onTapGuardar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.6),
                              border: Border.all(color: Colors.white24, width: 0.5),
                            ),
                            child: Icon(
                              esGuardado ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: esGuardado ? ColoresApp.primarioVerde : Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '\$ $precioSeguro',
                          style: TextStyle(color: diffColor, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),

                    if (estaAsignado)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 2), color: Colors.black54),
                              child: const Text('OFERTA TOMADA', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Container(height: 2, width: double.infinity, color: diffColor),

              Expanded(
                flex: 55,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(CalculadorTiempoRelativo.calcular(fechaCreacionSegura), style: TextStyle(color: textTheme.bodySmall?.color, fontSize: 9)),
                      ),
                      const SizedBox(height: 2),
                      
                      Expanded(
                        child: Text(
                          descripcionSegura, 
                          maxLines: 5, 
                          overflow: TextOverflow.ellipsis, 
                          style: textTheme.titleSmall?.copyWith(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
                        ),
                      ),
                      
                      Row(
                        children:[
                          Expanded(
                            flex: 1,
                            child: horario.isNotEmpty
                              ? Row(
                                  children:[
                                    Icon(Icons.access_time_rounded, color: textTheme.bodyMedium?.color, size: 12),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        horario, 
                                        style: TextStyle(color: textTheme.bodyMedium?.color, fontSize: 11, fontWeight: FontWeight.bold), 
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children:[
                                const Icon(Icons.location_on_rounded, color: ColoresApp.errorRojo, size: 12),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    locText, 
                                    style: TextStyle(color: textTheme.bodyMedium?.color, fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🛡️ R2-GUARDIAN: Implementación estricta de Caché de Imágenes
  Widget _buildImagen(String url) {
    if (url.isEmpty) {
      return Container(
        color: ColoresApp.fondoBuscador,
        child: const Center(child: Icon(Icons.handyman_rounded, color: Colors.white24, size: 30)),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: ColoresApp.fondoBuscador,
        child: const Center(
          child: CircularProgressIndicator(color: ColoresApp.primarioVerde, strokeWidth: 2)
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: ColoresApp.fondoBuscador,
        child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 30)),
      ),
    );
  }
}