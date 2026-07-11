// lib/4_componentes_globales/cabeceras/titulo_seccion_con_icono.dart

import 'package:flutter/material.dart';

class TituloSeccionConIcono extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorTema;

  const TituloSeccionConIcono({
    Key? key,
    required this.titulo,
    required this.icono,
    required this.colorTema,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Este componente está excelente, los colores son pasados por parámetro 
    // y se adaptan visualmente bien tanto al claro como oscuro.
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Row(
        children:[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorTema.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: colorTema, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            titulo.toUpperCase(),
            style: TextStyle(
              color: colorTema,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:[colorTema.withOpacity(0.5), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}