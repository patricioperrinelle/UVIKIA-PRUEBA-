// lib/4_componentes_globales/botones/boton_cristal_icono.dart

import 'package:flutter/material.dart';
import '../../2_tema/dimensiones_app.dart';

class BotonCristalIcono extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color colorAcento;
  final VoidCallback? onTap;
  final bool isProcessing;

  const BotonCristalIcono({
    Key? key,
    required this.texto,
    required this.icono,
    required this.colorAcento,
    required this.onTap,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isProcessing ? null : onTap,
      borderRadius: DimensionesApp.radioTarjetas,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorAcento.withOpacity(0.08),
          borderRadius: DimensionesApp.radioTarjetas,
          border: Border.all(color: colorAcento.withOpacity(0.4), width: 1.5),
        ),
        child: isProcessing
            ? Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: colorAcento, strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Icon(icono, color: colorAcento, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      texto,
                      style: TextStyle(
                        color: colorAcento,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}