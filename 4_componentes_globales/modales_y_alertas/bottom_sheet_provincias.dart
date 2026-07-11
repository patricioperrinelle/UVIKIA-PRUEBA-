// lib/4_componentes_globales/modales_y_alertas/bottom_sheet_provincias.dart
import 'package:flutter/material.dart';
import '../../1_nucleo/utilidades/constantes_geograficas.dart';

class BottomSheetProvincias {
  static void mostrar(
    BuildContext context, {
    required String? provinciaActual,
    required Function(String) onProvinciaSeleccionada,
    Color? colorActivo,
  }) {
    final provincias = ConstantesGeograficas.provinciasArgentina;
    final tema = Theme.of(context);
    final colorResalte = colorActivo ?? tema.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tema.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Text('Selecciona tu Provincia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: provincias.length,
                  itemBuilder: (context, index) {
                    final prov = provincias[index];
                    final isSelected = prov == provinciaActual;
                    return ListTile(
                      title: Text(prov, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
                      leading: Icon(Icons.map_rounded, color: isSelected ? colorResalte : Colors.grey),
                      tileColor: isSelected ? colorResalte.withOpacity(0.1) : null,
                      onTap: () {
                        onProvinciaSeleccionada(prov);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}