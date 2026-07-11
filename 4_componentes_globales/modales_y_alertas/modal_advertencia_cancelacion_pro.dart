// lib/4_componentes_globales/modales_y_alertas/modal_advertencia_cancelacion_pro.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class ModalAdvertenciaCancelacionPro extends StatelessWidget {
  final int puntosPenalizacion;
  final VoidCallback onConfirmar;

  const ModalAdvertenciaCancelacionPro({
    Key? key,
    required this.puntosPenalizacion,
    required this.onConfirmar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

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
            const Text('¿Cancelar asistencia?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Debido a la cercanía del horario pactado, cancelar este trabajo afectará tu nivel de confiabilidad. Se restarán ',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                children: [
                  TextSpan(text: '$puntosPenalizacion puntos', style: const TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.errorRojo)),
                  const TextSpan(text: ' de tu score global como profesional.'),
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
                  const Text('Impacto en métricas:', style: TextStyle(fontWeight: FontWeight.w600, color: ColoresApp.errorRojo)),
                  Text('-$puntosPenalizacion pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.errorRojo)),
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