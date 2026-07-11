// lib/4_componentes_globales/formularios/selector_desplegable_cristal.dart
import 'package:flutter/material.dart';

class SelectorDesplegableCristal extends StatelessWidget {
  final String hintText;
  final String? valorSeleccionado;
  final IconData iconoPrefix;
  final VoidCallback onTap;
  final Color? colorActivo;

  const SelectorDesplegableCristal({
    Key? key,
    required this.hintText,
    this.valorSeleccionado,
    required this.iconoPrefix,
    required this.onTap,
    this.colorActivo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bool hasValue = valorSeleccionado != null && valorSeleccionado!.isNotEmpty;
    final colorResalte = colorActivo ?? tema.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: tema.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tema.dividerColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(iconoPrefix, color: hasValue ? colorResalte : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? valorSeleccionado! : hintText,
                style: TextStyle(
                  color: hasValue ? tema.colorScheme.onSurface : Colors.grey, 
                  fontSize: 14
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}