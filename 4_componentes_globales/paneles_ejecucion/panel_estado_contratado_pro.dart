// lib/4_componentes_globales/paneles_ejecucion/panel_estado_contratado_pro.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../botones/boton_cristal_icono.dart';
import '../botones/boton_accion_lista.dart';

class PanelEstadoContratadoPro extends StatelessWidget {
  final String estadoPuja;
  final bool profesionalEnCamino;
  final String? coordenadasLlegada;
  final String? codigoCheckout;
  final bool enMediacion; // 🛡️ NUEVO: Estado Zen
  
  final VoidCallback onAceptarTrabajo;
  final VoidCallback onRechazarTrabajo; 
  final VoidCallback onLlegadaGPS;
  final VoidCallback onValidarCheckin; 
  final VoidCallback onValidarCheckout; 
  final VoidCallback? onFinalizarTarea;
  final VoidCallback onAbrirMapa;
  final VoidCallback onReportarProblema; 
  final VoidCallback? onCancelar; 
  final VoidCallback? onVerPoliticas;
  final bool esProfesional;

  const PanelEstadoContratadoPro({
    Key? key,
    required this.estadoPuja,
    required this.profesionalEnCamino,
    this.coordenadasLlegada,
    this.codigoCheckout,
    this.enMediacion = false,
    required this.onAceptarTrabajo,
    required this.onRechazarTrabajo,
    required this.onLlegadaGPS,
    required this.onValidarCheckin,
    required this.onValidarCheckout,
    this.onFinalizarTarea,
    required this.onAbrirMapa,
    required this.onReportarProblema,
    this.onCancelar,
    this.onVerPoliticas,
    this.esProfesional = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (enMediacion) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueGrey.withOpacity(0.3))),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:[
        if (estadoPuja == 'esperando_confirmacion_pro') ...[
          const Icon(Icons.stars_rounded, color: ColoresApp.primarioVerde, size: 48),
          const SizedBox(height: 8),
          const Text('¡Has sido seleccionado!', textAlign: TextAlign.center, style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Asegúrate de estar disponible para la fecha pactada.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children:[
              Expanded(child: BotonCristalIcono(texto: 'RECHAZAR', icono: Icons.cancel_outlined, colorAcento: ColoresApp.errorRojo, onTap: onRechazarTrabajo)),
              const SizedBox(width: 12),
              Expanded(child: BotonCristalIcono(texto: 'ACEPTAR TRABAJO', icono: Icons.check_circle_rounded, colorAcento: ColoresApp.primarioVerde, onTap: onAceptarTrabajo)),
            ],
          ),
        ] 
        else if (estadoPuja == 'aceptada' || estadoPuja == 'asignado') ...[
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
                        Text(esProfesional ? 'Llegada registrada. Solicita al cliente el PIN de inicio para confirmar tu llegada.' : 'El trabajador llegó. Proporciónale el PIN de inicio.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
              child: Text(esProfesional ? 'Cuando llegues al lugar de la jornada, registra tu llegada.' : 'Esperando la llegada del trabajador.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
            ),
            const SizedBox(height: 12),
            if (esProfesional) ...[
              BotonAccionLista(texto: 'Llegué al lugar (GPS)', icono: Icons.location_on_rounded, onTap: onLlegadaGPS),
            ],
            BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportarProblema),
          ]
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
            const Text('El trabajador finalizó el trabajo.\nProporciónale el PIN de finalización.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: ColoresApp.primarioVerde)),
              child: Text(codigoCheckout ?? '-----', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: ColoresApp.primarioVerde)),
            ),
            const SizedBox(height: 12),
          ],
          // 🚨 BOTÓN TRANQUILIZADOR (GRIS)
          BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportarProblema),
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
            child: Text(esProfesional ? 'Cuando termines tu labor, presiona finalizar trabajo.' : 'El trabajador está haciendo su trabajo. Espera a que finalice la tarea.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
          ),
          const SizedBox(height: 12),
          if (esProfesional) ...[
            BotonAccionLista(texto: 'Finalizar trabajo', icono: Icons.logout_rounded, onTap: onFinalizarTarea ?? onValidarCheckout),
          ],
          // 🚨 BOTÓN TRANQUILIZADOR (GRIS)
          BotonAccionLista(texto: 'Centro de Resolución', icono: Icons.support_agent_rounded, iconoDerecho: null, onTap: onReportarProblema),
        ]
      ],
    );
  }
}