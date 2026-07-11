// lib/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_mis_servicios_pro.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚨 CACHÉ VISUAL AÑADIDO
import '../../../2_tema/colores_app.dart';
import '../controladores/controlador_mis_servicios_pro.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../componentes/tarjeta_servicio_catalogo.dart';
import 'pantalla_creador_servicio.dart';

class PantallaMisServiciosPro extends StatefulWidget {
  const PantallaMisServiciosPro({Key? key}) : super(key: key);

  @override
  State<PantallaMisServiciosPro> createState() => _PantallaMisServiciosProState();
}

class _PantallaMisServiciosProState extends State<PantallaMisServiciosPro> {
  final ControladorMisServiciosPro _controlador = ControladorMisServiciosPro();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Servicios', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: ColoresApp.terciarioMorado,
            labelColor: ColoresApp.terciarioMorado,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Publicados'),
              Tab(text: 'Pausados'),
              Tab(text: 'Borradores'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: ColoresApp.terciarioMorado,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Crear Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () async {
            final resultado = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const PantallaCreadorServicio())
            );
            if (resultado == true) _controlador.cargarMisServicios();
          },
        ),
        body: ListenableBuilder(
          listenable: _controlador,
          builder: (context, _) {
            if (_controlador.isCargando) {
              return const Center(child: CircularProgressIndicator(color: ColoresApp.terciarioMorado));
            }

            if (_controlador.errorCarga != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: ColoresApp.errorRojo, size: 48),
                      const SizedBox(height: 16),
                      const Text('No pudimos cargar tus servicios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Error: ${_controlador.errorCarga}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }

            return TabBarView(
              children: [
                _ConstruirLista(_controlador.serviciosPublicados, _controlador, esOscuro, tema),
                _ConstruirLista(_controlador.serviciosPausados, _controlador, esOscuro, tema),
                _ConstruirLista(_controlador.serviciosBorradores, _controlador, esOscuro, tema),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConstruirLista extends StatelessWidget {
  final List<ModeloServicioCatalogo> lista;
  final ControladorMisServiciosPro controlador;
  final bool esOscuro;
  final ThemeData tema;

  const _ConstruirLista(this.lista, this.controlador, this.esOscuro, this.tema);

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return const Center(
        child: Text('No tienes servicios en esta sección.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final servicio = lista[index];

        return TarjetaServicioCatalogo(
          servicio: servicio,
          esVistaPro: true,
          onTapVerServicio: () async {
            final resultado = await Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => PantallaCreadorServicio(servicioAEditar: servicio, modoLectura: true)
              )
            );
            if (resultado == true) controlador.cargarMisServicios();
          },
          onTapEliminar: () => _confirmarEliminacion(context, servicio),
          onTapPausar: () => _confirmarPausa(context, servicio),
          onTapReanudar: () => _confirmarReanudacion(context, servicio),
        );
      },
    );
  }

  void _confirmarPausa(BuildContext context, ModeloServicioCatalogo servicio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Pausar servicio?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Al pausar "${servicio.titulo}", dejará de aparecer en el catálogo y nadie más podrá comprarlo. Las ventas que ya realizaste no se verán afectadas.\n\nPodrás reanudarlo cuando quieras.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controlador.pausarServicio(servicio.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Servicio pausado correctamente.'))
              );
            },
            child: const Text('Pausar', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmarReanudacion(BuildContext context, ModeloServicioCatalogo servicio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Activar servicio?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Al activar "${servicio.titulo}", volverá a aparecer en el catálogo y los clientes podrán comprarlo nuevamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controlador.reanudarServicio(servicio.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Servicio activado. Ahora es visible en el catálogo.'))
              );
            },
            child: const Text('Activar', style: TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, ModeloServicioCatalogo servicio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar servicio?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar "${servicio.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controlador.eliminarServicio(servicio.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Servicio eliminado correctamente'))
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}