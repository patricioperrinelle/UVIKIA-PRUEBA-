// lib/5_modulos/modulo_publicaciones/pantallas/pantalla_solicitar_presupuesto_privado.dart

import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';

import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/selector_dificultad_nivel.dart';
import '../../../4_componentes_globales/formularios/selector_fecha_hora.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/formularios/selector_categoria_inteligente.dart'; // 🛡️ IMPORTADO

import '../controladores/controlador_publicacion.dart';
import '../componentes/seccion_carga_imagenes.dart';
import '../componentes/seccion_direccion_maps.dart';
import '../componentes/seccion_requisitos_herramientas.dart';
import '../componentes/banner_profesional_destino.dart';

class PantallaSolicitarPresupuestoPrivado extends StatefulWidget {
  final String nombreProfesional;
  final String idProfesional;

  const PantallaSolicitarPresupuestoPrivado({
    Key? key,
    required this.nombreProfesional,
    required this.idProfesional,
  }) : super(key: key);

  @override
  State<PantallaSolicitarPresupuestoPrivado> createState() => _PantallaSolicitarPresupuestoPrivadoState();
}

class _PantallaSolicitarPresupuestoPrivadoState extends State<PantallaSolicitarPresupuestoPrivado> {
  final ControladorPublicacion _controlador = ControladorPublicacion();

  @override
  void initState() {
    super.initState();
    _controlador.proSolicitadoId = widget.idProfesional; 
  }

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
              title: Text('Presupuesto Directo', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
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
                    BannerProfesionalDestino(nombreProfesional: widget.nombreProfesional),
                    const SizedBox(height: 32),

                    // 🛡️ REGLA DATA INTEGRITY: Categoría en Privado
                    Text('Categoría Global', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorCategoriaInteligente(
                      valorInicial: _controlador.categoriaSeleccionada,
                      onSeleccionado: _controlador.setCategoria,
                    ),
                    const SizedBox(height: 16),

                    Text('Oficio Requerido', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(controller: _controlador.oficioCtrl, hintText: 'Ej. Electricista, Plomero...', maxLength: 40),
                    const SizedBox(height: 24),

                    Text('Dificultad del trabajo', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorDificultadNivel(
                      nivelSeleccionado: _controlador.dificultad,
                      onChanged: _controlador.setDificultad,
                    ),
                    const SizedBox(height: 24),

                    Text('Fotos explicativas (hasta 5)', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    SeccionCargaImagenes(
                      imagenes: _controlador.imagenes,
                      onAgregar: (source) => _controlador.agregarImagenes(context, source),
                      onEliminar: _controlador.eliminarImagen,
                    ),
                    const SizedBox(height: 24),

                    Text('Descripción del requerimiento', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    CampoTextoCristal(
                      controller: _controlador.descCtrl, 
                      hintText: 'Describe qué necesitas resolver...', 
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
                      colorTema: ColoresApp.secundarioCyan,
                    ),
                    const SizedBox(height: 24),

                    Text('Dirección exacta del trabajo', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
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
                      colorTema: ColoresApp.secundarioCyan,
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

                    Text('¿Cuándo lo necesitás?', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    SelectorFechaHora(
                      fechaSeleccionada: _controlador.fechaElegida,
                      horaSeleccionada: _controlador.horaElegida,
                      onFechaChanged: (f) => _controlador.setFechaHora(f, null),
                      onHoraChanged: (h) => _controlador.setFechaHora(null, h),
                      colorTema: ColoresApp.secundarioCyan,
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _controlador.isSubmitting ? null : () => _controlador.publicarTrabajo(context, esJornada: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColoresApp.secundarioCyan.withOpacity(0.15), 
                          foregroundColor: ColoresApp.secundarioCyan, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: ColoresApp.secundarioCyan, width: 1.5),
                          elevation: 0,
                        ),
                        child: _controlador.isSubmitting 
                            ? const CircularProgressIndicator(color: ColoresApp.secundarioCyan) 
                            : const Text('ENVIAR SOLICITUD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
                      ),
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