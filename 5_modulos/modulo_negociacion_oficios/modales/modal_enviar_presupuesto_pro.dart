// lib/5_modulos/modulo_negociacion_oficios/modales/modal_enviar_presupuesto_pro.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../1_nucleo/formateadores_texto.dart'; // Extraído en la Fase 2
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';

class ModalEnviarPresupuestoPro extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final Function(String) onConfirmar;

  const ModalEnviarPresupuestoPro({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.onConfirmar,
  }) : super(key: key);

  @override
  State<ModalEnviarPresupuestoPro> createState() => _ModalEnviarPresupuestoProState();
}

class _ModalEnviarPresupuestoProState extends State<ModalEnviarPresupuestoPro> {
  final TextEditingController _montoCtrl = TextEditingController();

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escudo protector de Notch inferior + Teclado
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        bottom: true,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ColoresApp.fondoPrincipal.withOpacity(0.9),
                border: const Border(top: BorderSide(color: ColoresApp.primarioVerde, width: 2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Expanded(child: Text(widget.titulo, style: EstilosTextoApp.h3, overflow: TextOverflow.ellipsis)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.subtitulo, style: EstilosTextoApp.cuerpoRegular),
                  const SizedBox(height: 24),
                  
                  // INPUT NUMÉRICO GIGANTE
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ColoresApp.primarioVerde, width: 2),
                    ),
                    child: TextField(
                      controller: _montoCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: const TextStyle(color: ColoresApp.primarioVerde, fontSize: 32, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        hintText: '\$ 0',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  BotonAccionPrincipal(
                    texto: 'ENVIAR PRESUPUESTO',
                    onPressed: () {
                      if (_montoCtrl.text.trim().isNotEmpty && _montoCtrl.text.trim() != '\$ ') {
                        widget.onConfirmar(_montoCtrl.text.trim());
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}