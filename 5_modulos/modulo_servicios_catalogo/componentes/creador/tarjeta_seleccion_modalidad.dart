// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/tarjeta_seleccion_modalidad.dart

import 'package:flutter/material.dart';

class TarjetaSeleccionModalidad extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool seleccionada;
  final VoidCallback onTap;

  const TarjetaSeleccionModalidad({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.seleccionada,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorAcento = tema.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionada ? colorAcento.withOpacity(0.05) : (esOscuro ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionada ? colorAcento : (esOscuro ? Colors.white24 : Colors.grey.shade300),
            width: seleccionada ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: seleccionada ? colorAcento : Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: seleccionada ? colorAcento : null)),
                  const SizedBox(height: 4),
                  Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}