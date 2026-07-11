// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/stepper_creacion_servicio.dart

import 'package:flutter/material.dart';

class StepperCreacionServicio extends StatelessWidget {
  final int pasoActual;

  const StepperCreacionServicio({Key? key, required this.pasoActual}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorAcento = tema.colorScheme.primary;
    final esOscuro = tema.brightness == Brightness.dark;
    final colorInactivo = esOscuro ? Colors.white24 : Colors.grey.shade300;
    final colorTextoInactivo = esOscuro ? Colors.white54 : Colors.grey.shade500;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          _construirPaso(1, 'Información', 0, colorAcento, colorInactivo, colorTextoInactivo),
          _construirLinea(0, colorAcento, colorInactivo),
          _construirPaso(2, 'Planes y extras', 1, colorAcento, colorInactivo, colorTextoInactivo),
          _construirLinea(1, colorAcento, colorInactivo),
          _construirPaso(3, 'Vista previa', 2, colorAcento, colorInactivo, colorTextoInactivo),
        ],
      ),
    );
  }

  Widget _construirPaso(int numero, String titulo, int indicePaso, Color colorAcento, Color colorInactivo, Color textoInactivo) {
    final estaCompletado = pasoActual > indicePaso;
    final estaActivo = pasoActual >= indicePaso;

    return Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: estaActivo ? colorAcento : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: estaActivo ? colorAcento : colorInactivo, width: 1.5),
          ),
          child: Center(
            child: estaCompletado
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$numero', style: TextStyle(fontSize: 12, color: estaActivo ? Colors.white : textoInactivo, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: estaActivo ? FontWeight.bold : FontWeight.normal,
            color: estaActivo ? (estaCompletado ? textoInactivo : null) : textoInactivo,
          ),
        ),
      ],
    );
  }

  Widget _construirLinea(int indicePaso, Color colorAcento, Color colorInactivo) {
    final lineaActiva = pasoActual > indicePaso;
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: lineaActiva ? colorAcento : colorInactivo,
      ),
    );
  }
}