// lib/5_modulos/modulo_negociacion_oficios/controladores/extension_negociacion_parseo.dart
import '../../../1_nucleo/utilidades/formateador_textos_trabajos.dart';
import 'controlador_negociacion.dart';

extension ParseoNegociacion on ControladorNegociacion {
  
  bool get mostrarContactoLiberado {
    final estaActivo = estadoActual == EstadoNegociacion.asignado || estadoActual == EstadoNegociacion.enCurso;
    return (estaActivo || estadoActual == EstadoNegociacion.finalizado) && !perdiElTrabajo;
  }

  String get telefonoContacto {
    if (soyElDueno) { return pujaAceptada?.telefono ?? ''; }
    return jobData['telefono']?.toString() ?? '';
  }

  String get _fechaCruda => jobData['date']?.toString() ?? jobData['fecha_hora']?.toString() ?? '';

  String get fechaFormateada => FormateadorTextosTrabajos.obtenerFechaFormateada(_fechaCruda);

  String get fechaSubLabel {
    if (_fechaCruda.isEmpty) return 'Fecha a acordar';
    DateTime? dt;
    try {
      if (_fechaCruda.contains('/')) {
        final p = _fechaCruda.split('/');
        if (p.length == 3) dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } else { dt = DateTime.parse(_fechaCruda).toLocal(); }
    } catch (_) {}
    if (dt == null) return '';
    final hoy = DateTime.now();
    final diff = DateTime(dt.year, dt.month, dt.day).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diff < 0) return 'Completado / Expirado';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 7) return 'En $diff días';
    return diff == 7 ? 'En 1 semana' : 'Futuro';
  }

  String get horarioLimpio => FormateadorTextosTrabajos.obtenerHorarioLimpio(_fechaCruda);

  String get referenciaLugar {
    String desc = jobData['description']?.toString() ?? '';
    if (desc.contains('Notas del cliente:')) {
      final partes = desc.split('Notas del cliente:');
      if (partes.length > 1 && partes[1].trim().isNotEmpty) {
        return partes[1].trim();
      }
    }
    return '';
  }

  String get descripcionLimpia {
    String desc = jobData['description']?.toString() ?? 'Sin descripción';
    if (desc.contains('Notas del cliente:')) {
      desc = desc.split('Notas del cliente:')[0].trim();
    }
    final reqOriginales = jobData['requisitos']?.toString() ?? '';
    if (reqOriginales.isEmpty && desc.contains('🛠️')) return desc.split('🛠️')[0].trim();
    return desc;
  }

  String get requisitosLimpios {
    String req = jobData['requisitos']?.toString() ?? '';
    final desc = jobData['description']?.toString() ?? '';
    if (req.isEmpty && desc.contains('🛠️')) req = desc.split('🛠️').sublist(1).join('🛠️').trim();
    if (req.startsWith('Requiere herramientas:')) req = req.replaceFirst('Requiere herramientas:', '').trim();
    if (req.startsWith('Requisitos:')) req = req.replaceFirst('Requisitos:', '').trim();
    return req.isNotEmpty ? req : 'Ninguno';
  }

  bool get revelarDireccion {
    final estaActivo = estadoActual == EstadoNegociacion.asignado || estadoActual == EstadoNegociacion.enCurso;
    return soyElDueno || ((estaActivo || estadoActual == EstadoNegociacion.finalizado) && !perdiElTrabajo);
  }

  String get ubicacionParaDetalles {
    String ubicacionExacta = jobData['ubicacion_exacta']?.toString() ?? '';
    String localidad = jobData['location']?.toString() ?? '';
    return FormateadorTextosTrabajos.obtenerUbicacionParaDetalles(ubicacionExacta, localidad, revelarDireccion);
  }

  String get ubicacionMaps {
    String ubicacionExacta = jobData['ubicacion_exacta']?.toString() ?? '';
    return FormateadorTextosTrabajos.obtenerUbicacionMaps(ubicacionExacta, jobData['location']?.toString() ?? '');
  }

  String get counterpartName {
    if (soyElDueno) { return pujaAceptada?.apodoProfesional ?? 'Profesional'; }
    String name = jobData['counterpart']?.toString() ?? jobData['contraparteNombre']?.toString() ?? '';
    if (name.isEmpty || name == 'null') {
      final perf = jobData['perfiles'] ?? jobData['perfil'];
      if (perf is Map) {
        name = perf['apodo']?.toString() ?? perf['nombre']?.toString() ?? '';
      }
    }
    if (name.isEmpty || name == 'null') name = 'Usuario';
    return name.replaceAll('Cliente: ', '').replaceAll('Profesional: ', '');
  }

  String get counterpartAvatar {
    if (soyElDueno) { return pujaAceptada?.avatarUrl ?? ''; }
    String avatar = jobData['counterpartAvatar']?.toString() ?? jobData['contraparteAvatar']?.toString() ?? jobData['avatarUrl']?.toString() ?? '';
    if (avatar.isEmpty || avatar == 'null') {
      final perf = jobData['perfiles'] ?? jobData['perfil'];
      if (perf is Map) {
        avatar = perf['foto_url']?.toString() ?? perf['avatar_url']?.toString() ?? '';
      }
    }
    return avatar;
  }

  // 🛡️ REFACTOR: Getter de Rating blindado para SWR, priorizando el de cliente.
  double get counterpartRating {
    if (soyElDueno) { return pujaAceptada?.rating ?? 0.0; }
    
    final rootRating = jobData['ratingContraparte']?.toString() ?? jobData['rating_cliente']?.toString() ?? jobData['ratingCliente']?.toString() ?? jobData['rating']?.toString();
    if (rootRating != null && rootRating.isNotEmpty) return double.tryParse(rootRating) ?? 0.0;
    
    final perf = jobData['perfiles'] ?? jobData['perfil'];
    if (perf is Map) {
      final perfRating = perf['rating_cliente']?.toString() ?? perf['promedio_estrellas']?.toString() ?? perf['rating']?.toString();
      if (perfRating != null && perfRating.isNotEmpty) return double.tryParse(perfRating) ?? 0.0;
    }
    return 0.0;
  }

  // 🛡️ REFACTOR: Getter de Reseñas blindado para SWR, priorizando el de cliente.
  int get counterpartReviews {
    if (soyElDueno) { return pujaAceptada?.reviews ?? 0; }
    
    final rootRev = jobData['reviewsContraparte']?.toString() ?? jobData['cantidad_resenas_cliente']?.toString() ?? jobData['cantidadResenasCliente']?.toString() ?? jobData['reviews']?.toString() ?? jobData['cantidad_resenas']?.toString();
    if (rootRev != null && rootRev.isNotEmpty) return int.tryParse(rootRev) ?? 0;
    
    final perf = jobData['perfiles'] ?? jobData['perfil'];
    if (perf is Map) {
      final perfRev = perf['cantidad_resenas_cliente']?.toString() ?? perf['cantidad_resenas']?.toString();
      if (perfRev != null && perfRev.isNotEmpty) return int.tryParse(perfRev) ?? 0;
    }
    return 0;
  }
}