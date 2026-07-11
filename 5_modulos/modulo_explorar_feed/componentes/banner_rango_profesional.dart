// lib/5_modulos/modulo_explorar_feed/componentes/banner_rango_profesional.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class BannerRangoProfesional extends StatelessWidget {
  const BannerRangoProfesional({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esOscuro ? ColoresApp.terciarioMorado.withOpacity(0.1) : ColoresApp.terciarioMorado.withOpacity(0.05),
        borderRadius: DimensionesApp.radioTarjetas,
        border: Border.all(color: ColoresApp.terciarioMorado.withOpacity(0.3)),
      ),
      child: Row(
        children:[
          const Icon(Icons.star_rounded, color: ColoresApp.terciarioMorado, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text('Mi Rango Profesional', style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Completa más trabajos para subir de nivel y destacar.', style: TextStyle(color: tema.textTheme.bodyMedium?.color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}