// lib/4_componentes_globales/chat/barra_entrada_chat.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class BarraEntradaChat extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final Color colorAcento;

  const BarraEntradaChat({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.colorAcento = ColoresApp.secundarioCyan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children:[
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              // 🚨 CORRECCIÓN DE CONTRASTE: Ahora el texto SIEMPRE es blanco para que sea legible
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                // 🚨 DISEÑO PREMIUM: En modo claro inyecta un fondo gris oscuro (Casi negro), 
                // en modo oscuro inyecta un cristal translúcido. Nunca más "todo blanco".
                fillColor: esOscuro ? Colors.white.withOpacity(0.08) : const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: esOscuro ? Colors.white12 : Colors.transparent, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: esOscuro ? Colors.white12 : Colors.transparent, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorAcento.withOpacity(0.8), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(color: colorAcento, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}