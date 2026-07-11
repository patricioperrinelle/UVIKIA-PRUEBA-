// lib/4_componentes_globales/modales_y_alertas/dialogo_exito_cristal.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import '../../2_tema/dimensiones_app.dart';

class DialogoExitoCristal extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final IconData icono;
  final Color colorTema;
  final VoidCallback onAceptar;

  const DialogoExitoCristal({
    Key? key,
    required this.titulo,
    required this.mensaje,
    required this.onAceptar,
    this.icono = Icons.check_circle_outline_rounded,
    this.colorTema = ColoresApp.primarioVerde,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: DimensionesApp.radioModales,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: DimensionesApp.paddingPantalla,
            decoration: BoxDecoration(
              color: ColoresApp.fondoTarjetas.withOpacity(0.9),
              borderRadius: DimensionesApp.radioModales,
              border: Border.all(color: colorTema, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                Icon(icono, color: colorTema, size: 64),
                const SizedBox(height: 16),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: EstilosTextoApp.h2,
                ),
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAceptar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: DimensionesApp.radioMedio,
                      ),
                      side: BorderSide(color: colorTema, width: 1.5),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: colorTema,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}