// lib/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_explorar_catalogo.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 

import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/busqueda/modal_busqueda_inmersiva.dart'; 
import '../../../4_componentes_globales/busqueda/cabecera_filtros_activos.dart'; 
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

import '../../modulo_explorar_feed/componentes/estado_vacio_feed.dart';

import '../controladores/controlador_catalogo_cliente.dart';
import '../componentes/tarjeta_servicio_catalogo.dart';
import 'pantalla_detalle_servicio.dart';
import 'pantalla_favoritos_catalogo.dart'; 

class PantallaExplorarCatalogo extends StatefulWidget {
  const PantallaExplorarCatalogo({Key? key}) : super(key: key);

  @override
  State<PantallaExplorarCatalogo> createState() => _PantallaExplorarCatalogoState();
}

class _PantallaExplorarCatalogoState extends State<PantallaExplorarCatalogo> {
  // 🚀 V5.9.3: CONEXIÓN AL SINGLETON INMORTAL
  final ControladorCatalogoCliente _controlador = ControladorCatalogoCliente.instancia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controlador.cargarCatalogoPublico(context);
    });
  }

  @override
  void dispose() {
    // 🛡️ V5.9.3: PROHIBIDO MATAR AL CEREBRO. 
    // Se eliminó _controlador.dispose(); protegiendo el Scroll y la RAM.
    super.dispose();
  }

  Future<void> _abrirFiltrosInmersivos() async {
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
          builder: (_) => PantallaFavoritosCatalogo(controlador: _controlador),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: esOscuro ? Colors.black : Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface), 
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Catálogo de Servicios', style: TextStyle(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, fontSize: 18)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: tema.colorScheme.onSurface),
            onPressed: _abrirFiltrosInmersivos,
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border_rounded, color: tema.colorScheme.onSurface),
            onPressed: _abrirFavoritosCongelandoFeed, 
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: _controlador,
            builder: (context, child) {
              final listaFiltrada = _controlador.listaServiciosFiltrada;

              return Expanded(
                child: Column(
                  children: [
                    if (_controlador.isLoadingCatalogo && listaFiltrada.isNotEmpty)
                      const LinearProgressIndicator(color: ColoresApp.primarioVerde, minHeight: 3),

                    CabeceraFiltrosActivos(
                      palabraClave: _controlador.palabraClave,
                      provincia: _controlador.provinciaFiltro,
                      localidad: _controlador.localidadFiltro,
                      categoria: _controlador.categoriaFiltro,
                      onTapAbrirModal: _abrirFiltrosInmersivos,
                      onLimpiarPalabraClave: _controlador.limpiarPalabraClave,
                      onLimpiarProvincia: _controlador.limpiarProvincia,
                      onLimpiarLocalidad: _controlador.limpiarLocalidad,
                      onLimpiarCategoria: _controlador.limpiarCategoria,
                    ),

                    // Banner informativo
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: esOscuro ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: esOscuro ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: tema.colorScheme.onSurface.withOpacity(0.6), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los servicios que compres aparecerán directamente en tu Agenda.',
                              style: TextStyle(
                                fontSize: 13,
                                color: tema.colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        color: ColoresApp.primarioVerde,
                        backgroundColor: tema.colorScheme.surface,
                        onRefresh: () => _controlador.cargarCatalogoPublico(context, isRefreshManual: true),
                        child: _controlador.isLoadingCatalogo && listaFiltrada.isEmpty
                            ? const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde))
                            : listaFiltrada.isEmpty
                                ? EstadoVacioFeed(
                                    icono: _controlador.palabraClave.isEmpty ? Icons.handyman_rounded : Icons.search_off_rounded,
                                    titulo: _controlador.palabraClave.isEmpty ? 'No hay servicios' : 'Sin resultados para la búsqueda',
                                    subtitulo: _controlador.provinciaFiltro.isNotEmpty 
                                          ? 'Intenta borrar la zona geográfica en los filtros' 
                                          : 'Intenta modificar tus filtros en la Lupa',
                                  )
                                : ListView.builder(
                                    controller: _controlador.scrollControllerPaginacion,
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: listaFiltrada.length + (_controlador.isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      
                                      if (index == listaFiltrada.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 32.0),
                                          child: Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde)),
                                        );
                                      }

                                      final servicio = listaFiltrada[index];
                                      final esFavorito = _controlador.misFavoritosIds.contains(servicio.id);

                                      return TarjetaServicioCatalogo(
                                        servicio: servicio,
                                        esFavorito: esFavorito,
                                        onTapFavorito: () => _controlador.toggleFavoritoGlobal(context, servicio), 
                                        onTapVerServicio: () {
                                          GestorSesionGlobal.requerirAuth(() {
                                            _controlador.abrirDetalleServicio(servicio);
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => PantallaDetalleServicio(controlador: _controlador),
                                            )).then((_) => _controlador.sincronizarInteraccionesLocales(context));
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
            },
          ),
        ],
      ),
    );
  }
}