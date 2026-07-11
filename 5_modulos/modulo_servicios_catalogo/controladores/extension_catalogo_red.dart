// lib/5_modulos/modulo_servicios_catalogo/controladores/extension_catalogo_red.dart
part of 'controlador_catalogo_cliente.dart';

List<ModeloServicioCatalogo> _mapearServiciosBackground(List<Map<String, dynamic>> rawList) {
  return rawList.map((row) => ModeloServicioCatalogo.fromJson(row)).toList();
}

extension ExtensionCatalogoRed on ControladorCatalogoCliente {
  
  Future<void> _fetchSiguientePagina() async {
    final genActual = _generacion; // 🛡️ Toma la "foto" de la generación (Línea 1)

    try {
      // 🛡️ REGLA V5.7: Lectura estricta y pura de la RAM (Sin inyección silenciosa del perfil)
      final ciudadBusqueda = provinciaFiltro;
      final localidadBusqueda = localidadFiltro;

      List<Map<String, dynamic>> rawJobs = await ServicioCatalogoSupabase.obtenerServiciosPaginadosV5(
        ciudad: ciudadBusqueda,
        localidad: localidadBusqueda,
        categoria: categoriaFiltro, // 🛡️ Inyección estricta
        keyword: palabraClave,      // 🛡️ Inyección estricta
        cursorEsCiudad: _motorCatalogo.cursor.esCiudad,
        cursorEsLocalidad: _motorCatalogo.cursor.esLocalidad,
        cursorRank: _motorCatalogo.cursor.rank,
        cursorRotacion: _motorCatalogo.cursor.rotacion,
        cursorFecha: _motorCatalogo.cursor.fecha,
        cursorId: _motorCatalogo.cursor.id,
        limit: 20,
        perfilesCache: _cachePerfilesVendedores,
      );

      // 🛡️ CORTOCIRCUITO ANTI-GHOST: Matamos al fantasma si el usuario tocó un filtro
      if (genActual != _generacion) return;

      // 🛡️ EL CLEAR ESTRATÉGICO (Anti-Wipeout)
      // Se borra la memoria RAM vieja solo una fracción de segundo antes de inyectar la nueva
      if (_isRefresh) {
        _motorCatalogo.elementos.clear(); 
        _isRefresh = false;
      }

      if (rawJobs.isNotEmpty) {
        final last = rawJobs.last;
        
        _motorCatalogo.cursor.esCiudad = ciudadBusqueda.isNotEmpty && (last['ciudad'] == ciudadBusqueda);
        _motorCatalogo.cursor.esLocalidad = localidadBusqueda.isNotEmpty && (last['localidad'] == localidadBusqueda);
        
        _motorCatalogo.cursor.rank = (last['rank_calc'] as num?)?.toDouble() ?? 0.0;
        _motorCatalogo.cursor.rotacion = (last['rotacion_calc'] as num?)?.toInt() ?? 2147483647;
        _motorCatalogo.cursor.fecha = last['created_at']?.toString() ?? '2000-01-01T00:00:00Z';
        _motorCatalogo.cursor.id = last['id']?.toString() ?? '00000000-0000-0000-0000-000000000000';

        final nuevosModelos = await compute(_mapearServiciosBackground, rawJobs);
        final miId = GestorSesionGlobal().miIdUsuario;
        final nuevosModelosFiltrados = nuevosModelos.where((s) => s.profesionalId != miId).toList();
        
        _motorCatalogo.anexarPaginaSegura(nuevosModelosFiltrados, esRefresh: false);
        
      } else {
        _motorCatalogo.hasReachedMax = true;
        // Obligamos al motor a procesar la anexión de página nula
        _motorCatalogo.anexarPaginaSegura([], esRefresh: false);
      }
    } catch (e) {
      debugPrint('Error en fetch paginado V5.7 de Catálogo: $e');
    }
  }

  // ----------------------------------------------------------------------
  // 🚀 V5.9.3: FETCH SILENCIOSO PARA PARCHE SWR EN RAM
  // ----------------------------------------------------------------------
  Future<List<ModeloServicioCatalogo>> _obtenerPagina1CatalogoSilenciosa() async {
    try {
      final cursorLimpio = CursorTuplaV5(); // 🛡️ Cursor inmaculado para traer solo Página 1
      
      List<Map<String, dynamic>> rawJobs = await ServicioCatalogoSupabase.obtenerServiciosPaginadosV5(
        ciudad: provinciaFiltro,
        localidad: localidadFiltro,
        categoria: categoriaFiltro, 
        keyword: palabraClave,      
        cursorEsCiudad: cursorLimpio.esCiudad,
        cursorEsLocalidad: cursorLimpio.esLocalidad,
        cursorRank: cursorLimpio.rank,
        cursorRotacion: cursorLimpio.rotacion,
        cursorFecha: cursorLimpio.fecha,
        cursorId: cursorLimpio.id,
        limit: 20,
        perfilesCache: _cachePerfilesVendedores, // 🛡️ Reusamos el caché de perfiles para ahorrar requests
      );

      if (rawJobs.isEmpty) return [];

      // Procesamiento asíncrono para no bloquear el Hilo Principal (UI Thread)
      final modelos = await compute(_mapearServiciosBackground, rawJobs);
      final miId = GestorSesionGlobal().miIdUsuario;
      return modelos.where((s) => s.profesionalId != miId).toList();
    } catch (e) {
      debugPrint('SWR-Titan: Error Extracción SWR Silenciosa (Catálogo): $e');
      return [];
    }
  }

}
