// lib/4_componentes_globales/modales_y_alertas/flujo_calificacion/fase_transferencia_alias.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../botones/boton_accion_principal.dart';

class FaseTransferenciaAlias extends StatelessWidget {
  final String aliasPro;
  final VoidCallback onContinuar;

  const FaseTransferenciaAlias({
    Key? key,
    required this.aliasPro,
    required this.onContinuar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    bool tieneAlias = aliasPro.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:[
        const Icon(Icons.account_balance_rounded, color: ColoresApp.secundarioCyan, size: 36),
        const SizedBox(height: 12),
        Text('Datos de Transferencia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface)),
        const SizedBox(height: 16),
        
        if (tieneAlias) ...[
          Text('Transfiere el monto acordado al siguiente ALIAS/CVU:', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: tema.textTheme.bodyMedium?.color)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ColoresApp.secundarioCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: ColoresApp.secundarioCyan.withOpacity(0.5))),
            child: Text(aliasPro, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: ColoresApp.secundarioCyan)),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ColoresApp.advertenciaAmarillo.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: ColoresApp.advertenciaAmarillo.withOpacity(0.5))),
            child: const Text('El profesional no especificó su ALIAS en su perfil. Pídeselo por el chat.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.advertenciaAmarillo)),
          ),
        ],
        
        const SizedBox(height: 24),
        BotonAccionPrincipal(texto: 'OK, CONTINUAR A CALIFICAR', onPressed: onContinuar),
      ],
    );
  }
}