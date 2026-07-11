// lib/4_componentes_globales/cabeceras/cabecera_hero_perfil.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';

class CabeceraHeroPerfil extends StatelessWidget {
  final String apodo;
  final String fotoUrl;
  final String oficioPrincipal; 
  final double? rating;
  final int? reviews;
  final String zonaTrabajo;
  final String miembroDesde;
  final int? edad; // 🚀 NUEVO: Parámetro para inyectar edad
  final VoidCallback? onAvatarTap;

  const CabeceraHeroPerfil({
    Key? key,
    required this.apodo,
    required this.fotoUrl,
    required this.oficioPrincipal,
    this.rating,
    this.reviews,
    this.zonaTrabajo = '',
    this.miembroDesde = '',
    this.edad,
    this.onAvatarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final bool hasAvatar = fotoUrl.isNotEmpty;
    final bool isNetwork = fotoUrl.startsWith('http');
    final double ratingFinal = rating ?? 0.0;
    final int reviewsFinal = reviews ?? 0;
    final Color colorSecundario = tema.textTheme.bodyMedium?.color ?? Colors.grey;

    // 🚀 INYECCIÓN VISUAL DE EDAD (Ej: "Juan P. • 34 años")
    final String textoApodo = apodo.isEmpty ? 'Usuario' : apodo;
    final String apodoConEdad = (edad != null && edad! > 0) ? '$textoApodo • $edad años' : textoApodo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12, width: 1.5), 
                color: tema.inputDecorationTheme.fillColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasAvatar
                    ? (isNetwork 
                        ? CachedNetworkImage(
                            imageUrl: fotoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(color: ColoresApp.infoAzul, strokeWidth: 2)
                            ),
                            errorWidget: (context, url, error) => _fallbackIcon(context),
                          )
                        : Image.file(File(fotoUrl), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackIcon(context)))
                    : _fallbackIcon(context),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Row(
                  children:[
                    Flexible(
                      child: Text(
                        apodoConEdad, // 🚀 APLICACIÓN DEL TEXTO
                        style: EstilosTextoApp.h2.copyWith(color: tema.colorScheme.onSurface, fontSize: 24, height: 1.1), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      )
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: ColoresApp.infoAzul, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                
                if (oficioPrincipal.isNotEmpty) ...[
                  Text(oficioPrincipal, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                ],

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:[
                    const Icon(Icons.star_rounded, color: ColoresApp.advertenciaAmarillo, size: 20),
                    const SizedBox(width: 4),
                    Text(ratingFinal > 0 ? ratingFinal.toStringAsFixed(1) : 'Nuevo', style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('($reviewsFinal reseñas)', style: TextStyle(color: colorSecundario, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:[
                    Icon(Icons.location_on_outlined, color: colorSecundario, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(zonaTrabajo.isNotEmpty ? zonaTrabajo : 'Ubicación no especificada', style: TextStyle(color: colorSecundario, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),

                if (miembroDesde.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:[
                      Icon(Icons.calendar_today_outlined, color: colorSecundario, size: 14),
                      const SizedBox(width: 6),
                      Text('Miembro desde $miembroDesde', style: TextStyle(color: colorSecundario, fontSize: 13)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(Icons.person_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 40);
  }
}