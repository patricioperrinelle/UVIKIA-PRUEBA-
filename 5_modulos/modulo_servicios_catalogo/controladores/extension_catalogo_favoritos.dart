// lib/5_modulos/modulo_servicios_catalogo/controladores/extension_catalogo_favoritos.dart
part of 'controlador_catalogo_cliente.dart';

extension ExtensionCatalogoFavoritos on ControladorCatalogoCliente {
  
  // 🚀 OPTIMISTIC UI PURO V5.9
  void toggleFavoritoGlobal(BuildContext context, ModeloServicioCatalogo servicio) {
    GestorSesionGlobal.requerirAuth(() async {
      final miId = context.read<GestorSesionGlobal>().miIdUsuario;
      if (miId.isEmpty) return; 

      final bool isYaFavorito = misFavoritosIds.contains(servicio.id);
      
      // 🛡️ Mutación en RAM instantánea (0ms)
      if (isYaFavorito) {
        misFavoritosIds.remove(servicio.id);
        serviciosGuardadosCompletos.removeWhere((s) => s.id == servicio.id);
      } else {
        misFavoritosIds.add(servicio.id);
        serviciosGuardadosCompletos.insert(0, servicio); // Añade al inicio
      }
      
      _guardarCacheFavoritosLocal();
      actualizarUI();

      // 🛡️ Sincronización en Red con Fallback (Rollback Visual)
      try {
        await ServicioCatalogoSupabase.toggleFavorito(miId, servicio.id, isYaFavorito);
      } catch (e) {
        debugPrint("Data-Miser: Fallo al guardar en DB. Revertiendo.");
        if (isYaFavorito) {
          misFavoritosIds.add(servicio.id);
          serviciosGuardadosCompletos.insert(0, servicio);
        } else {
          misFavoritosIds.remove(servicio.id);
          serviciosGuardadosCompletos.removeWhere((s) => s.id == servicio.id);
        }
        _guardarCacheFavoritosLocal();
        actualizarUI();
      }
    });
  }

  // 🚀 LECTURA SWR INDEPENDIENTE
  Future<void> _cargarCacheFavoritosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final serviciosStr = prefs.getString('cache_catalogo_favs');
      if (serviciosStr != null) {
        serviciosGuardadosCompletos = (jsonDecode(serviciosStr) as List)
            .map((e) => ModeloServicioCatalogo.fromJson(e)).toList();
      }

      final idsStr = prefs.getStringList('feed_catalogo_favs_ids');
      if (idsStr != null) misFavoritosIds = idsStr.toSet();

    } catch (e) {
      debugPrint('Error cargando caché de favoritos catálogo: $e');
    }
  }

  // 🚀 ESCRITURA SWR INDEPENDIENTE
  Future<void> _guardarCacheFavoritosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_catalogo_favs', jsonEncode(serviciosGuardadosCompletos.map((e) => e.toJson()).toList()));
      await prefs.setStringList('feed_catalogo_favs_ids', misFavoritosIds.toList());
    } catch (e) {
      debugPrint('Error guardando caché de favoritos catálogo: $e');
    }
  }

  // 🚀 MOTOR PURGADOR (Destrucción de Tarjetas Zombis + Escudo Offline)
  void purgarFantasmasFavoritos(Set<String>? idsVigentes) {
    if (idsVigentes == null) return; // 🛡️ BARRERA ANTI-WIPEOUT: Si no hay internet, no borramos la memoria.

    bool huboCambios = false;
    
    final antes = serviciosGuardadosCompletos.length;
    serviciosGuardadosCompletos.removeWhere((s) => !idsVigentes.contains(s.id));
    
    if (serviciosGuardadosCompletos.length != antes) huboCambios = true;

    // Actualizamos el Set maestro de RAM si hubo cambios o desincronización
    if (misFavoritosIds.length != idsVigentes.length || huboCambios) {
      misFavoritosIds = idsVigentes;
      _guardarCacheFavoritosLocal();
      actualizarUI();
    }
  }

  // 🚀 AUTO-SANACIÓN AL VOLO
  void sincronizarObjetosFavoritosDesdeFeed(List<ModeloServicioCatalogo> feedActual) {
    bool huboCambios = false;
    
    for (var servicio in feedActual) {
      if (misFavoritosIds.contains(servicio.id)) {
        final existe = serviciosGuardadosCompletos.any((s) => s.id == servicio.id);
        if (!existe) {
          serviciosGuardadosCompletos.insert(0, servicio);
          huboCambios = true;
        }
      }
    }
    
    if (huboCambios) {
      _guardarCacheFavoritosLocal();
    }
  }
}