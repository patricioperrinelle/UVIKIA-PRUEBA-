// lib/4_componentes_globales/tarjetas/tarjeta_feed_base.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ VISUAL
import '../../2_tema/colores_app.dart';
import '../../2_tema/dimensiones_app.dart';

class TarjetaFeedBase extends StatelessWidget {
  final String titulo;
  final String imagenUrl;
  final String ubicacionRelativa; 
  final String tiempoRelativo;    
  final String textoPostulantes;  
  final bool tienePostulantes;
  
  final Widget? contenidoEspecialCentral; 
  final Widget? widgetAntesDelBoton; 
  final Widget etiquetaEstadoFlotante;    
  final bool mostrarCintaAsignado;   
  
  final String textoBoton;
  final VoidCallback onTap;
  final Color colorBoton;
  final Color colorTextoBoton;
  final bool estaOscurecida;
  final bool botonDelineado; 

  const TarjetaFeedBase({
    Key? key,
    required this.titulo,
    required this.imagenUrl,
    required this.ubicacionRelativa,
    required this.tiempoRelativo,
    required this.textoPostulantes,
    required this.tienePostulantes,
    this.contenidoEspecialCentral,
    this.widgetAntesDelBoton,
    this.etiquetaEstadoFlotante = const SizedBox.shrink(),
    this.mostrarCintaAsignado = false,
    required this.textoBoton,
    required this.onTap,
    this.colorBoton = ColoresApp.primarioVerde,
    this.colorTextoBoton = Colors.black,
    this.estaOscurecida = false,
    this.botonDelineado = false,
  }) : super(key: key);

  Widget _buildImagenRobusta(BuildContext context) {
    String cleanUrl = imagenUrl.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", "").trim();
    
    if (cleanUrl.contains(',')) {
      cleanUrl = cleanUrl.split(',').first.trim();
    }
    
    if (cleanUrl.isEmpty) return _buildPlaceholder(context);

    if (cleanUrl.startsWith('http')) {
      // 🚨 REEMPLAZADO: Usamos CachedNetworkImage en lugar del pesado Image.network
      return CachedNetworkImage(
        imageUrl: cleanUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Theme.of(context).inputDecorationTheme.fillColor, 
          child: const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde, strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    } else {
      return Image.file(
        File(cleanUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      );
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    return Container(
      color: tema.inputDecorationTheme.fillColor, 
      child: Center(
        child: Icon(Icons.handyman_rounded, color: esOscuro ? Colors.white24 : Colors.black26, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: estaOscurecida ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: DimensionesApp.radioTarjetas,
            color: estaOscurecida ? (esOscuro ? Colors.black87 : Colors.grey[200]) : tema.colorScheme.surface,
            border: Border.all(
              color: estaOscurecida ? Colors.grey.withOpacity(0.3) : colorBoton.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: estaOscurecida ? null :[
              BoxShadow(
                color: esOscuro ? colorBoton.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: _buildImagenRobusta(context), 
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors: <Color>[Colors.black.withOpacity(0.9), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: etiquetaEstadoFlotante,
                    ),
                    if (mostrarCintaAsignado)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.redAccent, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.black54,
                              ),
                              child: const Text('OFERTA TOMADA', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                flex: 17,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: estaOscurecida ? tema.textTheme.bodySmall?.color : tema.colorScheme.onSurface,
                          decoration: estaOscurecida ? TextDecoration.lineThrough : null,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      _buildMiniRow(context, Icons.location_on_rounded, ColoresApp.errorRojo, ubicacionRelativa),
                      const SizedBox(height: 4),
                      _buildMiniRow(context, Icons.access_time, null, tiempoRelativo),
                      const SizedBox(height: 6),
                      _buildMiniRow(context, Icons.people_alt_outlined, tienePostulantes ? ColoresApp.secundarioCyan : null, textoPostulantes),
                      
                      const Spacer(),
                      
                      if (contenidoEspecialCentral != null) ...<Widget>[
                        contenidoEspecialCentral!,
                        const SizedBox(height: 6),
                      ],

                      if (widgetAntesDelBoton != null) ...<Widget>[
                        widgetAntesDelBoton!,
                        const Spacer(),
                      ],
                      
                      if (widgetAntesDelBoton == null) const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: botonDelineado ? (esOscuro ? Colors.white12 : colorBoton.withOpacity(0.1)) : colorBoton,
                            foregroundColor: botonDelineado ? (esOscuro ? Colors.white : colorBoton) : colorTextoBoton,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: botonDelineado ? BorderSide(color: colorBoton, width: 1.5) : BorderSide.none,
                            ),
                            elevation: botonDelineado || estaOscurecida ? 0 : 5,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            textoBoton,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ),
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

  Widget _buildMiniRow(BuildContext context, IconData icon, Color? iconColor, String text) {
    final colorEfectivo = iconColor ?? Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: colorEfectivo, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colorEfectivo, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}