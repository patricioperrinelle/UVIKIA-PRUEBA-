// lib/4_componentes_globales/tarjetas/tarjeta_puja_postulante.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ
import '../../3_modelos/modelo_puja.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/dimensiones_app.dart';
import '../../2_tema/estilos_texto.dart';
import 'tarjeta_minimalista_base.dart';
import '../indicadores/columna_info_destacada.dart';
import '../indicadores/etiqueta_estado_badge.dart';
import '../indicadores/estrellas_calificacion_fila.dart';

class TarjetaPujaPostulante extends StatelessWidget {
  final ModeloPuja puja;
  final VoidCallback onTapPerfil;
  final Widget? botonesAccion; 
  final bool isCongelado;
  final bool ocultarMonto;

  const TarjetaPujaPostulante({
    Key? key,
    required this.puja,
    required this.onTapPerfil,
    this.botonesAccion,
    this.isCongelado = false,
    this.ocultarMonto = false, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    Color estadoColor; String estadoLabel; IconData estadoIcon;
    
    // 🛡️ REFACTOR: Mapeo estricto y granular para las pastillas visuales de estados (Badges)
    switch (puja.estadoPuja) {
      case 'rechazada': case 'desestimada':
        estadoColor = ColoresApp.errorRojo; estadoLabel = 'RECHAZADA'; estadoIcon = Icons.cancel_rounded; break;
      case 'cancelada': case 'cancelada_por_cliente': case 'cancelada_por_pro': case 'cancelada_vista_pro':
        estadoColor = ColoresApp.errorRojo; estadoLabel = 'CANCELADA'; estadoIcon = Icons.cancel_presentation_rounded; break;
      case 'aceptada': case 'finalizada': case 'en_curso': case 'pendiente_revision':
        estadoColor = ColoresApp.primarioVerde; estadoLabel = 'CONTRATADO'; estadoIcon = Icons.check_circle_rounded; break;
      default:
        estadoColor = ColoresApp.advertenciaAmarillo; estadoLabel = 'ESPERANDO'; estadoIcon = Icons.hourglass_top_rounded;
    }

    final String ubicacion = puja.zonaTrabajo.isNotEmpty ? puja.zonaTrabajo : 'Ubicación no especificada';
    final String oficiosStr = puja.oficios.isNotEmpty ? puja.oficios.take(2).join(' • ') : 'Multioficios';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TarjetaMinimalistaBase(
        margin: EdgeInsets.zero,
        padding: DimensionesApp.paddingTarjetas,
        child: Column(
          children:[
            GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onTapPerfil,
              child: Column(
                children:[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      _ConstruirAvatarPuja(url: puja.avatarUrl, colorBorde: estadoColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Row(
                              children:[
                                Flexible(child: Text(puja.apodoProfesional.isNotEmpty ? puja.apodoProfesional : 'Profesional', style: EstilosTextoApp.h3.copyWith(fontSize: 16, color: tema.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 14, color: ColoresApp.infoAzul),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(oficiosStr, style: EstilosTextoApp.cuerpoDestacado.copyWith(fontSize: 12, color: ColoresApp.infoAzul), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children:[
                                EstrellasCalificacionFila(rating: puja.rating, tamano: 14),
                                const SizedBox(width: 6),
                                Text('${puja.rating} ', style: EstilosTextoApp.cuerpoDestacado.copyWith(fontSize: 13, color: tema.colorScheme.onSurface)),
                                Text('(${puja.reviews})', style: EstilosTextoApp.cuerpoPequeno),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children:[
                                Icon(Icons.location_on_outlined, size: 12, color: tema.textTheme.bodySmall?.color),
                                const SizedBox(width: 4),
                                Expanded(child: Text(ubicacion, style: EstilosTextoApp.cuerpoPequeno.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children:[
                          EtiquetaEstadoBadge(texto: estadoLabel, icono: estadoIcon, colorTema: estadoColor),
                          if (botonesAccion != null) ...[
                            const SizedBox(height: 8), 
                            botonesAccion!,
                          ]
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: esOscuro ? Colors.white12 : Colors.black12, height: 1),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      children:[
                        Expanded(child: ColumnaInfoDestacada(icono: Icons.access_time, label: 'Puntualidad', valor: '${puja.puntualidad.toInt()}%', subLabel: '', colorValor: ColoresApp.primarioVerde)),
                        Expanded(child: ColumnaInfoDestacada(icono: Icons.calendar_month, label: 'Asistencia', valor: '${puja.asistencia.toInt()}%', subLabel: '', colorValor: ColoresApp.infoAzul)),
                        Expanded(child: ColumnaInfoDestacada(icono: Icons.work_outline, label: 'Completados', valor: '${puja.jornadasCompletadas.toInt()}%', subLabel: '', colorValor: ColoresApp.primarioVerde)),
                        Expanded(child: ColumnaInfoDestacada(icono: Icons.cancel_outlined, label: 'Cancelados', valor: '${puja.cancelacionesPro.toInt()}%', subLabel: '', colorValor: ColoresApp.errorRojo)),
                        Expanded(child: ColumnaInfoDestacada(icono: Icons.shield_outlined, label: 'Score', valor: puja.scoreConfiabilidadPro.toStringAsFixed(1), subLabel: '', colorValor: ColoresApp.terciarioMorado)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!ocultarMonto) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: esOscuro ? Colors.black.withOpacity(0.4) : Colors.grey[100], borderRadius: DimensionesApp.radioBoton, border: Border.all(color: estadoColor.withOpacity(0.3))),
                child: Column(
                  children:[
                    Text('PRECIO OFRECIDO', style: TextStyle(color: estadoColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(puja.montoOfrecido, style: TextStyle(color: estadoColor, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConstruirAvatarPuja extends StatelessWidget {
  final String url; final Color colorBorde;
  const _ConstruirAvatarPuja({required this.url, required this.colorBorde});
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final String urlLimpia = url.trim();
    Widget avatarWidget = Icon(Icons.person, color: tema.textTheme.bodySmall?.color, size: 28);
    
    if (urlLimpia.isNotEmpty && urlLimpia != 'null') {
      avatarWidget = urlLimpia.startsWith('http') 
          // 🚨 REEMPLAZADO CON CACHÉ
          ? CachedNetworkImage(
              imageUrl: urlLimpia, 
              fit: BoxFit.cover, 
              errorWidget: (_,__,___)=>avatarWidget
            ) 
          : Image.file(File(urlLimpia), fit: BoxFit.cover, errorBuilder: (_,__,___)=>avatarWidget);
    }
    
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorBorde.withOpacity(0.5), width: 2), color: tema.inputDecorationTheme.fillColor),
      child: ClipOval(child: avatarWidget),
    );
  }
}