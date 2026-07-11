// lib/4_componentes_globales/busqueda/panel_busqueda_avanzada.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../formularios/campo_texto_cristal.dart';

class PanelBusquedaAvanzada extends StatefulWidget {
  final TextEditingController palabraClaveCtrl;
  final TextEditingController ciudadCtrl;
  final TextEditingController localidadCtrl;
  final String? categoriaSeleccionada;
  final VoidCallback onAbrirSelectorCategorias;
  final VoidCallback onBuscar; // Se ejecuta en vivo con cada tecla
  final VoidCallback onLimpiar;

  const PanelBusquedaAvanzada({
    Key? key,
    required this.palabraClaveCtrl,
    required this.ciudadCtrl,
    required this.localidadCtrl,
    this.categoriaSeleccionada,
    required this.onAbrirSelectorCategorias,
    required this.onBuscar,
    required this.onLimpiar,
  }) : super(key: key);

  @override
  State<PanelBusquedaAvanzada> createState() => _PanelBusquedaAvanzadaState();
}

class _PanelBusquedaAvanzadaState extends State<PanelBusquedaAvanzada> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Escuchamos cada tecla que el usuario presiona para filtrar en vivo
    widget.palabraClaveCtrl.addListener(_alCambiarTexto);
    widget.ciudadCtrl.addListener(_alCambiarTexto);
    widget.localidadCtrl.addListener(_alCambiarTexto);
  }

  @override
  void dispose() {
    widget.palabraClaveCtrl.removeListener(_alCambiarTexto);
    widget.ciudadCtrl.removeListener(_alCambiarTexto);
    widget.localidadCtrl.removeListener(_alCambiarTexto);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PanelBusquedaAvanzada oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoriaSeleccionada != widget.categoriaSeleccionada) {
      widget.onBuscar(); // Forzamos filtrado si selecciona categoría
    }
  }

  void _alCambiarTexto() {
    setState(() {}); // Prende o apaga el semáforo
    widget.onBuscar(); // Filtra la RAM
  }

  // 🚨 DETECTOR DE FILTROS: ¿Hay algo filtrando la pantalla?
  bool get _hasActiveFilters {
    return widget.palabraClaveCtrl.text.trim().isNotEmpty ||
           widget.ciudadCtrl.text.trim().isNotEmpty ||
           widget.localidadCtrl.text.trim().isNotEmpty ||
           (widget.categoriaSeleccionada != null && widget.categoriaSeleccionada!.isNotEmpty);
  }

  void _limpiarFiltros() {
    widget.onLimpiar(); 
    setState(() {
      _isExpanded = false; // Comprime al limpiar
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    // 🚨 GESTURE DETECTOR: Si desliza hacia arriba, se comprime
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Detecta el swipe hacia arriba (delta negativo)
        if (details.primaryDelta != null && details.primaryDelta! < -3) {
          if (_isExpanded) {
            FocusScope.of(context).unfocus(); // Oculta el teclado
            setState(() => _isExpanded = false); // Comprime el panel
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tema.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BARRA SUPERIOR (Siempre visible)
            Row(
              children: [
                Expanded(
                  child: CampoTextoCristal(
                    controller: widget.palabraClaveCtrl,
                    hintText: 'Buscar...',
                    iconoPrefijo: Icons.search_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                
                // 🚨 BOTÓN DE FILTROS INTUITIVO (Renglones)
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus(); 
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // Fondo siempre blanco o su variante oscura
                      color: esOscuro ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        // Borde sutilmente verde si está activo para acompañar al ícono
                        color: _hasActiveFilters 
                            ? ColoresApp.primarioVerde.withOpacity(0.5) 
                            : (esOscuro ? Colors.white24 : Colors.grey.shade300)
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded, // Logo de los renglones (Filtros)
                      // 🚨 El ícono se pinta de verde si hay filtros activos
                      color: _hasActiveFilters ? ColoresApp.primarioVerde : tema.iconTheme.color
                    ),
                  ),
                ),
              ],
            ),
            
            // 2. ÁREA EXPANDIBLE (Filtros Avanzados)
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Container(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CampoTextoCristal(
                            controller: widget.ciudadCtrl,
                            hintText: 'Ciudad',
                            iconoPrefijo: Icons.location_city_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoTextoCristal(
                            controller: widget.localidadCtrl,
                            hintText: 'Localidad',
                            iconoPrefijo: Icons.map_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: widget.onAbrirSelectorCategorias,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: esOscuro ? Colors.black.withOpacity(0.5) : tema.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: esOscuro ? Colors.white24 : Colors.black12)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.categoriaSeleccionada != null && widget.categoriaSeleccionada!.isNotEmpty 
                                  ? widget.categoriaSeleccionada! 
                                  : 'Seleccionar Categoría',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.categoriaSeleccionada != null && widget.categoriaSeleccionada!.isNotEmpty 
                                    ? tema.colorScheme.onSurface 
                                    : (esOscuro ? Colors.white38 : Colors.black38)
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: esOscuro ? Colors.white54 : Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // BOTÓN LIMPIAR
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _limpiarFiltros,
                        icon: const Icon(Icons.cleaning_services_rounded, color: Colors.grey, size: 18),
                        label: const Text('Limpiar filtros', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      ),
                    )
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}