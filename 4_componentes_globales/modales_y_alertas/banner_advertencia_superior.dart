// lib/4_componentes_globales/modales_y_alertas/banner_advertencia_superior.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/dimensiones_app.dart';
import '../../2_tema/estilos_texto.dart';

class BannerAdvertenciaSuperior extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final Color colorTema;
  final IconData icono;

  const BannerAdvertenciaSuperior({
    Key? key,
    required this.titulo,
    required this.mensaje,
    this.colorTema = ColoresApp.advertenciaAmarillo,
    this.icono = Icons.warning_amber_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: DimensionesApp.paddingTarjetas,
      decoration: BoxDecoration(
        color: colorTema.withOpacity(0.1),
        borderRadius: DimensionesApp.radioTarjetas,
        border: Border.all(color: colorTema.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Icon(icono, color: colorTema, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(
                  titulo,
                  style: TextStyle(color: colorTema, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  mensaje,
                  style: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}