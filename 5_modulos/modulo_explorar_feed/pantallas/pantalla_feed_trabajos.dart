// lib/5_modulos/modulo_explorar_feed/pantallas/pantalla_feed_trabajos.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../2_tema/colores_app.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../4_componentes_globales/busqueda/modal_busqueda_inmersiva.dart'; 
import '../../../4_componentes_globales/busqueda/cabecera_filtros_activos.dart';

import '../controladores/controlador_feed_publicaciones.dart';
import '../componentes/tarjeta_trabajo_feed.dart';
import '../componentes/estado_vacio_feed.dart';

import '../../modulo_negociacion_oficios/pantallas/pantalla_negociacion_oficio.dart';
import 'pantalla_favoritos_trabajos.dart'; 
import '../../../3_modelos/modelo_oficio_trabajo.dart';

class PantallaFeedTrabajos extends StatefulWidget {
  const PantallaFeedTrabajos({Key? key}) : super(key: key);

  @override
  State<PantallaFeedTrabajos> createState() => _PantallaFeedTrabajosState();
}

class _PantallaFeedTrabajosState extends State<PantallaFeedTrabajos> {
  // 🚀 V5.9.3: CONEXIÓN AL SINGLETON INMORTAL
  final ControladorFeedPublicaciones _controlador = ControladorFeedPublicaciones.instancia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controlador.cargarFeeds(context);
    });
  }

  @override
  void dispose() {
    // 🛡️ V5.9.3: PROHIBIDO MATAR AL CEREBRO. 
    // Se eliminó _controlador.dispose(); para proteger el ScrollController y la RAM.
    super.dispose();
  }

  void _abrirTrabajoONotificar(ModeloOficioTrabajo trabajoTipado, bool isDueno, bool esModoCliente) {
    if (isDueno || !esModoCliente) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaNegociacionOficio(jobData: trabajoTipado.toJson(), esHistorial: false),
        ),
      ).then((resultado) {
        if (resultado == true) {
          _controlador.eliminarTrabajoDeRAM(trabajoTipado.id);
        } else {
          _controlador.sincronizarInteraccionesLocales(context);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes cambiar a Modo Profesional para enviar presupuestos.', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
          backgroundColor: ColoresApp.advertenciaAmarillo
        )
      );
    }
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
          builder: (_) => PantallaFavoritosTrabajos(controlador: _controlador),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorSesionGlobal>();
    final String miId = gestor.miIdUsuario;
    final bool esModoCliente = gestor.modoActual == ModoUsuario.cliente;
    final tema = Theme.of(context); 

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor, 
      appBar: AppBar(
        title: Text('Trabajos a Presupuestar', style: TextStyle(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, fontSize: 18)), 
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
      body: SafeArea(
        bottom: true,
        child: Column(
          children:[
            if (esModoCliente)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: ColoresApp.infoAzul.withOpacity(0.15), 
                  border: Border(bottom: BorderSide(color: tema.dividerColor.withOpacity(0.1)))
                ),
                child: Row(
                  children:[
                    const Icon(Icons.info_outline_rounded, color: ColoresApp.infoAzul, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Modo Cliente: Cambia a tu perfil PRO para ofertar.', 
                      style: TextStyle(color: ColoresApp.infoAzul.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

            ListenableBuilder(
              listenable: _controlador,
              builder: (context, child) {
                final lista = _controlador.oficios; 
                
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
                          onRefresh: () => _controlador.cargarFeeds(context, isRefreshManual: true),
                          child: _controlador.isLoading && lista.isEmpty
                              ? const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde))
                              : lista.isEmpty
                                  ? EstadoVacioFeed(
                                      icono: Icons.handyman_rounded, 
                                      titulo: 'No hay trabajos en tu especialidad', 
                                      subtitulo: _controlador.provinciaFiltro.isNotEmpty 
                                          ? 'Intenta borrar la zona geográfica en los filtros' 
                                          : 'Intenta modificar tus filtros en la Lupa'
                                    )
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: GridView.builder(
                                            controller: _controlador.scrollOficios, 
                                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2, 
                                              childAspectRatio: 0.58, 
                                              crossAxisSpacing: 8, 
                                              mainAxisSpacing: 8
                                            ),
                                            itemCount: lista.length,
                                            itemBuilder: (context, index) {
                                              final trabajo = lista[index];
                                              final bool yaOfertado = _controlador.misPostulacionesIds.contains(trabajo.id);
                                              final bool isDueno = trabajo.ownerId == miId;
                                              final bool esGuardado = _controlador.misTrabajosGuardadosIds.contains(trabajo.id);

                                              return TarjetaTrabajoFeed(
                                                trabajo: trabajo, 
                                                yaOfertado: yaOfertado, 
                                                isDueno: isDueno,
                                                esModoCliente: esModoCliente, 
                                                esGuardado: esGuardado, 
                                                onTapGuardar: () => _controlador.toggleTrabajoGuardadoGlobal(context, trabajo, false),
                                                onTap: () => _abrirTrabajoONotificar(trabajo as ModeloOficioTrabajo, isDueno, esModoCliente),
                                              );
                                            },
                                          ),
                                        ),
                                        if (_controlador.isLoadingMoreOficios)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 16.0),
                                            child: Center(
                                              child: CircularProgressIndicator(color: ColoresApp.primarioVerde),
                                            ),
                                          ),
                                      ],
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
    );
  }
}