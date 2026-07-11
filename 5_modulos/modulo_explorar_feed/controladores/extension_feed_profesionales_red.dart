// lib/5_modulos/modulo_explorar_feed/controladores/extension_feed_profesionales_red.dart
part of 'controlador_feed_profesionales.dart';

List<ModeloPerfil> _mapearPerfilesBackground(List<Map<String, dynamic>> rawList) {
  return rawList.map((row) => ModeloPerfil.fromJson(row)).toList();
}

extension ExtensionRedProfesionales on ControladorFeedProfesionales {
  
  Future<void> _fetchSiguientePagina() async {
    final genActual = _generacion; // 🛡️ Toma la "foto" de la generación (Línea 1)

    try {
      final miId = GestorSesionGlobal().miIdUsuario;
      
      // 🛡️ REGLA V5.7: Lectura estricta y pura de la RAM (Sin inyección silenciosa del perfil)
      final ciudadBusqueda = provinciaFiltro;
      final localidadBusqueda = localidadFiltro;

      List<Map<String, dynamic>> rawPros = await ServicioFeedSupabase.obtenerProfesionalesPaginadosV5(
        ciudad: ciudadBusqueda,
        localidad: localidadBusqueda,
        categoria: categoriaFiltro, // 🛡️ Inyección estricta
        keyword: palabraClave,      // 🛡️ Inyección estricta
        cursorEsCiudad: _motorProfesionales.cursor.esCiudad,
        cursorEsLocalidad: _motorProfesionales.cursor.esLocalidad,
        cursorRank: _motorProfesionales.cursor.rank,
        cursorScore: _motorProfesionales.cursor.score,
        cursorEstrellas: _motorProfesionales.cursor.estrellas,
        cursorActividad: _motorProfesionales.cursor.actividad,
        cursorRotacion: _motorProfesionales.cursor.rotacion,
        cursorId: _motorProfesionales.cursor.id,
        limit: 20, 
        miId: miId,
      );

      // 🛡️ CORTOCIRCUITO ANTI-GHOST: Matamos al fantasma si el usuario tocó un filtro
      if (genActual != _generacion) return;

      // 🛡️ EL CLEAR ESTRATÉGICO (Anti-Wipeout)
      // Se borra la memoria RAM vieja solo una fracción de segundo antes de inyectar la nueva
      if (_isRefresh) {
        _motorProfesionales.elementos.clear(); 
        _isRefresh = false;
      }

      if (rawPros.isNotEmpty) {
        final last = rawPros.last;
        
        _motorProfesionales.cursor.esCiudad = ciudadBusqueda.isNotEmpty && (last['ciudad'] == ciudadBusqueda);
        _motorProfesionales.cursor.esLocalidad = localidadBusqueda.isNotEmpty && (last['localidad'] == localidadBusqueda);
        
        _motorProfesionales.cursor.rank = (last['rank_calc'] as num?)?.toDouble() ?? 0.0;
        _motorProfesionales.cursor.score = (last['score_confiabilidad_pro'] as num?)?.toDouble() ?? 100.0;
        _motorProfesionales.cursor.estrellas = (last['promedio_estrellas'] as num?)?.toDouble() ?? 5.0;
        _motorProfesionales.cursor.actividad = last['created_at'] ?? '2000-01-01T00:00:00Z';
        _motorProfesionales.cursor.rotacion = (last['rotacion_calc'] as num?)?.toInt() ?? 2147483647;
        _motorProfesionales.cursor.id = last['id'] ?? '00000000-0000-0000-0000-000000000000';

        final nuevos = await compute(_mapearPerfilesBackground, rawPros);
        
        _motorProfesionales.anexarPaginaSegura(nuevos, esRefresh: false);
        
      } else {
        _motorProfesionales.hasReachedMax = true;
        // Obligamos al motor a procesar la anexión de página nula
        _motorProfesionales.anexarPaginaSegura([], esRefresh: false);
      }
    } catch (e) {
      debugPrint('Error en fetch V5.7 de Profesionales: $e');
    }
  }

  // ----------------------------------------------------------------------
  // 🚀 V5.9.3: FETCH SILENCIOSO PARA PARCHE SWR EN RAM
  // ----------------------------------------------------------------------
  Future<List<ModeloPerfil>> _obtenerPagina1ProfesionalesSilenciosa() async {
    try {
      final miId = GestorSesionGlobal().miIdUsuario;
      final cursorLimpio = CursorTuplaV5(); // 🛡️ Cursor inmaculado para traer solo Página 1
      
      List<Map<String, dynamic>> rawPros = await ServicioFeedSupabase.obtenerProfesionalesPaginadosV5(
        ciudad: provinciaFiltro,
        localidad: localidadFiltro,
        categoria: categoriaFiltro, 
        keyword: palabraClave,      
        cursorEsCiudad: cursorLimpio.esCiudad,
        cursorEsLocalidad: cursorLimpio.esLocalidad,
        cursorRank: cursorLimpio.rank,
        cursorScore: cursorLimpio.score,
        cursorEstrellas: cursorLimpio.estrellas,
        cursorActividad: cursorLimpio.actividad,
        cursorRotacion: cursorLimpio.rotacion,
        cursorId: cursorLimpio.id,
        limit: 20, 
        miId: miId,
      );

      if (rawPros.isEmpty) return [];

      // Procesamiento asíncrono para no bloquear el Hilo Principal (UI Thread)
      return await compute(_mapearPerfilesBackground, rawPros);
    } catch (e) {
      debugPrint('SWR-Titan: Error Extracción SWR Silenciosa (Profesionales): $e');
      return [];
    }
  }
}