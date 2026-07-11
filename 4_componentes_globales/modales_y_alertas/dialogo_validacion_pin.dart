// lib/4_componentes_globales/modales_y_alertas/dialogo_validacion_pin.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';

class DialogoValidacionPin extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  
  const DialogoValidacionPin({
    Key? key,
    required this.titulo,
    required this.subtitulo,
  }) : super(key: key);

  @override
  State<DialogoValidacionPin> createState() => _DialogoValidacionPinState();
}

class _DialogoValidacionPinState extends State<DialogoValidacionPin> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: tema.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: ColoresApp.primarioVerde.withOpacity(0.3))),
      title: Column(
        children:[
          const Icon(Icons.pin_rounded, color: ColoresApp.primarioVerde, size: 48),
          const SizedBox(height: 12),
          Text(widget.titulo, style: EstilosTextoApp.h2.copyWith(color: tema.colorScheme.onSurface)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          Text(widget.subtitulo, textAlign: TextAlign.center, style: TextStyle(color: tema.textTheme.bodySmall?.color)),
          const SizedBox(height: 24),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: ColoresApp.primarioVerde),
            inputFormatters:[FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(color: tema.textTheme.bodySmall?.color?.withOpacity(0.3)),
              filled: true,
              fillColor: tema.scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions:[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Cancelar', style: TextStyle(color: tema.textTheme.bodySmall?.color)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            if (_pinController.text.length == 6) {
              Navigator.pop(context, _pinController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresApp.primarioVerde,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('VALIDAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}