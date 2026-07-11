// lib/4_componentes_globales/formularios/selector_categoria_inteligente.dart

import 'package:flutter/material.dart';
import '../../1_nucleo/utilidades/constantes_categorias.dart';
import '../../2_tema/colores_app.dart';

class SelectorCategoriaInteligente extends StatefulWidget {
  final String valorInicial;
  final Function(String) onSeleccionado;
  final String hintText;

  const SelectorCategoriaInteligente({
    Key? key,
    required this.valorInicial,
    required this.onSeleccionado,
    this.hintText = 'Seleccionar categoría...',
  }) : super(key: key);

  @override
  State<SelectorCategoriaInteligente> createState() => _SelectorCategoriaInteligenteState();
}

class _SelectorCategoriaInteligenteState extends State<SelectorCategoriaInteligente> {
  
  void _abrirModalCategorias(BuildContext context) {
    // Escondemos el teclado general por si venía de escribir otra cosa
    FocusScope.of(context).unfocus(); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ModalBuscadorCategorias(
          categoriaActual: widget.valorInicial,
          onSeleccionado: (categoriaElegida) {
            widget.onSeleccionado(categoriaElegida);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tieneValor = widget.valorInicial.isNotEmpty;

    return GestureDetector(
      onTap: () => _abrirModalCategorias(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: tema.brightness == Brightness.dark ? Colors.black.withOpacity(0.5) : tema.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tema.brightness == Brightness.dark ? Colors.white24 : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.category_rounded, color: tema.brightness == Brightness.dark ? Colors.white54 : Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tieneValor ? widget.valorInicial : widget.hintText,
                      style: TextStyle(
                        color: tieneValor ? tema.colorScheme.onSurface : (tema.brightness == Brightness.dark ? Colors.white38 : Colors.black38),
                        fontSize: 16,
                        fontWeight: tieneValor ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET INTERNO: EL MODAL CON EL BUSCADOR PURO (Cero escritura en Base de Datos)
// ----------------------------------------------------------------------
class _ModalBuscadorCategorias extends StatefulWidget {
  final String categoriaActual;
  final Function(String) onSeleccionado;

  const _ModalBuscadorCategorias({
    required this.categoriaActual,
    required this.onSeleccionado,
  });

  @override
  State<_ModalBuscadorCategorias> createState() => _ModalBuscadorCategoriasState();
}

class _ModalBuscadorCategoriasState extends State<_ModalBuscadorCategorias> {
  String filtroVisual = '';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    // Filtramos la lista oficial del núcleo basándonos en lo que escribe
    final listaFiltrada = ConstantesCategorias.categoriasGlobales
        .where((c) => c.toLowerCase().contains(filtroVisual.toLowerCase()))
        .toList();

    // MediaQuery para que el modal ocupe un buen espacio y soporte el teclado
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Selecciona una Categoría', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          
          // Buscador Visual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: tema.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (val) => setState(() => filtroVisual = val),
                decoration: const InputDecoration(
                  hintText: 'Buscar en la lista...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // La Lista Estricta
          Expanded(
            child: listaFiltrada.isEmpty
                ? const Center(
                    child: Text('No se encontraron categorías.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final categoria = listaFiltrada[index];
                      final isSelected = categoria == widget.categoriaActual;
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? ColoresApp.primarioVerde : Colors.grey,
                        ),
                        title: Text(
                          categoria,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? ColoresApp.primarioVerde : tema.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () => widget.onSeleccionado(categoria), // 🚨 AQUÍ ESTÁ EL CANDADO: Solo se envía tocando
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}