// lib/4_componentes_globales/motor_cancelaciones_visuales/motor_cancelaciones.dart

import 'package:flutter/material.dart';
import 'modelos/cancelacion_contexto.dart';
import 'resolvers/resolver_base.dart';
import 'resolvers/resolver_oficios.dart';
import 'resolvers/resolver_jornadas.dart';
import 'resolvers/resolver_catalogo.dart';

class MotorCancelaciones {
  
  /// Factory interna para obtener el resolver exacto según el dominio
  static ResolverCancelacion _obtenerResolver(DominioApp dominio) {
    switch (dominio) {
      case DominioApp.oficios:
        return ResolverOficios();
      case DominioApp.jornadas:
        return ResolverJornadas();
      case DominioApp.catalogo:
        return ResolverCatalogo();
    }
  }

  /// Orquestador para levantar Modales (BottomSheet)
  static Future<void> resolverYMostrarModal(BuildContext context, CancelacionContexto contexto) async {
    final resolver = _obtenerResolver(contexto.dominio);
    final modalVisual = resolver.construirModal(context, contexto);

    if (modalVisual != null) {
      // Configuraciones de UX: ¿El usuario puede tocar fuera para cerrar?
      final bool esBloqueante = (contexto.accion == TipoAccionCancelacion.avisoProCanceladoPorCliente || 
                                 contexto.accion == TipoAccionCancelacion.avisoClienteCanceladoPorPro);

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: !esBloqueante,
        enableDrag: !esBloqueante,
        builder: (ctx) => modalVisual,
      );
    }
  }

  /// Orquestador para inyectar Vistas Estáticas dentro del árbol de Widgets (Ej: Paneles de estado)
  static Widget resolverVistaEstatica(BuildContext context, CancelacionContexto contexto) {
    final resolver = _obtenerResolver(contexto.dominio);
    return resolver.construirVistaInPlace(context, contexto);
  }
}