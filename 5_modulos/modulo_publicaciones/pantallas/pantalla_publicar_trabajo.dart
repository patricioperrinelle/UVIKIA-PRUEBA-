// lib/5_modulos/modulo_publicaciones/pantallas/pantalla_publicar_trabajo.dart

import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';

import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/selector_dificultad_nivel.dart';
import '../../../4_componentes_globales/formularios/selector_fecha_hora.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/formularios/selector_categoria_inteligente.dart'; 

import '../controladores/controlador_publicacion.dart';
import '../componentes/seccion_carga_imagenes.dart';
import '../componentes/seccion_direccion_maps.dart';
import '../componentes/seccion_requisitos_herramientas.dart';

class PantallaPublicarTrabajo extends StatefulWidget {
  const PantallaPublicarTrabajo({Key? key}) : super(key: key);

  @override
  State<PantallaPublicarTrabajo> createState() => _PantallaPublicarTrabajoState();
}

class _PantallaPublicarTrabajoState extends State<PantallaPublicarTrabajo> {
  final ControladorPublicacion _controlador = ControladorPublicacion();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: tema.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Publicar Oferta', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface),
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
                    Text('Título del trabajo', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.tituloCtrl, hintText: 'Ej. Cortar el pasto del jardín trasero', maxLength: 60),
                    const SizedBox(height: 16),

                    Text('Categoría Global', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorCategoriaInteligente(
                      valorInicial: _controlador.categoriaSeleccionada,
                      onSeleccionado: _controlador.setCategoria,
                    ),
                    const SizedBox(height: 16),

                    Text('Oficio Específico Requerido', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.oficioCtrl, hintText: 'Ej. Electricista, Plomero, Albañil...', maxLength: 40),
                    const SizedBox(height: 24),

                    Text('Dificultad del trabajo', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorDificultadNivel(
                      nivelSeleccionado: _controlador.dificultad,
                      onChanged: _controlador.setDificultad,
                    ),
                    const SizedBox(height: 24),

                    Text('Fotos del área de trabajo (hasta 5)', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    SeccionCargaImagenes(
                      imagenes: _controlador.imagenes,
                      onAgregar: (source) => _controlador.agregarImagenes(context, source),
                      onEliminar: _controlador.eliminarImagen,
                    ),
                    const SizedBox(height: 24),

                    Text('Descripción detallada', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(
                      controller: _controlador.descCtrl, 
                      hintText: 'Ej. Necesito cambiar los cables de la cocina...', 
                      minLines: 3, 
                      maxLines: null,
                      maxLength: 500,
                      keyboardType: TextInputType.multiline, 
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 24),

                    Text('Herramientas', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SeccionRequisitosHerramientas(
                      traerHerramientas: _controlador.traerHerramientas,
                      herramientasCtrl: _controlador.herramientasCtrl,
                      onChanged: _controlador.toggleHerramientas,
                    ),
                    const SizedBox(height: 24),

                    Text('Dirección exacta del trabajo', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SeccionDireccionMaps(
                      calleCtrl: _controlador.calleCtrl,
                      numeroCtrl: _controlador.numeroCtrl,
                      
                      // 🛡️ REGLA DATA INTEGRITY (Cables Conectados)
                      provinciaSeleccionada: _controlador.provinciaSeleccionada,
                      onProvinciaChanged: _controlador.setProvincia,
                      
                      localidadCtrl: _controlador.localidadCtrl,
                      barrioCtrl: _controlador.barrioCtrl,
                      paisCtrl: _controlador.paisCtrl,
                    ),
                    const SizedBox(height: 16),
                    Text('Referencias del lugar (Opcional)', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(
                      controller: _controlador.referenciaCtrl,
                      hintText: 'Ej: Portón negro, timbre no funciona, perro bravo...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    Text('Contacto de WhatsApp', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: tema.brightness == Brightness.dark ? Colors.black.withOpacity(0.5) : tema.inputDecorationTheme.fillColor, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: tema.brightness == Brightness.dark ? Colors.white24 : Colors.black12)
                      ),
                      child: TextField(
                        controller: _controlador.whatsappCtrl, keyboardType: TextInputType.phone, style: TextStyle(color: tema.colorScheme.onSurface),
                        decoration: InputDecoration(
                          filled: false, hintText: 'Ej. +54 9 11 1234-5678', hintStyle: TextStyle(color: tema.brightness == Brightness.dark ? Colors.white38 : Colors.black38),
                          prefixIcon: Icon(Icons.phone_android_rounded, color: tema.brightness == Brightness.dark ? Colors.white54 : Colors.black54),
                          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 4, bottom: 24),
                      child: Text('🔒 Tu número se mantendrá oculto. Solo se revelará al profesional confirmado.', style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 12, fontStyle: FontStyle.italic)),
                    ),

                    Text('¿Cuándo lo necesitás?', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorFechaHora(
                      fechaSeleccionada: _controlador.fechaElegida,
                      horaSeleccionada: _controlador.horaElegida,
                      onFechaChanged: (f) => _controlador.setFechaHora(f, null),
                      onHoraChanged: (h) => _controlador.setFechaHora(null, h),
                    ),
                    const SizedBox(height: 40),

                    BotonAccionPrincipal(
                      texto: 'PUBLICAR OFERTA',
                      isLoading: _controlador.isSubmitting,
                      onPressed: () => _controlador.publicarTrabajo(context, esJornada: false),
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