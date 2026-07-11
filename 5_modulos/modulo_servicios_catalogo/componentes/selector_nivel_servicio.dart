// lib/5_modulos/modulo_servicios_catalogo/componentes/selector_nivel_servicio.dart

import 'package:flutter/material.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';

class SelectorNivelServicio extends StatelessWidget {
  final List<ModeloNivelServicio> niveles;
  final String idSeleccionado;
  final Function(String) onNivelSeleccionado;

  const SelectorNivelServicio({
    Key? key,
    required this.niveles,
    required this.idSeleccionado,
    required this.onNivelSeleccionado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorAcento = tema.colorScheme.primary; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: niveles.asMap().entries.map((entry) {
            final int idx = entry.key;
            final ModeloNivelServicio nivel = entry.value;
            final seleccionado = nivel.idNivel == idSeleccionado;
            
            final itemsCaracteristicas = nivel.caracteristicasProcesadas;
            final itemsNoCubre = nivel.loQueNoCubreProcesado;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onNivelSeleccionado(nivel.idNivel),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: idx < niveles.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: seleccionado ? colorAcento.withOpacity(0.04) : (esOscuro ? Colors.white10 : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: seleccionado ? colorAcento : (esOscuro ? Colors.white24 : Colors.grey.shade300), 
                      width: seleccionado ? 2 : 1
                    ),
                    boxShadow: seleccionado ? [] : [
                      if (!esOscuro) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(nivel.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tema.colorScheme.onSurface))),
                          if (seleccionado) Icon(Icons.check_circle_rounded, size: 16, color: colorAcento),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('\$${nivel.precioFijo.toInt()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: seleccionado ? colorAcento : tema.colorScheme.onSurface)),
                      
                      if (itemsCaracteristicas.isNotEmpty || itemsNoCubre.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Divider(height: 1, color: seleccionado ? colorAcento.withOpacity(0.2) : (esOscuro ? Colors.white12 : Colors.grey.shade200)),
                        const SizedBox(height: 8),
                        if (itemsCaracteristicas.isNotEmpty)
                          ...itemsCaracteristicas.map((carac) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check, size: 12, color: seleccionado ? colorAcento : Colors.grey.shade400),
                                const SizedBox(width: 6),
                                Expanded(child: Text(carac, style: TextStyle(fontSize: 11, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade700, height: 1.2))),
                              ],
                            ),
                          )).toList(),
                        if (itemsNoCubre.isNotEmpty)
                          ...itemsNoCubre.map((noCarac) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.close_rounded, size: 12, color: Colors.redAccent),
                                const SizedBox(width: 6),
                                Expanded(child: Text(noCarac, style: TextStyle(fontSize: 11, color: esOscuro ? Colors.red.shade200 : Colors.red.shade800, height: 1.2))),
                              ],
                            ),
                          )).toList(),
                      ],
                      
                      const Spacer(),
                      const SizedBox(height: 8),
                      
                      // 🚨 NUEVO: Renglón con la duración estricta de este plan inyectado al fondo (PASO C)
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: esOscuro ? Colors.grey.shade400 : Colors.black87),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nivel.duracionEstimada, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: esOscuro ? Colors.grey.shade300 : Colors.black87)
                            )
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}