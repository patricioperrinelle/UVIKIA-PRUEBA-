// lib/5_modulos/modulo_gestion_jornadas/modales/modal_reportar_ausencia_strike.dart

import 'package:flutter/material.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';
import '../../../2_tema/colores_app.dart';

class ModalReportarAusenciaStrike {
  static Future<bool?> mostrar(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: '¿Reportar Ausencia?',
        mensaje: 'Si el profesional no se presentó y no registró su llegada por GPS, se le aplicará un STRIKE en su perfil, se cancelará su asignación y se te reembolsará el 5% de la comisión automáticamente.',
        textoBotonConfirmar: 'Sí, Reportar',
        textoBotonCancelar: 'Cancelar',
        colorConfirmar: ColoresApp.errorRojo, // Botón rojo punitivo
        onCancelar: () => Navigator.pop(ctx, false),
        onConfirmar: () => Navigator.pop(ctx, true),
      ),
    );
  }
}