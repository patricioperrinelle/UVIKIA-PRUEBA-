// lib/4_componentes_globales/tarjetas/tarjeta_perfil_usuario.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../3_modelos/modelo_perfil.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import 'tarjeta_minimalista_base.dart';
import '../indicadores/columna_info_destacada.dart';
import '../indicadores/etiqueta_estado_badge.dart';
import '../indicadores/estrellas_calificacion_fila.dart';

class TarjetaPerfilUsuario extends StatelessWidget {
  final ModeloPerfil perfil;
  final bool esCliente;
  final VoidCallback onTap;

  const TarjetaPerfilUsuario({
    Key? key,
    required this.perfil,
    this.esCliente = true, 
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final colorAcento = esCliente ? ColoresApp.primarioVerde : ColoresApp.infoAzul;
    final rating = esCliente ? perfil.ratingCliente : (perfil.perfilProfesional?.ratingProfesional ?? perfil.ratingCliente);
    final reviews = esCliente ? perfil.cantidadResenasCliente : (perfil.perfilProfesional?.cantidadResenasProfesional ?? perfil.cantidadResenasCliente);
    final ubicacion = perfil.perfilProfesional?.zonaTrabajo ?? 'Ubicación no especificada';
    
    return GestureDetector(
      onTap: onTap,
      child: TarjetaMinimalistaBase(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            EtiquetaEstadoBadge(
              texto: esCliente ? 'CONTRATANTE' : 'TRABAJADOR',
              icono: esCliente ? Icons.business_center_outlined : Icons.person_outline,
              colorTema: colorAcento,
            ),
            const SizedBox(height: 16),
            Row(
              children:[
                _ConstruirAvatar(url: perfil.fotoUrl, colorBorde: colorAcento),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children:[
                          Flexible(child: Text(perfil.apodo.isNotEmpty ? perfil.apodo : 'Usuario', style: EstilosTextoApp.h3.copyWith(fontSize: 18, color: tema.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 16, color: ColoresApp.infoAzul),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children:[
                          EstrellasCalificacionFila(rating: rating, tamano: 14),
                          const SizedBox(width: 6),
                          Text('${rating.toStringAsFixed(1)} ', style: EstilosTextoApp.cuerpoDestacado.copyWith(fontSize: 14, color: tema.colorScheme.onSurface)),
                          Text('($reviews reseñas)', style: EstilosTextoApp.cuerpoPequeno),
                        ],
                      ),
                      // 🛡️ REFACTOR: Solo imprimimos el ícono y texto de ubicación si NO es cliente
                      if (!esCliente) ...[
                        const SizedBox(height: 4),
                        Row(
                          children:[
                            Icon(Icons.location_on_outlined, size: 14, color: tema.textTheme.bodySmall?.color),
                            const SizedBox(width: 4),
                            Expanded(child: Text(ubicacion, style: EstilosTextoApp.cuerpoPequeno, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: tema.textTheme.bodySmall?.color),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: esOscuro ? Colors.white12 : Colors.black12, height: 1),
            const SizedBox(height: 16),
            esCliente ? _dashboardCliente() : _dashboardProfesional(),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCliente() {
    final int trabajos = perfil.trabajosPublicados;
    final int contratacion = trabajos > 0 ? ((perfil.trabajadoresContratados / trabajos) * 100).toInt() : 0;
    return IntrinsicHeight(
      child: Row(
        children:[
          Expanded(child: ColumnaInfoDestacada(icono: Icons.list_alt, label: 'Trabajos', valor: '$trabajos', subLabel: 'Publicados', colorValor: ColoresApp.infoAzul)),
          Expanded(child: ColumnaInfoDestacada(icono: Icons.handshake_outlined, label: 'Contratación', valor: '$contratacion%', subLabel: 'Tasa media', colorValor: ColoresApp.primarioVerde)),
          Expanded(child: ColumnaInfoDestacada(icono: Icons.cancel_outlined, label: 'Cancelados', valor: '${perfil.cancelacionesCliente.toInt()}%', subLabel: 'Por cliente', colorValor: ColoresApp.errorRojo)),
          Expanded(child: ColumnaInfoDestacada(icono: Icons.favorite_border, label: 'Buen Trato', valor: perfil.recomendacionTrabajadores.toStringAsFixed(1), subLabel: 'Al personal', colorValor: ColoresApp.terciarioMorado)),
        ],
      ),
    );
  }

  Widget _dashboardProfesional() {
    final pro = perfil.perfilProfesional;
    return IntrinsicHeight(
      child: Row(
        children:[
          Expanded(child: ColumnaInfoDestacada(icono: Icons.access_time, label: 'Puntualidad', valor: '${pro?.puntualidad.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.primarioVerde)),
          Expanded(child: ColumnaInfoDestacada(icono: Icons.calendar_month, label: 'Asistencia', valor: '${pro?.asistencia.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.infoAzul)),
          Expanded(child: ColumnaInfoDestacada(icono: Icons.work_outline, label: 'Completados', valor: '${pro?.jornadasCompletadas.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.primarioVerde)),
          Expanded(child: ColumnaInfoDestacada(icono: Icons.cancel_outlined, label: 'Cancelados', valor: '${pro?.cancelacionesPro.toInt() ?? 0}%', subLabel: '', colorValor: ColoresApp.errorRojo)),
          Expanded(child: ColumnaInfoDestacada(icono: Icons.shield_outlined, label: 'Score', valor: (pro?.scoreConfiabilidadPro ?? 0).toStringAsFixed(1), subLabel: '', colorValor: ColoresApp.terciarioMorado)),
        ],
      ),
    );
  }
}

class _ConstruirAvatar extends StatelessWidget {
  final String url; final Color colorBorde;
  const _ConstruirAvatar({required this.url, required this.colorBorde});
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final String urlLimpia = url.trim();
    Widget avatarWidget = Icon(Icons.person, color: tema.textTheme.bodySmall?.color, size: 30);
    
    if (urlLimpia.isNotEmpty && urlLimpia != 'null') {
      avatarWidget = urlLimpia.startsWith('http') 
          ? CachedNetworkImage(
              imageUrl: urlLimpia, 
              fit: BoxFit.cover, 
              errorWidget: (_,__,___)=>avatarWidget
            ) 
          : Image.file(File(urlLimpia), fit: BoxFit.cover, errorBuilder: (_,__,___)=>avatarWidget);
    }
    
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorBorde.withOpacity(0.5), width: 1.5), color: tema.inputDecorationTheme.fillColor),
      child: ClipOval(child: avatarWidget),
    );
  }
}