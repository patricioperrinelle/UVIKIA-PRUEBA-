// lib/4_componentes_globales/motor_cancelaciones_visuales/resolvers/resolver_catalogo.dart

import 'package:flutter/material.dart';
import 'resolver_base.dart';
import '../modelos/cancelacion_contexto.dart';
import '../../modales_y_alertas/modal_advertencia_cancelacion_cliente.dart';
import '../../modales_y_alertas/modal_advertencia_cancelacion_pro.dart';
import '../../paneles_ejecucion/panel_aviso_cancelacion_pro.dart';
import '../../paneles_ejecucion/panel_aviso_cancelacion_cliente.dart';
import '../../modales_y_alertas/modal_politica_cancelacion.dart';

// 🛡️ REFACTOR: Importación limpia intra-capa (Cero dependencias a lib/5_modulos)
import '../ui/panel_estado_cancelado_global.dart';

class ResolverCatalogo implements ResolverCancelacion {
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
    if (contexto.accion == TipoAccionCancelacion.vistaInPlace) {
      final estado = contexto.estadoTransaccional ?? '';
      final soyPro = contexto.actor == ActorCancelacion.profesional;
      
      final bool fueCanceladoPorPro = estado == 'cancelada_por_pro' || estado == 'cancelada_vista_cliente';
      final bool yoCancele = (soyPro && fueCanceladoPorPro) || (!soyPro && !fueCanceladoPorPro);

      return PanelEstadoCanceladoGlobal(
        titulo: 'RESERVA CANCELADA',
        subtitulo: yoCancele 
            ? 'Has cancelado esta reserva de catálogo. El servicio no se llevará a cabo.' 
            : 'La contraparte ha cancelado este servicio.',
        esError: true,
      );
    }
    
    return const SizedBox.shrink();
  }
}