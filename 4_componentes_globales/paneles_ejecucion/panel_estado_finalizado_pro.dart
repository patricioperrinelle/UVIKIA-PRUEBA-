// lib/4_componentes_globales/paneles_ejecucion/panel_estado_finalizado_pro.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import '../botones/boton_accion_principal.dart';

class PanelEstadoFinalizadoPro extends StatelessWidget {
  // 🚨 PURGA LEGACY: Eliminada la variable "metodoPago" que se pedía en el constructor.
  final bool proCalifico; 
  final VoidCallback onCalificar;

  const PanelEstadoFinalizadoPro({
    Key? key,
    required this.proCalifico,
    required this.onCalificar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (proCalifico) ...[
            const Icon(Icons.thumb_up_rounded, color: ColoresApp.secundarioCyan, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Trabajo completado con éxito.', 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.secundarioCyan)
            ),
            const SizedBox(height: 8),
            Text(
              'Este registro pasará a tu historial.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13)
            ),
          ] else ...[
            const Icon(Icons.verified_rounded, color: ColoresApp.primarioVerde, size: 48),
            const SizedBox(height: 12),
            const Text(
              '¡El cliente finalizó el servicio!', 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)
            ),
            const SizedBox(height: 8),
            Text(
              'El dinero retenido en Escrow será liberado a tu billetera. Ya puedes evaluar al empleador.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13)
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: BotonAccionPrincipal(texto: 'CALIFICAR AL CLIENTE', onPressed: onCalificar)
            ),
          ]
        ],
      ),
    );
  }
}