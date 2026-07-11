// lib/4_componentes_globales/botones/boton_delineado_secundario.dart

import 'package:flutter/material.dart';
import '../../2_tema/dimensiones_app.dart';

class BotonDelineadoSecundario extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;
  final Color colorPrimario;
  final bool isLoading;

  const BotonDelineadoSecundario({
    Key? key,
    required this.texto,
    required this.onPressed,
    required this.colorPrimario,
    this.icono,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorPrimario.withOpacity(0.8), width: 1.5),
          backgroundColor: colorPrimario.withOpacity(0.05), // Leve tinte de fondo
          shape: RoundedRectangleBorder(
            borderRadius: DimensionesApp.radioBoton,
          ),
          padding: DimensionesApp.paddingBotones,
        ),
        icon: isLoading 
            ? SizedBox(
                width: 18, 
                height: 18, 
                child: CircularProgressIndicator(color: colorPrimario, strokeWidth: 2)
              )
            : (icono != null ? Icon(icono, color: colorPrimario, size: 18) : const SizedBox.shrink()),
        label: Text(
          texto,
          style: TextStyle(
            color: colorPrimario,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}