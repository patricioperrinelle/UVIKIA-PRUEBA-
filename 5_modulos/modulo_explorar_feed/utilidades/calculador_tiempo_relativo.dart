// lib/5_modulos/modulo_explorar_feed/utilidades/calculador_tiempo_relativo.dart

class CalculadorTiempoRelativo {
  /// Recibe un String en formato ISO 8601 (o similar) y devuelve una cadena legible.
  static String calcular(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recientemente';
    
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.isNegative) return 'Hace 1 min';

      if (diff.inMinutes < 60) {
        return diff.inMinutes <= 1 ? 'Hace 1 min' : 'Hace ${diff.inMinutes} min';
      }
      
      if (diff.inHours < 24 && now.day == date.day) {
        return 'Hace ${diff.inHours} hs';
      }

      final int days = diff.inDays;
      if (days == 0 || days == 1) return 'Hace 1 día';
      if (days < 7) return 'Hace $days días';
      if (days < 14) return 'Hace 1 semana';
      if (days < 30) return 'Hace ${days ~/ 7} semanas';
      if (days < 60) return 'Hace 1 mes';
      
      return 'Hace ${days ~/ 30} meses';
    } catch (_) {
      return 'Recientemente';
    }
  }
}