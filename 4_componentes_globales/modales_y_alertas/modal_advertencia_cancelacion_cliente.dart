// lib/4_componentes_globales/modales_y_alertas/modal_advertencia_cancelacion_cliente.dart
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class ModalAdvertenciaCancelacionCliente extends StatelessWidget {
  final double porcentajeRetencion;
  final double montoRetenido;
  final VoidCallback onConfirmar;

  const ModalAdvertenciaCancelacionCliente({
    Key? key,
    required this.porcentajeRetencion,
    required this.montoRetenido,
    required this.onConfirmar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final porcentajeEntero = (porcentajeRetencion * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded, size: 56, color: ColoresApp.errorRojo),
            const SizedBox(height: 16),
            const Text('¿Cancelar este trabajo?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Debido a la cercanía del horario pactado, se aplicará una retención del ',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                children: [
                  TextSpan(text: '$porcentajeEntero%', style: const TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.errorRojo)),
                  const TextSpan(text: ' para compensar el tiempo del profesional reservado.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ColoresApp.errorRojo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monto a retener:', style: TextStyle(fontWeight: FontWeight.w600, color: ColoresApp.errorRojo)),
                  Text('\$ ${montoRetenido.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.errorRojo)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('VOLVER', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirmar();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.errorRojo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SÍ, CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}