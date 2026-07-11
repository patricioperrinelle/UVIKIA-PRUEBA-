// lib/4_componentes_globales/estados/pantalla_cargando_bloqueante.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class PantallaCargandoBloqueante extends StatelessWidget {
  final String? mensaje;

  const PantallaCargandoBloqueante({
    Key? key,
    this.mensaje,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.6), // Fondo oscuro bloqueante
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            const CircularProgressIndicator(color: ColoresApp.primarioVerde),
            if (mensaje != null) ...[
              const SizedBox(height: 16),
              Text(
                mensaje!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}