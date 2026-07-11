// lib/5_modulos/modulo_perfil_usuario/componentes/grilla_actividad_estadisticas.dart

import 'package:flutter/material.dart';
import '../../../2_tema/estilos_texto.dart';

// 🚨 AQUÍ ESTÁ LA OTRA CLASE QUE DEBE TENER 'colorIcono'
class DatoActividad {
  final IconData icono;
  final Color colorIcono; // <-- Este es el parámetro que pedía Flutter
  final String valor;
  final String titulo;

  DatoActividad({
    required this.icono, 
    required this.colorIcono, 
    required this.valor, 
    required this.titulo
  });
}

class GrillaActividadEstadisticas extends StatelessWidget {
  final String titulo;
  final List<DatoActividad> datos;

  const GrillaActividadEstadisticas({
    Key? key,
    required this.titulo,
    required this.datos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorTextoBase = tema.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(titulo, style: EstilosTextoApp.h3.copyWith(color: colorTextoBase)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: datos.map((dato) => _buildColumnaDato(dato, tema)).toList(),
        ),
      ],
    );
  }

  Widget _buildColumnaDato(DatoActividad dato, ThemeData tema) {
    return Expanded(
      child: Column(
        children:[
          Icon(dato.icono, color: dato.colorIcono, size: 26),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dato.valor,
              style: TextStyle(
                color: tema.colorScheme.onSurface, // Números sin color
                fontSize: 20, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dato.titulo,
            textAlign: TextAlign.center,
            style: TextStyle(color: tema.textTheme.bodyMedium?.color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}