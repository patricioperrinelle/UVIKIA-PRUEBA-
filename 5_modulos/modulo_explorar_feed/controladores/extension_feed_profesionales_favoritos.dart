// lib/5_modulos/modulo_explorar_feed/controladores/extension_feed_profesionales_favoritos.dart
part of 'controlador_feed_profesionales.dart';

extension ExtensionFeedProfesionalesFavoritos on ControladorFeedProfesionales {
  
  // 🚀 OPTIMISTIC UI PURO Y DESACOPLADO V5.9
  void toggleFavoritoGlobal(BuildContext context, ModeloPerfil perfil) {
    GestorSesionGlobal.requerirAuth(() async {
      final miId = context.read<GestorSesionGlobal>().miIdUsuario;
      if (miId.isEmpty) return;

      final bool isYaFavorito = favoritosIds.contains(perfil.id);
      
      // 🛡️ Mutación en RAM instantánea (0ms)
      if (isYaFavorito) {
        favoritosIds.remove(perfil.id);
        profesionalesGuardadosCompletos.removeWhere((p) => p.id == perfil.id);
      } else {
        favoritosIds.add(perfil.id);
        profesionalesGuardadosCompletos.insert(0, perfil); // Añade al inicio
      }
      
      _guardarCacheFavoritosLocal();
      notifyListeners();
      
      // 🛡️ Sincronización en Red con Fallback (Rollback Visual)
      try {
        await ServicioFeedSupabase.toggleFavorito(miId, perfil.id, isYaFavorito);
      } catch (e) {
        debugPrint('Error de red al guardar profesional. Ejecutando Rollback Visual...');
        if (isYaFavorito) {
          favoritosIds.add(perfil.id);
          profesionalesGuardadosCompletos.insert(0, perfil);
        } else {
          favoritosIds.remove(perfil.id);
          profesionalesGuardadosCompletos.removeWhere((p) => p.id == perfil.id);
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
      
      final perfilesStr = prefs.getString('cache_profesionales_favs');
      if (perfilesStr != null) {
        profesionalesGuardadosCompletos = (jsonDecode(perfilesStr) as List)
            .map((e) => ModeloPerfil.fromJson(e)).toList();
      }

      final idsStr = prefs.getStringList('feed_profesionales_favs_ids');
      if (idsStr != null) favoritosIds = idsStr.toSet();

    } catch (e) {
      debugPrint('Error cargando caché de favoritos pros: $e');
    }
  }

  // 🚀 ESCRITURA SWR INDEPENDIENTE
  Future<void> _guardarCacheFavoritosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_profesionales_favs', jsonEncode(profesionalesGuardadosCompletos.map((e) => e.toJson()).toList()));
      await prefs.setStringList('feed_profesionales_favs_ids', favoritosIds.toList());
    } catch (e) {
      debugPrint('Error guardando caché de favoritos pros: $e');
    }
  }

  // 🚀 MOTOR PURGADOR (Destrucción de Tarjetas Zombis)
  void purgarFantasmasFavoritos(Set<String>? idsVigentes) {
    if (idsVigentes == null) return; // 🛡️ Protección de red

    bool huboCambios = false;
    
    final antes = profesionalesGuardadosCompletos.length;
    profesionalesGuardadosCompletos.removeWhere((p) => !idsVigentes.contains(p.id));
    
    if (profesionalesGuardadosCompletos.length != antes) huboCambios = true;

    // Actualizamos el Set maestro de RAM si hubo cambios o desincronización
    if (favoritosIds.length != idsVigentes.length || huboCambios) {
      favoritosIds = idsVigentes;
      _guardarCacheFavoritosLocal();
      notifyListeners();
    }
  }

  // 🚀 AUTO-SANACIÓN AL VOLO: Clona tarjetas si hay desincronización de memoria
  void sincronizarObjetosFavoritosDesdeFeed(List<ModeloPerfil> feedActual) {
    bool huboCambios = false;
    
    for (var perfil in feedActual) {
      if (favoritosIds.contains(perfil.id)) {
        final existe = profesionalesGuardadosCompletos.any((p) => p.id == perfil.id);
        if (!existe) {
          profesionalesGuardadosCompletos.insert(0, perfil);
          huboCambios = true;
        }
      }
    }
    
    if (huboCambios) {
      _guardarCacheFavoritosLocal();
    }
  }
}