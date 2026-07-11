// lib/4_componentes_globales/indicadores/etiqueta_estado_badge.dart

import 'package:flutter/material.dart';
import '../../2_tema/dimensiones_app.dart';

class EtiquetaEstadoBadge extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color colorTema;

  const EtiquetaEstadoBadge({
    Key? key,
    required this.texto,
    required this.icono,
    required this.colorTema,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorTema.withOpacity(0.12),
        borderRadius: DimensionesApp.radioPequeno,
        border: Border.all(color: colorTema.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:[
          Icon(icono, size: 12, color: colorTema),
          const SizedBox(width: 4),
          Text(
            texto.toUpperCase(),
            style: TextStyle(
              color: colorTema,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}