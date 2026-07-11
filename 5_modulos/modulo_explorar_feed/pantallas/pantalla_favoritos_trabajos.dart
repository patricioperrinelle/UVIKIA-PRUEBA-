// lib/5_modulos/modulo_explorar_feed/pantallas/pantalla_favoritos_trabajos.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../2_tema/colores_app.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

import '../controladores/controlador_feed_publicaciones.dart';
import '../componentes/tarjeta_trabajo_feed.dart';
import '../componentes/estado_vacio_feed.dart';

import '../../modulo_negociacion_oficios/pantallas/pantalla_negociacion_oficio.dart';
import '../../../3_modelos/modelo_oficio_trabajo.dart';

class PantallaFavoritosTrabajos extends StatelessWidget {
  final ControladorFeedPublicaciones controlador;

  const PantallaFavoritosTrabajos({Key? key, required this.controlador}) : super(key: key);

  void _abrirTrabajoONotificar(BuildContext context, ModeloOficioTrabajo trabajoTipado, bool isDueno, bool esModoCliente) {
    if (isDueno || !esModoCliente) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaNegociacionOficio(jobData: trabajoTipado.toJson(), esHistorial: false),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorSesionGlobal>();
    final String miId = gestor.miIdUsuario;
    final bool esModoCliente = gestor.modoActual == ModoUsuario.cliente;
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Trabajos Guardados', style: TextStyle(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: tema.scaffoldBackgroundColor,
      ),
      body: SafeArea(
        bottom: true,
        child: ListenableBuilder(
          listenable: controlador,
          builder: (context, child) {
            // 🛡️ LECTURA ESTRICTA DE RAM DEDICADA
            final listaGuardados = controlador.oficiosGuardadosCompletos;

            if (listaGuardados.isEmpty) {
              return const EstadoVacioFeed(
                icono: Icons.bookmark_border_rounded,
                titulo: 'Sin trabajos guardados',
                subtitulo: 'No tienes trabajos en tu lista de favoritos.',
              );
            }

            return GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.58, 
                crossAxisSpacing: 8, 
                mainAxisSpacing: 8
              ),
              itemCount: listaGuardados.length,
              itemBuilder: (context, index) {
                final trabajo = listaGuardados[index];
                final bool yaOfertado = controlador.misPostulacionesIds.contains(trabajo.id);
                final bool isDueno = trabajo.ownerId == miId;

                return TarjetaTrabajoFeed(
                  trabajo: trabajo, 
                  yaOfertado: yaOfertado, 
                  isDueno: isDueno,
                  esModoCliente: esModoCliente, 
                  esGuardado: true, // 🛡️ Renderizado ciego: Siempre true en esta pantalla
                  onTapGuardar: () => controlador.toggleTrabajoGuardadoGlobal(context, trabajo, false),
                  onTap: () => _abrirTrabajoONotificar(context, trabajo as ModeloOficioTrabajo, isDueno, esModoCliente),
                );
              },
            );
          }
        ),
      ),
    );
  }
}