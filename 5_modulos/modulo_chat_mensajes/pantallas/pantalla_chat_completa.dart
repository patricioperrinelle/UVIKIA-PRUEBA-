// lib/5_modulos/modulo_chat_mensajes/pantallas/pantalla_chat_completa.dart

import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../controladores/controlador_chat.dart';
import '../componentes/lista_mensajes_sincronizada.dart';
import '../../../4_componentes_globales/chat/barra_entrada_chat.dart';

class PantallaChatCompleta extends StatefulWidget {
  final String trabajoId;
  final String miId;
  final String contraparteId;
  final String nombreContraparte;
  final bool isCongelado;
  final Color colorAcento;

  const PantallaChatCompleta({
    Key? key,
    required this.trabajoId,
    required this.miId,
    required this.contraparteId,
    required this.nombreContraparte,
    this.isCongelado = false,
    this.colorAcento = ColoresApp.secundarioCyan,
  }) : super(key: key);

  @override
  State<PantallaChatCompleta> createState() => _PantallaChatCompletaState();
}

class _PantallaChatCompletaState extends State<PantallaChatCompleta> {
  final ControladorChat _controlador = ControladorChat();

  @override
  void initState() {
    super.initState();
    // Inicializamos el motor del chat
    _controlador.inicializar(
      pTrabajoId: widget.trabajoId,
      pMiId: widget.miId,
      pContraparteId: widget.contraparteId,
      iniciarExpandido: true, // Siempre expandido en vista completa
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Evita que el teclado se quede pegado si tocamos el fondo de la lista
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ColoresApp.fondoPrincipal,
        appBar: AppBar(
          title: Text('Chat con ${widget.nombreContraparte}', style: EstilosTextoApp.h3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: ColoresApp.bordeCristal, height: 1.0),
          ),
        ),
        body: SafeArea(
          bottom: true,
          child: ListenableBuilder(
            listenable: _controlador,
            builder: (context, child) {
              return Column(
                children:[
                  // 1. LISTA DE MENSAJES (Ocupa todo el espacio disponible)
                  Expanded(
                    child: _controlador.isLoading
                        ? Center(child: CircularProgressIndicator(color: widget.colorAcento))
                        : ListaMensajesSincronizada(
                            mensajes: _controlador.mensajes,
                            miIdUsuario: widget.miId,
                            colorAcento: widget.colorAcento,
                          ),
                  ),

                  // 2. INPUT DE CHAT O CARTEL DE CONGELADO
                  if (widget.isCongelado)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ColoresApp.fondoTarjetas,
                        border: Border(top: BorderSide(color: ColoresApp.bordeCristal)),
                      ),
                      child: const Text(
                        'Chat congelado por seguridad.\nEl trato finalizó o fue cancelado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: ColoresApp.fondoPrincipal,
                        border: Border(top: BorderSide(color: ColoresApp.bordeCristal)),
                      ),
                      child: BarraEntradaChat(
                        controller: _controlador.inputController,
                        focusNode: _controlador.inputFocusNode,
                        colorAcento: widget.colorAcento,
                        onSend: () => _controlador.enviarMensaje(context),
                      ),
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