// lib/5_modulos/modulo_chat_mensajes/componentes/burbuja_mensaje_sistema.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class BurbujaMensajeSistema extends StatelessWidget {
  final String codigoSistema;

  const BurbujaMensajeSistema({
    Key? key,
    required this.codigoSistema,
  }) : super(key: key);

  String _traducirComando(String comando) {
    switch (comando) {
      case 'SYS_SALIENDO': return 'El profesional se encuentra en camino al lugar.';
      case 'SYS_LLEGUE': return 'El profesional ha llegado al lugar.';
      case 'SYS_TERMINE': return 'El profesional ha finalizado el trabajo.';
      case 'SYS_CONFIRMA_SALIDA': return 'El cliente confirmó la salida del profesional.';
      case 'SYS_ESPERA_SALIDA': return 'El cliente ha solicitado al profesional que espere.';
      case 'SYS_NO_LLEGO': return 'El cliente reportó que no encuentra al profesional.';
      case 'SYS_NO_TERMINO': return 'El cliente reportó que el trabajo aún no está terminado.';
      case 'SYS_PAGADO': return 'El cliente ha informado que realizó el pago.';
      case 'SYS_PAGO_RECIBIDO': return 'El profesional confirmó la recepción del pago. Trabajo finalizado.';
      default: return 'Actualización del sistema.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ColoresApp.cristalFuerte, // Gris oscuro translúcido
            borderRadius: DimensionesApp.radioTarjetas,
            border: Border.all(color: ColoresApp.bordeCristal),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:[
              const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _traducirComando(codigoSistema),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}