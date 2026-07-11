// lib/5_modulos/modulo_negociacion_oficios/componentes/panel_estado_abierto_profesional.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/boton_delineado_secundario.dart';
import '../../../3_modelos/modelo_puja.dart';

class PanelEstadoAbiertoProfesional extends StatelessWidget {
  final ModeloPuja? miPuja;
  final VoidCallback onEnviarModificarOferta;
  final VoidCallback onRetirarOferta;

  const PanelEstadoAbiertoProfesional({
    Key? key,
    required this.miPuja,
    required this.onEnviarModificarOferta,
    required this.onRetirarOferta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    if (miPuja != null && miPuja!.estadoPuja != 'rechazada') {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: tema.colorScheme.surface, // 🚨 Fondo Adaptativo
          border: const Border(top: BorderSide(color: ColoresApp.primarioVerde, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: esOscuro ? Colors.black.withOpacity(0.5) : Colors.grey[100], // 🚨 Fondo Adaptativo
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12),
              ),
              child: Column(
                children:[
                  Text(
                    'Tu presupuesto enviado:', 
                    style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                  ),
                  const SizedBox(height: 6),
                  Text(
                    miPuja!.montoOfrecido,
                    style: const TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esperando que el cliente decida...', 
                    style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 14, fontStyle: FontStyle.italic)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children:[
                Expanded(
                  child: BotonDelineadoSecundario(
                    texto: 'Modificar',
                    icono: Icons.edit_rounded,
                    colorPrimario: tema.colorScheme.onSurface,
                    onPressed: onEnviarModificarOferta,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BotonDelineadoSecundario(
                    texto: 'Retirar',
                    icono: Icons.delete_outline_rounded,
                    colorPrimario: ColoresApp.errorRojo,
                    onPressed: onRetirarOferta,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface, // 🚨 Fondo Adaptativo
        border: Border(top: BorderSide(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          if (miPuja?.estadoPuja == 'rechazada')
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Trato anterior rechazado o cancelado. Puedes volver a enviar un presupuesto si lo deseas.', 
                style: TextStyle(color: ColoresApp.advertenciaAmarillo, fontSize: 12, fontStyle: FontStyle.italic), 
                textAlign: TextAlign.center
              ),
            ),
          BotonAccionPrincipal(
            texto: 'ENVIAR MI PRESUPUESTO',
            onPressed: onEnviarModificarOferta,
          ),
        ],
      ),
    );
  }
}