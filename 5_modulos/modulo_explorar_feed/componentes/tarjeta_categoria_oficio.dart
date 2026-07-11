// lib/5_modulos/modulo_explorar_feed/componentes/tarjeta_categoria_oficio.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class TarjetaCategoriaOficio extends StatelessWidget {
  final String nombre;
  final IconData icono;
  final VoidCallback onTap;

  const TarjetaCategoriaOficio({
    Key? key,
    required this.nombre,
    required this.icono,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: DimensionesApp.radioModales, 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              // 🚨 Adaptación de fondo cristal y borde
              color: esOscuro ? ColoresApp.cristalSuave : Colors.white.withOpacity(0.6),
              borderRadius: DimensionesApp.radioModales,
              border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black.withOpacity(0.05)),
              boxShadow: esOscuro ? null :[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Icon(icono, size: 40, color: ColoresApp.secundarioCyan),
                const SizedBox(height: 12),
                // 🚨 Texto adaptativo
                Text(nombre, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}