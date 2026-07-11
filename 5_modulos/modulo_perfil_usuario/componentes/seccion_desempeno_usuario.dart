// lib/5_modulos/modulo_perfil_usuario/componentes/seccion_desempeno_usuario.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';

// 🚨 AQUÍ ESTÁ LA CLASE QUE DEBE TENER 'colorIcono'
class MetricaDesempeno {
  final IconData icono;
  final Color colorIcono; // <-- Este es el parámetro que pedía Flutter
  final String titulo;
  final String subtitulo;
  final String valorText;

  MetricaDesempeno({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.subtitulo,
    required this.valorText,
  });
}

class SeccionDesempenoUsuario extends StatelessWidget {
  final String tituloSeccion;
  final String subtituloSeccion;
  final List<MetricaDesempeno> metricas;
  
  final double scoreConfiabilidad;
  final String etiquetaScore;
  final String tipoScore; 
  final Color colorScoreBox;

  const SeccionDesempenoUsuario({
    Key? key,
    required this.tituloSeccion,
    required this.subtituloSeccion,
    required this.metricas,
    required this.scoreConfiabilidad,
    required this.etiquetaScore,
    required this.tipoScore,
    required this.colorScoreBox,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorTextoBase = tema.colorScheme.onSurface;
    final colorGris = tema.textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: esOscuro ? ColoresApp.fondoTarjetas : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(tituloSeccion, style: EstilosTextoApp.h3.copyWith(color: colorTextoBase)),
              Text(subtituloSeccion, style: TextStyle(color: colorGris, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12), 
          
          ...metricas.asMap().entries.map((entry) {
            final int idx = entry.key;
            final MetricaDesempeno m = entry.value;
            return Column(
              children:[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children:[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: m.colorIcono.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(m.icono, color: m.colorIcono, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(m.titulo, style: TextStyle(color: colorTextoBase, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(m.subtitulo, style: TextStyle(color: colorGris, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        m.valorText,
                        style: TextStyle(
                          color: colorTextoBase, // Números sin color
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < metricas.length - 1)
                  Divider(color: esOscuro ? Colors.white12 : Colors.black12, height: 1, thickness: 1),
              ],
            );
          }).toList(),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScoreBox.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScoreBox.withOpacity(0.2)),
            ),
            child: Row(
              children:[
                Icon(Icons.shield_rounded, color: colorScoreBox, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text('Score de confiabilidad', style: TextStyle(color: colorTextoBase, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(etiquetaScore, style: TextStyle(color: colorGris, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children:[
                    Text(
                      scoreConfiabilidad.toStringAsFixed(1),
                      style: TextStyle(color: colorTextoBase, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScoreBox,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(tipoScore, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}