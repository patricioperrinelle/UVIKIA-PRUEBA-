import 'package:flutter/material.dart';
import '../../2_tema/dimensiones_app.dart';
import '../../2_tema/colores_app.dart';

class BotonAccionLista extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color? colorAcento;
  final VoidCallback? onTap;
  final bool isProcessing;
  final IconData? iconoDerecho;

  const BotonAccionLista({
    Key? key,
    required this.texto,
    required this.icono,
    this.colorAcento,
    required this.onTap,
    this.isProcessing = false,
    this.iconoDerecho = Icons.chevron_right_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = colorAcento ?? Theme.of(context).colorScheme.onSurface;
    
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProcessing ? null : onTap,
          borderRadius: DimensionesApp.radioTarjetas,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isProcessing)
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: color, strokeWidth: 2),
                  )
                else if (iconoDerecho != null)
                  Icon(iconoDerecho, color: color.withOpacity(0.6), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
