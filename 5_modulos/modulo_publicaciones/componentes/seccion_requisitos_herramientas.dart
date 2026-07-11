// lib/5_modulos/modulo_publicaciones/componentes/seccion_requisitos_herramientas.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';

class SeccionRequisitosHerramientas extends StatelessWidget {
  final bool traerHerramientas;
  final TextEditingController herramientasCtrl;
  final ValueChanged<bool?> onChanged;
  final Color colorTema;
  final String tituloCheckbox;
  final String hintInput;

  const SeccionRequisitosHerramientas({
    Key? key,
    required this.traerHerramientas,
    required this.herramientasCtrl,
    required this.onChanged,
    this.colorTema = ColoresApp.primarioVerde,
    this.tituloCheckbox = 'El profesional debe traer herramientas',
    this.hintInput = 'Ej. Necesito que traigas escalera y taladro...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), // Restaurado al original oscuro
        borderRadius: DimensionesApp.radioTarjetas,
        border: Border.all(color: Colors.white24),
      ),
      // 🚨 PROTECCIÓN: Evita que la columna intente crecer infinitamente
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children:[
          // 🚨 RESTAURADO AL ORIGINAL: Evita el crash de componentes customizados
          Theme(
            data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white54),
            child: CheckboxListTile(
              title: Text(tituloCheckbox, style: const TextStyle(color: Colors.white, fontSize: 14)),
              value: traerHerramientas,
              activeColor: colorTema,
              checkColor: Colors.black,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onChanged: onChanged,
            ),
          ),
          if (traerHerramientas)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: CampoTextoCristal(
                controller: herramientasCtrl,
                hintText: hintInput,
                textInputAction: TextInputAction.done,
              ),
            ),
        ],
      ),
    );
  }
}