// lib/5_modulos/modulo_negociacion_oficios/componentes/selector_acciones_negociacion.dart

import 'package:flutter/material.dart'; // Selector de acciones actualizado
import '../../../2_tema/colores_app.dart'; 
import '../../../2_tema/estilos_texto.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_estado_contratado_pro.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_estado_finalizado_pro.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_acciones_finales_cliente.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_validacion_pin.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_centro_resolucion.dart';
import '../../../1_nucleo/servicios/servicio_gps_localizacion.dart';

import '../controladores/controlador_negociacion.dart'; 
import 'panel_estado_abierto_profesional.dart'; 
import '../modales/modal_enviar_presupuesto_pro.dart';

import '../../../4_componentes_globales/motor_cancelaciones_visuales/motor_cancelaciones.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

import '../../modulo_billetera/componentes/seccion_checkout_integrado.dart';

class SelectorAccionesNegociacion extends StatelessWidget { 
  final ControladorNegociacion controlador; 
  final bool calificacionLocalExitosa; 
  final Function(bool) onAbrirCalificacion;

  final String trabajoId; 
  final String tituloTrabajo; 
  final double sueldo;

  const SelectorAccionesNegociacion({ 
    Key? key, 
    required this.controlador,
    required this.calificacionLocalExitosa, 
    required this.onAbrirCalificacion,
    required this.trabajoId, 
    required this.tituloTrabajo, 
    required this.sueldo, 
  }) : super(key: key);

  void _envolverLlamada(BuildContext context, Future Function() funcion) async {
    try { await funcion(); } catch (e) { if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
      Text(e.toString().replaceAll('Exception: ', '')), backgroundColor:
      ColoresApp.errorRojo)); } } 
  }

  @override 
  Widget build(BuildContext context) { 
    // 🛡️ ARQUITECTURA LIMPIA: La UI ya no piensa. Le pregunta al Controlador su estado semántico.
    if (controlador.estaCanceladoOPerdido) {
      return MotorCancelaciones.resolverVistaEstatica(
        context,
        CancelacionContexto(
          dominio: DominioApp.oficios,
          accion: TipoAccionCancelacion.vistaInPlace,
          actor: controlador.soyElDueno ? ActorCancelacion.cliente : ActorCancelacion.profesional,
          estadoTransaccional: controlador.estadoOperativoCiego, 
        ),
      );
    }

    if (controlador.soyElDueno) {
      
      if (controlador.esperandoConfirmacionPro) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.handshake_rounded, size: 64, color: ColoresApp.secundarioCyan),
              const SizedBox(height: 16),
              const Text('Esperando al profesional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.secundarioCyan)),
              const SizedBox(height: 8),
              const Text('Has aceptado el presupuesto. El profesional debe confirmar su disponibilidad antes de habilitar el pago y liberar el contrato.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
            ],
          ),
        );
      }

      if (controlador.esperandoPagoCliente) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SeccionCheckoutIntegrado(
            trabajoId: trabajoId,
            tituloTrabajo: tituloTrabajo,
            nombreProfesional: controlador.contraparteNombre,
            idProfesional: controlador.pujaAceptada?.profesionalId,
            subtotal: sueldo,
            tarifaPlataforma: sueldo * 0.10,
            tipoTrabajo: 'oficio',
            fecha: controlador.fechaFormateada,
            horaInicio: controlador.horarioLimpio,
            descripcion: controlador.descripcionLimpia,
            onPagoCompletado: () {
              _envolverLlamada(context, () => controlador.confirmarPagoYLiberarContrato());
            },
          ),
        );
      }

      if (controlador.tratoCerradoYCalificado(calificacionLocalExitosa)) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded, color: ColoresApp.primarioVerde, size: 48),
                const SizedBox(height: 12),
                const Text(
                  '¡Gracias por confiar en nuestro servicio!', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)
                ),
                const SizedBox(height: 8),
                Text(
                  'El registro pasará a tu historial.', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)
                ),
              ],
            ),
          ),
        );
      }

      if (controlador.requierePanelAccionesFinales) {
        // 🛡️ REFACTOR: Force 'asignado' or 'en_curso' based on estadoActual to prevent UI disappearing during sync delays
        String estadoPujaForzado = controlador.pujaActiva?.estadoPuja ?? '';
        if (controlador.estadoActual == EstadoNegociacion.asignado && estadoPujaForzado != 'asignado' && estadoPujaForzado != 'aceptada') {
          estadoPujaForzado = 'asignado';
        } else if (controlador.estadoActual == EstadoNegociacion.enCurso && estadoPujaForzado != 'en_curso' && estadoPujaForzado != 'esperando_pin_salida') {
          estadoPujaForzado = 'en_curso';
        }

        return PanelAccionesFinalesCliente(
          estadoPuja: estadoPujaForzado,
          yaLlego: controlador.yaLlego,
          codigoCheckin: controlador.pujaActiva?.codigoCheckin,
          codigoCheckout: controlador.pujaActiva?.codigoCheckout,
          clienteCalificoPuja: controlador.clienteCalifico || calificacionLocalExitosa,
          enMediacion: controlador.estaEnDisputa, 
          onFinalizar: () => onAbrirCalificacion(true),
          onReportar: () async {
            final result = await showModalBottomSheet<Map<String, dynamic>>(
              context: context, 
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => const ModalCentroResolucion(esCliente: true)
            );
            if (result != null) { 
              controlador.abrirDisputaYMediar(result['categoria'], result['solucion_esperada'], result['descripcion']); 
            }
          },
          onCancelar: () => controlador.solicitarCancelacionCliente(),
          onVerPoliticas: () => controlador.solicitarVerPoliticasCancelacion(),
        );
      }
    } else {
      if (controlador.esperandoConfirmacionPro) {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.handshake_rounded, size: 64, color: ColoresApp.primarioVerde),
                const SizedBox(height: 16),
                const Text('¡El cliente aceptó tu oferta!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
                const SizedBox(height: 8),
                const Text('Por favor, confirma tu disponibilidad para realizar el trabajo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
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
                        onPressed: () => _envolverLlamada(context, () => controlador.rechazarTrabajoPro()),
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
                        onPressed: () => _envolverLlamada(context, () => controlador.aceptarTrabajoPro()),
                        child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
      } else if (controlador.esperandoPagoCliente) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                const Icon(Icons.access_time_filled_rounded, size: 64, color: ColoresApp.secundarioCyan),
                const SizedBox(height: 16),
                const Text('Esperando el pago del cliente.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.secundarioCyan)),
                const SizedBox(height: 8),
                const Text('Has confirmado tu disponibilidad. El sistema está esperando que el cliente realice el pago para liberar el chat y asegurar el contrato.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
              ],
            ),
          );
      } else if (controlador.requierePanelAccionesPro) {
          return PanelEstadoAbiertoProfesional(
            miPuja: controlador.miPuja,
            onEnviarModificarOferta: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) => ModalEnviarPresupuestoPro(titulo: 'Enviar Presupuesto', subtitulo: 'Monto a cobrar.', onConfirmar: (monto) { Navigator.pop(ctx); _envolverLlamada(context, () => controlador.enviarModificarPresupuesto(monto)); })),
            onRetirarOferta: () => _envolverLlamada(context, () async { await controlador.cancelarTrabajo(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta retirada'))); Navigator.pop(context); } }), 
          );
      }
      
      if (controlador.tratoFinalizado) {
        return PanelEstadoFinalizadoPro(
          proCalifico: controlador.proCalifico || calificacionLocalExitosa,
          onCalificar: () => onAbrirCalificacion(false),
        );
      }
      
      if (controlador.requierePanelAccionesFinales) {
        String estadoPujaForzado = controlador.pujaActiva?.estadoPuja ?? '';
        if (controlador.estadoActual == EstadoNegociacion.asignado && estadoPujaForzado != 'asignado' && estadoPujaForzado != 'aceptada') {
          estadoPujaForzado = 'asignado';
        } else if (controlador.estadoActual == EstadoNegociacion.enCurso && estadoPujaForzado != 'en_curso' && estadoPujaForzado != 'esperando_pin_salida') {
          estadoPujaForzado = 'en_curso';
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelEstadoContratadoPro(
              estadoPuja: estadoPujaForzado,
              profesionalEnCamino: false, 
              coordenadasLlegada: controlador.pujaActiva?.coordenadasLlegada,
              enMediacion: controlador.estaEnDisputa, 
              onAceptarTrabajo: () {}, onRechazarTrabajo: () {},
              onLlegadaGPS: () => _envolverLlamada(context, () => controlador.registrarLlegadaGPS(() { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Habilita el GPS para registrar tu llegada.'))); })),
              onValidarCheckin: () async {
                final pin = await showDialog<String>(context: context, builder: (_) => const DialogoValidacionPin(titulo: 'PIN de Llegada', subtitulo: 'Pídele al cliente el PIN de 6 dígitos para iniciar.'));
                if (pin != null && pin.isNotEmpty) { _envolverLlamada(context, () => controlador.validarCheckInPro(pin)); }
              },
              onFinalizarTarea: () => _envolverLlamada(context, () => controlador.solicitarCheckOutPro()),
              onValidarCheckout: () async {
                final pin = await showDialog<String>(context: context, builder: (_) => const DialogoValidacionPin(titulo: 'PIN de Salida', subtitulo: 'Pídele al cliente el PIN final de 6 dígitos para terminar.'));
                if (pin != null && pin.isNotEmpty) { _envolverLlamada(context, () => controlador.validarCheckOutPro(pin)); }
              },
              onAbrirMapa: () => ServicioGpsLocalizacion.abrirEnMapa(controlador.ubicacionMaps),
              onReportarProblema: () async {
                final result = await showModalBottomSheet<Map<String, dynamic>>(
                  context: context, 
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const ModalCentroResolucion(esCliente: false)
                );
                if (result != null) { 
                  controlador.abrirDisputaYMediar(result['categoria'], result['solucion_esperada'], result['descripcion']); 
                }
              },
              onCancelar: () => controlador.solicitarCancelacionPro(),
              onVerPoliticas: () => controlador.solicitarVerPoliticasCancelacion(),
            ),
            if (!controlador.estaEnDisputa)
              const SizedBox.shrink(),
            const SizedBox(height: 12),
          ],
        );
      }
    }
    return const SizedBox.shrink();
  }
}