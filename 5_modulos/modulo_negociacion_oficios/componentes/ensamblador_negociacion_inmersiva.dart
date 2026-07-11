// lib/5_modulos/modulo_negociacion_oficios/componentes/ensamblador_negociacion_inmersiva.dart
import 'package:flutter/material.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../3_modelos/modelo_perfil.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_perfil_usuario.dart';
import '../controladores/controlador_negociacion.dart';
import 'carrusel_imagenes_trabajo.dart';
import 'seccion_detalles_trabajo.dart';
import 'selector_acciones_negociacion.dart';

class EnsambladorNegociacionInmersiva extends StatelessWidget {
  final ControladorNegociacion controlador;
  final bool calificacionLocalExitosa;
  final Function(String, String, String, double, int) onNavegarAPerfil;
  final Function(bool) onAbrirCalificacion;

  const EnsambladorNegociacionInmersiva({
    Key? key,
    required this.controlador,
    required this.calificacionLocalExitosa,
    required this.onNavegarAPerfil,
    required this.onAbrirCalificacion,
  }) : super(key: key);

  List<String> _obtenerImagenesSeguras() {
    final imgs = controlador.jobData['images'] ?? controlador.jobData['imagenes'];
    if (imgs is List) return imgs.map((e) => e.toString()).toList();
    return[];
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final mostrarContacto = !(controlador.soyElDueno && controlador.contraparteIdFija.isEmpty);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor, extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leadingWidth: 68, leading: Padding(padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0), child: Container(decoration: BoxDecoration(color: esOscuro ? Colors.black.withOpacity(0.5) : Colors.white, shape: BoxShape.circle), child: IconButton(icon: Icon(Icons.arrow_back, color: esOscuro ? Colors.white : Colors.black, size: 20), onPressed: () => Navigator.pop(context))))),
      body: Stack(
        children:[
          CarruselImagenesTrabajo(imagenes: _obtenerImagenesSeguras(), soyElDueno: false, categoria: controlador.jobData['oficio']?.toString() ?? 'Oficio'),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children:[
                Container(
                  margin: const EdgeInsets.only(top: 250),
                  decoration: BoxDecoration(color: tema.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                  child: Column(
                    children:[
                      const SizedBox(height: 16),
                      SeccionDetallesTrabajo(vistaMinimalista: false, imagenes: _obtenerImagenesSeguras(), title: controlador.jobData['title']?.toString() ?? 'Trabajo Solicitado', displayPrice: controlador.precioFinalDelBd.isNotEmpty && controlador.precioFinalDelBd != '\$ 0' ? controlador.precioFinalDelBd : (controlador.jobData['price']?.toString() ?? '\$0'), metodoPagoElegido: '', formattedDate: controlador.fechaFormateada, fechaSubLabel: controlador.fechaSubLabel, horarioLimpio: controlador.horarioLimpio, horarioSubLabel: 'Hora fijada', mainDesc: controlador.descripcionLimpia, requisitos: controlador.requisitosLimpios, ubicacionFinal: controlador.ubicacionParaDetalles),
                      
                      if (mostrarContacto) 
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children:[
                              Text('Sobre el cliente', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)), 
                              const SizedBox(height: 12), 
                              TarjetaPerfilUsuario(
                                perfil: ModeloPerfil(
                                  id: controlador.contraparteIdFija.isNotEmpty ? controlador.contraparteIdFija : (controlador.jobData['cliente_id']?.toString() ?? controlador.jobData['ownerId']?.toString() ?? ''), 
                                  apodo: controlador.counterpartName, 
                                  fotoUrl: controlador.counterpartAvatar, 
                                  
                                  // 🛡️ REFACTOR: Fallback seguro. Si los Getters fallan, extraemos directo del jobData.
                                  ratingCliente: double.tryParse(controlador.jobData['rating']?.toString() ?? '') ?? controlador.counterpartRating, 
                                  cantidadResenasCliente: int.tryParse(controlador.jobData['reviews']?.toString() ?? '') ?? controlador.counterpartReviews, 
                                  
                                  trabajosPublicados: int.tryParse(controlador.jobData['trabajos_publicados']?.toString() ?? '') ?? 0, 
                                  trabajadoresContratados: int.tryParse(controlador.jobData['trabajadores_contratados']?.toString() ?? '') ?? 0, 
                                  cancelacionesCliente: double.tryParse(controlador.jobData['cancelaciones_cliente']?.toString() ?? '') ?? 0.0, 
                                  recomendacionTrabajadores: double.tryParse(controlador.jobData['recomendacion_trabajadores']?.toString() ?? '') ?? 0.0, 
                                  
                                  // 🛡️ REFACTOR: El cliente NO tiene perfil profesional.
                                  perfilProfesional: null 
                                ), 
                                esCliente: true, 
                                onTap: () => onNavegarAPerfil(controlador.contraparteIdFija.isNotEmpty ? controlador.contraparteIdFija : (controlador.jobData['cliente_id']?.toString() ?? controlador.jobData['ownerId']?.toString() ?? ''), controlador.counterpartName, controlador.counterpartAvatar, controlador.counterpartRating, controlador.counterpartReviews)
                              )
                            ]
                          )
                        ),
                      
                      SelectorAccionesNegociacion(
                        controlador: controlador, 
                        calificacionLocalExitosa: calificacionLocalExitosa, 
                        onAbrirCalificacion: onAbrirCalificacion,
                        trabajoId: controlador.idTrabajoReal,
                        tituloTrabajo: controlador.jobData['title']?.toString() ?? controlador.jobData['titulo']?.toString() ?? 'Trabajo Solicitado',
                        sueldo: controlador.precioBaseAcordadoLimpio,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}