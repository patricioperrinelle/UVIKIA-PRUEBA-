// lib/4_componentes_globales/modales_y_alertas/flujo_calificacion/modal_finalizar_y_calificar.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../3_modelos/modelo_resena_payload.dart';
import 'controlador_calificacion_memoria.dart';
import 'fase_estrellas_resena.dart';

class ModalFinalizarYCalificar extends StatefulWidget {
  final ModeloPuja profesional; 
  final bool esCliente; 
  final Function(ModeloResenaPayload payload) onConfirmar;

  const ModalFinalizarYCalificar({
    Key? key,
    required this.profesional, 
    required this.esCliente,
    required this.onConfirmar,
  }) : super(key: key);

  @override
  State<ModalFinalizarYCalificar> createState() => _ModalFinalizarYCalificarState();
}

class _ModalFinalizarYCalificarState extends State<ModalFinalizarYCalificar> {
  final ControladorCalificacionMemoria _controlador = ControladorCalificacionMemoria();
  bool _enviando = false; 

  @override
  void initState() {
    super.initState();
    _controlador.inicializar(widget.profesional.id, widget.esCliente);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _intentarFinalizar() async {
    if (_enviando) return; 
    
    if (_controlador.estrellasDadas <= 3 && _controlador.etiquetasNegativas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona al menos un motivo por el que tuviste problemas.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: ColoresApp.errorRojo,
      ));
      return;
    }

    setState(() { _enviando = true; });

    final payloadBase = await _controlador.generarPayloadFinal(widget.esCliente);
    
    // 🛡️ QA-TERMINATOR: Protección de la brecha asíncrona
    if (!mounted) return; 

    if (payloadBase == null) {
      setState(() { _enviando = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una calificación.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: ColoresApp.advertenciaAmarillo,
        ),
      );
    } else {
      final bool esPrivado = _controlador.estrellasDadas <= 3;
      final payloadMutado = ModeloResenaPayload(
        rating: payloadBase.rating,
        comentario: payloadBase.comentario,
        metodoPago: payloadBase.metodoPago,
        esPuntualORespetuoso: payloadBase.esPuntualORespetuoso,
        esRecomendadoOClaro: payloadBase.esRecomendadoOClaro,
        esPuntual: payloadBase.esPuntual,
        loRecomienda: payloadBase.loRecomienda,
        tratoRespetuoso: payloadBase.tratoRespetuoso,
        descripcionPrecisa: payloadBase.descripcionPrecisa,
        esComentarioPrivado: esPrivado, 
        etiquetasNegativas: esPrivado ? _controlador.etiquetasNegativas : [], 
        rolEvaluado: payloadBase.rolEvaluado,
      );

      widget.onConfirmar(payloadMutado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return PopScope(
      canPop: false, 
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          bottom: true,
          child: Container(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: tema.scaffoldBackgroundColor, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                
                Flexible(
                  child: ListenableBuilder(
                    listenable: _controlador,
                    builder: (context, _) {
                      if (_controlador.cargandoMemoria) {
                        return const Padding(
                          padding: EdgeInsets.all(40), 
                          child: Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde))
                        );
                      }

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        // 🚨 PURGA LEGACY: Eliminado el Orquestador de Fases. 
                        // Arrancamos directo en las estrellas.
                        child: FaseEstrellasResena(
                          controlador: _controlador,
                          esCliente: widget.esCliente,
                          nombreObjetivo: widget.esCliente ? widget.profesional.apodoProfesional : 'el cliente',
                          onFinalizar: _intentarFinalizar,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}