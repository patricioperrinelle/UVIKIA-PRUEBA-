// lib/5_modulos/modulo_actividad_alertas/componentes/acordeon_categoria_historial.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';
import 'tarjeta_historial_estado.dart';

class AcordeonCategoriaHistorial extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final List<TrabajoContratable> trabajos;
  final Color colorTema;
  final bool esDueno;
  final bool esHistorial;
  final String textoVacio;
  final String miId;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  
  final Function(TrabajoContratable) onTapTrabajo;
  final Function(TrabajoContratable) onDeleteTrabajo;
  final int Function(TrabajoContratable) onCalcularAlertas;

  const AcordeonCategoriaHistorial({
    Key? key,
    required this.titulo,
    required this.icono,
    required this.trabajos,
    required this.colorTema,
    required this.esDueno,
    required this.textoVacio,
    required this.miId,
    required this.onTapTrabajo,
    required this.onDeleteTrabajo,
    required this.onCalcularAlertas,
    this.esHistorial = false,
    this.isExpanded,
    this.onExpansionChanged,
  }) : super(key: key);

  @override
  State<AcordeonCategoriaHistorial> createState() => _AcordeonCategoriaHistorialState();
}

class _AcordeonCategoriaHistorialState extends State<AcordeonCategoriaHistorial> {
  bool _mostrarTodo = false;
  final ExpansionTileController _controller = ExpansionTileController();

  @override
  void didUpdateWidget(AcordeonCategoriaHistorial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded!) {
        _controller.expand();
      } else {
        _controller.collapse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); 
    final esOscuro = tema.brightness == Brightness.dark;
    final int count = widget.trabajos.length;
    
    int alertasCategoria = 0;
    if (!widget.esHistorial) {
      for (var i in widget.trabajos) {
        alertasCategoria += widget.onCalcularAlertas(i);
      }
    }

    final listaVisible = _mostrarTodo ? widget.trabajos : widget.trabajos.take(2).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: esOscuro ? ColoresApp.fondoTarjetas : Colors.white, 
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200, width: 1.0),
        ),
        child: Theme(
          data: tema.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: _controller,
            initiallyExpanded: widget.isExpanded ?? (!widget.esHistorial && count > 0),
            onExpansionChanged: widget.onExpansionChanged,
            iconColor: tema.textTheme.bodyMedium?.color,
            collapsedIconColor: tema.textTheme.bodyMedium?.color, 
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Row(
              children:[
                Icon(widget.icono, size: 20, color: tema.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.titulo} ($count)', // 🔥 Inyección del Contador Maestro
                    style: TextStyle(
                      color: tema.colorScheme.onSurface, 
                      fontSize: 15, 
                      fontWeight: FontWeight.w700
                    )
                  )
                ),
                if (alertasCategoria > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColoresApp.errorRojo, 
                      borderRadius: BorderRadius.circular(4),
                      boxShadow:[BoxShadow(color: ColoresApp.errorRojo.withOpacity(0.5), blurRadius: 4)]
                    ),
                    child: Text(alertasCategoria.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            children:[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.trabajos.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(widget.textoVacio, style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 14, fontStyle: FontStyle.italic)),
                      )
                    : Column(
                        children:[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(), 
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: listaVisible.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final trabajo = listaVisible[index];
                              return TarjetaHistorialEstado(
                                trabajo: trabajo,
                                esDueno: widget.esDueno,
                                esHistorial: widget.esHistorial,
                                badgeCount: widget.onCalcularAlertas(trabajo),
                                miId: widget.miId,
                                onTapTipado: widget.onTapTrabajo, 
                                onDelete: () => widget.onDeleteTrabajo(trabajo),
                              );
                            },
                          ),
                          
                          if (widget.trabajos.length > 2)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _mostrarTodo = !_mostrarTodo;
                                });
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                alignment: Alignment.center,
                                child: Text(
                                  _mostrarTodo ? 'Ver menos' : 'Ver más', 
                                  style: const TextStyle(
                                    color: ColoresApp.terciarioMorado, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 14
                                  )
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}