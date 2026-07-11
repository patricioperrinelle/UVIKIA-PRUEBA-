// lib/5_modulos/modulo_servicios_catalogo/controladores/controlador_disponibilidad_agenda.dart

import '../../../3_modelos/modelo_servicio_catalogo.dart';

/// Representa un bloque de tiempo ya ocupado en la base de datos (por otro cliente)
class BloqueOcupado {
  final DateTime inicio;
  final DateTime fin;
  BloqueOcupado({required this.inicio, required this.fin});
}

class ControladorDisponibilidadAgenda {
  
  static List<DateTime> generarTodosLosSlotsBase({
    required DateTime fechaDeseada,
    required ModeloReglasDisponibilidad reglas,
  }) {
    if (!reglas.diasLaborales.contains(fechaDeseada.weekday)) {
      return [];
    }
    
    List<DateTime> todosLosSlots = [];
    
    final inicioJornada = _aplicarHoraAFecha(fechaDeseada, reglas.horarioInicio);
    final finJornada = _aplicarHoraAFecha(fechaDeseada, reglas.horarioFin);
    DateTime iterador = inicioJornada;
    while (iterador.isBefore(finJornada)) {
      todosLosSlots.add(iterador);
      iterador = iterador.add(Duration(minutes: reglas.frecuenciaSlotsMinutos));
    }

    if (reglas.dobleJornada) {
      final inicioJornada2 = _aplicarHoraAFecha(fechaDeseada, reglas.horarioInicio2);
      final finJornada2 = _aplicarHoraAFecha(fechaDeseada, reglas.horarioFin2);
      iterador = inicioJornada2;
      while (iterador.isBefore(finJornada2)) {
        todosLosSlots.add(iterador);
        iterador = iterador.add(Duration(minutes: reglas.frecuenciaSlotsMinutos));
      }
    }
    
    return todosLosSlots..sort();
  }

  /// Genera los "slots" (horarios) contratables para un día específico.
  /// Trabaja iterando cada 30 minutos desde la apertura hasta el cierre.
  static List<DateTime> generarSlotsDisponibles({
    required DateTime fechaDeseada,
    required DateTime fechaActual, // Inyectada para que el servidor/app controlen la zona horaria
    required ModeloReglasDisponibilidad reglas,
    required ModeloNivelServicio nivel,
    required int anticipacionMinimaHoras,
    required int capacidadSimultanea,
    required List<BloqueOcupado> reservasYaConfirmadas,
  }) {
    // 1. ¿Es un día laboral para el profesional?
    if (!reglas.diasLaborales.contains(fechaDeseada.weekday)) {
      return []; // El profesional no trabaja este día
    }

    // 2. Convertir strings de "08:00" a objetos DateTime absolutos para el día deseado
    final inicioJornada = _aplicarHoraAFecha(fechaDeseada, reglas.horarioInicio);
    final finJornada = _aplicarHoraAFecha(fechaDeseada, reglas.horarioFin);

    List<DateTime> slotsHabilitados = _evaluarRango(
      inicioJornada, finJornada, fechaActual, reglas, nivel, anticipacionMinimaHoras, capacidadSimultanea, reservasYaConfirmadas
    );

    if (reglas.dobleJornada) {
      final inicioJornada2 = _aplicarHoraAFecha(fechaDeseada, reglas.horarioInicio2);
      final finJornada2 = _aplicarHoraAFecha(fechaDeseada, reglas.horarioFin2);
      slotsHabilitados.addAll(_evaluarRango(
        inicioJornada2, finJornada2, fechaActual, reglas, nivel, anticipacionMinimaHoras, capacidadSimultanea, reservasYaConfirmadas
      ));
    }

    return slotsHabilitados..sort();
  }

  static List<DateTime> _evaluarRango(
    DateTime inicioJornada, DateTime finJornada, DateTime fechaActual, ModeloReglasDisponibilidad reglas,
    ModeloNivelServicio nivel, int anticipacionMinimaHoras, int capacidadSimultanea, List<BloqueOcupado> reservasYaConfirmadas
  ) {
    List<DateTime> slotsHabilitados = [];
    DateTime iteradorTiempo = inicioJornada;

    while (iteradorTiempo.isBefore(finJornada)) {
      final horaInicioServicio = iteradorTiempo;
      final horaFinServicio = iteradorTiempo.add(Duration(minutes: nivel.duracionMinutos));

      final bloqueOcupadoProfesionalInicio = horaInicioServicio.subtract(Duration(minutes: reglas.tiempoMuertoAntesMinutos));
      final bloqueOcupadoProfesionalFin = horaFinServicio.add(Duration(minutes: reglas.tiempoMuertoDespuesMinutos));

      bool esValido = true;

      if (bloqueOcupadoProfesionalInicio.isBefore(inicioJornada) || bloqueOcupadoProfesionalFin.isAfter(finJornada)) {
        esValido = false;
      }

      if (esValido) {
        final limiteAnticipacion = fechaActual.add(Duration(hours: anticipacionMinimaHoras));
        if (horaInicioServicio.isBefore(limiteAnticipacion)) {
          esValido = false;
        }
      }

      if (esValido) {
        for (var bloqueo in reglas.bloqueosManuales) {
          if (_haySuperposicion(bloqueOcupadoProfesionalInicio, bloqueOcupadoProfesionalFin, bloqueo.inicio, bloqueo.fin)) {
            esValido = false;
            break;
          }
        }
      }

      if (esValido) {
        int cuposOcupados = 0;
        for (var reserva in reservasYaConfirmadas) {
          if (_haySuperposicion(bloqueOcupadoProfesionalInicio, bloqueOcupadoProfesionalFin, reserva.inicio, reserva.fin)) {
            cuposOcupados++;
          }
        }
        
        if (cuposOcupados >= capacidadSimultanea) {
          esValido = false;
        }
      }

      if (esValido) {
        slotsHabilitados.add(horaInicioServicio);
      }

      iteradorTiempo = iteradorTiempo.add(Duration(minutes: reglas.frecuenciaSlotsMinutos));
    }

    return slotsHabilitados;
  }

  /// Función auxiliar: Convierte "14:30" en un DateTime completo del día evaluado.
  static DateTime _aplicarHoraAFecha(DateTime fechaBase, String horaCadena) {
    try {
      final partes = horaCadena.split(':');
      final horas = int.parse(partes[0]);
      final minutos = int.parse(partes[1]);
      return DateTime(fechaBase.year, fechaBase.month, fechaBase.day, horas, minutos);
    } catch (e) {
      // Fallback estricto de seguridad si el string falla
      return DateTime(fechaBase.year, fechaBase.month, fechaBase.day, 0, 0); 
    }
  }

  /// Función auxiliar: Verifica si dos rangos de tiempo se tocan o superponen.
  static bool _haySuperposicion(DateTime inicioA, DateTime finA, DateTime inicioB, DateTime finB) {
    // La fórmula matemática exacta para detectar colisión entre dos segmentos de tiempo:
    // (El inicio de A ocurre antes del fin de B) Y (El fin de A ocurre después del inicio de B)
    return inicioA.isBefore(finB) && finA.isAfter(inicioB);
  }
}