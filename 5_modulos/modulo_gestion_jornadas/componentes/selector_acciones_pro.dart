// lib/5_modulos/modulo_gestion_jornadas/componentes/selector_acciones_pro.dart

import 'package:flutter/material.dart'; 
import '../../../2_tema/colores_app.dart'; 
import '../../../3_modelos/modelo_puja.dart'; 
import '../controladores/controlador_jornadas.dart'; 
import '../../../1_nucleo/servicios/servicio_gps_localizacion.dart'; 
import '../modales/modal_alerta_gps_desactivado.dart'; 
import '../../../4_componentes_globales/modales_y_alertas/dialogo_validacion_pin.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_estado_contratado_pro.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_estado_finalizado_pro.dart';
import 'panel_estado_desestimado_pro.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_centro_resolucion.dart';

class SelectorAccionesPro extends StatelessWidget { 
  final ControladorJornadas controlador; 
  final Function(bool, ModeloPuja?) onAbrirCalificacion;
  final bool proCalificoLocal;

  const SelectorAccionesPro({ 
    Key? key, 
    required this.controlador, 
    required this.onAbrirCalificacion, 
    this.proCalificoLocal = false, 
  }) : super(key: key);

  @override 
  Widget build(BuildContext context) { 
    // 🛡️ ARQUITECTURA LIMPIA: La vista ya no evalúa strings de base de datos.
    if (controlador.miPujaDesestimada) { 
      return PanelEstadoDesestimadoPro( 
        proCalifico: controlador.miPuja?.proCalificoPuja == true || proCalificoLocal, 
        onCalificar: () => onAbrirCalificacion(false, controlador.miPuja) 
      ); 
    }

    if (controlador.miPujaFinalizada) {
      return PanelEstadoFinalizadoPro(
        proCalifico: controlador.miPuja?.proCalificoPuja == true || proCalificoLocal, 
        onCalificar: () => onAbrirCalificacion(false, controlador.miPuja)
      );
    } 

    if (controlador.esperandoConfirmacionPro) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.handshake_rounded, size: 64, color: ColoresApp.primarioVerde),
            const SizedBox(height: 16),
            const Text('¡El cliente te eligió!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
            const SizedBox(height: 8),
            const Text('Por favor, confirma tu disponibilidad para asistir a la jornada.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.errorRojo,
                      side: const BorderSide(color: ColoresApp.errorRojo),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => controlador.rechazarContratacionPro(),
                    child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.primarioVerde,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => controlador.aceptarContratacionPro(),
                    child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    if (controlador.esperandoPagoCliente) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            const Icon(Icons.access_time_filled_rounded, size: 64, color: ColoresApp.secundarioCyan),
            const SizedBox(height: 16),
            const Text('Esperando el pago del cliente.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.secundarioCyan)),
            const SizedBox(height: 8),
            const Text('Has confirmado tu disponibilidad. El sistema está esperando que el cliente realice el pago para liberar el chat y asegurar tu lugar en la jornada.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
      );
    }

    if (controlador.miPujaEnEjecucion) {
      return PanelEstadoContratadoPro(
        estadoPuja: controlador.miPuja!.estadoPuja, 
        profesionalEnCamino: controlador.profesionalEnCamino, 
        coordenadasLlegada: controlador.miPuja?.coordenadasLlegada, 
        enMediacion: controlador.miPuja?.estadoPuja == 'en_disputa',
        onAceptarTrabajo: () {}, 
        onRechazarTrabajo: () {}, 
        onLlegadaGPS: () => controlador.registrarLlegadaGPS(() => ModalAlertaGpsDesactivado.mostrar(context)),
        onValidarCheckin: () async {
          final pin = await showDialog<String>(context: context, builder: (_) => const DialogoValidacionPin(titulo: 'Validar Llegada', subtitulo: 'Ingresa el PIN que te dictó el cliente para registrar el comienzo de la jornada.'));
          if (pin != null && pin.isNotEmpty) controlador.validarCheckInPro(controlador.miPuja!, pin);
        },
        onFinalizarTarea: () => controlador.solicitarCheckOutPro(),
        onValidarCheckout: () async {
          final pin = await showDialog<String>(context: context, builder: (_) => const DialogoValidacionPin(titulo: 'Finalizar Jornada', subtitulo: 'Ingresa el PIN que te dictó el cliente para cerrar correctamente la jornada.'));
          if (pin != null && pin.isNotEmpty) controlador.validarCheckOutPro(controlador.miPuja!, pin);
        },
        onAbrirMapa: () => ServicioGpsLocalizacion.abrirEnMapa(controlador.miPuja?.coordenadasLlegada ?? ''),
        onReportarProblema: () async {
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context, 
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const ModalCentroResolucion(esCliente: false)
          );
          if (result != null) { 
            controlador.abrirDisputaYMediar(controlador.miPuja!, result['categoria'], result['solucion_esperada'], result['descripcion']); 
          }
        },
        onCancelar: controlador.solicitarCancelacionPro,
        onVerPoliticas: controlador.solicitarVerPoliticasCancelacion,
      );
    }

    return const SizedBox.shrink();
  }
}