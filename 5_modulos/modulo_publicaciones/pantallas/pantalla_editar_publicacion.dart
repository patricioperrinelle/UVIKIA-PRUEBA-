// lib/5_modulos/modulo_publicaciones/pantallas/pantalla_editar_publicacion.dart

import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';

import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/selector_dificultad_nivel.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/formularios/selector_fecha_hora.dart';
import '../../../4_componentes_globales/formularios/selector_categoria_inteligente.dart'; // 🛡️ IMPORTADO

import '../controladores/controlador_publicacion.dart';
import '../componentes/seccion_carga_imagenes.dart';
import '../componentes/seccion_direccion_maps.dart';
import '../componentes/seccion_requisitos_herramientas.dart';

class PantallaEditarPublicacion extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const PantallaEditarPublicacion({Key? key, required this.jobData}) : super(key: key);

  @override
  State<PantallaEditarPublicacion> createState() => _PantallaEditarPublicacionState();
}

class _PantallaEditarPublicacionState extends State<PantallaEditarPublicacion> {
  final ControladorPublicacion _controlador = ControladorPublicacion();

  @override
  void initState() {
    super.initState();
    _controlador.precargarDatosEdicion(widget.jobData);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esJornada = widget.jobData['dificultad'] == 'jornada';
    
    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: ColoresApp.fondoPrincipal,
            appBar: AppBar(
              title: const Text('Editar Oferta', style: EstilosTextoApp.h3),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              bottom: true,
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) {
                  if (notification.dragDetails != null && notification.scrollDelta != null && notification.scrollDelta! < -2.0) {
                    final currentFocus = FocusManager.instance.primaryFocus;
                    if (currentFocus != null && currentFocus.hasFocus) {
                      currentFocus.unfocus();
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    const Text('Título del trabajo', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.tituloCtrl, hintText: 'Ej. Cortar el pasto del jardín', maxLength: 60),
                    const SizedBox(height: 16),

                    // 🛡️ REGLA DATA INTEGRITY: Categoría en Edición
                    const Text('Categoría Global', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    SelectorCategoriaInteligente(
                      valorInicial: _controlador.categoriaSeleccionada,
                      onSeleccionado: _controlador.setCategoria,
                    ),
                    const SizedBox(height: 16),

                    const Text('Oficio Requerido', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.oficioCtrl, hintText: 'Ej. Electricista, Plomero...', maxLength: 40),
                    const SizedBox(height: 24),

                    if (!esJornada) ...[
                      const Text('Dificultad del trabajo', style: EstilosTextoApp.cuerpoDestacado),
                      const SizedBox(height: 8),
                      SelectorDificultadNivel(nivelSeleccionado: _controlador.dificultad, onChanged: _controlador.setDificultad),
                      const SizedBox(height: 24),
                    ],

                    const Text('Fotos del área de trabajo (hasta 5)', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 12),
                    SeccionCargaImagenes(
                      imagenes: _controlador.imagenes,
                      onAgregar: (source) => _controlador.agregarImagenes(context, source),
                      onEliminar: _controlador.eliminarImagen,
                    ),
                    const SizedBox(height: 24),

                    const Text('Descripción detallada', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.descCtrl, hintText: 'Describe el trabajo a realizar...', minLines: 3, maxLines: 6, maxLength: 500, textInputAction: TextInputAction.newline),
                    const SizedBox(height: 24),

                    const Text('Herramientas / Requisitos', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    SeccionRequisitosHerramientas(
                      traerHerramientas: _controlador.traerHerramientas, herramientasCtrl: _controlador.herramientasCtrl, onChanged: _controlador.toggleHerramientas,
                    ),
                    const SizedBox(height: 24),

                    const Text('Dirección exacta del trabajo', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    
                    // 🛡️ REGLA DATA INTEGRITY: Conexión Geográfica
                    SeccionDireccionMaps(
                      calleCtrl: _controlador.calleCtrl, 
                      numeroCtrl: _controlador.numeroCtrl,
                      provinciaSeleccionada: _controlador.provinciaSeleccionada, 
                      onProvinciaChanged: _controlador.setProvincia, 
                      localidadCtrl: _controlador.localidadCtrl,
                      barrioCtrl: _controlador.barrioCtrl,
                      paisCtrl: _controlador.paisCtrl,
                    ),
                    const SizedBox(height: 24),

                    const Text('Contacto de WhatsApp', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.whatsappCtrl, hintText: 'Ej. +54 9 11 1234-5678', iconoPrefix: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),

                    const Text('¿Cuándo lo necesitás?', style: EstilosTextoApp.cuerpoDestacado),
                    const SizedBox(height: 8),
                    SelectorFechaHora(
                      fechaSeleccionada: _controlador.fechaElegida, horaSeleccionada: _controlador.horaElegida,
                      onFechaChanged: (f) => _controlador.setFechaHora(f, null), onHoraChanged: (h) => _controlador.setFechaHora(null, h),
                    ),
                    const SizedBox(height: 40),

                    BotonAccionPrincipal(
                      texto: 'GUARDAR CAMBIOS',
                      isLoading: _controlador.isSubmitting,
                      onPressed: () => _controlador.publicarTrabajo(context, esJornada: esJornada),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        );
      }
    );
  }
}