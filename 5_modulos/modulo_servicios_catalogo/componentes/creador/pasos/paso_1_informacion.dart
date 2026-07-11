// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/pasos/paso_1_informacion.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'dart:io';
import '../../../../../2_tema/colores_app.dart'; 
import '../../../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../../../4_componentes_globales/formularios/selector_categoria_inteligente.dart';
import '../../../../../4_componentes_globales/formularios/selector_desplegable_cristal.dart'; 
import '../../../../../4_componentes_globales/modales_y_alertas/bottom_sheet_provincias.dart'; 
import '../../../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../controladores/controlador_creador_servicio.dart';
import '../tarjeta_seleccion_modalidad.dart';
import '../../../../modulo_publicaciones/componentes/seccion_direccion_maps.dart';

class Paso1Informacion extends StatelessWidget {
  final ControladorCreadorServicio controlador;

  const Paso1Informacion({Key? key, required this.controlador}) : super(key: key);

  void _mostrarSelectorEtiquetas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: controlador,
          builder: (context, child) {
            final tema = Theme.of(context);
            return Container(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Etiquetas de Confianza', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${controlador.etiquetasConfianzaSeleccionadas.length}/3 seleccionadas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controlador.etiquetasConfianzaSeleccionadas.length == 3 ? ColoresApp.primarioVerde : Colors.grey.shade600
                    )
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: controlador.opcionesEtiquetasConfianza.length,
                      itemBuilder: (context, index) {
                        final etiqueta = controlador.opcionesEtiquetasConfianza[index];
                        final isSelected = controlador.etiquetasConfianzaSeleccionadas.contains(etiqueta);
                        
                        return CheckboxListTile(
                          title: Text(
                            etiqueta, 
                            style: TextStyle(
                              fontSize: 15, 
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? (tema.brightness == Brightness.dark ? Colors.white : Colors.black87) : Colors.grey.shade600
                            )
                          ),
                          value: isSelected,
                          activeColor: ColoresApp.primarioVerde,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? val) {
                            if (val == true && controlador.etiquetasConfianzaSeleccionadas.length >= 3) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Solo puedes elegir 3 etiquetas máximo.'), duration: Duration(seconds: 2))
                              );
                              return;
                            }
                            controlador.toggleEtiquetaConfianza(etiqueta);
                          },
                        );
                      },
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: BotonAccionPrincipal(
                        texto: 'Confirmar selección',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _mostrarEditorZona(BuildContext context) {
    controlador.prepararEditorZona(); 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu Cobertura a Domicilio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('La localidad es opcional. Déjala en blanco si ofreces cobertura en toda la provincia.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              
              ListenableBuilder(
                listenable: controlador,
                builder: (context, child) {
                  return Column(
                    children: [
                      SelectorDesplegableCristal(
                        hintText: 'Provincia *',
                        valorSeleccionado: controlador.provinciaSeleccionada,
                        iconoPrefix: Icons.map_rounded,
                        colorActivo: Theme.of(context).colorScheme.primary,
                        onTap: () {
                          BottomSheetProvincias.mostrar(
                            context,
                            provinciaActual: controlador.provinciaSeleccionada,
                            colorActivo: Theme.of(context).colorScheme.primary,
                            onProvinciaSeleccionada: controlador.setProvincia,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      CampoTextoCristal(
                        controller: controlador.localidadCtrl, 
                        hintText: 'Localidad / Ciudad (Opcional)', 
                        iconoPrefix: Icons.location_city_rounded
                      ),
                    ],
                  );
                }
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: BotonAccionPrincipal(
                  texto: 'Guardar Zona',
                  onPressed: () {
                    // 🛡️ Actualiza la vista en vivo al tocar guardar
                    controlador.guardarEditorZona();
                    Navigator.pop(ctx);
                  },
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  Widget _buildFoto(int globalIndex) {
    final bool isExistente = globalIndex < controlador.fotosExistentesUrls.length;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isExistente
              ? CachedNetworkImage(imageUrl: controlador.fotosExistentesUrls[globalIndex], fit: BoxFit.cover)
              : Image.file(controlador.fotosSeleccionadas[globalIndex - controlador.fotosExistentesUrls.length], fit: BoxFit.cover),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () {
              if (isExistente) {
                controlador.eliminarFotoExistente(globalIndex);
              } else {
                controlador.eliminarFotoLocal(globalIndex - controlador.fotosExistentesUrls.length);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorAcento = tema.colorScheme.primary;
    final int totalFotos = controlador.fotosExistentesUrls.length + controlador.fotosSeleccionadas.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IgnorePointer(
            ignoring: controlador.modoLectura,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fotos / portada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('La primera imagen será la portada de tu servicio.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: totalFotos > 0
                          ? SizedBox(height: 140, child: _buildFoto(0))
                          : _BotonAgregarFoto(onTap: controlador.seleccionarFotos, colorAcento: colorAcento, limiteFotos: controlador.limiteFotos),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: totalFotos > 1
                          ? SizedBox(height: 140, child: _buildFoto(1))
                          : (totalFotos == 1 ? _BotonAgregarFoto(onTap: controlador.seleccionarFotos, colorAcento: colorAcento, limiteFotos: controlador.limiteFotos) : const SizedBox.shrink()),
                    ),
                  ],
                ),
                
                if (totalFotos > 2) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (totalFotos - 2) + (totalFotos < controlador.limiteFotos ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == (totalFotos - 2)) {
                          return Container(width: 80, margin: const EdgeInsets.only(right: 8), child: _BotonAgregarFoto(onTap: controlador.seleccionarFotos, colorAcento: colorAcento, limiteFotos: controlador.limiteFotos));
                        }
                        return Container(width: 80, margin: const EdgeInsets.only(right: 8), child: _buildFoto(index + 2));
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                const Text('Categoría Global', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SelectorCategoriaInteligente(
                  valorInicial: controlador.categoriaSeleccionada,
                  onSeleccionado: controlador.cambiarCategoria,
                  hintText: 'Ej. Limpieza, Reparación de PC...',
                ),

                const SizedBox(height: 24),

                const Text('Título', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CampoTextoCristal(controller: controlador.tituloController, hintText: 'Ej: Lavado de auto a domicilio'),

                const SizedBox(height: 24),

                const Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                        child: Row(
                          children: [
                            IconButton(icon: const Icon(Icons.format_bold, size: 20), onPressed: () => controlador.inyectarFormatoDescripcion('**', '**'), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            const SizedBox(width: 16),
                            IconButton(icon: const Icon(Icons.format_italic, size: 20), onPressed: () => controlador.inyectarFormatoDescripcion('*', '*'), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            const SizedBox(width: 16),
                            IconButton(icon: const Icon(Icons.format_list_bulleted, size: 20), onPressed: () => controlador.inyectarFormatoDescripcion('\n- ', ''), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            const SizedBox(width: 16),
                            IconButton(icon: const Icon(Icons.format_list_numbered, size: 20), onPressed: () => controlador.inyectarFormatoDescripcion('\n1. ', ''), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: controlador.descripcionController,
                          maxLines: 4,
                          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Dejamos tu auto impecable sin que tengas que moverte...'),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 12, bottom: 8),
                        child: Text('${controlador.descripcionController.text.length}/1000', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Etiquetas de Confianza', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${controlador.etiquetasConfianzaSeleccionadas.length}/3', 
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: controlador.etiquetasConfianzaSeleccionadas.length == 3 ? ColoresApp.primarioVerde : Colors.grey.shade600
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Elige exactamente 3 para destacar tu servicio en el catálogo.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: () => _mostrarSelectorEtiquetas(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            controlador.etiquetasConfianzaSeleccionadas.isEmpty 
                                ? 'Seleccioná 3 etiquetas...' 
                                : controlador.etiquetasConfianzaSeleccionadas.join(', '), 
                            style: TextStyle(
                              fontSize: 14, 
                              color: controlador.etiquetasConfianzaSeleccionadas.isEmpty ? Colors.grey : (tema.brightness == Brightness.dark ? Colors.white : Colors.black87)
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          )
                        ), 
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey)
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text('Modalidad y ubicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Modalidad del servicio', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TarjetaSeleccionModalidad(
                        titulo: 'A domicilio', subtitulo: 'Voy hasta donde estés', icono: Icons.home_outlined,
                        seleccionada: controlador.modalidadSeleccionada == 'a_domicilio',
                        onTap: () => controlador.cambiarModalidad('a_domicilio'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TarjetaSeleccionModalidad(
                        titulo: 'En local', subtitulo: 'Atendemos en nuestro local', icono: Icons.storefront_outlined,
                        seleccionada: controlador.modalidadSeleccionada == 'en_local',
                        onTap: () => controlador.cambiarModalidad('en_local'),
                      ),
                    ),
                  ],
                ),

                if (controlador.modalidadSeleccionada == 'a_domicilio') ...[
                  const SizedBox(height: 24),
                  const Text('Zona de cobertura', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            // 🛡️ ACTUALIZACIÓN DINÁMICA PERFECTA
                            controlador.provinciaSeleccionada == null 
                                ? 'No configurada (Toca Editar)' 
                                : (controlador.localidadCtrl.text.trim().isEmpty 
                                    ? 'Toda la provincia de ${controlador.provinciaSeleccionada}' 
                                    : 'Cobertura en localidad de ${controlador.localidadCtrl.text.trim()}, ${controlador.provinciaSeleccionada}'), 
                            style: TextStyle(fontWeight: FontWeight.w500, color: controlador.provinciaSeleccionada == null ? Colors.red : null)
                          )
                        ),
                        GestureDetector(
                          onTap: () => _mostrarEditorZona(context), 
                          child: Text('Editar', style: TextStyle(color: colorAcento, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  const Text('Dirección de tu local', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  
                  SeccionDireccionMaps(
                    calleCtrl: controlador.calleCtrl,
                    numeroCtrl: controlador.numeroCtrl,
                    provinciaSeleccionada: controlador.provinciaSeleccionada,
                    onProvinciaChanged: controlador.setProvincia,
                    localidadCtrl: controlador.localidadCtrl,
                    barrioCtrl: controlador.barrioCtrl,
                    paisCtrl: controlador.paisCtrl,
                  ),
                  const SizedBox(height: 16),
                  const Text('Detalles o referencias (Opcional)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  CampoTextoCristal(
                    controller: controlador.referenciaLocalCtrl,
                    hintText: 'Ej: Portón negro, tocar timbre fuerte...',
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ), 

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: BotonAccionPrincipal(
              texto: 'Continuar',
              onPressed: () {
                if (controlador.modoLectura) {
                  controlador.siguientePaso();
                } else {
                  controlador.validarPaso1((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: ColoresApp.errorRojo));
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _BotonAgregarFoto extends StatelessWidget {
  final VoidCallback onTap; 
  final Color colorAcento;
  final int limiteFotos;

  const _BotonAgregarFoto({required this.onTap, required this.colorAcento, required this.limiteFotos});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text('Agregar fotos', style: TextStyle(color: colorAcento, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Máx. $limiteFotos fotos', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}