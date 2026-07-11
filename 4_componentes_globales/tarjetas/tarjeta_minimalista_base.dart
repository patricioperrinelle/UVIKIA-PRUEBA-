// lib/4_componentes_globales/tarjetas/tarjeta_minimalista_base.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

/// Un contenedor estandarizado con fondo blanco/oscuro, bordes sutiles y sombra suave.
/// Reemplaza el uso repetitivo de Containers decorados en las vistas de detalles.
class TarjetaMinimalistaBase extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const TarjetaMinimalistaBase({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    this.margin = const EdgeInsets.only(bottom: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: esOscuro ? ColoresApp.fondoTarjetas : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200,
        ),
        boxShadow: esOscuro ? [] :[
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}