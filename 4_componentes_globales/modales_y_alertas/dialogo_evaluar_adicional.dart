// lib/4_componentes_globales/modales_y_alertas/dialogo_evaluar_adicional.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';

class DialogoEvaluarAdicional extends StatelessWidget {
  final Map<String, dynamic> adicional;

  const DialogoEvaluarAdicional({Key? key, required this.adicional}) : super(key: key);

  static Future<bool?> mostrar(BuildContext context, Map<String, dynamic> adicional) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Obliga al usuario a responder
      builder: (_) => DialogoEvaluarAdicional(adicional: adicional),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final concepto = adicional['concepto']?.toString() ?? 'Ítem extra';
    final monto = adicional['monto']?.toString() ?? '0';

    return AlertDialog(
      backgroundColor: tema.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: ColoresApp.advertenciaAmarillo, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text('Presupuesto Extra', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('El profesional ha solicitado agregar el siguiente ítem al contrato:', style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.hintColor)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tema.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tema.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(concepto, style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface))),
                Text('\$$monto', style: EstilosTextoApp.h2.copyWith(color: ColoresApp.primarioVerde, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('RECHAZAR', style: TextStyle(color: ColoresApp.errorRojo, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresApp.primarioVerde,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('ACEPTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}