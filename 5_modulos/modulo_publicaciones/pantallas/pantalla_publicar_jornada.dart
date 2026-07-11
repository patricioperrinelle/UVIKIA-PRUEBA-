// lib/5_modulos/modulo_publicaciones/pantallas/pantalla_publicar_jornada.dart

import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';

import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/formularios/selector_fecha_hora.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/formularios/selector_categoria_inteligente.dart'; 

import '../controladores/controlador_publicacion.dart';
import '../componentes/seccion_carga_imagenes.dart';
import '../componentes/seccion_direccion_maps.dart';
import '../componentes/seccion_requisitos_herramientas.dart';

class PantallaPublicarJornada extends StatefulWidget {
  const PantallaPublicarJornada({Key? key}) : super(key: key);

  @override
  State<PantallaPublicarJornada> createState() => _PantallaPublicarJornadaState();
}

class _PantallaPublicarJornadaState extends State<PantallaPublicarJornada> {
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
              title: Text('Publicar Jornada', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
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
                    Text('Título de la jornada / turno', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.tituloCtrl, hintText: 'Ej. Ayudante de cocina por 8 horas', maxLength: 60),
                    const SizedBox(height: 16),

                    Text('Categoría Global', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorCategoriaInteligente(
                      valorInicial: _controlador.categoriaSeleccionada,
                      onSeleccionado: _controlador.setCategoria,
                    ),
                    const SizedBox(height: 16),

                    Text('Rubro o Rol Específico', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.oficioCtrl, hintText: 'Ej. Ayudante, Mozo, Guardia...', maxLength: 40),
                    const SizedBox(height: 24),

                    Text('Pago Ofrecido (Sueldo Fijo)', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: tema.brightness == Brightness.dark ? Colors.black.withOpacity(0.5) : tema.inputDecorationTheme.fillColor, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: ColoresApp.secundarioCyan, width: 1.5)
                      ),
                      child: TextField(
                        controller: _controlador.sueldoCtrl, 
                        keyboardType: TextInputType.number, 
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: ColoresApp.secundarioCyan, fontSize: 20, fontWeight: FontWeight.w900),
                        decoration: InputDecoration(
                          filled: false, 
                          hintText: 'Ej. 25000', 
                          hintStyle: TextStyle(color: tema.brightness == Brightness.dark ? Colors.white24 : Colors.black26, fontSize: 16), 
                          prefixIcon: const Icon(Icons.attach_money_rounded, color: ColoresApp.secundarioCyan),
                          border: InputBorder.none, 
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Fotos del área o lugar (hasta 5)', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
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
                      hintText: 'Ej. Necesito cubrir el turno de 20hs a 04hs en mi bar...', 
                      minLines: 3, 
                      maxLines: null, 
                      maxLength: 500,
                      keyboardType: TextInputType.multiline, 
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 24),

                    Text('Herramientas o Requisitos', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SeccionRequisitosHerramientas(
                      traerHerramientas: _controlador.traerHerramientas,
                      herramientasCtrl: _controlador.herramientasCtrl,
                      onChanged: _controlador.toggleHerramientas,
                      tituloCheckbox: 'Aplica código de vestimenta o requerimientos',
                      hintInput: 'Ej. Traer camisa blanca y pantalón negro...',
                      colorTema: ColoresApp.secundarioCyan,
                    ),
                    const SizedBox(height: 24),

                    Text('Dirección exacta de la jornada', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
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
                      colorTema: ColoresApp.secundarioCyan,
                    ),
                    const SizedBox(height: 16),
                    Text('Referencias del lugar (Opcional)', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(
                      controller: _controlador.referenciaCtrl,
                      hintText: 'Ej: Portón negro, timbre no funciona...',
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
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: ColoresApp.secundarioCyan),
                          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 4, bottom: 24),
                      child: Text('🔒 Tu número se mantendrá oculto. Solo se revelará al profesional confirmado.', style: TextStyle(color: ColoresApp.secundarioCyan, fontSize: 12, fontStyle: FontStyle.italic)),
                    ),

                    Text('¿Cuándo es el turno / jornada?', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorFechaHora(
                      fechaSeleccionada: _controlador.fechaElegida,
                      horaSeleccionada: _controlador.horaElegida,
                      horaFinSeleccionada: _controlador.horaFinElegida,
                      onFechaChanged: (f) => _controlador.setFechaHora(f, null),
                      onHoraChanged: (h) => _controlador.setFechaHora(null, h),
                      onHoraFinChanged: (hFin) => _controlador.setFechaHora(null, null, hFin: hFin),
                      colorTema: ColoresApp.secundarioCyan,
                    ),
                    const SizedBox(height: 40),

                    BotonAccionPrincipal(
                      texto: 'PUBLICAR JORNADA / TURNO',
                      colorFondo: ColoresApp.secundarioCyan,
                      isLoading: _controlador.isSubmitting,
                      onPressed: () => _controlador.publicarTrabajo(context, esJornada: true),
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