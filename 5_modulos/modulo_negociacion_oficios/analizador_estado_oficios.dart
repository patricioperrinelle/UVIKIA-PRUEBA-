import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../4_componentes_globales/contratos/analizador_estado.dart';
import '../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';
import '../../3_modelos/contratos/trabajo_contratable.dart';

class AnalizadorEstadoOficios implements AnalizadorEstado {
  @override
  DominioApp get dominio => DominioApp.oficios;

  @override
  PaqueteVisualTarjeta analizar({
    required TrabajoContratable trabajo,
    required bool esDueno,
    required String miId,
    required bool esHistorial,
  }) {
    // 1. UBICACIÓN
    String textoUbicacionReal = '';
    if (trabajo.ubicacionExacta.isNotEmpty) {
      textoUbicacionReal = trabajo.ubicacionExacta.replaceAll('||', ' ').trim();
    } else if (trabajo.localidad.isNotEmpty) {
      textoUbicacionReal = trabajo.localidad.trim();
    }

    if (textoUbicacionReal.isEmpty ||
        textoUbicacionReal.toLowerCase().contains('convenir') ||
        textoUbicacionReal.toLowerCase().contains('definir')) {
      textoUbicacionReal = 'Dirección no especificada';
    }

    final bool tieneSolicitado = trabajo.profesionalSolicitadoId.toString().isNotEmpty && trabajo.profesionalSolicitadoId.toString() != 'null';
    final bool tieneAsignado = trabajo.profesionalAsignadoId.toString().isNotEmpty && trabajo.profesionalAsignadoId.toString() != 'null';

    final bool esPropuestaDirecta = esDueno && tieneSolicitado;
    final bool esRechazadaPorPro = esDueno && esPropuestaDirecta && (trabajo.estadoNegociacion == 'rechazada' || trabajo.estado == 'cancelado');
    final bool esRechazadaLocal = (!esDueno && (trabajo.estadoNegociacion == 'rechazada' || trabajo.estadoNegociacion == 'rechazada_por_pro'));
    final bool esCancelado = trabajo.estado == 'cancelado' || esRechazadaLocal;
    final bool esPendiente = !esCancelado && (trabajo.estado == 'pendiente' || trabajo.estado == 'abierto');
    final bool esAsignado = !esCancelado && trabajo.estado == 'asignado';
    final bool esEnCurso = !esCancelado && (trabajo.estado == 'en_curso' || trabajo.estado == 'esperando_pin_salida');

    final bool esFinalizado = trabajo.estado == 'finalizado';
    final bool faltaCalificarPro = esFinalizado && !esDueno && trabajo.proCalifico == false;
    final bool faltaCalificarCliente = esFinalizado && esDueno && trabajo.clienteCalifico == false;

    final bool esPerdedor = (!esDueno && (esAsignado || esEnCurso) && tieneAsignado && trabajo.profesionalAsignadoId != miId);
    final bool perdiElTrabajo = esRechazadaLocal || esPerdedor;

    final bool hayContratoActivo = trabajo.pujas.any((p) => p.estadoPuja == 'aceptada' || p.estadoPuja == 'en_curso' || p.estadoPuja == 'esperando_pin_salida') ||
                                   (trabajo.estado == 'asignado' || trabajo.estado == 'en_curso' || trabajo.estado == 'esperando_pin_salida');

    bool mostrarBasurero = false;

    if (esDueno) {
      if (!esHistorial && !hayContratoActivo && !esPropuestaDirecta && trabajo.estado != 'finalizado' && trabajo.estado != 'cancelado') {
        mostrarBasurero = true;
      }
    } else {
      if (esHistorial) {
        mostrarBasurero = esRechazadaPorPro || perdiElTrabajo || esCancelado;
      } else {
        mostrarBasurero = esPendiente && !faltaCalificarPro;
      }
    }

    final bool tacharTextos = esRechazadaPorPro || perdiElTrabajo || esCancelado;

    Color estadoColor = Colors.grey;
    String estadoLabel = '';
    bool usarPuntito = false;
    bool esPillBurbuja = false;

    if (esRechazadaPorPro) {
      estadoColor = ColoresApp.errorRojo;
      estadoLabel = 'No disponible';
      esPillBurbuja = true;
    } else if (perdiElTrabajo) {
      estadoColor = ColoresApp.errorRojo;
      estadoLabel = 'Eligieron a otro profesional';
      esPillBurbuja = true;
    } else if (esCancelado) {
      estadoColor = ColoresApp.errorRojo;
      estadoLabel = esDueno ? 'Cancelado' : 'Cancelado por el cliente';
      esPillBurbuja = true;
    } else if (faltaCalificarCliente || faltaCalificarPro) {
      estadoColor = ColoresApp.advertenciaAmarillo;
      estadoLabel = 'Falta calificar';
    } else if (esFinalizado) {
      estadoColor = ColoresApp.primarioVerde;
      estadoLabel = 'Finalizado';
    } else if (esEnCurso) {
      estadoColor = ColoresApp.secundarioCyan;
      estadoLabel = 'En curso';
    } else if (esAsignado) {
      estadoColor = ColoresApp.primarioVerde;
      estadoLabel = 'Trato cerrado';
    } else if (esPendiente) {
      if (esDueno) {
        int activeBids = trabajo.cantidadPujasTotales;
        if (activeBids == 0) {
          estadoLabel = 'Sin ofertas';
          estadoColor = Colors.grey;
        } else {
          estadoLabel = activeBids == 1 ? '1 oferta' : '$activeBids ofertas';
          estadoColor = ColoresApp.primarioVerde;
          usarPuntito = true;
        }
      } else {
        final bool aceptoBase = trabajo.aceptoPrecioBase == true;
        estadoLabel = aceptoBase ? 'Postulado' : 'Esperando';
        estadoColor = aceptoBase ? ColoresApp.primarioVerde : ColoresApp.advertenciaAmarillo;
      }
    } else {
      estadoLabel = trabajo.estado.toUpperCase();
    }

    String precioLimpio = '';
    double precioCalculado = trabajo.precioTotalFinal;
    if (precioCalculado > 0) {
      precioLimpio = precioCalculado.toStringAsFixed(0);
    } else {
      precioLimpio = trabajo.precio.replaceAll('\$', '').trim();
    }
    if (precioLimpio.isEmpty || precioLimpio == '0' || precioLimpio == '0.0') {
      precioLimpio = 'A definir';
    }
    final bool esTextoAdefinir = precioLimpio.toLowerCase().contains('definir') || precioLimpio.toLowerCase().contains('convenir');

    return PaqueteVisualTarjeta(
      estadoLabel: estadoLabel,
      estadoColor: estadoColor,
      usarPuntito: usarPuntito,
      esPillBurbuja: esPillBurbuja,
      mostrarBasurero: mostrarBasurero,
      tacharTextos: tacharTextos,
      textoFecha: _formatearSoloFecha(trabajo.fechaHora),
      textoHora: _formatearSoloHora(trabajo),
      textoUbicacion: textoUbicacionReal,
      precioLimpio: precioLimpio,
      esTextoAdefinir: esTextoAdefinir,
      iconoFallo: Icons.handyman_rounded,
    );
  }

  String _formatearSoloFecha(String isoDate) {
    if (isoDate.isEmpty || isoDate.toLowerCase().contains('definir')) return 'Fecha a definir';
    try {
      DateTime? dt = DateTime.tryParse(isoDate);
      if (dt == null) return isoDate.split('T').first;

      const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${dias[dt.weekday - 1]}, ${dt.day} ${meses[dt.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatearSoloHora(TrabajoContratable trabajo) {
    String isoDate = trabajo.fechaHora;
    String? horaFin = trabajo.horaFin;

    if (isoDate.isEmpty || isoDate.toLowerCase().contains('definir')) return 'Hora a definir';

    try {
      final f = DateTime.tryParse(isoDate);
      if (f == null) return isoDate;

      String horaInicio = '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

      if (horaFin != null && horaFin.isNotEmpty) {
        final hF = DateTime.tryParse(horaFin);
        if (hF != null) {
          String hFinStr = '${hF.hour.toString().padLeft(2, '0')}:${hF.minute.toString().padLeft(2, '0')}';
          return '$horaInicio - $hFinStr';
        }
        return '$horaInicio - $horaFin';
      }

      return horaInicio;
    } catch (_) {
      return 'Hora a definir';
    }
  }
}
