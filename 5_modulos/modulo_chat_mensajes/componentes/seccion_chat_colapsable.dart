// lib/5_modulos/modulo_chat_mensajes/componentes/seccion_chat_colapsable.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

import '../controladores/controlador_chat.dart';
import 'lista_mensajes_sincronizada.dart';
import '../../../4_componentes_globales/chat/barra_entrada_chat.dart';

class SeccionChatColapsable extends StatefulWidget {
  final ControladorChat controlador;
  final bool isCongelado;
  final Color colorAcento;

  const SeccionChatColapsable({
    Key? key,
    required this.controlador,
    this.isCongelado = false,
    this.colorAcento = ColoresApp.secundarioCyan,
  }) : super(key: key);

  @override
  State<SeccionChatColapsable> createState() => _SeccionChatColapsableState();
}

class _SeccionChatColapsableState extends State<SeccionChatColapsable> {
  final GlobalKey _headerKey = GlobalKey(); 

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Theme(
      data: tema.copyWith(dividerColor: Colors.transparent),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          key: _headerKey, 
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: DimensionesApp.radioTarjetas,
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListenableBuilder(
            listenable: widget.controlador,
            builder: (context, _) {
              final isExpanded = widget.controlador.isChatExpanded || widget.isCongelado;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: widget.isCongelado ? null : () {
                      final newExpanded = !widget.controlador.isChatExpanded;
                      widget.controlador.toggleExpandido(newExpanded);
                      if (newExpanded && !widget.isCongelado) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (!mounted) return;
                          if (widget.controlador.inputFocusNode.canRequestFocus) {
                            widget.controlador.inputFocusNode.requestFocus();
                          }
                        });
                      }
                    },
                    borderRadius: isExpanded 
                        ? const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)) 
                        : BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).colorScheme.onSurface, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Text('Chat del Trabajo', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                                if (widget.controlador.unreadMessages > 0 && !widget.controlador.isChatExpanded)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: ColoresApp.errorRojo, shape: BoxShape.circle),
                                    child: Text(widget.controlador.unreadMessages.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isExpanded ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔥 ALTURA COMPRIMIDA a 200 para evitar que el teclado empuje la cabecera
                        SizedBox(
                          height: 200, 
                          child: widget.controlador.isLoading
                              ? Center(child: CircularProgressIndicator(color: widget.colorAcento))
                              : ListaMensajesSincronizada(
                                  mensajes: widget.controlador.mensajes,
                                  miIdUsuario: widget.controlador.miId,
                                  colorAcento: widget.colorAcento,
                                ),
                        ),
                        
                        if (widget.isCongelado)
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: esOscuro ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02), border: Border(top: BorderSide(color: ColoresApp.bordeCristal))),
                            child: Text('Chat congelado por seguridad.\nEl trato finalizó o fue cancelado/rechazado.', textAlign: TextAlign.center, style: TextStyle(color: tema.textTheme.bodySmall?.color, fontStyle: FontStyle.italic, fontSize: 13)),
                          )
                        else
                          BarraEntradaChat(
                            controller: widget.controlador.inputController, focusNode: widget.controlador.inputFocusNode, colorAcento: widget.colorAcento, onSend: () => widget.controlador.enviarMensaje(context),
                          ),
                      ],
                    ) : const SizedBox(width: double.infinity),
                  ),
                ],
              );
            }
          ),
      ),
      ),
    );
  }
}