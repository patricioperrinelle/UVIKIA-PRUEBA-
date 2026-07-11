// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/item_extra_opcional.dart

import 'package:flutter/material.dart';

class ItemExtraOpcional extends StatelessWidget {
  final String nombre;
  final double precio;
  final bool seleccionado;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEditar; // 🚨 NUEVO

  const ItemExtraOpcional({
    Key? key,
    required this.nombre,
    required this.precio,
    required this.seleccionado,
    required this.onChanged,
    required this.onEditar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorAcento = tema.colorScheme.primary;
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: esOscuro ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(nombre, style: TextStyle(fontSize: 14, color: seleccionado ? null : Colors.grey))),
          Text('+ \$${precio.toInt()}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onEditar,
            child: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 18),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24, height: 24,
            child: Checkbox(
              value: seleccionado,
              onChanged: onChanged,
              activeColor: colorAcento,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          )
        ],
      ),
    );
  }
}