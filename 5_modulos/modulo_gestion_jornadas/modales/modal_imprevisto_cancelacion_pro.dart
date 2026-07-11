// lib/5_modulos/modulo_gestion_jornadas/modales/modal_imprevisto_cancelacion_pro.dart

import 'package:flutter/material.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';
import '../../../2_tema/colores_app.dart';

class ModalImprevistoCancelacionPro {
  static Future<bool?> mostrar(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: '¿Tuve un imprevisto?',
        // 🚨 TEXTO LIMPIO: Ya no menciona devoluciones de dinero ajenas.
        mensaje: 'Se cancelará tu asignación y se le notificará al cliente para que busque otro profesional. IMPORTANTE: Cancelar afecta negativamente tu historial (Strikes y % de Cancelaciones).',
        textoBotonConfirmar: 'Sí, Cancelar Asistencia',
        textoBotonCancelar: 'Volver',
        colorConfirmar: ColoresApp.errorRojo,
        onCancelar: () => Navigator.pop(ctx, false),
        onConfirmar: () => Navigator.pop(ctx, true),
      ),
    );
  }
}