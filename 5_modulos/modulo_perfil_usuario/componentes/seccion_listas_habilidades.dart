// lib/5_modulos/modulo_perfil_usuario/componentes/seccion_listas_habilidades.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';

class SeccionListasHabilidades extends StatelessWidget {
  final List<String> habilidades;
  final List<String> servicios;

  const SeccionListasHabilidades({
    Key? key,
    required this.habilidades,
    required this.servicios,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    // Si ambas están vacías, no dibujamos nada para ahorrar espacio
    if (habilidades.isEmpty && servicios.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        // COLUMNA IZQUIERDA: Habilidades y Certificados
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text('Habilidades y Certificados', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface, fontSize: 16)),
              const SizedBox(height: 12),
              if (habilidades.isEmpty)
                Text('No especificadas', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13, fontStyle: FontStyle.italic)),
              ...habilidades.map((item) => _buildBullet(item, context)),
            ],
          ),
        ),
        const SizedBox(width: 16), // Separador central
        // COLUMNA DERECHA: Servicios Extras
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text('Servicios Extras', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface, fontSize: 16)),
              const SizedBox(height: 12),
              if (servicios.isEmpty)
                Text('No especificados', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13, fontStyle: FontStyle.italic)),
              ...servicios.map((item) => _buildBullet(item, context)),
            ],
          ),
        ),
      ],
    );
  }

  // 🚀 VIÑETAS PREMIUM: Punto Verde + Texto ordenado
  Widget _buildBullet(String text, BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: ColoresApp.primarioVerde),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(color: tema.textTheme.bodyMedium?.color, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}