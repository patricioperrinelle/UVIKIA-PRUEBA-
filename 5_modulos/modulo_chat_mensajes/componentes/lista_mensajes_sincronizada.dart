// lib/5_modulos/modulo_chat_mensajes/componentes/lista_mensajes_sincronizada.dart

import 'package:flutter/material.dart';
import '../../../3_modelos/modelo_chat_mensaje.dart';
import '../../../2_tema/colores_app.dart';

// --- COMPONENTES GLOBALES Y LOCALES ---
import '../../../4_componentes_globales/chat/burbuja_chat_mensaje.dart';
import 'burbuja_mensaje_sistema.dart';

class ListaMensajesSincronizada extends StatefulWidget {
  final List<ModeloMensaje> mensajes;
  final String miIdUsuario;
  final Color colorAcento;

  const ListaMensajesSincronizada({
    Key? key,
    required this.mensajes,
    required this.miIdUsuario,
    this.colorAcento = ColoresApp.secundarioCyan,
  }) : super(key: key);

  @override
  State<ListaMensajesSincronizada> createState() => _ListaMensajesSincronizadaState();
}

class _ListaMensajesSincronizadaState extends State<ListaMensajesSincronizada> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(keepScrollOffset: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mensajes.isEmpty) {
      return Center(
        child: Text(
          'Sin mensajes aún. Escribe para coordinar.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54), fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Fundamental para que el scroll inicie desde abajo
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.mensajes.length,
      itemBuilder: (context, index) {
        final msg = widget.mensajes[index];

        // 1. Es un comando del sistema (Ej: SYS_LLEGUE)
        if (msg.esMensajeSistema) {
          return BurbujaMensajeSistema(codigoSistema: msg.texto);
        }

        // 2. Es un mensaje de chat normal
        final bool soyYo = msg.emisorId == widget.miIdUsuario;

        return BurbujaChatMensaje(
          texto: msg.texto,
          soyYo: soyYo,
          colorPrimario: widget.colorAcento,
        );
      },
    );
  }
}