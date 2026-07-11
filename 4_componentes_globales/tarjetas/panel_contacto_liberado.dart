// lib/4_componentes_globales/tarjetas/panel_contacto_liberado.dart

import 'package:flutter/material.dart';
import '../../2_tema/decoracion_cristal.dart';
// 🚨 NOTA: Este archivo GPS ahora se invoca desde el NÚCLEO.
import '../../1_nucleo/servicios/servicio_gps_localizacion.dart';

class PanelContactoLiberado extends StatelessWidget {
  final String ubicacionMaps;
  final String telefono;

  const PanelContactoLiberado({
    Key? key,
    required this.ubicacionMaps,
    required this.telefono,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Column(
      children:[
        const SizedBox(height: 24),
        ContenedorCristal(
           colorFondo: tema.colorScheme.surface,
           colorBorde: esOscuro ? Colors.white.withOpacity(0.1) : Colors.black12,
           child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                 Text('📍 Ubicación y Contacto Liberados', style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                 const SizedBox(height: 16),
                 if (ubicacionMaps.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                       Icon(Icons.map_outlined, color: tema.textTheme.bodySmall?.color, size: 20),
                       const SizedBox(width: 10),
                       Expanded(child: Text(ubicacionMaps, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 15, height: 1.3))),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => ServicioGpsLocalizacion.abrirEnMapa(ubicacionMaps),
                        icon: const Text('🗺️', style: TextStyle(fontSize: 16)),
                        label: Text('ABRIR MAPA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: tema.colorScheme.onSurface)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: esOscuro ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: esOscuro ? Colors.white12 : Colors.black12, height: 1),
                    const SizedBox(height: 20),
                 ],
                 if (telefono.isNotEmpty) ...[
                    Row(children:[
                       Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
                          child: Icon(Icons.phone_android_rounded, color: tema.colorScheme.onSurface, size: 20)
                       ),
                       const SizedBox(width: 12),
                       Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                          Text('Teléfono / WhatsApp', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(telefono, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                       ])
                    ])
                 ] else ...[
                    Text('No se registró un teléfono en la publicación.', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13, fontStyle: FontStyle.italic))
                 ]
              ]
           )
        ),
      ],
    );
  }
}