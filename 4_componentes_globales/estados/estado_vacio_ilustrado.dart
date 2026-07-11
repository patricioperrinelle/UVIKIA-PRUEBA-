// lib/4_componentes_globales/estados/estado_vacio_ilustrado.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';

class EstadoVacioIlustrado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const EstadoVacioIlustrado({
    Key? key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Icon(
            icono,
            size: 72,
            color: ColoresApp.textoSecundario.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            style: EstilosTextoApp.h3.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: EstilosTextoApp.cuerpoRegular,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}