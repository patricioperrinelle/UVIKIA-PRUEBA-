// lib/5_modulos/modulo_explorar_feed/pantallas/pantalla_categorias_oficios.dart

import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../componentes/tarjeta_categoria_oficio.dart';

import 'pantalla_feed_profesionales.dart';

class PantallaCategoriasOficios extends StatefulWidget {
  const PantallaCategoriasOficios({Key? key}) : super(key: key);

  @override
  State<PantallaCategoriasOficios> createState() => _PantallaCategoriasOficiosState();
}

class _PantallaCategoriasOficiosState extends State<PantallaCategoriasOficios> {
  final TextEditingController _busquedaController = TextEditingController();
  
  final List<Map<String, dynamic>> _todasCategorias =[
    {'nombre': 'Electricista', 'icono': Icons.electrical_services},
    {'nombre': 'Plomero', 'icono': Icons.plumbing},
    {'nombre': 'Jardinero', 'icono': Icons.yard},
    {'nombre': 'Albañil', 'icono': Icons.construction},
    {'nombre': 'Limpieza', 'icono': Icons.cleaning_services},
    {'nombre': 'Pintor', 'icono': Icons.format_paint},
  ];

  List<Map<String, dynamic>> _categoriasFiltradas =[];

  @override
  void initState() {
    super.initState();
    _categoriasFiltradas = _todasCategorias;
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _filtrarBusqueda(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _categoriasFiltradas = _todasCategorias;
      } else {
        _categoriasFiltradas = _todasCategorias
            .where((cat) => cat['nombre'].toString().toLowerCase().contains(texto.toLowerCase()))
            .toList();
      }
    });
  }

  void _navegarADirectorio(String categoria) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => const PantallaFeedProfesionales(),
        settings: RouteSettings(arguments: categoria), 
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); // 🚨 Leemos el tema

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: tema.scaffoldBackgroundColor, // 🚨 Fondo dinámico
        appBar: AppBar(
          title: Text('¿Qué necesitas?', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)), // 🚨 Texto dinámico
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface), // 🚨 Icono dinámico
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children:[
                const SizedBox(height: 10),
                CampoTextoCristal(
                  controller: _busquedaController,
                  hintText: 'Escribe un oficio...',
                  iconoPrefix: Icons.search,
                  onChanged: _filtrarBusqueda,
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _categoriasFiltradas.isEmpty
                      ? Center(
                          child: GestureDetector(
                            onTap: () => _navegarADirectorio('Otros oficios'),
                            child: ClipRRect(
                              borderRadius: DimensionesApp.radioModales,
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    // 🚨 Adaptamos el fondo cyan transparente según si es claro o oscuro
                                    color: tema.brightness == Brightness.dark 
                                        ? ColoresApp.secundarioCyan.withOpacity(0.08)
                                        : ColoresApp.secundarioCyan.withOpacity(0.15),
                                    borderRadius: DimensionesApp.radioModales,
                                    border: Border.all(color: ColoresApp.secundarioCyan, width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:[
                                      const Icon(Icons.search_off_rounded, size: 56, color: ColoresApp.secundarioCyan),
                                      const SizedBox(height: 16),
                                      Text('Otros oficios', textAlign: TextAlign.center, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text('Toque aquí para explorar profesionales en general', textAlign: TextAlign.center, style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _categoriasFiltradas.length,
                          itemBuilder: (context, index) {
                            final cat = _categoriasFiltradas[index];
                            return TarjetaCategoriaOficio(
                              nombre: cat['nombre'],
                              icono: cat['icono'],
                              onTap: () => _navegarADirectorio(cat['nombre']),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}