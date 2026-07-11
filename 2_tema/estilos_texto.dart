// lib/2_tema/estilos_texto.dart

import 'package:flutter/material.dart';
import 'colores_app.dart';

class EstilosTextoApp {
  static const String fuentePrincipal = 'Manrope';

  static const TextStyle h1 = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 32, fontWeight: FontWeight.w900, color: ColoresApp.textoPrincipal, height: 1.1, letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 26, fontWeight: FontWeight.w900, color: ColoresApp.textoPrincipal, letterSpacing: 0.5,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.textoPrincipal,
  );

  static const TextStyle cuerpoDestacado = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 16, fontWeight: FontWeight.bold, color: ColoresApp.textoPrincipal,
  );
  
  static const TextStyle cuerpoRegular = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 14, color: ColoresApp.textoSecundario, height: 1.4,
  );
  
  static const TextStyle cuerpoPequeno = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 12, color: ColoresApp.textoSecundario,
  );

  static const TextStyle botonPrincipal = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.0,
  );
  
  static const TextStyle etiquetaEstado = TextStyle(
    fontFamily: fuentePrincipal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0,
  );
}