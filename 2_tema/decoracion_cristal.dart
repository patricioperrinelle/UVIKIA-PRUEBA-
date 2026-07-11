// lib/2_tema/decoracion_cristal.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'colores_app.dart';

class DecoracionApp {
  static final BoxDecoration tarjetaOscura = BoxDecoration(
    color: ColoresApp.fondoTarjetas,
    borderRadius: BorderRadius.circular(16.0),
    border: Border.all(color: ColoresApp.bordeCristal),
  );

  static final BoxDecoration inputFondo = BoxDecoration(
    color: ColoresApp.fondoBuscador,
    borderRadius: BorderRadius.circular(12.0),
    border: Border.all(color: ColoresApp.bordeCristal),
  );

  static List<BoxShadow> glowVerde =[
    BoxShadow(color: ColoresApp.primarioVerde.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
  ];
  
  static List<BoxShadow> glowRojo =[
    BoxShadow(color: ColoresApp.errorRojo.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
  ];

  static List<BoxShadow> sombraCaida =[
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))
  ];
}

class ContenedorCristal extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? radio;
  final EdgeInsetsGeometry? padding;
  final Color? colorFondo;
  final Color? colorBorde;

  const ContenedorCristal({
    Key? key,
    required this.child,
    this.blur = 10.0,
    this.radio,
    this.padding,
    this.colorFondo,
    this.colorBorde,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = radio ?? BorderRadius.circular(16.0);
    
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorFondo ?? ColoresApp.cristalMedio,
            borderRadius: borderRadius,
            border: Border.all(color: colorBorde ?? ColoresApp.bordeCristal),
          ),
          child: child,
        ),
      ),
    );
  }
}