// lib/5_modulos/modulo_explorar_feed/componentes/estado_vacio_feed.dart

import 'package:flutter/material.dart';
import '../../../4_componentes_globales/estados/estado_vacio_ilustrado.dart';

class EstadoVacioFeed extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;

  const EstadoVacioFeed({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: EstadoVacioIlustrado(
          icono: icono,
          titulo: titulo,
          subtitulo: subtitulo,
        ),
      ),
    );
  }
}