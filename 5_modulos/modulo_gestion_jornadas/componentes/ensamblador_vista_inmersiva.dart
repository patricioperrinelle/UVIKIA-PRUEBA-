// lib/5_modulos/modulo_gestion_jornadas/componentes/ensamblador_vista_inmersiva.dart
import 'package:flutter/material.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../3_modelos/modelo_perfil.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_perfil_usuario.dart';
import '../controladores/controlador_jornadas.dart';
import 'carrusel_imagenes_jornada.dart';
import 'seccion_detalles_jornada.dart';
import 'panel_estado_postulante_pro.dart';

import '../../../4_componentes_globales/motor_cancelaciones_visuales/motor_cancelaciones.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

class EnsambladorVistaInmersiva extends StatelessWidget {
  final ControladorJornadas controlador;
  final ThemeData tema;
  final bool esOscuro;
  final bool isKeyboardOpen;

  const EnsambladorVistaInmersiva({
    Key? key,
    required this.controlador,
    required this.tema,
    required this.esOscuro,
    required this.isKeyboardOpen,
  }) : super(key: key);

  Widget? _obtenerFooterFlotante(BuildContext context) {
    if (controlador.soyElDueno) return null; 
    
    final String estadoPuja = controlador.miPuja?.estadoPuja ?? 'ninguna';
    final bool esCancelada = estadoPuja == 'cancelada_por_cliente' || 
                             estadoPuja == 'cancelada_vista_pro' || 
                             estadoPuja == 'cancelada_por_pro' || 
                             estadoPuja == 'cancelada' ||
                             estadoPuja == 'rechazada' ||
                             estadoPuja == 'rechazada_por_pro' ||
                             controlador.tratoCancelado;

    if (esCancelada || controlador.esRechazado) {
       return Container(
         color: tema.scaffoldBackgroundColor,
         padding: const EdgeInsets.only(bottom: 16),
         child: SafeArea(
           top: false,
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 24),
             child: MotorCancelaciones.resolverVistaEstatica(
               context,
               CancelacionContexto(
                 dominio: DominioApp.jornadas,
                 accion: TipoAccionCancelacion.vistaInPlace,
                 actor: ActorCancelacion.profesional,
                 estadoTransaccional: estadoPuja,
               ),
             ),
           ),
         ),
       );
    }

    return PanelEstadoPostulantePro(
      estadoNegociacion: estadoPuja, 
      isProcessing: controlador.isProcessing, 
      isLoadingDatos: controlador.isLoading, 
      onRetirarPostulacion: controlador.retirarPostulacion, 
      onPostularse: controlador.postularse
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobData = controlador.jobDataExtendida;
    final stickyFooter = _obtenerFooterFlotante(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor, 
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0), 
          child: Container(
            decoration: BoxDecoration(color: esOscuro ? Colors.black.withOpacity(0.5) : Colors.white, shape: BoxShape.circle), 
            child: IconButton(icon: Icon(Icons.arrow_back, color: esOscuro ? Colors.white : Colors.black, size: 20), onPressed: () => Navigator.pop(context))
          )
        ),
      ),
      body: Column(
        children:[
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(), 
              padding: EdgeInsets.only(bottom: isKeyboardOpen ? 20 : 24),
              child: Stack(
                children:[
                  CarruselImagenesJornada(imagenes: List<String>.from(jobData['images'] ??[]), categoria: jobData['category'] ?? jobData['oficio'] ?? 'Jornada'),
                  Container(
                    margin: const EdgeInsets.only(top: 250), 
                    decoration: BoxDecoration(color: tema.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          SeccionDetallesJornada(
                            vistaMinimalista: false, imagenes: List<String>.from(jobData['images'] ??[]), titulo: jobData['title'] ?? jobData['titulo'] ?? 'Jornada Solicitada', precio: jobData['price'] ?? jobData['sueldo_base'] ?? '\$0',
                            descripcionLimpia: controlador.descripcionLimpia, requisitosLimpios: controlador.requisitosLimpios, fechaFormateada: controlador.fechaFormateada, fechaSubLabel: controlador.fechaSubLabel, horarioLimpio: controlador.horarioLimpio, horarioSubLabel: controlador.horarioSubLabel, ubicacionFinal: controlador.ubicacionParaDetalles,
                          ),
                          const SizedBox(height: 8), 
                          Text('Sobre el cliente', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)), 
                          const SizedBox(height: 16),
                          TarjetaPerfilUsuario(
                            perfil: ModeloPerfil(
                              id: controlador.clienteId, 
                              apodo: jobData['counterpart'] ?? jobData['cliente_nombre'] ?? 'Usuario', 
                              fotoUrl: jobData['avatarUrl'] ?? jobData['cliente_avatar'] ?? '', 
                              
                              // COPIA EXACTA DE LA LÓGICA DE OFICIOS: Atrapa el dato directo del mapa para saltarse el retraso de SWR
                              ratingCliente: double.tryParse(jobData['rating']?.toString() ?? '') ?? controlador.counterpartRating, 
                              cantidadResenasCliente: int.tryParse(jobData['reviews']?.toString() ?? '') ?? controlador.counterpartReviews, 
                              
                              trabajosPublicados: int.tryParse(jobData['trabajos_publicados']?.toString() ?? '') ?? 0, 
                              trabajadoresContratados: int.tryParse(jobData['trabajadores_contratados']?.toString() ?? '') ?? 0, 
                              cancelacionesCliente: double.tryParse(jobData['cancelaciones_cliente']?.toString() ?? '') ?? 0.0, 
                              recomendacionTrabajadores: double.tryParse(jobData['recomendacion_trabajadores']?.toString() ?? '') ?? 0.0, 
                              
                              perfilProfesional: null 
                            ), 
                            esCliente: true, 
                            onTap: () => Navigator.pushNamed(context, '/perfil_profesional', arguments: {'id': controlador.clienteId, 'name': jobData['counterpart'] ?? 'Usuario', 'image': jobData['avatarUrl'] ?? ''})
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isKeyboardOpen && stickyFooter != null) stickyFooter,
        ],
      ),
    );
  }
}