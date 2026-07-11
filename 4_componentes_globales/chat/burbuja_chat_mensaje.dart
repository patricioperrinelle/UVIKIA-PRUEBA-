// lib/4_componentes_globales/chat/burbuja_chat_mensaje.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';


class BurbujaChatMensaje extends StatelessWidget {
  final String texto;
  final bool soyYo; // Determina de qué lado va la burbuja y el color
  final Color colorPrimario;

  const BurbujaChatMensaje({
    Key? key,
    required this.texto,
    required this.soyYo,
    this.colorPrimario = ColoresApp.secundarioCyan, // Cyan por defecto (Jornadas), en Oficios se inyectará Verde
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🚨 Detectamos dinámicamente si estamos en modo claro u oscuro
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: soyYo ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: soyYo 
              ? colorPrimario.withOpacity(0.15) 
              : (esOscuro ? Colors.white12 : Colors.black.withOpacity(0.05)), // Fondo adaptativo
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: soyYo ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !soyYo ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: soyYo 
                ? colorPrimario 
                : (esOscuro ? Colors.white : Colors.black87), // Texto adaptativo
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}