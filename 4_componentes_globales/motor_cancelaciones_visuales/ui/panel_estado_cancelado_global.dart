// lib/4_componentes_globales/motor_cancelaciones_visuales/ui/panel_estado_cancelado_global.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';

/// Un "Dumb Component" absoluto. Reemplaza a las 3 variantes tóxicas de los módulos.
/// Solo recibe Strings y dibuja. No conoce el dominio, ni actores, ni estados.
class PanelEstadoCanceladoGlobal extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool esError;

  const PanelEstadoCanceladoGlobal({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.esError = true,
  });

  @override
  Widget build(BuildContext context) {
    // Si no es un error "culpable" (Ej: mutuo acuerdo o info), usamos un tono neutro.
    final colorBase = esError ? ColoresApp.errorRojo : ColoresApp.infoAzul;

    return Container(
      width: double.infinity,
      padding: DimensionesApp.paddingTarjetas,
      decoration: BoxDecoration(
        color: colorBase.withOpacity(0.12), // Opacidad suave tintada con el color base
        borderRadius: DimensionesApp.radioTarjetas,
        border: Border.all(
          color: colorBase.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esError ? Icons.event_busy_rounded : Icons.info_outline_rounded,
                color: colorBase,
                size: DimensionesApp.iconoMedio,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  titulo.toUpperCase(),
                  style: EstilosTextoApp.cuerpoDestacado.copyWith(
                    color: colorBase,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            subtitulo,
            style: EstilosTextoApp.cuerpoRegular.copyWith(
              color: ColoresApp.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}