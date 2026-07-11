// lib/4_componentes_globales/modales_y_alertas/flujo_calificacion/chip_pulgar_calificacion.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';

class ChipPulgarCalificacion extends StatelessWidget {
  final String texto;
  final bool? estadoActual;
  final Function(bool?) onSeleccion;

  const ChipPulgarCalificacion({
    Key? key,
    required this.texto,
    required this.estadoActual,
    required this.onSeleccion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    final colorUp = ColoresApp.primarioVerde;
    final colorDown = ColoresApp.errorRojo;
    final inactivo = tema.textTheme.bodyMedium?.color?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        border: Border.all(color: esOscuro ? Colors.white12 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:[
          Text(texto, style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onSeleccion(estadoActual == true ? null : true), 
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: estadoActual == true ? colorUp.withOpacity(0.15) : Colors.transparent, shape: BoxShape.circle),
              child: Icon(Icons.thumb_up_alt_rounded, color: estadoActual == true ? colorUp : inactivo, size: 16),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onSeleccion(estadoActual == false ? null : false), 
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: estadoActual == false ? colorDown.withOpacity(0.15) : Colors.transparent, shape: BoxShape.circle),
              child: Icon(Icons.thumb_down_alt_rounded, color: estadoActual == false ? colorDown : inactivo, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}