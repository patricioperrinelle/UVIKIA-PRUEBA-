// lib/5_modulos/modulo_actividad_alertas/componentes/tarjeta_historial_estado.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';
import '../../../4_componentes_globales/contratos/analizador_estado.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';

class TarjetaHistorialEstado extends StatelessWidget {
  final TrabajoContratable trabajo;
  final bool esDueno;
  final bool esHistorial;
  final int badgeCount;
  final String miId;
  final VoidCallback? onTap; 
  final void Function(TrabajoContratable trabajoTipado)? onTapTipado; 
  final VoidCallback onDelete;

  const TarjetaHistorialEstado({
    Key? key,
    required this.trabajo,
    required this.esDueno,
    required this.esHistorial,
    this.badgeCount = 0,
    required this.miId,
    this.onTap,
    this.onTapTipado,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); 
    final esOscuro = tema.brightness == Brightness.dark;
    
    final analizador = RegistroAnalizadoresEstado.obtenerPorDominio(trabajo.dominio);
    if (analizador == null) return const SizedBox.shrink(); // Safety fallback

    final vista = analizador.analizar(
      trabajo: trabajo, 
      esDueno: esDueno, 
      miId: miId, 
      esHistorial: esHistorial
    );
    
    final bool hasImage = trabajo.imagenes.isNotEmpty;
    final bool faltaCalificar = (trabajo.estado == 'finalizado') && 
        ((esDueno && !trabajo.clienteCalifico) || (!esDueno && !trabajo.proCalifico));
    final bool mostrarBadgeGlobal = (badgeCount > 0 || faltaCalificar) && !esHistorial && !vista.tacharTextos;

    return Badge(
      isLabelVisible: mostrarBadgeGlobal,
      backgroundColor: ColoresApp.errorRojo,
      alignment: Alignment.topRight,
      offset: const Offset(-4, 4),
      label: Text(faltaCalificar ? '!' : badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (onTapTipado != null) onTapTipado!(trabajo);
          else if (onTap != null) onTap!();
        },
        child: Container(
          decoration: BoxDecoration(
            color: esOscuro ? ColoresApp.fondoTarjetas : Colors.white, 
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: vista.tacharTextos
                  ? Colors.grey.withOpacity(0.3)
                  : (mostrarBadgeGlobal ? (faltaCalificar ? ColoresApp.advertenciaAmarillo.withOpacity(0.8) : ColoresApp.primarioVerde.withOpacity(0.5)) : (esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200)),
              width: mostrarBadgeGlobal ? 2.0 : 1.0,
            ),
            boxShadow: esOscuro 
                ?[BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] 
                :[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4), 
                  child: SizedBox(
                    width: 70, height: 70,
                    child: hasImage
                        ? (trabajo.imagenes.first.startsWith('http') 
                            ? CachedNetworkImage(
                                imageUrl: trabajo.imagenes.first, 
                                fit: BoxFit.cover,
                                placeholder: (_,__) => Container(color: tema.inputDecorationTheme.fillColor),
                                errorWidget: (_,__,___) => Container(color: tema.inputDecorationTheme.fillColor, child: Center(child: Icon(vista.iconoFallo, color: esOscuro ? Colors.white24 : Colors.black26, size: 28)))
                              ) 
                            : Image.file(File(trabajo.imagenes.first), fit: BoxFit.cover))
                        : Container(color: tema.inputDecorationTheme.fillColor, child: Center(child: Icon(vista.iconoFallo, color: esOscuro ? Colors.white24 : Colors.black26, size: 28))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Expanded(
                            child: Text(
                              trabajo.titulo, 
                              style: TextStyle(
                                color: vista.tacharTextos ? tema.textTheme.bodySmall?.color : tema.colorScheme.onSurface, 
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                height: 1.2,
                                decoration: vista.tacharTextos ? TextDecoration.lineThrough : null,
                              ), 
                              maxLines: 2, overflow: TextOverflow.ellipsis
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          if (vista.esPillBurbuja)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: vista.estadoColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(vista.estadoLabel, style: TextStyle(color: vista.estadoColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          else if (vista.usarPuntito)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children:[
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: vista.estadoColor, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(vista.estadoLabel, style: TextStyle(color: vista.estadoColor, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            )
                          else 
                            Text(vista.estadoLabel, style: TextStyle(color: vista.estadoColor, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      Row(
                        children:[
                          Icon(Icons.location_on_outlined, color: tema.textTheme.bodySmall?.color, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vista.textoUbicacion, 
                              style: TextStyle(
                                color: tema.textTheme.bodySmall?.color, 
                                fontSize: 13,
                                decoration: vista.tacharTextos ? TextDecoration.lineThrough : null,
                              ), 
                              maxLines: 1, overflow: TextOverflow.ellipsis
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children:[
                          Icon(Icons.calendar_today_outlined, color: tema.textTheme.bodySmall?.color, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vista.textoFecha, 
                              style: TextStyle(
                                color: tema.textTheme.bodySmall?.color, 
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                                decoration: vista.tacharTextos ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:[
                          Icon(Icons.access_time_rounded, color: tema.textTheme.bodySmall?.color, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vista.textoHora, 
                              style: TextStyle(
                                color: tema.textTheme.bodySmall?.color, 
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                                decoration: vista.tacharTextos ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          Text.rich(
                            TextSpan(
                              children:[
                                if (!vista.esTextoAdefinir) 
                                  TextSpan(
                                    text: '\$ ', 
                                    style: TextStyle(
                                      color: vista.tacharTextos ? Colors.grey : ColoresApp.terciarioMorado, 
                                      fontSize: 16, 
                                      fontWeight: FontWeight.w900,
                                      decoration: vista.tacharTextos ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                TextSpan(
                                  text: vista.precioLimpio, 
                                  style: TextStyle(
                                    color: vista.tacharTextos ? Colors.grey : ColoresApp.terciarioMorado, 
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w900,
                                    decoration: vista.tacharTextos ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (vista.mostrarBasurero) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: onDelete,
                              child: const Icon(Icons.delete_outline_rounded, color: ColoresApp.errorRojo, size: 20),
                            )
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}