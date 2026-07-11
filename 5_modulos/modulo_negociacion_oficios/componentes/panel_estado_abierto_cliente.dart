// lib/5_modulos/modulo_negociacion_oficios/componentes/panel_estado_abierto_cliente.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_puja_postulante.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/boton_delineado_secundario.dart';

class PanelEstadoAbiertoCliente extends StatefulWidget {
  final List<ModeloPuja> pujas;
  final bool isLoadingBids;
  final Function(ModeloPuja) onAceptar;
  final Function(ModeloPuja) onRechazar;
  final Function(String) onTapPerfil;
  final Function(ModeloPuja) onEliminar; // 🚨 NUEVO: Para borrar las rechazadas

  const PanelEstadoAbiertoCliente({
    Key? key, 
    required this.pujas, 
    required this.isLoadingBids, 
    required this.onAceptar, 
    required this.onRechazar, 
    required this.onTapPerfil,
    required this.onEliminar,
  }) : super(key: key);

  @override
  State<PanelEstadoAbiertoCliente> createState() => _PanelEstadoAbiertoClienteState();
}

class _PanelEstadoAbiertoClienteState extends State<PanelEstadoAbiertoCliente> {
  bool _expandirPendientes = false;

  Widget _buildHeaderSeccion(String titulo, int total, bool expandido, VoidCallback onToggle) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children:[
          Icon(Icons.people_outline_rounded, color: tema.textTheme.bodyMedium?.color, size: 20),
          const SizedBox(width: 8),
          Text('$titulo ($total)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          if (total > 2)
            InkWell(
              onTap: onToggle,
              child: Row(
                children:[
                  Text(expandido ? 'Ocultar' : 'Ver más', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13)),
                  Icon(expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_right, color: tema.textTheme.bodySmall?.color, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // 🚨 FIX: Incluimos los estados de confirmación y rechazo, pero evitamos los eliminados visualmente
    final pendientes = widget.pujas.where((p) => 
      p.mensaje != 'ELIMINADA_POR_CLIENTE' && 
      (p.estadoPuja == 'esperando' || p.estadoPuja == 'pendiente' || p.estadoPuja == 'esperando_confirmacion_pro' || p.estadoPuja == 'rechazada_por_pro')
    ).toList();
    
    final pendientesToShow = _expandirPendientes ? pendientes : pendientes.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          if (widget.isLoadingBids)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: ColoresApp.primarioVerde)))
          else if (pendientes.isEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(32), margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(color: tema.colorScheme.surface, borderRadius: DimensionesApp.radioModales, border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12)),
              child: Column(
                children:[
                  Icon(Icons.hourglass_empty_rounded, color: tema.textTheme.bodySmall?.color?.withOpacity(0.5), size: 48), 
                  const SizedBox(height: 12),
                  Text('Aún no hay ofertas.', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ],
              ),
            )
          else ...[
            _buildHeaderSeccion('Ofertas Recibidas', pendientes.length, _expandirPendientes, () => setState(() => _expandirPendientes = !_expandirPendientes)),
            ...pendientesToShow.map((puja) => Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                children:[
                  TarjetaPujaPostulante(puja: puja, onTapPerfil: () => widget.onTapPerfil(puja.profesionalId)),
                  const SizedBox(height: 12),
                  
                  // 🚨 1. BANNER ROJO: El profesional rechazó
                  if (puja.estadoPuja == 'rechazada_por_pro') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: ColoresApp.errorRojo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('El profesional no tiene disponibilidad para realizar el trabajo.', style: TextStyle(color: ColoresApp.errorRojo, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 12),
                    BotonDelineadoSecundario(texto: 'ELIMINAR DE LA LISTA', icono: Icons.delete_outline, colorPrimario: ColoresApp.errorRojo, onPressed: () => widget.onEliminar(puja)),
                  ] 
                  // 🚨 2. BANNER AMARILLO: Esperando que el pro confirme
                  else if (puja.estadoPuja == 'esperando_confirmacion_pro') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: ColoresApp.advertenciaAmarillo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Aguardando confirmación del profesional...', style: TextStyle(color: ColoresApp.advertenciaAmarillo, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 12),
                    BotonDelineadoSecundario(texto: 'CANCELAR SOLICITUD', icono: Icons.close, colorPrimario: ColoresApp.errorRojo, onPressed: () => widget.onRechazar(puja)),
                  ] 
                  // 🚨 3. BOTONES NORMALES: Recién llegó la oferta
                  else ...[
                    Row(
                      children:[
                        Expanded(flex: 4, child: BotonDelineadoSecundario(texto: 'Rechazar', icono: Icons.close_rounded, colorPrimario: ColoresApp.errorRojo, onPressed: () => widget.onRechazar(puja))),
                        const SizedBox(width: 12),
                        Expanded(flex: 6, child: BotonAccionPrincipal(texto: 'ACEPTAR OFERTA', colorFondo: ColoresApp.primarioVerde, onPressed: () => widget.onAceptar(puja))),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Divider(color: esOscuro ? Colors.white12 : Colors.black12),
                ],
              ),
            )).toList()
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}