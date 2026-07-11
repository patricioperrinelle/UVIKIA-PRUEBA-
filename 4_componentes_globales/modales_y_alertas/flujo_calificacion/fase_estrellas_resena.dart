// lib/4_componentes_globales/modales_y_alertas/flujo_calificacion/fase_estrellas_resena.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../formularios/campo_texto_cristal.dart';
import 'controlador_calificacion_memoria.dart';
import 'chip_pulgar_calificacion.dart';

class FaseEstrellasResena extends StatefulWidget {
  final ControladorCalificacionMemoria controlador;
  final bool esCliente;
  final String nombreObjetivo;
  final VoidCallback onFinalizar;

  const FaseEstrellasResena({
    Key? key,
    required this.controlador,
    required this.esCliente,
    required this.nombreObjetivo,
    required this.onFinalizar,
  }) : super(key: key);

  @override
  State<FaseEstrellasResena> createState() => _FaseEstrellasResenaState();
}

class _FaseEstrellasResenaState extends State<FaseEstrellasResena> {
  // 🛡️ CHIPS NEGATIVOS (Escudo de 1 a 3 estrellas)
  final List<String> _chipsCliente = ['Impuntual', 'Trabajo incompleto', 'Mala actitud', 'Desordenado', 'No cumplió presupuesto'];
  final List<String> _chipsPro = ['Cliente conflictivo', 'Demora en pago', 'Exigencias fuera de trato', 'Maltrato', 'Ambiente inseguro'];

  String _obtenerTextoEstrellas() {
    switch (widget.controlador.estrellasDadas) {
      case 1: return 'Muy mala (1/5)';
      case 2: return 'Mala (2/5)';
      case 3: return 'Regular (3/5)';
      case 4: return 'Buena (4/5)';
      case 5: return '¡Excelente! (5/5)';
      default: return 'Selecciona una puntuación';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final int estrellas = widget.controlador.estrellasDadas;
    final bool esMalaCalificacion = estrellas > 0 && estrellas <= 3;
    final List<String> chipsMostrados = widget.esCliente ? _chipsCliente : _chipsPro;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children:[
        Text('Trabajo finalizado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text('¿Cómo fue tu experiencia con ${widget.nombreObjetivo}?', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tema.colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text('Tu reseña ayuda a mantener una comunidad confiable.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tema.textTheme.bodyMedium?.color)),
        
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                widget.controlador.actualizarEstrellas(index + 1);
                setState(() {}); // Forzamos redibujado local para inyectar el Escudo Híbrido
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < estrellas ? Icons.star_rounded : Icons.star_outline_rounded, 
                  color: ColoresApp.terciarioMorado, 
                  size: 42,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(_obtenerTextoEstrellas(), style: TextStyle(color: tema.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600)),
        
        const SizedBox(height: 20),
        
        // 🛡️ EL ESCUDO HÍBRIDO DE RESEÑAS
        if (esMalaCalificacion) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ColoresApp.errorRojo.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: ColoresApp.errorRojo.withOpacity(0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 16, color: ColoresApp.errorRojo),
                    SizedBox(width: 8),
                    Text('Reporte Interno (Privado)', style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.errorRojo)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Tu comentario NO será público. Selecciona los problemas que tuviste y cuéntanos qué pasó para que el equipo de soporte evalúe el caso.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: chipsMostrados.map((chip) {
                    final seleccionado = widget.controlador.etiquetasNegativas.contains(chip);
                    return ChoiceChip(
                      label: Text(chip, style: TextStyle(fontSize: 12, color: seleccionado ? Colors.white : tema.colorScheme.onSurface)),
                      selected: seleccionado,
                      selectedColor: ColoresApp.errorRojo,
                      onSelected: (val) {
                        setState(() {
                          if (val) widget.controlador.etiquetasNegativas.add(chip);
                          else widget.controlador.etiquetasNegativas.remove(chip);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                CampoTextoCristal(
                  controller: widget.controlador.resenaController,
                  hintText: 'Detalla lo ocurrido de forma objetiva...',
                  minLines: 2, maxLines: 4, maxLength: 500,
                ),
              ],
            ),
          )
        ] 
        else ...[
          Align(alignment: Alignment.centerLeft, child: Text('Escribe tu reseña (opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tema.colorScheme.onSurface))),
          const SizedBox(height: 8),
          CampoTextoCristal(
            controller: widget.controlador.resenaController,
            hintText: widget.esCliente ? 'Ej: Llegó a horario y fue muy amable...' : 'Ej: Fue claro con las instrucciones...',
            minLines: 2, maxLines: 3, maxLength: 500, textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerLeft, child: Text('¿Qué destacas?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tema.colorScheme.onSurface))),
          const SizedBox(height: 12),
          if (widget.esCliente) ...[
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children:[
                ChipPulgarCalificacion(texto: 'Llega a horario', estadoActual: widget.controlador.puntualidad, onSeleccion: widget.controlador.setPuntualidad),
                ChipPulgarCalificacion(texto: 'Lo recomiendo', estadoActual: widget.controlador.loRecomiendaCliente, onSeleccion: widget.controlador.setLoRecomiendaCliente),
              ],
            ),
          ] else ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                ChipPulgarCalificacion(texto: 'Trato respetuoso', estadoActual: widget.controlador.tratoRespetuoso, onSeleccion: widget.controlador.setTratoRespetuoso),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: ChipPulgarCalificacion(texto: 'Lo recomiendo', estadoActual: widget.controlador.loRecomiendaPro, onSeleccion: widget.controlador.setLoRecomiendaPro))),
                    const SizedBox(width: 8),
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: ChipPulgarCalificacion(texto: 'Descripción precisa', estadoActual: widget.controlador.descripcionPrecisa, onSeleccion: widget.controlador.setDescripcionPrecisa))),
                  ],
                ),
              ],
            ),
          ],
        ],
        
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onFinalizar,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.terciarioMorado,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ENVIAR RESEÑA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }
}