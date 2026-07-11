// lib/5_modulos/modulo_gestion_jornadas/modales/modal_gestion_postulante.dart

import 'package:flutter/material.dart'; // Modal de gestión actualizado
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../modulo_chat_mensajes/controladores/controlador_chat.dart';
import '../../modulo_chat_mensajes/componentes/seccion_chat_colapsable.dart'; 
import '../../../4_componentes_globales/indicadores/etiqueta_estado_badge.dart';
import '../../../4_componentes_globales/indicadores/linea_tiempo_estados.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/motor_cancelaciones.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

// 🚨 IMPORT DEL MIDDLEWARE DE PAGOS
import '../../modulo_billetera/componentes/seccion_checkout_integrado.dart';

class ModalGestionPostulante extends StatelessWidget {
  final ModeloPuja puja;
  final ControladorChat controladorChat;
  final Widget accionesFinales;
  final bool isCongelado;
  final VoidCallback? onContratar; 
  final VoidCallback? onRechazar; 
  
  // 🚨 NUEVO CALLBACK DEL HANDSHAKE
  final VoidCallback? onConfirmarPago;

  final dynamic trabajoId;
  final String tituloTrabajo;
  final double sueldo;
  
  // 🚨 NUEVOS CAMPOS PARA DETALLE DE CHECKOUT
  final String tipoTrabajo;
  final String? fecha;
  final String? horaInicio;
  final String? horaFin;
  final String? totalHoras;
  final String? descripcion;

  const ModalGestionPostulante({
    Key? key,
    required this.puja,
    required this.controladorChat,
    required this.accionesFinales,
    this.isCongelado = false,
    this.onContratar,
    this.onRechazar,
    this.onConfirmarPago,
    required this.trabajoId,
    required this.tituloTrabajo,
    required this.sueldo,
    required this.tipoTrabajo,
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.totalHoras,
    this.descripcion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final bool esPendiente = puja.estadoPuja == 'esperando' || puja.estadoPuja == 'pendiente';
    final bool esperandoPro = puja.estadoPuja == 'esperando_confirmacion_pro';
    
    // 🚨 NUEVO ESTADO DEL HANDSHAKE
    final bool esperandoPago = puja.estadoPuja == 'esperando_pago_cliente';
    
    final bool rechazadaPro = puja.estadoPuja == 'rechazada_por_pro';
    final bool fueCanceladaPorCliente = puja.estadoPuja == 'cancelada_por_cliente' || puja.estadoPuja == 'cancelada_vista_pro' || puja.estadoPuja == 'cancelada';
    final bool fueCanceladaPorPro = puja.estadoPuja == 'cancelada_por_pro';
    final bool estaCanceladaTotal = fueCanceladaPorCliente || fueCanceladaPorPro;
    
    final bool yaLlego = puja.coordenadasLlegada != null && puja.coordenadasLlegada!.isNotEmpty;
    final bool yaHizoCheckin = puja.estadoPuja == 'en_curso' || puja.estadoPuja == 'esperando_pin_salida' || puja.estadoPuja == 'finalizada';
    final bool completada = puja.estadoPuja == 'finalizada';

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children:[
                Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children:[
                      CircleAvatar(radius: 28, backgroundImage: NetworkImage(puja.avatarUrl)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(puja.apodoProfesional, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children:[
                                EtiquetaEstadoBadge(
                                  texto: fueCanceladaPorCliente ? 'CANCELADA' : (fueCanceladaPorPro ? 'CANCELÓ ASISTENCIA' : (rechazadaPro ? 'NO DISPONIBLE' : (esperandoPago ? 'ESPERANDO PAGO' : (esPendiente ? 'ESPERANDO RESPUESTA' : (esperandoPro ? 'AGUARDANDO AL PRO' : (completada ? 'FINALIZADA' : 'CONTRATADO')))))), 
                                  icono: estaCanceladaTotal ? Icons.cancel_presentation_rounded : (rechazadaPro ? Icons.cancel_rounded : (esperandoPago ? Icons.payment_rounded : (esPendiente ? Icons.hourglass_top_rounded : (esperandoPro ? Icons.sync_rounded : Icons.check_circle_rounded)))), 
                                  colorTema: estaCanceladaTotal ? ColoresApp.errorRojo : (rechazadaPro ? ColoresApp.errorRojo : (esperandoPago ? ColoresApp.advertenciaAmarillo : (esPendiente ? ColoresApp.advertenciaAmarillo : (esperandoPro ? ColoresApp.secundarioCyan : (completada ? ColoresApp.primarioVerde : ColoresApp.terciarioMorado))))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),

                if (rechazadaPro || estaCanceladaTotal) ...[
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children:[
                            MotorCancelaciones.resolverVistaEstatica(
                              context,
                              CancelacionContexto(
                                dominio: DominioApp.jornadas,
                                accion: TipoAccionCancelacion.vistaInPlace,
                                actor: ActorCancelacion.cliente,
                                estadoTransaccional: puja.estadoPuja,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            if (rechazadaPro)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ColoresApp.errorRojo, 
                                    side: BorderSide(color: ColoresApp.errorRojo.withOpacity(0.5)), 
                                    padding: const EdgeInsets.symmetric(vertical: 16), 
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ), 
                                  onPressed: onRechazar, 
                                  child: const Text('Eliminar de la lista', style: TextStyle(fontWeight: FontWeight.bold))
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                ]
                else if (esPendiente) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children:[
                          const Icon(Icons.handshake_rounded, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Este postulante espera tu respuesta. Al contratarlo, se le enviará una notificación para que confirme su disponibilidad de asistencia.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColoresApp.terciarioMorado, 
                                foregroundColor: Colors.white, 
                                padding: const EdgeInsets.symmetric(vertical: 16), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                                elevation: 0
                              ), 
                              // 🚨 PASO 1 DEL HANDSHAKE: Contratación seca
                              onPressed: onContratar, 
                              child: const Text('Contratar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ] 
                else if (esperandoPro) ...[
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children:[
                            const Icon(Icons.access_time_filled_rounded, size: 64, color: ColoresApp.secundarioCyan),
                            const SizedBox(height: 16),
                            const Text('Esperando confirmación del profesional.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.secundarioCyan)),
                            const SizedBox(height: 8),
                            const Text('Debe confirmar que sigue disponible para esa fecha. Una vez que acepte, el sistema te solicitará el pago.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                ]
                // 🚨 NUEVO BLOQUE: EL PEAJE FINANCIERO DEL CLIENTE
                else if (esperandoPago) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: SeccionCheckoutIntegrado(
                        trabajoId: puja.id,
                        tituloTrabajo: tituloTrabajo,
                        nombreProfesional: puja.apodoProfesional,
                        idProfesional: puja.profesionalId,
                        subtotal: sueldo,
                        tarifaPlataforma: sueldo * 0.10,
                        tipoTrabajo: tipoTrabajo,
                        fecha: fecha,
                        horaInicio: horaInicio,
                        horaFin: horaFin,
                        totalHoras: totalHoras,
                        descripcion: descripcion,
                        onPagoCompletado: () {
                          onConfirmarPago?.call();
                        },
                      ),
                    ),
                  ),
                ]
                else ...[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                const Text('Estado de la jornada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                LineaTiempoEstados(llegoAlLugar: yaLlego, enCurso: yaHizoCheckin, completada: completada),
                                if (!isCongelado && !completada && accionesFinales is! SizedBox) ...[
                                  const SizedBox(height: 24), accionesFinales,
                                ]
                              ],
                            ),
                          ),
                          Container(height: 8, color: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.grey.shade100),
                          
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SeccionChatColapsable(
                              controlador: controladorChat,
                              isCongelado: isCongelado,
                              colorAcento: ColoresApp.terciarioMorado, 
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}