// lib/4_componentes_globales/motor_cancelaciones_visuales/resolvers/resolver_jornadas.dart

import 'package:flutter/material.dart';
import 'resolver_base.dart';
import '../modelos/cancelacion_contexto.dart';
import '../../modales_y_alertas/modal_advertencia_cancelacion_cliente.dart';
import '../../modales_y_alertas/modal_advertencia_cancelacion_pro.dart';
import '../../paneles_ejecucion/panel_aviso_cancelacion_pro.dart';
import '../../paneles_ejecucion/panel_aviso_cancelacion_cliente.dart';
import '../../modales_y_alertas/modal_politica_cancelacion.dart';

// 🛡️ REFACTOR: Importación limpia intra-capa
import '../ui/panel_estado_cancelado_global.dart';

class ResolverJornadas implements ResolverCancelacion {
  @override
  Widget? construirModal(BuildContext context, CancelacionContexto contexto) {
    switch (contexto.accion) {
      case TipoAccionCancelacion.advertenciaCliente:
        return ModalAdvertenciaCancelacionCliente(
          porcentajeRetencion: contexto.porcentajeRetencion ?? 0.0,
          montoRetenido: contexto.montoRetenido ?? 0.0,
          onConfirmar: contexto.onConfirmar ?? () {},
        );
      case TipoAccionCancelacion.advertenciaPro:
        return ModalAdvertenciaCancelacionPro(
          puntosPenalizacion: contexto.puntosPenalizacion ?? 0,
          onConfirmar: contexto.onConfirmar ?? () {},
        );
      case TipoAccionCancelacion.avisoProCanceladoPorCliente:
        return PanelAvisoCancelacionPro(
          gananciaPro: contexto.gananciaPro ?? 0.0,
          onEntendido: contexto.onEntendido ?? () {},
        );
      case TipoAccionCancelacion.avisoClienteCanceladoPorPro:
        return PanelAvisoCancelacionCliente(
          onRepublicar: null, 
          onEntendido: contexto.onEntendido ?? () {},
        );
      case TipoAccionCancelacion.verPoliticas:
        return const ModalPoliticaCancelacion();
      default:
        return null;
    }
  }

  @override
  Widget construirVistaInPlace(BuildContext context, CancelacionContexto contexto) {
    final estado = contexto.estadoTransaccional ?? '';
    final bool soyPro = contexto.actor == ActorCancelacion.profesional;
    final bool soyCliente = contexto.actor == ActorCancelacion.cliente;
    
    if (estado == 'cancelada_por_cliente' || estado == 'cancelada_vista_pro' || estado == 'cancelada') {
      return PanelEstadoCanceladoGlobal(
        titulo: soyCliente ? 'CANCELASTE ESTE CONTRATO' : 'CONTRATO CANCELADO',
        subtitulo: soyCliente 
            ? 'Has cancelado a este postulante. El profesional ha sido notificado.' 
            : 'El cliente ha cancelado este contrato individual y el trabajo no se llevará a cabo.',
        esError: true,
      );
    } 
    else if (estado == 'cancelada_por_pro') {
      return PanelEstadoCanceladoGlobal(
        titulo: soyPro ? 'CANCELASTE TU ASISTENCIA' : 'EL PROFESIONAL CANCELÓ',
        subtitulo: soyPro 
            ? 'Has cancelado tu asistencia a esta jornada. Tu reputación ha sido penalizada según las políticas.' 
            : 'El profesional tuvo un imprevisto y canceló su asistencia. Ha sido penalizado en su reputación.',
        esError: true,
      );
    }
    else if (estado == 'rechazada_por_pro') {
      return PanelEstadoCanceladoGlobal(
        titulo: soyPro ? 'RECHAZASTE LA CONTRATACIÓN' : 'NO DISPONIBLE',
        subtitulo: soyPro 
            ? 'Has rechazado la contratación para esta jornada.' 
            : 'Ha rechazado la contratación por problemas de disponibilidad en su agenda.',
        esError: true,
      );
    }
    
    return const SizedBox.shrink();
  }
}