// lib/1_nucleo/utilidades/calculador_penalizaciones.dart
class CalculadorPenalizaciones {
  
  /// Devuelve el porcentaje de retención económica para el CLIENTE basado en la anticipación.
  static double calcularRetencionCliente(DateTime fechaPactada) {
    final horasRestantes = fechaPactada.difference(DateTime.now()).inHours;
    
    if (horasRestantes >= 48) return 0.20; // 20%
    if (horasRestantes >= 24) return 0.35; // 35%
    if (horasRestantes >= 8)  return 0.60; // 60%
    return 1.00; // 100%
  }

  /// Calcula la distribución del dinero retenido al cliente.
  static Map<String, double> calcularDistribucionCancelacion(DateTime fechaPactada, double precioTotal) {
    final horasRestantes = fechaPactada.difference(DateTime.now()).inHours;
    
    double porcentajeRetencionTotal = 0.0;
    double porcentajeApp = 0.0;
    double porcentajePro = 0.0;

    if (horasRestantes >= 48) {
      porcentajeRetencionTotal = 0.20;
      porcentajeApp = 0.20; 
      porcentajePro = 0.00; 
    } 
    else if (horasRestantes >= 24) {
      porcentajeRetencionTotal = 0.35;
      porcentajeApp = 0.20;
      porcentajePro = 0.15; 
    } 
    else if (horasRestantes >= 8) {
      porcentajeRetencionTotal = 0.60;
      porcentajeApp = 0.20;
      porcentajePro = 0.40; 
    } 
    else {
      porcentajeRetencionTotal = 1.00;
      porcentajeApp = 0.30; 
      porcentajePro = 0.70; 
    }

    final montoRetenidoTotal = precioTotal * porcentajeRetencionTotal;

    return {
      'montoRetenidoTotal': montoRetenidoTotal,
      'gananciaApp': precioTotal * porcentajeApp,
      'gananciaPro': precioTotal * porcentajePro,
      'porcentajePro': porcentajePro,
    };
  }

  static double calcularMontoRetencion(double precioTotal, double porcentaje) {
    return precioTotal * porcentaje;
  }

  // 🚨 NUEVO: Motor de Penalización de Confiabilidad para el PROFESIONAL
  static int calcularPuntosPenalizacionPro(DateTime fechaPactada) {
    final horasRestantes = fechaPactada.difference(DateTime.now()).inHours;
    
    if (horasRestantes >= 48) return 0;   // Sin penalización grave
    if (horasRestantes >= 24) return 5;   // Advertencia leve
    if (horasRestantes >= 8)  return 15;  // Pérdida moderada
    return 30;                            // Incidencia grave (menos de 8 hs)
  }
}