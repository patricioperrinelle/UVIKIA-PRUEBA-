// lib/4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart

import 'package:flutter/material.dart';
import '../../../3_modelos/contratos/dominio_app.dart';
export '../../../3_modelos/contratos/dominio_app.dart';

enum TipoAccionCancelacion {
  advertenciaCliente,           // Modal rojo antes de cancelar (Cliente)
  advertenciaPro,               // Modal rojo antes de cancelar (Pro)
  avisoProCanceladoPorCliente,  // Cartel de compensación o aviso (Pro)
  avisoClienteCanceladoPorPro,  // Cartel de opciones para republicar (Cliente)
  verPoliticas,                 // Tabla informativa neutra
  vistaInPlace                  // 🚨 Renderiza la UI estática muerta (Ej: cortina visual en Jornadas)
}

enum ActorCancelacion { cliente, profesional }

class CancelacionContexto {
  final DominioApp dominio;
  final TipoAccionCancelacion accion;
  final ActorCancelacion actor;
  
  // Datos Matemáticos / Retenciones
  final double? porcentajeRetencion;
  final double? montoRetenido;
  final double? gananciaPro;
  final int? puntosPenalizacion;
  
  // Datos Contextuales de Estado
  final String? estadoTransaccional; // Ej: 'cancelada_por_cliente', 'rechazada_por_pro'
  final String? identificadorTarget; // Puede ser el ID de la puja (Jornadas) o del trabajo
  
  // Callbacks para delegar ejecución al controlador padre
  final VoidCallback? onConfirmar;
  final VoidCallback? onEntendido;
  final VoidCallback? onRepublicar;

  CancelacionContexto({
    required this.dominio,
    required this.accion,
    required this.actor,
    this.porcentajeRetencion,
    this.montoRetenido,
    this.gananciaPro,
    this.puntosPenalizacion,
    this.estadoTransaccional,
    this.identificadorTarget,
    this.onConfirmar,
    this.onEntendido,
    this.onRepublicar,
  });
}