// lib/5_modulos/modulo_gestion_jornadas/controladores/extension_jornadas_parseo.dart

import '../../../1_nucleo/utilidades/formateador_textos_trabajos.dart';
import 'controlador_jornadas.dart';

extension ParseoJornadas on ControladorJornadas {
  
  bool get tratoCancelado => jobDataExtendida['estado'] == 'cancelado';
  bool get tratoFinalizado => jobDataExtendida['estado'] == 'finalizado' || esHistorial;
  bool get proCalifico => jobDataExtendida['pro_califico'] == true;
  bool get esRechazado => !soyElDueno && (miPuja?.estadoPuja == 'rechazada' || miPuja?.estadoPuja == 'rechazada_por_pro');

  bool get revelarDireccion => soyElDueno || 
    ((miPuja?.estadoPuja == 'aceptada' || miPuja?.estadoPuja == 'en_curso' || miPuja?.estadoPuja == 'esperando_pin_salida' || miPuja?.estadoPuja == 'finalizada') && !tratoCancelado);

  bool get mostrarContactoLiberado => (miPuja?.estadoPuja == 'aceptada' || miPuja?.estadoPuja == 'en_curso' || miPuja?.estadoPuja == 'esperando_pin_salida' || miPuja?.estadoPuja == 'finalizada' || miPuja?.estadoPuja == 'desestimada') && !tratoCancelado;

  String get referenciaLugar {
    final desc = jobDataExtendida['description'] ?? '';
    if (desc.contains('Notas del cliente:')) {
      final partes = desc.split('Notas del cliente:');
      if (partes.length > 1 && partes[1].trim().isNotEmpty) {
        return partes[1].trim();
      }
    }
    return '';
  }

  String get descripcionLimpia {
    final desc = jobDataExtendida['description'] ?? '';
    if (desc.contains('Notas del cliente:')) {
      return desc.split('Notas del cliente:')[0].trim();
    }
    return desc;
  }

  String get requisitosLimpios => jobDataExtendida['requisitos']?.toString() ?? '';
  String get fechaCruda => jobDataExtendida['date']?.toString() ?? jobDataExtendida['fecha_hora']?.toString() ?? '';

  String get fechaFormateada => FormateadorTextosTrabajos.obtenerFechaFormateada(fechaCruda);

  String get fechaSubLabel {
    if (fechaCruda.isEmpty) return 'Fecha a acordar';
    DateTime? dt;
    try {
      if (fechaCruda.contains('/')) {
        final p = fechaCruda.split('/');
        if (p.length == 3) dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } else {
        dt = DateTime.parse(fechaCruda).toLocal();
      }
    } catch (_) {}
    if (dt == null) return '';
    final hoy = DateTime.now();
    final diff = DateTime(dt.year, dt.month, dt.day).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;

    if (diff < 0) return 'Completado / Expirado';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 7) return 'En $diff días';
    if (diff == 7) return 'En 1 semana';
    if (diff < 30) return 'En ${(diff / 7).floor()} semanas';
    return 'En ${(diff / 30).floor()} meses';
  }

  String get horaInicioExtraida => FormateadorTextosTrabajos.obtenerHorarioLimpio(fechaCruda);

  String get horaFinExtraida => jobDataExtendida['hora_fin']?.toString() ?? '';

  String get horarioLimpio {
    if (horaInicioExtraida.isNotEmpty) {
      String armado = horaInicioExtraida;
      if (horaFinExtraida.isNotEmpty) armado += '  -  $horaFinExtraida';
      return armado;
    }
    return 'A coordinar';
  }

  String get horarioSubLabel {
    if (horaInicioExtraida.isEmpty || horaFinExtraida.isEmpty) return 'Horario estimado';
    try {
      final startParts = horaInicioExtraida.split(':');
      final endParts = horaFinExtraida.split(':');
      if (startParts.length >= 2 && endParts.length >= 2) {
        final hStart = int.parse(startParts[0]);
        final mStart = int.parse(startParts[1]);
        final hEnd = int.parse(endParts[0]);
        final mEnd = int.parse(endParts[1]);

        var duracionMinutos = (hEnd * 60 + mEnd) - (hStart * 60 + mStart);
        if (duracionMinutos < 0) duracionMinutos += 24 * 60;

        final horas = duracionMinutos ~/ 60;
        final minutosRestantes = duracionMinutos % 60;

        if (minutosRestantes == 0) return '$horas hora${horas != 1 ? 's' : ''}';
        return '$horas h $minutosRestantes min';
      }
    } catch(_) {}
    return 'Horario estimado';
  }

  String get ubicacionParaDetalles {
    String ubicacionCompleta = jobDataExtendida['ubicacion_exacta']?.toString() ?? jobDataExtendida['location']?.toString() ?? 'Dirección no especificada';
    return FormateadorTextosTrabajos.obtenerUbicacionParaDetalles(jobDataExtendida['ubicacion_exacta']?.toString() ?? '', ubicacionCompleta, revelarDireccion);
  }

  String get ubicacionMaps {
    String ubicacion = jobDataExtendida['ubicacion_exacta']?.toString() ?? '';
    return FormateadorTextosTrabajos.obtenerUbicacionMaps(ubicacion, jobDataExtendida['location']?.toString() ?? '');
  }

  String get telefonoContacto => jobDataExtendida['telefono_contacto']?.toString() ?? jobDataExtendida['whatsapp']?.toString() ?? jobDataExtendida['telefono_contraparte']?.toString() ?? '';

  String get metodoPagoDetectado {
    String metodoDetectado = 'Acordado';
    final precioFinal = jobDataExtendida['precio_final_acordado']?.toString() ?? '';
    if (precioFinal.contains('Efectivo')) metodoDetectado = 'Efectivo';
    if (precioFinal.contains('Transferencia')) metodoDetectado = 'Transferencia';
    return metodoDetectado;
  }
}