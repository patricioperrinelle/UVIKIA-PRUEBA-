// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/tarjeta_plan_creado.dart

import 'package:flutter/material.dart';

class TarjetaPlanCreado extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final double precio;
  final String duracionEstimada; // 🚨 NUEVO: Recibe el tiempo estimado
  final bool seleccionada;
  final List<String> loQueCubre;
  final List<String> loQueNoCubre;
  final VoidCallback onToggle;
  final VoidCallback onEditar;

  const TarjetaPlanCreado({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.precio,
    required this.duracionEstimada, // 🚨 NUEVO
    required this.seleccionada,
    this.loQueCubre = const [],
    this.loQueNoCubre = const [],
    required this.onToggle,
    required this.onEditar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorAcento = tema.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: seleccionada ? colorAcento.withOpacity(0.05) : (esOscuro ? Colors.white10 : Colors.white),
        border: Border.all(color: seleccionada ? colorAcento : (esOscuro ? Colors.white24 : Colors.grey.shade300)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onToggle, 
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 4), // Ajustado el right para el IconButton
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox visual
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: seleccionada ? colorAcento : Colors.transparent,
                      border: Border.all(color: seleccionada ? colorAcento : Colors.grey.shade400, width: 1.5),
                    ),
                    child: seleccionada ? const Center(child: Icon(Icons.check, size: 14, color: Colors.white)) : null,
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: seleccionada ? null : Colors.grey)),
                          const SizedBox(width: 8),
                          Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            duracionEstimada, 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Listado de lo que cubre
                      if (loQueCubre.isNotEmpty) ...[
                        ...loQueCubre.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check, size: 12, color: seleccionada ? colorAcento : Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item, 
                                  style: TextStyle(fontSize: 12, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade700)
                                )
                              ),
                            ],
                          ),
                        )).toList(),
                      ] else ...[
                        Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],

                      // Listado de lo que NO cubre
                      if (loQueNoCubre.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...loQueNoCubre.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.close_rounded, size: 12, color: Colors.redAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item, 
                                  style: TextStyle(fontSize: 12, color: esOscuro ? Colors.red.shade200 : Colors.red.shade800)
                                )
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ],
                  ),
                ),
                
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text('\$${precio.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: seleccionada ? null : Colors.grey)),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: onEditar,
                          icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 20),
                          splashRadius: 24,
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}