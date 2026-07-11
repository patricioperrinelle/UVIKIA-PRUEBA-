// lib/4_componentes_globales/paneles_ejecucion/panel_aviso_cancelacion_cliente.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class PanelAvisoCancelacionCliente extends StatelessWidget {
  final VoidCallback? onRepublicar;
  // 🛡️ REFACTOR: Renombramos onEliminar a onEntendido. El componente es ciego.
  final VoidCallback onEntendido;

  const PanelAvisoCancelacionCliente({
    Key? key,
    this.onRepublicar,
    required this.onEntendido,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bool permiteRepublicar = onRepublicar != null;

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
              const Icon(Icons.event_busy_rounded, color: ColoresApp.errorRojo, size: 48),
              const SizedBox(height: 16),
              const Text(
                'El profesional ha cancelado su asistencia', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ColoresApp.errorRojo)
              ),
              const SizedBox(height: 16),
              
              Text(
                permiteRepublicar 
                  ? 'El trabajador tuvo un imprevisto y ha sido penalizado.\n\nEl servicio está pausado. ¿Deseas volver a publicarlo para recibir nuevas postulaciones?'
                  : 'El profesional tuvo un imprevisto y ha sido penalizado en su score de confiabilidad.\n\nLa reserva ha sido cancelada y los fondos/slots liberados. Puedes explorar el catálogo para agendar otro turno.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              if (permiteRepublicar) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onEntendido, // 🛡️ Actualizado
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('NO, CERRAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onRepublicar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColoresApp.primarioVerde,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('REPUBLICAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onEntendido, // 🛡️ Actualizado
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.primarioVerde,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}