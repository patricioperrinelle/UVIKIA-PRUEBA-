// lib/4_componentes_globales/indicadores/fila_informacion_icono.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/dimensiones_app.dart';
import '../../2_tema/estilos_texto.dart';

class FilaInformacionIcono extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const FilaInformacionIcono({
    Key? key,
    required this.icono,
    required this.titulo,
    required this.valor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); // 🚨 Leemos el tema global
    final esOscuro = tema.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: esOscuro ? ColoresApp.cristalMedio : Colors.black.withOpacity(0.05), // 🚨 Fondo del icono adaptable
            borderRadius: DimensionesApp.radioMedio,
          ),
          child: Icon(icono, color: tema.textTheme.bodySmall?.color, size: 20), // 🚨 Icono adaptable
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text(
                titulo,
                style: EstilosTextoApp.cuerpoPequeno.copyWith(color: tema.textTheme.bodySmall?.color), // 🚨 Título adaptable
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: EstilosTextoApp.cuerpoDestacado.copyWith(fontSize: 15, color: tema.colorScheme.onSurface), // 🚨 Valor adaptable
              ),
            ],
          ),
        ),
      ],
    );
  }
}