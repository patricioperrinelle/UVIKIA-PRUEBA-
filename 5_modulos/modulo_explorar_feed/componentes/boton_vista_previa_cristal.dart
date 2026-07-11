// lib/5_modulos/modulo_explorar_feed/componentes/boton_vista_previa_cristal.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';

class BotonVistaPreviaCristal extends StatelessWidget {
  final int cantidad;
  final String tipo;
  final VoidCallback onTap;

  const BotonVistaPreviaCristal({
    Key? key,
    required this.cantidad,
    required this.tipo,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cantidad == 0) return const SizedBox.shrink();
    
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final String texto = cantidad == 1 ? '👀 Previsualizar mi $tipo activo' : '👀 Previsualizar mis $cantidad ${tipo}s activos';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: esOscuro ? ColoresApp.cristalMedio : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Text(texto, style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: tema.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}