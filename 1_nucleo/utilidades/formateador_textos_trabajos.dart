// lib/1_nucleo/utilidades/formateador_textos_trabajos.dart

class FormateadorTextosTrabajos {
  static String obtenerFechaFormateada(String fechaCruda) {
    if (fechaCruda.isEmpty) return 'A definir';
    DateTime? dt;
    try {
      if (fechaCruda.contains('/')) {
        final p = fechaCruda.split('/');
        if (p.length == 3) dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } else { 
        dt = DateTime.parse(fechaCruda).toLocal(); 
      }
    } catch (_) {}
    if (dt == null) return fechaCruda;
    final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${dias[dt.weekday - 1]}, ${dt.day} ${meses[dt.month - 1]}';
  }

  static String obtenerHorarioLimpio(String fechaCruda) {
    if (fechaCruda.isEmpty) return 'A definir';
    try {
      if (!fechaCruda.contains('/')) {
        final dt = DateTime.parse(fechaCruda).toLocal();
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return 'A definir';
  }

  static String obtenerUbicacionParaDetalles(String ubicacionExacta, String localidad, bool revelarDireccion) {
    String ubicacionBase = ubicacionExacta.isNotEmpty ? ubicacionExacta : localidad;
    if (ubicacionBase.contains('||')) {
      final partes = ubicacionBase.split('||');
      if (partes.length >= 5) {
        List<String> trozos = [];
        if (revelarDireccion) {
          String calleNum = '${partes[0].trim()} ${partes[1].trim()}'.trim();
          if (calleNum.isNotEmpty) trozos.add(calleNum);
        }
        if (partes[2].trim().isNotEmpty) trozos.add(partes[2].trim()); 
        if (partes[3].trim().isNotEmpty) trozos.add(partes[3].trim()); 
        if (partes[4].trim().isNotEmpty) trozos.add(partes[4].trim()); 
        return trozos.join(', ');
      }
    }
    return ubicacionBase;
  }

  static String obtenerUbicacionMaps(String ubicacionExacta, String localidad) {
    if (ubicacionExacta.contains('||')) {
      final partes = ubicacionExacta.split('||');
      if (partes.length >= 5) {
        String calleNum = '${partes[0].trim()} ${partes[1].trim()}'.trim();
        List<String> trozos = [];
        if (calleNum.isNotEmpty) trozos.add(calleNum);
        if (partes[3].trim().isNotEmpty) trozos.add(partes[3].trim()); 
        if (partes[4].trim().isNotEmpty) trozos.add(partes[4].trim()); 
        return trozos.join(', ');
      }
    }
    return ubicacionExacta.isNotEmpty ? ubicacionExacta : localidad;
  }
}
