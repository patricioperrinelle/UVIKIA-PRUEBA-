// lib/5_modulos/modulo_servicios_catalogo/componentes/panel_ejecucion_catalogo_viajero.dart
import 'package:flutter/material.dart';
import '../../../../2_tema/colores_app.dart';
import '../../../../4_componentes_globales/botones/boton_accion_lista.dart';

class PanelEjecucionCatalogoViajero extends StatelessWidget {
  final String estadoPuja;
  final bool profesionalEnCamino;
  final String? coordenadasLlegada;
  final String? codigoCheckout;
  final VoidCallback onLlegadaGPS;
  final VoidCallback onValidarCheckin;
  final VoidCallback onFinalizarTarea;
  final VoidCallback onValidarCheckout;
  final VoidCallback onAbrirMapa;
  final VoidCallback onReportarProblema;
  final bool esProfesional;
  final bool yaCalifico;
  final VoidCallback onCalificar;

  const PanelEjecucionCatalogoViajero({
    Key? key,
    required this.estadoPuja,
    required this.profesionalEnCamino,
    this.coordenadasLlegada,
    this.codigoCheckout,
    required this.onLlegadaGPS,
    required this.onValidarCheckin,
    required this.onFinalizarTarea,
    required this.onValidarCheckout,
    required this.onAbrirMapa,
    required this.onReportarProblema,
    required this.esProfesional,
    required this.yaCalifico,
    required this.onCalificar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColoresApp.fondoTarjetas,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          if (estadoPuja == 'contratado' || estadoPuja == 'aceptada' || estadoPuja == 'asignado' || estadoPuja == 'esperando_confirmacion_pro') ...[
            if (coordenadasLlegada != null) ...[
               Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: ColoresApp.primarioVerde,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(esProfesional ? 'Llegada registrada. Solicita al cliente el PIN de inicio para confirmar tu llegada.' : 'Llegada registrada. Solicita al profesional el PIN de inicio para confirmar tu llegada.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BotonAccionLista(texto: 'Ver en Google Maps', icono: Icons.map_outlined, onTap: onAbrirMapa),
              BotonAccionLista(texto: 'Ingresar PIN de llegada', icono: Icons.key_outlined, onTap: onValidarCheckin),
              BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportarProblema),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3))),
                child: Text(esProfesional ? 'Cuando llegues al domicilio, registra tu llegada.' : 'Cuando llegues al local, registra tu llegada.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
              ),
              const SizedBox(height: 12),
              
              BotonAccionLista(texto: 'Llegué al lugar (GPS)', icono: Icons.location_on_rounded, onTap: onLlegadaGPS),
              BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportarProblema),
            ]
          ] 
          else if (estadoPuja == 'en_curso') ...[
            const Icon(Icons.play_circle_fill_rounded, color: ColoresApp.primarioVerde, size: 40),
            const SizedBox(height: 8),
            const Text('Trabajo en curso', textAlign: TextAlign.center, style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3))),
              child: Text(esProfesional ? 'Cuando termines tu labor, avisa que la tarea está finalizada.' : 'El profesional está haciendo su trabajo. Espera a que finalice la tarea.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
            ),
            const SizedBox(height: 12),
            if (esProfesional) ...[
              BotonAccionLista(texto: 'Finalizar Tarea', icono: Icons.logout_rounded, onTap: onFinalizarTarea),
            ],
            BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportarProblema),
          ]
          else if (estadoPuja == 'esperando_pin_salida') ...[
            if (esProfesional) ...[
              const Icon(Icons.check_circle_outline_rounded, color: ColoresApp.primarioVerde, size: 40),
              const SizedBox(height: 8),
              const Text('Tarea Finalizada', textAlign: TextAlign.center, style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3))),
                child: const Text('Solicita al cliente el PIN de finalización para completar el servicio.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
              ),
              const SizedBox(height: 12),
              BotonAccionLista(texto: 'Ingresar PIN de salida', icono: Icons.login_rounded, onTap: onValidarCheckout),
            ] else ...[
               const Text('El profesional finalizó el trabajo.\nProporciónale el PIN de finalización.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
               const SizedBox(height: 12),
               Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: ColoresApp.primarioVerde)),
                  child: Text(codigoCheckout ?? '-----', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: ColoresApp.primarioVerde)),
                ),
               const SizedBox(height: 12),
            ],
            BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportarProblema),
          ]
          else if (estadoPuja == 'finalizado' || estadoPuja == 'finalizada') ...[
            const Icon(Icons.verified_rounded, color: ColoresApp.primarioVerde, size: 48),
            const SizedBox(height: 8),
            Text(esProfesional ? 'Trabajo completado con éxito.' : '¡Gracias por confiar en nuestro servicio!', textAlign: TextAlign.center, style: const TextStyle(color: ColoresApp.primarioVerde, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (yaCalifico)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Center(child: Text('✅ EVALUADO', style: TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.bold)))),
          ]
        ],
      ),
    );
  }
}
