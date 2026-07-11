// lib/4_componentes_globales/formularios/casilla_verificacion_tema.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class CasillaVerificacionTema extends StatelessWidget {
  final String titulo;
  final bool valor;
  final ValueChanged<bool?> onChanged;
  final Color colorTema;

  const CasillaVerificacionTema({
    Key? key,
    required this.titulo,
    required this.valor,
    required this.onChanged,
    this.colorTema = ColoresApp.primarioVerde,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: ColoresApp.textoSecundario,
      ),
      child: CheckboxListTile(
        title: Text(
          titulo,
          style: const TextStyle(color: ColoresApp.textoPrincipal, fontSize: 14),
        ),
        value: valor,
        activeColor: colorTema,
        checkColor: Colors.black, // El tilde negro contrasta perfecto con verde/cyan/amarillo
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}