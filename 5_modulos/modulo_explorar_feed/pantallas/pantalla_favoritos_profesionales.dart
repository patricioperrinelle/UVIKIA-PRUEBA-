// lib/5_modulos/modulo_explorar_feed/pantallas/pantalla_favoritos_profesionales.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../2_tema/colores_app.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../3_modelos/modelo_perfil.dart';

import '../controladores/controlador_feed_profesionales.dart';
import '../componentes/tarjeta_profesional_directorio.dart';
import '../componentes/estado_vacio_feed.dart';

import '../../modulo_perfil_usuario/pantallas/pantalla_perfil_publico.dart';

class PantallaFavoritosProfesionales extends StatelessWidget {
  final ControladorFeedProfesionales controlador;

  const PantallaFavoritosProfesionales({Key? key, required this.controlador}) : super(key: key);

  void _abrirPerfil(BuildContext context, ModeloPerfil perfil) {
    FocusScope.of(context).unfocus();
    final pro = perfil.perfilProfesional;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PantallaPerfilPublico(),
        settings: RouteSettings(arguments: {
          'id': perfil.id,
          'name': perfil.apodo,
          'image': perfil.fotoUrl,
          'tags': pro?.tagsOficios ?? List<String>.empty(),
          'rating': pro?.ratingProfesional ?? 0.0,
          'reviews': pro?.cantidadResenasProfesional ?? 0,
          'biography': pro?.bio ?? '',
        }),
      )
    ).then((_) => controlador.cargarDirectorio(context));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profesionales Guardados', style: TextStyle(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface, fontSize: 18)),
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
            final listaGuardados = controlador.profesionalesGuardadosCompletos;

            if (listaGuardados.isEmpty) {
              return const EstadoVacioFeed(
                icono: Icons.bookmark_border_rounded,
                titulo: 'Sin profesionales guardados',
                subtitulo: 'No tienes profesionales en tu lista de favoritos.',
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
              itemCount: listaGuardados.length,
              itemBuilder: (context, index) {
                final perfil = listaGuardados[index];
                // En esta pantalla siempre es favorito
                const bool isFavorite = true;

                return TarjetaProfesionalDirectorio(
                  perfil: perfil,
                  isFavorite: isFavorite,
                  onFavoriteToggle: () => controlador.toggleFavoritoGlobal(context, perfil),
                  onTapCard: () => _abrirPerfil(context, perfil),
                );
              },
            );
          }
        ),
      ),
    );
  }
}