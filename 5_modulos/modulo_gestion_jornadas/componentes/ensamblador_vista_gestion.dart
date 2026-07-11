// lib/5_modulos/modulo_gestion_jornadas/componentes/ensamblador_vista_gestion.dart
import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/modelo_perfil.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_perfil_usuario.dart';
import '../../modulo_chat_mensajes/controladores/controlador_chat.dart';
import '../../modulo_chat_mensajes/componentes/seccion_chat_colapsable.dart';
import '../controladores/controlador_jornadas.dart';
import '../modales/modal_confirmar_contratacion_multi.dart';
import 'seccion_detalles_jornada.dart';
import 'panel_postulantes_cliente.dart';
import '../../../4_componentes_globales/indicadores/linea_tiempo_estados.dart';
import 'selector_acciones_pro.dart';

class EnsambladorVistaGestion extends StatelessWidget {
  final ControladorJornadas controlador;
  final ControladorChat controladorChat;
  final ThemeData tema;
  final bool esOscuro;
  final Function(ModeloPuja) onAbrirModalGestion;
  final Function(bool, ModeloPuja?) onAbrirCalificacion;
  final bool calificacionLocalExitosa;

  const EnsambladorVistaGestion({
    Key? key,
    required this.controlador,
    required this.controladorChat,
    required this.tema,
    required this.esOscuro,
    required this.onAbrirModalGestion,
    required this.onAbrirCalificacion,
    this.calificacionLocalExitosa = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jobData = controlador.jobDataExtendida;
    final bool soyPro = !controlador.soyElDueno;
    final bool yaLlego = controlador.miPuja?.coordenadasLlegada != null && controlador.miPuja!.coordenadasLlegada!.isNotEmpty;
    final bool yaHizoCheckin = controlador.miPuja?.estadoPuja == 'en_curso' || controlador.miPuja?.estadoPuja == 'esperando_pin_salida' || controlador.miPuja?.estadoPuja == 'finalizada';
    final bool completada = controlador.miPuja?.estadoPuja == 'finalizada';
    final bool esEsperandoConfirmacion = controlador.miPuja?.estadoPuja == 'esperando_confirmacion_pro';

    final bool _proCalificoVisual = controlador.miPuja?.proCalificoPuja == true || 
                                    controlador.jobDataExtendida['pro_califico'] == true || 
                                    controlador.jobDataExtendida['proCalifico'] == true ||
                                    calificacionLocalExitosa;

    return Scaffold(
      backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text('Gestión de jornada', style: TextStyle(color: tema.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: tema.textTheme.bodyLarge?.color),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            SeccionDetallesJornada(
              vistaMinimalista: true, imagenes: List<String>.from(jobData['images'] ??[]),
              titulo: jobData['title'] ?? jobData['titulo'] ?? 'Jornada Solicitada', precio: jobData['price'] ?? jobData['sueldo_base'] ?? '\$0',
              descripcionLimpia: controlador.descripcionLimpia, requisitosLimpios: controlador.requisitosLimpios, fechaFormateada: controlador.fechaFormateada,
              fechaSubLabel: controlador.fechaSubLabel, horarioLimpio: controlador.horarioLimpio, horarioSubLabel: controlador.horarioSubLabel, ubicacionFinal: controlador.ubicacionParaDetalles,
              referenciaLugar: controlador.referenciaLugar,
              mostrarContactoLiberado: controlador.mostrarContactoLiberado, ubicacionMaps: controlador.ubicacionMaps, telefonoContacto: controlador.telefonoContacto,
            ),

            if (controlador.soyElDueno) 
              PanelPostulantesCliente(
                precioGlobal: jobData['price'] ?? '\$0', pujas: controlador.pujas, isLoadingBids: controlador.isLoading, isProcessing: controlador.isProcessing, isCongelado: controlador.tratoFinalizado || controlador.tratoCancelado, 
                onTapPerfil: (p) => Navigator.pushNamed(context, '/perfil_profesional', arguments: {'id': p.profesionalId, 'name': p.apodoProfesional, 'image': p.avatarUrl}),
                onContratar: (p) async { if (await ModalConfirmarContratacionMulti.mostrar(context) == true) controlador.contratarProfesional(p); },
                onDeshacerRechazo: controlador.deshacerRechazoPostulante, 
                onAbrirModalGestion: onAbrirModalGestion,
              )
            else if (soyPro) ...[
              if (!esEsperandoConfirmacion)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    const Text('Sobre el cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // 🛡️ REFACTOR: Se inyectan las métricas usando los Getters robustos del controlador.
                    TarjetaPerfilUsuario(
                      perfil: ModeloPerfil(
                        id: controlador.clienteId, 
                        apodo: jobData['counterpart'] ?? jobData['cliente_nombre'] ?? 'Usuario', 
                        fotoUrl: jobData['avatarUrl'] ?? jobData['cliente_avatar'] ?? '', 
                        ratingCliente: controlador.counterpartRating, 
                        cantidadResenasCliente: controlador.counterpartReviews,
                        trabajosPublicados: (jobData['trabajos_publicados'] as num?)?.toInt() ?? 0,
                        trabajadoresContratados: (jobData['trabajadores_contratados'] as num?)?.toInt() ?? 0,
                        cancelacionesCliente: (jobData['cancelaciones_cliente'] as num?)?.toDouble() ?? 0.0,
                        recomendacionTrabajadores: (jobData['recomendacion_trabajadores'] as num?)?.toDouble() ?? 0.0,
                        perfilProfesional: DatosProfesionales(
                          zonaTrabajo: jobData['zona_trabajo_cliente']?.toString() ?? '',
                          ratingProfesional: controlador.counterpartRating,
                          cantidadResenasProfesional: controlador.counterpartReviews,
                          scoreConfiabilidadPro: (jobData['score_confiabilidad_pro'] as num?)?.toDouble() ?? 0.0,
                          puntualidad: (jobData['puntualidad_pro'] as num?)?.toDouble() ?? 0.0,
                          asistencia: (jobData['asistencia_pro'] as num?)?.toDouble() ?? 0.0,
                          jornadasCompletadas: (jobData['jornadas_completadas_pro'] as num?)?.toDouble() ?? (controlador.miPuja?.jornadasCompletadas ?? 0.0),
                          cancelacionesPro: (jobData['cancelaciones_profesional'] as num?)?.toDouble() ?? (controlador.miPuja?.cancelacionesPro ?? 0.0)
                        )
                      ), 
                      esCliente: true, 
                      onTap: () => Navigator.pushNamed(context, '/perfil_profesional', arguments: {'id': controlador.clienteId, 'name': jobData['counterpart'] ?? 'Usuario', 'image': jobData['avatarUrl'] ?? ''})
                    ),
                  ])
                ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    if (!esEsperandoConfirmacion) ...[
                       const Text('Estado de la jornada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 20),
                       LineaTiempoEstados(llegoAlLugar: yaLlego, enCurso: yaHizoCheckin, completada: completada),
                       const SizedBox(height: 24),
                    ],
                    SelectorAccionesPro(
                      controlador: controlador, 
                      onAbrirCalificacion: onAbrirCalificacion,
                      proCalificoLocal: _proCalificoVisual,
                    ),
                    if (controlador.mostrarContactoLiberado)
                       SeccionChatColapsable(controlador: controladorChat, isCongelado: controlador.tratoFinalizado || controlador.miPuja?.estadoPuja == 'finalizada' || controlador.miPuja?.estadoPuja == 'desestimada', colorAcento: ColoresApp.terciarioMorado)
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