// lib/5_modulos/modulo_explorar_feed/componentes/tarjeta_profesional_directorio.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ
import '../../../3_modelos/modelo_perfil.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_minimalista_base.dart';
import '../../../4_componentes_globales/indicadores/columna_info_destacada.dart';
import '../../../4_componentes_globales/indicadores/estrellas_calificacion_fila.dart';

class TarjetaProfesionalDirectorio extends StatelessWidget {
  final ModeloPerfil perfil;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTapCard;

  const TarjetaProfesionalDirectorio({
    Key? key,
    required this.perfil,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTapCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final pro = perfil.perfilProfesional;
    final double rating = pro?.ratingProfesional ?? 0.0;
    final int reviews = pro?.cantidadResenasProfesional ?? 0;
    
    final List<String> displayTags = (pro?.tagsOficios ??[]).take(2).toList();
    final String oficios = displayTags.isNotEmpty ? displayTags.join(' • ') : 'Multioficios';
    final String ubicacion = pro?.zonaTrabajo != null && pro!.zonaTrabajo.isNotEmpty ? pro.zonaTrabajo : 'Ubicación no especificada';

    return GestureDetector(
      onTap: onTapCard,
      child: TarjetaMinimalistaBase(
        margin: const EdgeInsets.only(bottom: 6),
        padding: DimensionesApp.paddingTarjetas,
        child: Column(
          children:[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children:[
                _ConstruirImagenPro(url: perfil.fotoUrl),
                const SizedBox(width: 14),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Row(
                        children:[
                          Flexible(
                            child: Text(
                              perfil.apodo.isNotEmpty ? perfil.apodo : 'Profesional', 
                              style: EstilosTextoApp.h3.copyWith(fontSize: 18, color: tema.colorScheme.onSurface), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            )
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: ColoresApp.infoAzul),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(oficios, style: EstilosTextoApp.cuerpoDestacado.copyWith(fontSize: 13, color: ColoresApp.infoAzul), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children:[
                          EstrellasCalificacionFila(rating: rating, tamano: 16),
                          const SizedBox(width: 6),
                          Text('($reviews)', style: EstilosTextoApp.cuerpoPequeno.copyWith(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children:[
                          Icon(Icons.location_on_outlined, size: 14, color: tema.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Expanded(child: Text(ubicacion, style: EstilosTextoApp.cuerpoPequeno.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? ColoresApp.errorRojo : tema.iconTheme.color?.withOpacity(0.3),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: esOscuro ? Colors.white12 : Colors.black12, height: 1),
            const SizedBox(height: 16),
            
            IntrinsicHeight(
              child: Row(
                children:[
                  Expanded(child: ColumnaInfoDestacada(icono: Icons.access_time, label: 'Puntualidad', valor: '${pro?.puntualidad.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.primarioVerde)),
                  Expanded(child: ColumnaInfoDestacada(icono: Icons.calendar_month, label: 'Asistencia', valor: '${pro?.asistencia.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.infoAzul)),
                  Expanded(child: ColumnaInfoDestacada(icono: Icons.work_outline, label: 'Completados', valor: '${pro?.jornadasCompletadas.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.primarioVerde)),
                  Expanded(child: ColumnaInfoDestacada(icono: Icons.cancel_outlined, label: 'Cancelados', valor: '${pro?.cancelacionesPro.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.errorRojo)),
                  Expanded(child: ColumnaInfoDestacada(icono: Icons.shield_outlined, label: 'Score', valor: (pro?.scoreConfiabilidadPro ?? 0).toStringAsFixed(1), subLabel: '', colorValor: ColoresApp.terciarioMorado)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstruirImagenPro extends StatelessWidget {
  final String url;
  const _ConstruirImagenPro({required this.url});
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final String urlLimpia = url.trim();
    
    Widget avatarWidget = Icon(Icons.person, color: tema.textTheme.bodySmall?.color, size: 40);
    
    if (urlLimpia.isNotEmpty && urlLimpia != 'null') {
      avatarWidget = urlLimpia.startsWith('http') 
          // 🚨 REEMPLAZADO CON CACHÉ
          ? CachedNetworkImage(
              imageUrl: urlLimpia, 
              fit: BoxFit.cover, 
              errorWidget: (_,__,___) => avatarWidget
            ) 
          : Image.file(File(urlLimpia), fit: BoxFit.cover, errorBuilder: (_,__,___) => avatarWidget);
    }
    
    return Container(
      width: 90, 
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: esOscuro ? Colors.white12 : Colors.black12, width: 1.5), 
        color: tema.inputDecorationTheme.fillColor
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: avatarWidget
      ),
    );
  }
}