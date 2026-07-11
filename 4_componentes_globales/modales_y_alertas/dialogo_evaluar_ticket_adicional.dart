// lib/4_componentes_globales/modales_y_alertas/dialogo_evaluar_ticket_adicional.dart
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';

class DialogoEvaluarTicketAdicional extends StatelessWidget {
  final double precioBase;
  final List<Map<String, dynamic>> itemsPropuestos;

  const DialogoEvaluarTicketAdicional({
    Key? key,
    required this.precioBase,
    required this.itemsPropuestos,
  }) : super(key: key);

  static Future<bool?> mostrar(
    BuildContext context, {
    required double precioBase,
    required List<Map<String, dynamic>> itemsPropuestos,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoEvaluarTicketAdicional(
        precioBase: precioBase,
        itemsPropuestos: itemsPropuestos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    double totalAdicional = 0.0;
    for (var ad in itemsPropuestos) {
      totalAdicional += double.tryParse(ad['monto'].toString()) ?? 0.0;
    }
    
    final double totalFinal = precioBase + totalAdicional;

    return Dialog(
      backgroundColor: tema.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: ColoresApp.primarioVerde, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('Ticket Actualizado', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface))),
              ],
            ),
            const SizedBox(height: 12),
            Text('El profesional te ha enviado un recibo final con el siguiente detalle. Revisa el total antes de aceptar.', style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.hintColor)),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tema.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tema.dividerColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Precio Base', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                      // 🚨 AISLAMIENTO DE TIPOGRAFÍA
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                            TextSpan(text: precioBase.toStringAsFixed(0)),
                          ]
                        ),
                        style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  
                  if (itemsPropuestos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...itemsPropuestos.map((ad) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(ad['concepto'], style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.hintColor))),
                          // 🚨 AISLAMIENTO DE TIPOGRAFÍA
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                                TextSpan(text: ad['monto'].toString()),
                              ]
                            ),
                            style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.hintColor),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL FINAL', style: EstilosTextoApp.h2.copyWith(color: tema.colorScheme.onSurface, fontSize: 18)),
                // 🚨 AISLAMIENTO DE TIPOGRAFÍA
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                      TextSpan(text: totalFinal.toStringAsFixed(0)),
                    ]
                  ),
                  style: EstilosTextoApp.h2.copyWith(color: ColoresApp.primarioVerde, fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('RECHAZAR', style: TextStyle(color: ColoresApp.errorRojo, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.primarioVerde,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ACEPTAR TICKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}