// lib/5_modulos/modulo_gestion_jornadas/componentes/panel_estado_postulante_pro.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';

class PanelEstadoPostulantePro extends StatelessWidget {
  final String estadoNegociacion; 
  final bool isProcessing;
  final bool isLoadingDatos; // 🚨 ESCUDO ANTI MILISEGUNDO DE DOBLE POSTULACIÓN
  final VoidCallback onRetirarPostulacion;
  final VoidCallback onPostularse;

  const PanelEstadoPostulantePro({
    Key? key,
    required this.estadoNegociacion,
    required this.isProcessing,
    required this.isLoadingDatos,
    required this.onRetirarPostulacion,
    required this.onPostularse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // 🚨 Si la BD está calculando tu destino, bloquea la interfaz entera
    if (isLoadingDatos) {
      return Container(
        decoration: BoxDecoration(color: tema.colorScheme.surface, border: const Border(top: BorderSide(color: ColoresApp.primarioVerde, width: 1.5))),
        child: SafeArea(
          bottom: true, top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde)),
            )
          )
        )
      );
    }

    if (estadoNegociacion == 'esperando') {
      return Container(
        decoration: BoxDecoration(
          color: tema.colorScheme.surface, 
          border: Border(top: BorderSide(color: esOscuro ? Colors.white24 : Colors.black12)),
        ),
        child: SafeArea(
          bottom: true,
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : onRetirarPostulacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: esOscuro ? Colors.white12 : Colors.black.withOpacity(0.05),
                  foregroundColor: tema.colorScheme.onSurface,
                  side: BorderSide(color: esOscuro ? Colors.white38 : Colors.black26, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: isProcessing
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: tema.colorScheme.onSurface))
                    : const Text('POSTULADO - TOCAR PARA RETIRAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
              ),
            ),
          ),
        ),
      );
    } 
    // 🛡️ REFACTOR: Ceguera absoluta. Cualquier estado que no sea 'esperando' o 'ninguna' es destructivo o en curso y no dibuja el botón.
    else if (estadoNegociacion != 'ninguna') {
      return const SizedBox.shrink(); 
    } 
    else {
      return Container(
        decoration: BoxDecoration(
          color: tema.colorScheme.surface, 
          border: const Border(top: BorderSide(color: ColoresApp.primarioVerde, width: 1.5)),
        ),
        child: SafeArea(
          bottom: true,
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: BotonAccionPrincipal(
              texto: '¡ME POSTULO!',
              isLoading: isProcessing,
              onPressed: onPostularse,
            ),
          ),
        ),
      );
    }
  }
}