// lib/5_modulos/modulo_explorar_feed/componentes/boton_seccion_hub.dart

import 'package:flutter/material.dart';
import '../../../2_tema/dimensiones_app.dart';

class BotonSeccionHub extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color? colorIcono;
  final VoidCallback onTap;

  const BotonSeccionHub({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.onTap,
    this.colorIcono,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🚨 Leemos el tema y si es oscuro o claro
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Colores dinámicos para los efectos de cristal y bordes
    final colorCristal = esOscuro ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
    final colorBorde = esOscuro ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: DimensionesApp.radioTarjetas,
          splashColor: colorCristal,
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tema.colorScheme.surface, // 🚨 Fondo dinámico (blanco o negro)
              borderRadius: DimensionesApp.radioTarjetas,
              border: Border.all(color: colorBorde, width: 1.0),
              // 🚨 Sombreado suave solo en modo claro
              boxShadow: esOscuro ? null :[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children:[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorCristal,
                    borderRadius: DimensionesApp.radioMedio,
                    border: Border.all(color: colorBorde),
                  ),
                  child: Icon(icono, color: colorIcono ?? tema.colorScheme.onSurface.withOpacity(0.8), size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      // 🚨 Texto principal dinámico
                      Text(titulo, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                      const SizedBox(height: 6),
                      // 🚨 Texto secundario dinámico
                      Text(subtitulo, style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: tema.colorScheme.onSurface.withOpacity(0.2), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}