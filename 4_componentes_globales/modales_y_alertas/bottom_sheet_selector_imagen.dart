// lib/4_componentes_globales/modales_y_alertas/bottom_sheet_selector_imagen.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class BottomSheetSelectorImagen extends StatelessWidget {
  final String titulo; // Ahora tiene un valor por defecto en el constructor
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const BottomSheetSelectorImagen({
    super.key,
    this.titulo = 'Seleccionar imagen', // <--- Valor por defecto para no romper nada
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return SafeArea(
      bottom: true,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tema.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: esOscuro ? ColoresApp.bordeCristal : Colors.black12,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: esOscuro ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                color: tema.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColoresApp.primarioVerde.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: ColoresApp.primarioVerde),
              ),
              title: Text(
                'Tomar Foto',
                style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Usar la cámara del dispositivo', style: TextStyle(color: tema.textTheme.bodySmall?.color)),
              onTap: onCameraTap,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColoresApp.infoAzul.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: ColoresApp.infoAzul),
              ),
              title: Text(
                'Elegir de la Galería',
                style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Buscar en tus fotos guardadas', style: TextStyle(color: tema.textTheme.bodySmall?.color)),
              onTap: onGalleryTap,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}