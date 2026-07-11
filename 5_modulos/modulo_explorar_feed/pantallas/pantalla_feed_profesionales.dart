// lib/5_modulos/modulo_explorar_feed/pantallas/pantalla_feed_profesionales.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../2_tema/colores_app.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart'; 
import '../../../4_componentes_globales/busqueda/modal_busqueda_inmersiva.dart'; 
import '../../../4_componentes_globales/busqueda/cabecera_filtros_activos.dart';

import '../controladores/controlador_feed_profesionales.dart';
import '../componentes/tarjeta_profesional_directorio.dart';
import '../componentes/estado_vacio_feed.dart';

import '../../modulo_perfil_usuario/pantallas/pantalla_perfil_publico.dart';
import 'pantalla_favoritos_profesionales.dart'; 

class PantallaFeedProfesionales extends StatefulWidget {
  const PantallaFeedProfesionales({Key? key}) : super(key: key);

  @override
  State<PantallaFeedProfesionales> createState() => _PantallaFeedProfesionalesState();
}

class _PantallaFeedProfesionalesState extends State<PantallaFeedProfesionales> {
  // 🚀 V5.9.3: CONEXIÓN AL SINGLETON INMORTAL
  final ControladorFeedProfesionales _controlador = ControladorFeedProfesionales.instancia;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && arg.isNotEmpty && arg != 'Otros oficios') {
        _controlador.palabraClave = arg; 
      }
      _isInit = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controlador.cargarDirectorio(context);
      });
    }
  }

  @override
  void dispose() {
    // 🛡️ V5.9.3: PROHIBIDO MATAR AL CEREBRO. 
    // Se eliminó _controlador.dispose(); protegiendo el Scroll y la RAM.
    super.dispose();
  }

  void _abrirPerfil(Map<String, dynamic> proData) {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PantallaPerfilPublico(),
        settings: RouteSettings(arguments: proData),
      )
    ).then((_) => _controlador.sincronizarInteraccionesLocales(context));
  }

  Future<void> _abrirFiltros() async {
    final paquete = await ModalBusquedaInmersiva.mostrar(
      context: context,
      palabraClaveInicial: _controlador.palabraClave,
      provinciaInicial: _controlador.provinciaFiltro,
      localidadInicial: _controlador.localidadFiltro,
      categoriaInicial: _controlador.categoriaFiltro,
    );

    if (paquete != null) {
      _controlador.aplicarPaqueteFiltros(paquete);
    }
  }

  void _abrirFavoritosCongelandoFeed() {
    GestorSesionGlobal.requerirAuth(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaFavoritosProfesionales(controlador: _controlador),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor, 
      appBar: AppBar(
        title: Text('Directorio Profesional', style: TextStyle(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: tema.colorScheme.onSurface),
            onPressed: _abrirFiltros,
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border_rounded, color: tema.colorScheme.onSurface),
            onPressed: _abrirFavoritosCongelandoFeed,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: true,
          child: Column(
            children: <Widget>[
              
              ListenableBuilder(
                listenable: _controlador,
                builder: (context, child) {
                  final lista = _controlador.profesionalesFiltrados;

                  return Expanded(
                    child: Column(
                      children: [
                        if (_controlador.isLoading && lista.isNotEmpty)
                          const LinearProgressIndicator(color: ColoresApp.primarioVerde, minHeight: 3),

                        CabeceraFiltrosActivos(
                          palabraClave: _controlador.palabraClave,
                          provincia: _controlador.provinciaFiltro,
                          localidad: _controlador.localidadFiltro,
                          categoria: _controlador.categoriaFiltro,
                          onTapAbrirModal: _abrirFiltros,
                          onLimpiarPalabraClave: _controlador.limpiarPalabraClave,
                          onLimpiarProvincia: _controlador.limpiarProvincia,
                          onLimpiarLocalidad: _controlador.limpiarLocalidad,
                          onLimpiarCategoria: _controlador.limpiarCategoria,
                        ),

                        Expanded(
                          child: RefreshIndicator(
                            color: ColoresApp.primarioVerde,
                            backgroundColor: tema.colorScheme.surface,
                            onRefresh: () => _controlador.cargarDirectorio(context, isRefreshManual: true),
                            child: _controlador.isLoading && lista.isEmpty
                              ? const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde))
                              : lista.isEmpty
                                ? EstadoVacioFeed(
                                    icono: _controlador.palabraClave.isEmpty ? Icons.people_outline_rounded : Icons.search_off_rounded,
                                    titulo: _controlador.palabraClave.isEmpty ? 'No hay profesionales en tu zona' : 'Sin resultados para la búsqueda',
                                    subtitulo: _controlador.provinciaFiltro.isNotEmpty 
                                          ? 'Intenta borrar la zona geográfica en los filtros' 
                                          : 'Intenta modificar tus filtros en la Lupa',
                                  )
                                : ListView.builder(
                                    controller: _controlador.scrollControllerPaginacion,
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 24),
                                    itemCount: lista.length + (_controlador.isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      
                                      if (index == lista.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 32.0),
                                          child: Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde)),
                                        );
                                      }

                                      final perfil = lista[index];
                                      final bool isFavorite = _controlador.favoritosIds.contains(perfil.id);

                                      return TarjetaProfesionalDirectorio(
                                        perfil: perfil,
                                        isFavorite: isFavorite,
                                        onFavoriteToggle: () => _controlador.toggleFavoritoGlobal(context, perfil),
                                        onTapCard: () {
                                          final pro = perfil.perfilProfesional;
                                          _abrirPerfil({
                                            'id': perfil.id,
                                            'name': perfil.apodo,
                                            'image': perfil.fotoUrl,
                                            'tags': pro?.tagsOficios ?? List<String>.empty(),
                                            'rating': pro?.ratingProfesional ?? 0.0,
                                            'reviews': pro?.cantidadResenasProfesional ?? 0,
                                            'biography': pro?.bio ?? '',
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}