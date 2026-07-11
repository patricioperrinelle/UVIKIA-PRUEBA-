// lib/5_modulos/modulo_explorar_feed/controladores/extension_feed_favoritos.dart
part of 'controlador_feed_publicaciones.dart';

extension ExtensionFeedFavoritos on ControladorFeedPublicaciones {
  
  // 🚀 OPTIMISTIC UI PURO Y DESACOPLADO V5.8.1
  void toggleTrabajoGuardadoGlobal(BuildContext context, TrabajoContratable trabajo, bool esJornada) {
    GestorSesionGlobal.requerirAuth(() async {
      final miId = context.read<GestorSesionGlobal>().miIdUsuario;
      if (miId.isEmpty) return;

      final bool isYaGuardado = misTrabajosGuardadosIds.contains(trabajo.id);
      
      // 🛡️ Mutación en RAM instantánea (0ms)
      if (isYaGuardado) {
        misTrabajosGuardadosIds.remove(trabajo.id);
        if (esJornada) {
          jornadasGuardadasCompletas.removeWhere((t) => t.id == trabajo.id);
        } else {
          oficiosGuardadosCompletos.removeWhere((t) => t.id == trabajo.id);
        }
      } else {
        misTrabajosGuardadosIds.add(trabajo.id);
        if (esJornada) {
          jornadasGuardadasCompletas.insert(0, trabajo as ModeloJornada); // Añade al inicio (Stack reciente)
        } else {
          oficiosGuardadosCompletos.insert(0, trabajo as ModeloOficioTrabajo); // Añade al inicio
        }
      }
      
      _guardarCacheFavoritosLocal();
      notifyListeners();
      
      // 🛡️ Sincronización en Red con Fallback (Rollback)
      try {
        await ServicioFeedSupabase.toggleTrabajoGuardado(miId, trabajo.id, isYaGuardado);
      } catch (e) {
        debugPrint('Error de red al guardar trabajo. Ejecutando Rollback Visual...');
        if (isYaGuardado) {
          misTrabajosGuardadosIds.add(trabajo.id);
          if (esJornada) jornadasGuardadasCompletas.insert(0, trabajo as ModeloJornada);
          else oficiosGuardadosCompletos.insert(0, trabajo as ModeloOficioTrabajo);
        } else {
          misTrabajosGuardadosIds.remove(trabajo.id);
          if (esJornada) jornadasGuardadasCompletas.removeWhere((t) => t.id == trabajo.id);
          else oficiosGuardadosCompletos.removeWhere((t) => t.id == trabajo.id);
        }
        _guardarCacheFavoritosLocal();
        notifyListeners();
      }
    });
  }

  // 🚀 LECTURA SWR INDEPENDIENTE
  Future<void> _cargarCacheFavoritosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final oficiosStr = prefs.getString('cache_oficios_favs');
      if (oficiosStr != null) {
        oficiosGuardadosCompletos = (jsonDecode(oficiosStr) as List)
            .map((e) => ModeloOficioTrabajo.fromJson(e)).toList();
      }

      final jornadasStr = prefs.getString('cache_jornadas_favs');
      if (jornadasStr != null) {
        jornadasGuardadasCompletas = (jsonDecode(jornadasStr) as List)
            .map((e) => ModeloJornada.fromJson(e)).toList();
      }

      final idsStr = prefs.getStringList('feed_trabajos_guardados_ids');
      if (idsStr != null) misTrabajosGuardadosIds = idsStr.toSet();

    } catch (e) {
      debugPrint('Error cargando caché de favoritos: $e');
    }
  }

  // 🚀 ESCRITURA SWR INDEPENDIENTE
  Future<void> _guardarCacheFavoritosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_oficios_favs', jsonEncode(oficiosGuardadosCompletos.map((e) => e.toJson()).toList()));
      await prefs.setString('cache_jornadas_favs', jsonEncode(jornadasGuardadasCompletas.map((e) => e.toJson()).toList()));
      await prefs.setStringList('feed_trabajos_guardados_ids', misTrabajosGuardadosIds.toList());
    } catch (e) {
      debugPrint('Error guardando caché de favoritos: $e');
    }
  }

  // 🚀 MOTOR PURGADOR CON AUTO-SANACIÓN Y ANTI-WIPEOUT
  void purgarFantasmasFavoritos(Set<String>? idsVigentes) {
    if (idsVigentes == null) return; // 🛡️ Protección de red: Se omite si hubo error de internet

    bool huboCambios = false;
    
    // Filtramos oficios
    final oficiosAntes = oficiosGuardadosCompletos.length;
    oficiosGuardadosCompletos.removeWhere((t) => !idsVigentes.contains(t.id));
    if (oficiosGuardadosCompletos.length != oficiosAntes) huboCambios = true;

    // Filtramos jornadas
    final jornadasAntes = jornadasGuardadasCompletas.length;
    jornadasGuardadasCompletas.removeWhere((t) => !idsVigentes.contains(t.id));
    if (jornadasGuardadasCompletas.length != jornadasAntes) huboCambios = true;

    // Actualizamos el Set maestro de RAM
    if (misTrabajosGuardadosIds.length != idsVigentes.length || huboCambios) {
      misTrabajosGuardadosIds = idsVigentes;
      _guardarCacheFavoritosLocal();
      notifyListeners();
    }
  }

  // 🚀 AUTO-SANACIÓN AL VOLO: Clona tarjetas si hay desincronización de memoria
  void sincronizarObjetosFavoritosDesdeFeed(List<dynamic> feedActual, bool esJornada) {
    bool huboCambios = false;
    
    for (var trabajo in feedActual) {
      if (misTrabajosGuardadosIds.contains(trabajo.id)) {
        if (esJornada) {
          final existe = jornadasGuardadasCompletas.any((t) => t.id == trabajo.id);
          if (!existe) {
            jornadasGuardadasCompletas.insert(0, trabajo as ModeloJornada);
            huboCambios = true;
          }
        } else {
          final existe = oficiosGuardadosCompletos.any((t) => t.id == trabajo.id);
          if (!existe) {
            oficiosGuardadosCompletos.insert(0, trabajo as ModeloOficioTrabajo);
            huboCambios = true;
          }
        }
      }
    }
    
    if (huboCambios) {
      _guardarCacheFavoritosLocal();
    }
  }
}