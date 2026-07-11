// lib/5_modulos/modulo_servicios_catalogo/componentes/tarjeta_servicio_catalogo.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ VISUAL
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';

class TarjetaServicioCatalogo extends StatelessWidget {
  final ModeloServicioCatalogo servicio;
  final VoidCallback onTapVerServicio;
  final VoidCallback? onTapFavorito;
  final bool esFavorito;
  final bool esVistaPro;
  final VoidCallback? onTapEliminar;
  final VoidCallback? onTapPausar;
  final VoidCallback? onTapReanudar;

  const TarjetaServicioCatalogo({
    Key? key,
    required this.servicio,
    required this.onTapVerServicio,
    this.onTapFavorito,
    this.esFavorito = false,
    this.esVistaPro = false,
    this.onTapEliminar,
    this.onTapPausar,
    this.onTapReanudar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    final planesMostrar = servicio.niveles.take(3).toList();

    return Stack(
      children: [
        GestureDetector(
          onTap: onTapVerServicio, 
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: esOscuro ? ColoresApp.fondoTarjetas : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade300),
              boxShadow: esOscuro ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
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
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: servicio.imagenes.isNotEmpty
                            ? (servicio.imagenes.first.startsWith('http')
                                // 🚨 REEMPLAZADO: Usamos CachedNetworkImage
                                ? CachedNetworkImage(
                                    imageUrl: servicio.imagenes.first,
                                    width: 110,
                                    height: 145,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 110, height: 145, 
                                      color: esOscuro ? Colors.grey[800] : Colors.grey[200], 
                                      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: 110, height: 145, 
                                      color: esOscuro ? Colors.grey[800] : Colors.grey[200], 
                                      child: const Icon(Icons.image, color: Colors.grey)
                                    ),
                                  )
                                : Image.file(File(servicio.imagenes.first), width: 110, height: 145, fit: BoxFit.cover))
                            : Container(width: 110, height: 145, color: esOscuro ? Colors.grey[800] : Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                      ),
                      if (!esVistaPro)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: onTapFavorito,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4), 
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                color: esFavorito ? Colors.redAccent : Colors.white, 
                                size: 18
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: SizedBox(
                      height: 145,
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
                                        text: servicio.titulo,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, height: 1.2),
                                      ),
                                      if (servicio.profesionalVerificado) ...[
                                        const WidgetSpan(child: SizedBox(width: 4)),
                                        const WidgetSpan(child: Icon(Icons.verified, color: ColoresApp.terciarioMorado, size: 16)),
                                      ],
                                      if (servicio.estado == 'pausado') ...[
                                        const WidgetSpan(child: SizedBox(width: 4)),
                                        WidgetSpan(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('PAUSADO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _construirPillModalidad(servicio.modalidad, esOscuro),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  servicio.profesionalNombre.isEmpty ? 'Profesional Independiente' : servicio.profesionalNombre, 
                                  style: TextStyle(fontSize: 12, color: esOscuro ? Colors.grey.shade400 : Colors.black87, fontWeight: FontWeight.bold), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text(servicio.profesionalRating.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface)),
                            ],
                          ),
                          
                          const SizedBox(height: 6), 
                          
                          Text(
                            servicio.descripcionCortaFeed,
                            style: TextStyle(fontSize: 12, color: esOscuro ? Colors.grey.shade300 : Colors.black87, height: 1.3, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const Spacer(),

                          Row(
                            children: [
                              Icon(Icons.location_on, color: esOscuro ? Colors.grey.shade400 : Colors.grey.shade800, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  servicio.ubicacionBaseCortada, 
                                  style: TextStyle(fontSize: 11, color: esOscuro ? Colors.grey.shade300 : Colors.black87, fontWeight: FontWeight.w600), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),

                          Row(
                            children: [
                              Icon(Icons.calendar_month, color: esOscuro ? Colors.grey.shade400 : Colors.grey.shade800, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  servicio.diasLaboralesResumen, 
                                  style: TextStyle(fontSize: 11, color: esOscuro ? Colors.grey.shade300 : Colors.black87, fontWeight: FontWeight.w600), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                )
                              ),
                              if (servicio.usaProductosPremium) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.auto_awesome, color: Colors.amber, size: 10),
                                      SizedBox(width: 2),
                                      Text('PREMIUM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                          const SizedBox(height: 2),

                          Row(
                            children: [
                              Icon(Icons.access_time, color: esOscuro ? Colors.grey.shade400 : Colors.grey.shade800, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  servicio.horarioLaboralResumen, 
                                  style: TextStyle(fontSize: 11, color: esOscuro ? Colors.grey.shade300 : Colors.black87, fontWeight: FontWeight.w600), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                )
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
            
            if (servicio.etiquetasConfianza.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: servicio.etiquetasConfianza.map((etiqueta) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColoresApp.primarioVerde.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 11, color: ColoresApp.primarioVerde),
                          const SizedBox(width: 4),
                          Text(
                            etiqueta, 
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: esOscuro ? ColoresApp.primarioVerde : Colors.green.shade800
                            )
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            if (planesMostrar.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200))
                ),
                child: Row(
                  children: planesMostrar.asMap().entries.map((entry) {
                    int idx = entry.key;
                    ModeloNivelServicio plan = entry.value;
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: idx < planesMostrar.length - 1 ? (esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200) : Colors.transparent))
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SERVICIO ${plan.nombre.toUpperCase()}', 
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: esOscuro ? Colors.grey.shade400 : Colors.black87, letterSpacing: 0.5), 
                              textAlign: TextAlign.center, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${plan.precioFijo.toInt()}', 
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: tema.colorScheme.onSurface), 
                              textAlign: TextAlign.center
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    ),
    if (esVistaPro) ...[
      if (onTapEliminar != null)
        Positioned(
          right: 12,
          top: 48,
          child: Material(
            color: esOscuro ? Colors.white12 : Colors.grey.shade100,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.2),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
              onPressed: onTapEliminar,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      if (onTapPausar != null && servicio.estado == 'publicado')
        Positioned(
          right: 12,
          top: 96,
          child: Material(
            color: esOscuro ? Colors.white12 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.2),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTapPausar,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause_circle_outline_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    const Text('Pausar', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (onTapReanudar != null && servicio.estado == 'pausado')
        Positioned(
          right: 12,
          top: 96,
          child: Material(
            color: esOscuro ? Colors.white12 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.2),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTapReanudar,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline_rounded, color: ColoresApp.primarioVerde, size: 16),
                    const SizedBox(width: 4),
                    const Text('Activar', style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
    ]
    ],
  );
}

  Widget _construirPillModalidad(String modalidad, bool esOscuro) {
    final esDomicilio = modalidad == 'a_domicilio';
    final Color colorFuerte = esDomicilio ? ColoresApp.terciarioMorado : (esOscuro ? Colors.white : Colors.black87);
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: esDomicilio ? colorFuerte.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorFuerte, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(esDomicilio ? Icons.local_shipping : Icons.storefront_outlined, size: 10, color: colorFuerte),
          const SizedBox(width: 4),
          Text(
            esDomicilio ? 'A DOMICILIO' : 'EN LOCAL', 
            style: TextStyle(fontSize: 9, color: colorFuerte, fontWeight: FontWeight.w900, letterSpacing: 0.5)
          ),
        ],
      ),
    );
  }
}