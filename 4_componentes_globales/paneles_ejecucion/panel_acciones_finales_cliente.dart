// lib/4_componentes_globales/paneles_ejecucion/panel_acciones_finales_cliente.dart
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../botones/boton_accion_lista.dart';

class PanelAccionesFinalesCliente extends StatelessWidget {
  final String estadoPuja;
  final bool yaLlego;
  final String? codigoCheckin;
  final String? codigoCheckout;
  final bool clienteCalificoPuja; 
  final bool enMediacion;

  final VoidCallback onFinalizar;
  final VoidCallback onReportar;
  final VoidCallback? onCancelar; 
  final VoidCallback? onVerPoliticas; 
  final VoidCallback? onFinalizarTarea;
  final VoidCallback? onValidarCheckout;
  final bool esProfesional;

  const PanelAccionesFinalesCliente({
    Key? key,
    required this.estadoPuja,
    required this.yaLlego,
    this.codigoCheckin,
    this.codigoCheckout,
    this.clienteCalificoPuja = false,
    this.enMediacion = false,
    required this.onFinalizar,
    required this.onReportar,
    this.onCancelar,
    this.onVerPoliticas,
    this.onFinalizarTarea,
    this.onValidarCheckout,
    this.esProfesional = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    if (enMediacion) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), border: const Border(top: BorderSide(color: Colors.blueGrey, width: 2))),
        child: const Column(
          children: [
            Icon(Icons.support_agent_rounded, color: Colors.blueGrey, size: 48),
            SizedBox(height: 16),
            Text('Centro de Resolución Activo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            SizedBox(height: 8),
            Text('Estamos ayudando a resolver un inconveniente. El trabajo y los pagos se encuentran pausados preventivamente.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColoresApp.fondoTarjetas,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children:[
          if (estadoPuja == 'aceptada' || estadoPuja == 'asignado' || estadoPuja == 'esperando_confirmacion_pro') ...[
             if (yaLlego) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColoresApp.primarioVerde.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, color: ColoresApp.primarioVerde, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  esProfesional ? 'El cliente ya llegó al local' : 'El profesional llegó al domicilio', 
                                  style: const TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                                const SizedBox(height: 4),
                                const Text('Proporciónale el PIN de inicio.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: ColoresApp.primarioVerde)),
                        child: Text((codigoCheckin == null || codigoCheckin!.isEmpty) ? '-----' : codigoCheckin!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: ColoresApp.primarioVerde)),
                      ),
                    ],
                  ),
                ),
             ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColoresApp.primarioVerde.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3)),
                  ),
                  child: Text(
                    esProfesional 
                      ? 'Esperando la llegada del cliente.' 
                      : 'Esperando la llegada del profesional.', 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)
                  ),
                )
             ]
          ]
          else if (estadoPuja == 'en_curso') ...[
            if (esProfesional) ...[
              const Text('Trabajo en curso', textAlign: TextAlign.center, style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3))),
                child: const Text('Cuando termines tu labor, avisa que la tarea está finalizada.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              if (onFinalizarTarea != null)
                BotonAccionLista(texto: 'Finalizar Tarea', icono: Icons.logout_rounded, onTap: onFinalizarTarea),
            ] else ...[
              const Text('El trabajo está en proceso.\nEspera a que finalice la tarea.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: ColoresApp.primarioVerde)),
                child: const Text('EN CURSO...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
              ),
            ]
          ]
          else if (estadoPuja == 'esperando_pin_salida') ...[
            if (esProfesional) ...[
              const Text('Tarea Finalizada', textAlign: TextAlign.center, style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3))),
                child: const Text('Solicita al cliente el PIN de finalización para completar el servicio.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              if (onValidarCheckout != null)
                BotonAccionLista(texto: 'Ingresar PIN de salida', icono: Icons.login_rounded, onTap: onValidarCheckout),
            ] else ...[
              const Text('El profesional finalizó el trabajo.\nProporciónale el PIN de finalización.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: ColoresApp.primarioVerde)),
                child: Text((codigoCheckout == null || codigoCheckout!.isEmpty) ? '-----' : codigoCheckout!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: ColoresApp.primarioVerde)),
              ),
            ]
          ]
          else if (estadoPuja == 'finalizado' || estadoPuja == 'finalizada') ...[
            const Icon(Icons.verified_rounded, color: ColoresApp.primarioVerde, size: 48),
            const SizedBox(height: 8),
            Text(esProfesional ? 'Trabajo completado con éxito.' : '¡Gracias por confiar en nuestro servicio!', textAlign: TextAlign.center, style: const TextStyle(color: ColoresApp.primarioVerde, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (clienteCalificoPuja)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Center(child: Text('✅ EVALUADO', style: TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.bold)))),
          ],

          if (estadoPuja != 'finalizado' && estadoPuja != 'finalizada' || ((estadoPuja == 'finalizado' || estadoPuja == 'finalizada') && !clienteCalificoPuja))
             const SizedBox(height: 16),
          
          if ((estadoPuja == 'finalizado' || estadoPuja == 'finalizada') && !clienteCalificoPuja)
             BotonAccionLista(texto: 'Calificar', icono: Icons.star_rate_rounded, onTap: onFinalizar),
             
          if (estadoPuja != 'finalizado' && estadoPuja != 'finalizada' || ((estadoPuja == 'finalizado' || estadoPuja == 'finalizada') && !clienteCalificoPuja))
             BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportar),
        ],
      ),
    );
  }
}