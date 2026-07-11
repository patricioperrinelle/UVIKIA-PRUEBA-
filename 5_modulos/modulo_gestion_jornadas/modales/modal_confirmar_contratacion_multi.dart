// lib/5_modulos/modulo_gestion_jornadas/modales/modal_confirmar_contratacion_multi.dart

import 'package:flutter/material.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';
import '../../../2_tema/colores_app.dart';

class ModalConfirmarContratacionMulti {
  static Future<bool?> mostrar(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: 'Confirmar Contratación',
        mensaje: 'Al contratar a este profesional se generará una deuda del 5% del sueldo en tu billetera de la app. ¿Deseas continuar?',
        textoBotonConfirmar: 'Contratar',
        textoBotonCancelar: 'Cancelar',
        colorConfirmar: ColoresApp.primarioVerde, // Botón verde porque es una acción positiva
        onCancelar: () => Navigator.pop(ctx, false),
        onConfirmar: () => Navigator.pop(ctx, true),
      ),
    );
  }
}