// lib/4_componentes_globales/modales_y_alertas/dto_recibo.dart
import 'package:flutter/material.dart';

class DatosReciboDTO {
  final IconData iconoServicio;
  final String subtituloServicio;
  final bool mostrarRangoHorario;
  final bool mostrarModalidad;
  final bool detalleOperativoEsLista;

  DatosReciboDTO({
    required this.iconoServicio,
    required this.subtituloServicio,
    required this.mostrarRangoHorario,
    required this.mostrarModalidad,
    required this.detalleOperativoEsLista,
  });
}
