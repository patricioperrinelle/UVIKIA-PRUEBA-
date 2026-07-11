// lib/4_componentes_globales/botones/selector_dificultad_nivel.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/dimensiones_app.dart';

class SelectorDificultadNivel extends StatelessWidget {
  final int nivelSeleccionado;
  final Function(int) onChanged;

  const SelectorDificultadNivel({
    Key? key,
    required this.nivelSeleccionado,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children:[
        Expanded(child: _buildBoton(1, 'Level 1', 'Básico', ColoresApp.primarioVerde)),
        const SizedBox(width: 8),
        Expanded(child: _buildBoton(2, 'Level 2', 'Medio', ColoresApp.advertenciaAmarillo)),
        const SizedBox(width: 8),
        Expanded(child: _buildBoton(3, 'Level 3', 'Complejo', ColoresApp.errorRojo)),
      ],
    );
  }

  Widget _buildBoton(int valor, String titulo, String subtitulo, Color colorNivel) {
    final bool isSelected = nivelSeleccionado == valor;
    
    // Si no está seleccionado, se ve gris/blanco por defecto. 
    // Si está seleccionado, toma el color de su respectivo nivel.
    final Color colorActivo = isSelected ? colorNivel : ColoresApp.textoPrincipal;
    
    return GestureDetector(
      onTap: () => onChanged(valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorNivel.withOpacity(0.15) : ColoresApp.cristalFuerte,
          borderRadius: DimensionesApp.radioMedio,
          border: Border.all(
            color: isSelected ? colorNivel : ColoresApp.bordeCristal,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children:[
            Text(
              titulo,
              style: TextStyle(
                color: colorActivo,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                color: isSelected ? colorNivel.withOpacity(0.8) : ColoresApp.textoSecundario,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}