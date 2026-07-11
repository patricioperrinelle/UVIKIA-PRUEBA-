// lib/4_componentes_globales/indicadores/columna_info_destacada.dart

import 'package:flutter/material.dart';

/// Una columna estandarizada para mostrar Icono + Etiqueta + Valor Principal (Fitted) + Subtítulo.
/// Ideal para grillas de datos compactas (Ej: Fecha, Horario, Precio).
class ColumnaInfoDestacada extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final String? prefijoValor; // 🔥 NUEVO: Para inyectar símbolos separados del texto numérico
  final String subLabel;
  final Color? colorValor;

  const ColumnaInfoDestacada({
    Key? key,
    required this.icono,
    required this.label,
    required this.valor,
    this.prefijoValor,
    required this.subLabel,
    this.colorValor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Forzamos que si es un rango de horas o texto con guion, se comprima
    final String valorCompacto = valor.replaceAll(' - ', '-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children:[
            Icon(icono, size: 12, color: esOscuro ? Colors.grey.shade400 : Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label, 
                style: TextStyle(fontSize: 11, color: esOscuro ? Colors.grey.shade400 : Colors.grey.shade600, letterSpacing: -0.3), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          // 🔥 SEPARACIÓN ESTRUCTURAL: Utilizamos Text.rich para aislar el prefijo del valor
          child: Text.rich(
            TextSpan(
              children:[
                if (prefijoValor != null)
                  TextSpan(text: prefijoValor),
                TextSpan(text: valorCompacto),
              ],
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: colorValor ?? (esOscuro ? Colors.white : Colors.black),
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (subLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subLabel, 
            style: TextStyle(fontSize: 10, color: esOscuro ? Colors.grey.shade500 : Colors.grey.shade400, letterSpacing: -0.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]
      ],
    );
  }
}