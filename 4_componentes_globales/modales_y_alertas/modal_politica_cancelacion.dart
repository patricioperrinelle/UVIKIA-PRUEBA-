// lib/4_componentes_globales/modales_y_alertas/modal_politica_cancelacion.dart
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class ModalPoliticaCancelacion extends StatelessWidget {
  const ModalPoliticaCancelacion({Key? key}) : super(key: key);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text(
              'Política de Cancelación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para proteger el tiempo de nuestros profesionales, las cancelaciones generan retenciones proporcionales al tiempo restante:',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _FilaTabla(tiempo: 'Más de 48 hs', porcentaje: '20% retenido', color: ColoresApp.primarioVerde),
            _FilaTabla(tiempo: 'Entre 48 y 24 hs', porcentaje: '35% retenido', color: Colors.orange),
            _FilaTabla(tiempo: 'Entre 24 y 8 hs', porcentaje: '60% retenido', color: Colors.deepOrange),
            _FilaTabla(tiempo: 'Menos de 8 hs', porcentaje: '100% retenido', color: ColoresApp.errorRojo),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ENTENDIDO', style: TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _FilaTabla extends StatelessWidget {
  final String tiempo;
  final String porcentaje;
  final Color color;

  const _FilaTabla({required this.tiempo, required this.porcentaje, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tiempo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(porcentaje, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          )
        ],
      ),
    );
  }
}