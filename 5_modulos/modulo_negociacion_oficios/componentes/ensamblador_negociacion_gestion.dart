// lib/5_modulos/modulo_negociacion_oficios/componentes/ensamblador_negociacion_gestion.dart

import 'package:flutter/material.dart'; 
import '../../../2_tema/colores_app.dart'; 
import '../../../3_modelos/modelo_perfil.dart'; 
// import '../../../3_modelos/modelo_puja.dart'; 
import '../../../4_componentes_globales/tarjetas/tarjeta_perfil_usuario.dart'; 
import '../../../4_componentes_globales/indicadores/linea_tiempo_estados.dart'; 
import '../../../4_componentes_globales/botones/boton_accion_lista.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_constructor_presupuesto.dart';
import '../controladores/controlador_negociacion.dart'; 
import '../../modulo_chat_mensajes/controladores/controlador_chat.dart'; 
import '../../modulo_chat_mensajes/componentes/seccion_chat_colapsable.dart'; 
import 'seccion_detalles_trabajo.dart'; 
import 'panel_estado_abierto_cliente.dart';
import 'selector_acciones_negociacion.dart';

class EnsambladorNegociacionGestion extends StatelessWidget { 
  final ControladorNegociacion controlador; 
  final ControladorChat controladorChat; 
  final bool calificacionLocalExitosa; 
  final Function(String, String, String, double, int) onNavegarAPerfil; 
  final Function(bool) onAbrirCalificacion;

  const EnsambladorNegociacionGestion({ 
    Key? key, 
    required this.controlador,
    required this.controladorChat, 
    required this.calificacionLocalExitosa, 
    required this.onNavegarAPerfil, 
    required this.onAbrirCalificacion, 
  }) : super(key: key);

  void _envolverLlamada(BuildContext context, Future Function() funcion) async {
    try { await funcion(); } catch (e) { if (context.mounted)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
    Text(e.toString().replaceAll('Exception: ', '')), backgroundColor:
    ColoresApp.errorRojo)); } 
  }

  List<String> _obtenerImagenesSeguras() { 
    final imgs = controlador.jobData['images'] ?? controlador.jobData['imagenes']; 
    if (imgs is List) return imgs.map((e) => e.toString()).toList(); 
    return []; 
  }

  @override 
  Widget build(BuildContext context) { 
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final estado = controlador.estadoActual;
    final estaActivo = estado == EstadoNegociacion.asignado || estado == EstadoNegociacion.enCurso || estado == EstadoNegociacion.enDisputa;
    final bool isFrozen = estado == EstadoNegociacion.finalizado || estado == EstadoNegociacion.cancelado || controlador.perdiElTrabajo;
    final mostrarContacto = !(controlador.soyElDueno && controlador.contraparteIdFija.isEmpty);

    return Scaffold(
      backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text('Gestión del trabajo', style: TextStyle(color: tema.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: tema.textTheme.bodyLarge?.color),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            SeccionDetallesTrabajo(
              vistaMinimalista: true,
              imagenes: _obtenerImagenesSeguras(),
              title: controlador.jobData['title']?.toString() ?? 'Trabajo Solicitado',
              displayPrice: controlador.precioFinalDelBd.isNotEmpty && controlador.precioFinalDelBd != '\$ 0' ? controlador.precioFinalDelBd : (controlador.jobData['price']?.toString() ?? '\$0'),
              metodoPagoElegido: estaActivo || isFrozen ? controlador.metodoPagoElegido : '',
              formattedDate: controlador.fechaFormateada,
              fechaSubLabel: controlador.fechaSubLabel,
              horarioLimpio: controlador.horarioLimpio,
              horarioSubLabel: 'Hora fijada',
              mainDesc: controlador.descripcionLimpia,
              requisitos: controlador.requisitosLimpios,
              ubicacionFinal: controlador.ubicacionParaDetalles,
              referenciaLugar: controlador.referenciaLugar,
              mostrarContactoLiberado: !controlador.soyElDueno && controlador.mostrarContactoLiberado, 
              ubicacionMaps: controlador.ubicacionMaps, 
              telefonoContacto: controlador.telefonoContacto,
            ),
            
            // 🛡️ REFACTOR: Permite ocultar el panel de lista de postulantes si el profesional ya aceptó y ahora esperamos el pago o ya está el contrato en curso/aceptado
            if (controlador.soyElDueno &&
                estado == EstadoNegociacion.abierto &&
                controlador.pujaAceptada?.estadoPuja != 'esperando_pago_cliente' &&
                controlador.pujaAceptada?.estadoPuja != 'aceptada' &&
                controlador.pujaAceptada?.estadoPuja != 'asignado' &&
                controlador.pujaAceptada?.estadoPuja != 'en_curso' &&
                controlador.pujaAceptada?.estadoPuja != 'esperando_pin_salida' &&
                controlador.pujaAceptada?.estadoPuja != 'finalizada' &&
                controlador.pujaAceptada?.estadoPuja != 'en_disputa')
              PanelEstadoAbiertoCliente(
                pujas: controlador.pujas, isLoadingBids: controlador.isLoading,
                onTapPerfil: (id) { try { final puja = controlador.pujas.firstWhere((p) => p.profesionalId == id); onNavegarAPerfil(puja.profesionalId, puja.apodoProfesional, puja.avatarUrl, puja.rating, puja.reviews); } catch (_) {} }, 
                onAceptar: (puja) => _envolverLlamada(context, () => controlador.aceptarOferta(puja, 'Escrow')),
                onRechazar: (puja) => _envolverLlamada(context, () => controlador.rechazarOferta(puja)),
                onEliminar: (puja) => _envolverLlamada(context, () => controlador.ocultarPujaRechazada(puja)),
              )
            // 🛡️ REFACTOR: Muestra la vista de gestión y botoneras si NO está abierto, o si está abierto PERO en un estado avanzado o esperando pago
            else if (estado != EstadoNegociacion.abierto ||
                controlador.pujaAceptada?.estadoPuja == 'esperando_pago_cliente' ||
                controlador.pujaAceptada?.estadoPuja == 'aceptada' ||
                controlador.pujaAceptada?.estadoPuja == 'asignado' ||
                controlador.pujaAceptada?.estadoPuja == 'en_curso' ||
                controlador.pujaAceptada?.estadoPuja == 'esperando_pin_salida' ||
                controlador.pujaAceptada?.estadoPuja == 'finalizada' ||
                controlador.pujaAceptada?.estadoPuja == 'en_disputa') ...[
              if (mostrarContacto)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(controlador.soyElDueno ? 'Sobre el profesional' : 'Sobre el cliente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                      const SizedBox(height: 12),
                      TarjetaPerfilUsuario(
                        perfil: ModeloPerfil(
                          id: controlador.contraparteIdFija, 
                          apodo: controlador.counterpartName, 
                          fotoUrl: controlador.counterpartAvatar, 
                          ratingCliente: controlador.counterpartRating, 
                          cantidadResenasCliente: controlador.counterpartReviews,
                          trabajosPublicados: (controlador.jobData['trabajos_publicados'] as num?)?.toInt() ?? 0, 
                          trabajadoresContratados: (controlador.jobData['trabajadores_contratados'] as num?)?.toInt() ?? 0, 
                          cancelacionesCliente: (controlador.jobData['cancelaciones_cliente'] as num?)?.toDouble() ?? 0.0, 
                          recomendacionTrabajadores: (controlador.jobData['recomendacion_trabajadores'] as num?)?.toDouble() ?? 0.0, 
                          perfilProfesional: DatosProfesionales(
                            zonaTrabajo: controlador.jobData['zona_trabajo_cliente']?.toString() ?? controlador.pujaAceptada?.zonaTrabajo ?? '',
                            ratingProfesional: controlador.counterpartRating,
                            cantidadResenasProfesional: controlador.counterpartReviews,
                            scoreConfiabilidadPro: (controlador.jobData['score_confiabilidad_pro'] as num?)?.toDouble() ?? (controlador.pujaAceptada?.scoreConfiabilidadPro ?? 0.0),
                            puntualidad: (controlador.jobData['puntualidad_pro'] as num?)?.toDouble() ?? (controlador.pujaAceptada?.puntualidad ?? 0.0),
                            asistencia: (controlador.jobData['asistencia_pro'] as num?)?.toDouble() ?? (controlador.pujaAceptada?.asistencia ?? 0.0),
                            jornadasCompletadas: (controlador.jobData['jornadas_completadas_pro'] as num?)?.toDouble() ?? (controlador.pujaAceptada?.jornadasCompletadas ?? 0.0),
                            cancelacionesPro: (controlador.jobData['cancelaciones_profesional'] as num?)?.toDouble() ?? (controlador.pujaAceptada?.cancelacionesPro ?? 0.0)
                          )
                        ),
                        esCliente: !controlador.soyElDueno, 
                        onTap: () => onNavegarAPerfil(controlador.contraparteIdFija, controlador.counterpartName, controlador.counterpartAvatar, controlador.counterpartRating, controlador.counterpartReviews)
                      ),
                    ],
                  ),
                ),

              if (!controlador.soyElDueno && controlador.requierePanelAccionesFinales && !controlador.estaEnDisputa && !controlador.tratoFinalizado)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: BotonAccionLista(
                    texto: 'Actualizar Presupuesto',
                    icono: Icons.receipt_long_rounded,
                    colorAcento: ColoresApp.terciarioMorado,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => ListenableBuilder(
                          listenable: controlador,
                          builder: (ctx, child) {
                            return ModalConstructorPresupuesto(
                              tituloTrabajo: controlador.jobData['title']?.toString() ?? 'Trabajo en curso',
                              precioBase: controlador.precioBaseAcordadoLimpio,
                              itemsDb: controlador.adicionalesBorradorPro,
                              bloqueado: controlador.tieneAdicionalesPendientes,
                              onEnviar: (nuevosItems) {
                                controlador.enviarTicketAdicionales(nuevosItems);
                              },
                            );
                          }
                        ),
                      );
                    },
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                     if (!isFrozen || controlador.completada) ...[
                       const Text('Estado de la negociación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 20),
                       LineaTiempoEstados(llegoAlLugar: controlador.yaLlego, enCurso: controlador.yaHizoCheckin, completada: controlador.completada),
                       const SizedBox(height: 24),
                     ],
                     SelectorAccionesNegociacion(
                       controlador: controlador, 
                       calificacionLocalExitosa: calificacionLocalExitosa, 
                       onAbrirCalificacion: onAbrirCalificacion,
                       trabajoId: controlador.idTrabajoReal,
                       tituloTrabajo: controlador.jobData['title']?.toString() ?? controlador.jobData['titulo']?.toString() ?? 'Trabajo Solicitado',
                       sueldo: controlador.precioBaseAcordadoLimpio,
                     ),
                     if (controlador.mostrarContactoLiberado || isFrozen)
                        SeccionChatColapsable(controlador: controladorChat, isCongelado: isFrozen || calificacionLocalExitosa, colorAcento: estado == EstadoNegociacion.enCurso ? ColoresApp.secundarioCyan : ColoresApp.primarioVerde),
                  ]
                )
              ),
              
              const SizedBox(height: 16),
            ]
          ],
        ),
      ),
    );
  } 
}