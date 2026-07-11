// lib/4_componentes_globales/indicadores/estrellas_calificacion_fila.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class EstrellasCalificacionFila extends StatelessWidget {
  final double rating;
  final double tamano;
  final Color colorActivo;
  final Color? colorInactivo; // 🚨 Cambio a nullable para detectarlo por contexto

  const EstrellasCalificacionFila({
    Key? key,
    required this.rating,
    this.tamano = 16.0,
    this.colorActivo = ColoresApp.advertenciaAmarillo,
    this.colorInactivo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🚨 Detectamos si estamos en modo oscuro o claro
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 🚨 Si no nos pasan un color inactivo, usamos uno inteligente
    final colorVacio = colorInactivo ?? (isDark ? Colors.white24 : Colors.black12);

    // 🚨 Creamos la lista sin usar corchetes vacíos para evitar el corte del chat
    List<Widget> estrellas = List<Widget>.empty(growable: true);

    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        estrellas.add(Icon(Icons.star_rounded, color: colorActivo, size: tamano));
      } else if (rating >= i - 0.5) {
        estrellas.add(Icon(Icons.star_half_rounded, color: colorActivo, size: tamano));
      } else {
        estrellas.add(Icon(Icons.star_rounded, color: colorVacio, size: tamano));
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: estrellas,
    );
  }
}