// lib/5_modulos/modulo_servicios_catalogo/componentes/seccion_detalles_catalogo.dart

import 'package:flutter/material.dart';

class SeccionDetallesCatalogo extends StatelessWidget {
  final String titulo;
  final String precio;
  final String fechaFormateada; // 🚨 NUEVO: Recibe el string limpio
  final String horarioFormateado; // 🚨 NUEVO: Recibe el string limpio
  final String descripcion;
  final List<String> imagenes;
  final String ubicacionLimpia; // 🚨 NUEVO: Recibe el string limpio

  const SeccionDetallesCatalogo({
    Key? key,
    required this.titulo,
    required this.precio,
    required this.fechaFormateada,
    required this.horarioFormateado,
    required this.descripcion,
    required this.imagenes,
    required this.ubicacionLimpia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: esOscuro ? const Color(0xFF161616) : Colors.white,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Text('\$ $precio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tema.colorScheme.primary)),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(fechaFormateada, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(horarioFormateado, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (ubicacionLimpia.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(ubicacionLimpia, style: const TextStyle(fontSize: 15))),
              ],
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 16),
          const Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(descripcion, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }
}