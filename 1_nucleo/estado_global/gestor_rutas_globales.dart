// lib_editada/1_nucleo/estado_global/gestor_rutas_globales.dart
import 'package:flutter/material.dart';
import '../../5_modulos/modulo_perfil_usuario/pantallas/pantalla_perfil_publico.dart';

class GestorRutasGlobales {
  static void abrirPerfilPublico(
    BuildContext context, {
    required String id,
    required String name,
    required String image,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PantallaPerfilPublico(),
        settings: RouteSettings(
          arguments: {
            'id': id,
            'name': name,
            'image': image,
          },
        ),
      ),
    );
  }
}
