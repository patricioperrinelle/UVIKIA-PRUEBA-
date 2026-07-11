// lib/4_componentes_globales/paneles_ejecucion/panel_aviso_cancelacion_pro.dart
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class PanelAvisoCancelacionPro extends StatelessWidget {
  final double gananciaPro;
  final VoidCallback onEntendido;

  const PanelAvisoCancelacionPro({
    Key? key,
    required this.gananciaPro,
    required this.onEntendido,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tema.colorScheme.surface, 
        border: const Border(top: BorderSide(color: ColoresApp.errorRojo, width: 2)), 
      ),
      child: SafeArea(
        bottom: false, top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children:[
              const Icon(Icons.info_outline_rounded, color: ColoresApp.errorRojo, size: 48),
              const SizedBox(height: 16),
              const Text(
                'El cliente ha cancelado el trabajo', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ColoresApp.errorRojo)
              ),
              const SizedBox(height: 16),
              
              if (gananciaPro > 0) ...[
                const Text(
                  'Por políticas de protección al profesional, hemos aplicado una retención al cliente. Se ha acreditado el siguiente monto a tu favor:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: ColoresApp.primarioVerde.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('COMPENSACIÓN ACREDITADA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
                      const SizedBox(height: 4),
                      Text('\$ ${gananciaPro.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'La cancelación se realizó con más de 48 hs de anticipación. Según nuestras políticas, la reserva ha sido liberada sin penalidad a tu favor, permitiéndote tomar otros trabajos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onEntendido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.terciarioMorado,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}