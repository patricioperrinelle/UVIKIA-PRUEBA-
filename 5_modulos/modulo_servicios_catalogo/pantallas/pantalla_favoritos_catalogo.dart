// lib/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_favoritos_catalogo.dart

import 'package:flutter/material.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';

import '../controladores/controlador_catalogo_cliente.dart';
import '../componentes/tarjeta_servicio_catalogo.dart';
import 'pantalla_detalle_servicio.dart';
import '../../modulo_explorar_feed/componentes/estado_vacio_feed.dart';

class PantallaFavoritosCatalogo extends StatelessWidget {
  final ControladorCatalogoCliente controlador;

  const PantallaFavoritosCatalogo({Key? key, required this.controlador}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Servicios Guardados', style: TextStyle(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: esOscuro ? Colors.black : Colors.grey.shade50,
      ),
      body: SafeArea(
        bottom: true,
        child: ListenableBuilder(
          listenable: controlador,
          builder: (context, child) {
            // 🛡️ LECTURA ESTRICTA DE RAM DEDICADA
            final listaGuardados = controlador.serviciosGuardadosCompletos;

            if (listaGuardados.isEmpty) {
              return const EstadoVacioFeed(
                icono: Icons.bookmark_border_rounded,
                titulo: 'Sin servicios guardados',
                subtitulo: 'No tienes servicios en tu lista de favoritos.',
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: listaGuardados.length,
              itemBuilder: (context, index) {
                final servicio = listaGuardados[index];
                const bool esFavorito = true; // En esta pantalla siempre es true

                return TarjetaServicioCatalogo(
                  servicio: servicio,
                  esFavorito: esFavorito,
                  onTapFavorito: () => controlador.toggleFavoritoGlobal(context, servicio), // 🚀 V5.9
                  onTapVerServicio: () {
                    GestorSesionGlobal.requerirAuth(() {
                      controlador.abrirDetalleServicio(servicio);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PantallaDetalleServicio(controlador: controlador),
                      ));
                    });
                  },
                );
              },
            );
          }
        ),
      ),
    );
  }
}