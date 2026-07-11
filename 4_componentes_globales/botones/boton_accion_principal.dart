// lib/4_componentes_globales/botones/boton_accion_principal.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import '../../2_tema/dimensiones_app.dart';

class BotonAccionPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color colorFondo;
  final Color colorTexto;

  const BotonAccionPrincipal({
    Key? key,
    required this.texto,
    required this.onPressed,
    this.isLoading = false,
    this.colorFondo = ColoresApp.primarioVerde,
    this.colorTexto = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // Altura estándar táctil
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorFondo,
          foregroundColor: colorTexto,
          shape: RoundedRectangleBorder(
            borderRadius: DimensionesApp.radioTarjetas,
          ),
          elevation: 5,
          shadowColor: colorFondo.withOpacity(0.4),
        ),
        child: isLoading
            ? CircularProgressIndicator(color: colorTexto)
            : Text(
                texto.toUpperCase(),
                style: EstilosTextoApp.botonPrincipal.copyWith(color: colorTexto),
              ),
      ),
    );
  }
}