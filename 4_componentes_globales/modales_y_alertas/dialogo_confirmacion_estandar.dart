// lib/4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import '../../2_tema/dimensiones_app.dart';

class DialogoConfirmacionEstandar extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final String textoBotonConfirmar;
  final String textoBotonCancelar;
  final Color colorConfirmar;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const DialogoConfirmacionEstandar({
    Key? key,
    required this.titulo,
    required this.mensaje,
    required this.onConfirmar,
    required this.onCancelar,
    this.textoBotonConfirmar = 'Confirmar',
    this.textoBotonCancelar = 'Cancelar',
    this.colorConfirmar = ColoresApp.errorRojo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColoresApp.fondoTarjetas,
      shape: RoundedRectangleBorder(
        borderRadius: DimensionesApp.radioTarjetas,
      ),
      title: Text(
        titulo,
        style: EstilosTextoApp.h3.copyWith(color: colorConfirmar),
      ),
      content: Text(
        mensaje,
        style: EstilosTextoApp.cuerpoRegular.copyWith(color: ColoresApp.textoSecundario),
      ),
      actions:[
        TextButton(
          onPressed: onCancelar,
          child: Text(
            textoBotonCancelar,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorConfirmar,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: DimensionesApp.radioPequeno,
            ),
          ),
          child: Text(
            textoBotonConfirmar,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
