// lib/4_componentes_globales/motor_cancelaciones_visuales/resolvers/resolver_base.dart

import 'package:flutter/material.dart';
import '../modelos/cancelacion_contexto.dart';

abstract class ResolverCancelacion {
  /// Devuelve el BottomSheet correspondiente al contexto
  Widget? construirModal(BuildContext context, CancelacionContexto contexto);

  /// Devuelve un Widget estático para reemplazar UI hardcodeada (cortinas visuales)
  Widget construirVistaInPlace(BuildContext context, CancelacionContexto contexto);
}