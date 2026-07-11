// lib/4_componentes_globales/busqueda/modal_busqueda_inmersiva.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../formularios/campo_texto_cristal.dart';
import '../formularios/selector_desplegable_cristal.dart';
import '../formularios/selector_categoria_inteligente.dart';
import '../modales_y_alertas/bottom_sheet_provincias.dart';

class ModalBusquedaInmersiva extends StatefulWidget {
  final String palabraClaveInicial;
  final String provinciaInicial;
  final String localidadInicial;
  final String categoriaInicial;

  const ModalBusquedaInmersiva({
    Key? key,
    required this.palabraClaveInicial,
    required this.provinciaInicial,
    required this.localidadInicial,
    required this.categoriaInicial,
  }) : super(key: key);

  /// Método estático (Factory) para invocar el Modal de forma limpia desde los Controladores/Vistas
  static Future<Map<String, String>?> mostrar({
    required BuildContext context,
    required String palabraClaveInicial,
    required String provinciaInicial,
    required String localidadInicial,
    required String categoriaInicial,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true, // Permite pantalla completa
      backgroundColor: Colors.transparent, // Fondo transparente para el diseño Premium
      builder: (ctx) => Padding(
        // Empuja el modal si el teclado está abierto
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ModalBusquedaInmersiva(
          palabraClaveInicial: palabraClaveInicial,
          provinciaInicial: provinciaInicial,
          localidadInicial: localidadInicial,
          categoriaInicial: categoriaInicial,
        ),
      ),
    );
  }

  @override
  State<ModalBusquedaInmersiva> createState() => _ModalBusquedaInmersivaState();
}

class _ModalBusquedaInmersivaState extends State<ModalBusquedaInmersiva> {
  // Estados aislados en RAM (No afectan al Feed hasta que se presiona Aplicar)
  late TextEditingController _palabraClaveCtrl;
  late TextEditingController _localidadCtrl;
  String _provinciaSeleccionada = '';
  String _categoriaSeleccionada = '';

  @override
  void initState() {
    super.initState();
    _palabraClaveCtrl = TextEditingController(text: widget.palabraClaveInicial);
    _localidadCtrl = TextEditingController(text: widget.localidadInicial);
    _provinciaSeleccionada = widget.provinciaInicial;
    _categoriaSeleccionada = widget.categoriaInicial;
  }

  @override
  void dispose() {
    _palabraClaveCtrl.dispose();
    _localidadCtrl.dispose();
    super.dispose();
  }

  void _limpiarFiltros() {
    setState(() {
      _palabraClaveCtrl.clear();
      _localidadCtrl.clear();
      _provinciaSeleccionada = '';
      _categoriaSeleccionada = '';
    });
  }

  void _aplicarFiltros() {
    FocusScope.of(context).unfocus(); // Oculta el teclado nativo

    // 🛡️ ESCUDO ANTI-DOS Y PROTECCIÓN DE CPU: Límite estricto de 10 palabras
    String keywords = _palabraClaveCtrl.text.trim();
    if (keywords.isNotEmpty) {
      List<String> words = keywords.split(RegExp(r'\s+'));
      if (words.length > 10) {
        keywords = words.take(10).join(' '); // Trunca el exceso sin crashear
      }
    }

    // Retornamos el paquete cerrado al controlador padre
    Navigator.pop(context, {
      'palabraClave': keywords,
      'provincia': _provinciaSeleccionada,
      'localidad': _localidadCtrl.text.trim(),
      'categoria': _categoriaSeleccionada,
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.92, // Modo Inmersivo (92% de la pantalla)
      child: Container(
        decoration: BoxDecoration(
          color: tema.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag Handle (Barrita superior)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: esOscuro ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header del Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtros de Búsqueda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface)),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tema.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context), // Cierra sin aplicar
                  ),
                ],
              ),
            ),
            const Divider(),

            // Cuerpo Scrolleable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PALABRAS CLAVES ---
                    Text('¿Qué estás buscando?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tema.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(
                      controller: _palabraClaveCtrl,
                      hintText: 'Ej. Peluquero, Limpieza, Caño roto...',
                      iconoPrefijo: Icons.search_rounded,
                    ),
                    const SizedBox(height: 24),

                    // --- CATEGORÍA ---
                    Text('Especialidad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tema.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 8),
                    // 🛡️ REUTILIZACIÓN ESTRICTA: Lego Oficial instanciado con los parámetros correctos
                    SelectorCategoriaInteligente(
                      valorInicial: _categoriaSeleccionada, // Obligatorio
                      hintText: 'Todas las categorías',
                      onSeleccionado: (categoria) {
                        setState(() {
                          _categoriaSeleccionada = categoria;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- UBICACIÓN GEOGRÁFICA ---
                    Text('Ubicación', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tema.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 8),
                    // 1. Selector Estricto de Provincia con callback validado
                    SelectorDesplegableCristal(
                      hintText: 'Provincia (Obligatorio)',
                      valorSeleccionado: _provinciaSeleccionada.isNotEmpty ? _provinciaSeleccionada : null,
                      iconoPrefix: Icons.map_rounded,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        BottomSheetProvincias.mostrar(
                          context,
                          provinciaActual: _provinciaSeleccionada.isNotEmpty ? _provinciaSeleccionada : null,
                          onProvinciaSeleccionada: (prov) {
                            setState(() {
                              _provinciaSeleccionada = prov;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // 2. Input Libre para Localidad/Ciudad
                    CampoTextoCristal(
                      controller: _localidadCtrl,
                      hintText: 'Ciudad o Localidad (Ej. Carlos Paz)',
                      iconoPrefijo: Icons.location_city_rounded,
                    ),
                  ],
                ),
              ),
            ),

            // Footer con Botones de Acción
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tema.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: tema.dividerColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: _limpiarFiltros,
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Limpiar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _aplicarFiltros,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresApp.primarioVerde,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}