// lib/5_modulos/modulo_publicaciones/componentes/banner_profesional_destino.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class BannerProfesionalDestino extends StatelessWidget {
  final String nombreProfesional;

  const BannerProfesionalDestino({Key? key, required this.nombreProfesional}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); 

    return ClipRRect(
      borderRadius: DimensionesApp.radioTarjetas,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: DimensionesApp.paddingTarjetas,
          decoration: BoxDecoration(
            color: ColoresApp.secundarioCyan.withOpacity(0.1), 
            borderRadius: DimensionesApp.radioTarjetas,
            border: Border.all(color: ColoresApp.secundarioCyan.withOpacity(0.5)),
          ),
          child: Row(
            children:[
              const Icon(Icons.shield_rounded, color: ColoresApp.secundarioCyan, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 🚨 EL BLINDAJE: Evita desbordamiento vertical infinito en SingleChildScrollViews
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text('Solicitud directa y segura para:', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      nombreProfesional, 
                      style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}