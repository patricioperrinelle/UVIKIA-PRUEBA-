// lib/4_componentes_globales/formularios/campo_texto_cristal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import '../../2_tema/dimensiones_app.dart';

class CampoTextoCristal extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? iconoPrefix;
  final IconData? iconoPrefijo; // 🚨 NUEVO: Atajo en español
  final Widget? iconoSuffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool tecladoNumerico; // 🚨 NUEVO: Atajo booleano rápido
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int minLines;
  final int? maxLines;
  final int? maxLength;
  final bool readOnly;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const CampoTextoCristal({
    Key? key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.iconoPrefix,
    this.iconoPrefijo, // Inyectado
    this.iconoSuffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.tecladoNumerico = false, // Inyectado (Falso por defecto)
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onSubmitted,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Fusión inteligente: Si usa el atajo español, lo respeta.
    final iconoFinal = iconoPrefijo ?? iconoPrefix;
    final tecladoFinal = tecladoNumerico ? TextInputType.number : keyboardType;

    return Container(
      decoration: BoxDecoration(
        color: tema.inputDecorationTheme.fillColor, 
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: tecladoFinal, // Aplica el teclado numérico si se solicita
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLength,
        readOnly: readOnly,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: EstilosTextoApp.cuerpoRegular.copyWith(
          color: readOnly ? tema.textTheme.bodySmall?.color : tema.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          counterStyle: TextStyle(color: tema.textTheme.bodySmall?.color),
          hintStyle: EstilosTextoApp.cuerpoRegular.copyWith(color: esOscuro ? Colors.white38 : Colors.black38),
          labelStyle: EstilosTextoApp.cuerpoRegular.copyWith(color: esOscuro ? Colors.white54 : Colors.black54),
          prefixIcon: iconoFinal != null 
              ? Icon(iconoFinal, color: tema.textTheme.bodySmall?.color, size: 20) 
              : null,
          suffixIcon: iconoSuffix,
          border: InputBorder.none,
          contentPadding: DimensionesApp.paddingInputs,
        ),
      ),
    );
  }
}