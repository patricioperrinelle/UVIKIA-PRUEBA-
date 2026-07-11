// lib/4_componentes_globales/busqueda/cabecera_filtros_activos.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class CabeceraFiltrosActivos extends StatelessWidget {
  final String palabraClave;
  final String provincia;
  final String localidad;
  final String categoria;

  final VoidCallback onTapAbrirModal;
  final VoidCallback onLimpiarPalabraClave;
  final VoidCallback onLimpiarProvincia;
  final VoidCallback onLimpiarLocalidad;
  final VoidCallback onLimpiarCategoria;

  const CabeceraFiltrosActivos({
    Key? key,
    required this.palabraClave,
    required this.provincia,
    required this.localidad,
    required this.categoria,
    required this.onTapAbrirModal,
    required this.onLimpiarPalabraClave,
    required this.onLimpiarProvincia,
    required this.onLimpiarLocalidad,
    required this.onLimpiarCategoria,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hayChips = provincia.isNotEmpty || localidad.isNotEmpty || categoria.isNotEmpty;
    final bool hayPalabra = palabraClave.isNotEmpty;

    // 🛡️ Invisibilidad Condicional Absoluta
    if (!hayPalabra && !hayChips) return const SizedBox.shrink();

    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // 1. LA FALSA BARRA DE BÚSQUEDA (Mantiene su diseño Squircle)
          if (hayPalabra) ...[
            GestureDetector(
              onTap: onTapAbrirModal, // Tocar la barra re-abre el modal inmersivo
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
                decoration: BoxDecoration(
                  color: esOscuro ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: esOscuro ? Colors.white24 : Colors.black12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: tema.colorScheme.onSurface, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        palabraClave,
                        style: TextStyle(
                          color: tema.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                      onPressed: onLimpiarPalabraClave, 
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (hayChips) const SizedBox(height: 16),
          ],

          // 2. EL ROW DE FILTROS ALINEADOS (Diseño Minimalista Desnudo)
          if (hayChips) _construirFilaFiltros(),
        ],
      ),
    );
  }

  Widget _construirFilaFiltros() {
    List<Widget> filtros = [];

    if (provincia.isNotEmpty) {
      filtros.add(
        Expanded(
          child: _ChipFiltro(
            texto: provincia,
            icono: Icons.location_on_rounded,
            colorIcono: ColoresApp.errorRojo,
            onEliminar: onLimpiarProvincia,
          ),
        ),
      );
    }
    if (localidad.isNotEmpty) {
      filtros.add(
        Expanded(
          child: _ChipFiltro(
            texto: localidad,
            icono: Icons.map_rounded,
            colorIcono: ColoresApp.infoAzul,
            onEliminar: onLimpiarLocalidad,
          ),
        ),
      );
    }
    if (categoria.isNotEmpty) {
      filtros.add(
        Expanded(
          child: _ChipFiltro(
            texto: categoria,
            icono: Icons.label_outline_rounded,
            colorIcono: ColoresApp.terciarioMorado,
            onEliminar: onLimpiarCategoria,
          ),
        ),
      );
    }

    // Inyectar espaciadores dinámicos entre los Expanded
    List<Widget> rowChildren = [];
    for (int i = 0; i < filtros.length; i++) {
      rowChildren.add(filtros[i]);
      if (i < filtros.length - 1) {
        rowChildren.add(const SizedBox(width: 12));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rowChildren,
    );
  }
}

// ----------------------------------------------------------------------
// SUB-WIDGET PRIVADO: Filtro Desnudo (Cero Background/Bordes)
// ----------------------------------------------------------------------
class _ChipFiltro extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color colorIcono;
  final VoidCallback onEliminar;

  const _ChipFiltro({
    required this.texto,
    required this.icono,
    required this.colorIcono,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icono, size: 16, color: colorIcono),
        const SizedBox(width: 6),
        // 🛡️ PROTECCIÓN ANTI-OVERFLOW: Flexible asegura el recorte si el string es muy largo
        Flexible(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: tema.colorScheme.onSurface, // Color principal del tema
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onEliminar,
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}