// lib/5_modulos/modulo_gestion_jornadas/modales/modal_alerta_gps_desactivado.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';
import '../../../2_tema/colores_app.dart';

class ModalAlertaGpsDesactivado {
  static void mostrar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: 'GPS Desactivado o Sin Permisos',
        mensaje: 'Activa tu GPS y otorga permisos de ubicación para dejar constancia de tu llegada. Esto protege tu pago ante cualquier disputa.',
        textoBotonConfirmar: 'Activar GPS',
        textoBotonCancelar: 'Cancelar',
        colorConfirmar: ColoresApp.secundarioCyan,
        onCancelar: () => Navigator.pop(ctx),
        onConfirmar: () {
          Navigator.pop(ctx);
          Geolocator.openLocationSettings(); // Abre configuración nativa
        },
      ),
    );
  }
}