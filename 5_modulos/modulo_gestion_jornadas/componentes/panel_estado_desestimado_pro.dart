// lib/5_modulos/modulo_gestion_jornadas/componentes/panel_estado_desestimado_pro.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';

class PanelEstadoDesestimadoPro extends StatelessWidget {
  final bool proCalifico;
  final VoidCallback onCalificar;

  const PanelEstadoDesestimadoPro({
    Key? key,
    required this.proCalifico,
    required this.onCalificar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children:[
        if (proCalifico) ...[
          const Icon(Icons.thumb_up_rounded, color: ColoresApp.secundarioCyan, size: 40),
          const SizedBox(height: 8),
          const Text('¡Buen trabajo!', style: EstilosTextoApp.h3),
          const SizedBox(height: 8),
          Text('Has dejado constancia de tu calificación. Este contrato cancelado quedará en tu historial protegido.', textAlign: TextAlign.center, style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13)),
        ] else ...[
          const Icon(Icons.person_remove_rounded, color: ColoresApp.advertenciaAmarillo, size: 40),
          const SizedBox(height: 8),
          const Text('El cliente canceló tu contrato', style: EstilosTextoApp.h3),
          const SizedBox(height: 8),
          Text('El empleador desestimó la asignación antes de finalizarla. Por favor, deja constancia calificando al cliente.', textAlign: TextAlign.center, style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13)),
          const SizedBox(height: 16),
          BotonAccionPrincipal(texto: 'CALIFICAR AL CLIENTE', onPressed: onCalificar),
        ]
      ],
    );
  }
}