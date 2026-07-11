// lib/5_modulos/modulo_explorar_feed/componentes/tarjeta_jornada_feed.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🛡️ R2-GUARDIAN: Inyección de Caché Visual Estricta
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';
import '../utilidades/calculador_tiempo_relativo.dart';

class TarjetaJornadaFeed extends StatelessWidget {
  final TrabajoContratable jornada;
  final bool yaOfertado;
  final bool isDueno; 
  final bool esModoCliente;
  final bool esGuardado; // 🚀 NUEVO PARÁMETRO V5.8
  final VoidCallback? onTap; 
  final void Function(TrabajoContratable jornada)? onTapTipado; 
  final VoidCallback onTapGuardar; // 🚀 NUEVO CANAL SÍNCRONO V5.8

  const TarjetaJornadaFeed({
    Key? key,
    required this.jornada,
    required this.yaOfertado,
    required this.isDueno,
    required this.esModoCliente,
    required this.esGuardado,
    this.onTap,
    this.onTapTipado,
    required this.onTapGuardar,
  }) : super(key: key);

  String _extraerHora(String fechaIso, String? horaFin) {
    if (fechaIso.isEmpty) return '';
    try {
      final d = DateTime.parse(fechaIso).toLocal();
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      
      if (horaFin != null && horaFin.isNotEmpty) {
        return '$h:$m a $horaFin hs';
      }
      return '$h:$m hs'; 
    } catch(e) {
      return ''; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); 
    final textTheme = tema.textTheme;

    String locText = jornada.localidad;
    if (locText.startsWith('Aprox.')) {
      final parts = locText.split('·');
      locText = parts.length > 1 ? parts[1].trim() : 'Ubicación reservada';
    }
    if (locText.isEmpty) locText = 'Ubicación reservada';

    String textoBadge;
    Color colorBadge;

    if (yaOfertado) {
      colorBadge = ColoresApp.primarioVerde;
      if (jornada.cantidadPujasTotales > 1) {
        textoBadge = 'Te postulaste +${jornada.cantidadPujasTotales - 1}';
      } else {
        textoBadge = 'Te postulaste';
      }
    } else {
      if (jornada.cantidadPujasTotales == 0) {
        textoBadge = 'Sé el primero';
        colorBadge = Colors.black.withOpacity(0.7);
      } else {
        textoBadge = '${jornada.cantidadPujasTotales} postulados';
        colorBadge = ColoresApp.secundarioCyan.withOpacity(0.9);
      }
    }

    final String horario = _extraerHora(jornada.fechaHora, jornada.horaFin);

    return GestureDetector(
      onTap: () {
        if (onTapTipado != null) onTapTipado!(jornada);
        else if (onTap != null) onTap!();
      },
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
                  _buildImagen(jornada.imagenes.isNotEmpty ? jornada.imagenes.first : ''),
                  
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
                          border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const[
                            Icon(Icons.bookmark_rounded, color: ColoresApp.primarioVerde, size: 10),
                            SizedBox(width: 4),
                            Text('MÍA', style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 9, fontWeight: FontWeight.w900)),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children:[
                          const Text(
                            '\$ ',
                            style: TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          Text(
                            jornada.precio,
                            style: const TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 2, width: double.infinity, color: ColoresApp.primarioVerde),

            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(CalculadorTiempoRelativo.calcular(jornada.fechaCreacion), style: TextStyle(color: textTheme.bodySmall?.color, fontSize: 9)),
                    ),
                    const SizedBox(height: 2),
                    
                    Expanded(
                      child: Text(
                        jornada.descripcion, 
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
    );
  }

  // 🛡️ R2-GUARDIAN: Implementación estricta de Caché de Imágenes y Destrucción de Image.network
  Widget _buildImagen(String url) {
    if (url.isEmpty) {
      return Container(
        color: ColoresApp.fondoBuscador,
        child: const Center(child: Icon(Icons.event_seat_rounded, color: Colors.white24, size: 30)),
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