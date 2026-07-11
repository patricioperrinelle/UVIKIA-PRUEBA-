// lib/5_modulos/modulo_gestion_jornadas/componentes/panel_postulantes_cliente.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../3_modelos/modelo_puja.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_puja_postulante.dart';

// 🛡️ ARQUITECTURA LIMPIA: Mantenemos el componente "tonto" extrayendo la lógica sucia de la vista.
extension FiltroPujas on List<ModeloPuja> {
  List<ModeloPuja> get contratados => where((p) => (p.estadoPuja == 'esperando_confirmacion_pro' || p.estadoPuja == 'esperando_pago_cliente' || p.estadoPuja == 'aceptada' || p.estadoPuja == 'en_curso' || p.estadoPuja == 'esperando_pin_salida' || p.estadoPuja == 'finalizada' || p.estadoPuja == 'en_disputa') && p.mensaje != 'ELIMINADA_POR_CLIENTE').toList();
  List<ModeloPuja> get pendientes => where((p) => (p.estadoPuja == 'esperando' || p.estadoPuja == 'pendiente') && p.mensaje != 'ELIMINADA_POR_CLIENTE').toList();
  List<ModeloPuja> get desestimados => where((p) => (p.estadoPuja == 'cancelada' || p.estadoPuja == 'rechazada' || p.estadoPuja == 'rechazada_por_pro' || p.estadoPuja == 'desestimada' || p.estadoPuja == 'cancelada_por_pro' || p.estadoPuja == 'cancelada_por_cliente' || p.estadoPuja == 'cancelada_vista_pro') && p.mensaje != 'ELIMINADA_POR_CLIENTE').toList();
}

class PanelPostulantesCliente extends StatefulWidget {
  final String precioGlobal;
  final List<ModeloPuja> pujas;
  final bool isLoadingBids;
  final bool isProcessing;
  final bool isCongelado; 
  final Function(ModeloPuja) onTapPerfil; 
  final Function(ModeloPuja) onContratar;
  final Function(ModeloPuja) onDeshacerRechazo; 
  final Function(ModeloPuja) onAbrirModalGestion; 

  const PanelPostulantesCliente({
    Key? key,
    required this.precioGlobal,
    required this.pujas,
    required this.isLoadingBids,
    required this.isProcessing,
    this.isCongelado = false,
    required this.onTapPerfil,
    required this.onContratar,
    required this.onDeshacerRechazo,
    required this.onAbrirModalGestion,
  }) : super(key: key);

  @override
  State<PanelPostulantesCliente> createState() => _PanelPostulantesClienteState();
}

class _PanelPostulantesClienteState extends State<PanelPostulantesCliente> {
  bool _expandirContratados = false;
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

  Widget _botonGestionar(ModeloPuja puja, bool tieneMensajes) {
    if (puja.estadoPuja == 'finalizada' && (puja.clienteCalificoPuja == true)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: ColoresApp.primarioVerde.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: ColoresApp.primarioVerde.withOpacity(0.3))),
        child: const Text('Completado', style: TextStyle(color: ColoresApp.primarioVerde, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }
    return Badge(
      isLabelVisible: tieneMensajes,
      backgroundColor: ColoresApp.errorRojo,
      child: InkWell(
        onTap: () => widget.onAbrirModalGestion(puja),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: ColoresApp.terciarioMorado.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: ColoresApp.terciarioMorado.withOpacity(0.3))),
          child: const Text('Gestionar', style: TextStyle(color: ColoresApp.terciarioMorado, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    // 🛡️ CORRECCIÓN: La vista ahora solo recibe listas abstractas calculadas limpiamente.
    final contratados = widget.pujas.contratados;
    final pendientes = widget.pujas.pendientes;
    final desestimados = widget.pujas.desestimados;
    
    final bool todosCalificados = contratados.isNotEmpty && contratados.every((p) => p.estadoPuja == 'finalizada' && p.clienteCalificoPuja == true);

    final contratadosToShow = _expandirContratados ? contratados : contratados.take(2).toList();
    final pendientesToShow = _expandirPendientes ? pendientes : pendientes.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          if (todosCalificados)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24, top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              decoration: BoxDecoration(
                color: tema.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, color: ColoresApp.primarioVerde, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    '¡Servicio Completado!', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gracias por confiar en nuestro servicio. El registro pasará a tu historial de actividades.', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13)
                  ),
                ],
              ),
            ),
        
          if (widget.isLoadingBids)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: ColoresApp.terciarioMorado)))
          else if (contratados.isEmpty && pendientes.isEmpty && desestimados.isEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(32), margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(color: tema.colorScheme.surface, borderRadius: DimensionesApp.radioModales, border: Border.all(color: Colors.black12)),
              child: Column(
                children:[
                  Icon(Icons.hourglass_empty_rounded, color: tema.textTheme.bodySmall?.color?.withOpacity(0.5), size: 48),
                  const SizedBox(height: 12),
                  Text('Aún no hay postulantes.', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ],
              ),
            )
          else ...[
            if (contratados.isNotEmpty) ...[
              _buildHeaderSeccion(widget.isCongelado ? 'Asignados' : 'Contratados', contratados.length, _expandirContratados, () => setState(() => _expandirContratados = !_expandirContratados)),
              ...contratadosToShow.map((puja) => TarjetaPujaPostulante(
                  puja: puja, 
                  isCongelado: widget.isCongelado || puja.estadoPuja == 'finalizada' || puja.estadoPuja == 'esperando_confirmacion_pro' || puja.estadoPuja == 'esperando_pago_cliente', 
                  ocultarMonto: true, 
                  onTapPerfil: () => widget.onTapPerfil(puja),
                  botonesAccion: _botonGestionar(puja, !puja.notificacionLeidaCliente),
                )).toList(),
            ],

            if (pendientes.isNotEmpty && !widget.isCongelado) ...[
              _buildHeaderSeccion('Postulantes', pendientes.length, _expandirPendientes, () => setState(() => _expandirPendientes = !_expandirPendientes)),
              ...pendientesToShow.map((puja) => TarjetaPujaPostulante(puja: puja, ocultarMonto: true, onTapPerfil: () => widget.onTapPerfil(puja), botonesAccion: _botonGestionar(puja, false))).toList(),
            ],

            if (desestimados.isNotEmpty) ...[
              _buildHeaderSeccion('Historial de descartados', desestimados.length, true, () {}),
              ...desestimados.map((puja) => TarjetaPujaPostulante(
                  puja: puja, 
                  isCongelado: true, 
                  ocultarMonto: true, 
                  onTapPerfil: () => widget.onTapPerfil(puja),
                  botonesAccion: _botonGestionar(puja, !puja.notificacionLeidaCliente),
                )).toList(),
            ]
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}