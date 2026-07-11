// lib/5_modulos/modulo_negociacion_oficios/pantallas/vista_actividades_oficios.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../modulo_actividad_alertas/componentes/acordeon_categoria_historial.dart';
import '../controladores/controlador_actividad_oficios.dart';
import '../pantallas/pantalla_negociacion_oficio.dart';
import '../../../3_modelos/modelo_oficio_trabajo.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_recibo_transaccion.dart';

class VistaActividadesOficios extends StatefulWidget {
  final bool esCliente;
  const VistaActividadesOficios({Key? key, required this.esCliente}) : super(key: key);

  @override
  State<VistaActividadesOficios> createState() => _VistaActividadesOficiosState();
}

class _VistaActividadesOficiosState extends State<VistaActividadesOficios> {
  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorSesionGlobal>();
    final miId = gestor.miIdUsuario;
    final controlador = ControladorActividadOficios(); // Singleton

    if (widget.esCliente) {
      final listFinalizados = controlador.historialFinalizadoCliente;
      final listCancelados = controlador.historialCanceladoCliente;
      
      return Column(
        children: [
          AcordeonCategoriaHistorial(
            titulo: 'Oficios publicados', 
            icono: Icons.work_outline_rounded,
            trabajos: controlador.oficiosActivosCliente + controlador.propuestasDirectasActivasCliente,
            colorTema: ColoresApp.primarioVerde, esDueno: true, textoVacio: 'No tienes ofertas de oficios publicadas.',
            miId: miId,
            onTapTrabajo: (t) => _abrirTrabajo(t, true, false), onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, true), onCalcularAlertas: (t) => controlador.calcularAlertasItem(t as ModeloOficioTrabajo, true),
          ),
          AcordeonCategoriaHistorial(
            titulo: 'Historial de oficios finalizados', 
            icono: Icons.check_circle_outline_rounded,
            trabajos: listFinalizados,
            colorTema: ColoresApp.primarioVerde, esDueno: true, esHistorial: true, textoVacio: 'Aún no finalizaste oficios.',
            miId: miId,
            onTapTrabajo: (t) => _abrirTrabajo(t, true, true, esRecibo: true), onDeleteTrabajo: (t) {}, onCalcularAlertas: (_) => 0,
          ),
          AcordeonCategoriaHistorial(
            titulo: 'Oficios cancelados', 
            icono: Icons.cancel_outlined,
            trabajos: listCancelados,
            colorTema: ColoresApp.errorRojo, esDueno: true, esHistorial: true, textoVacio: 'No tienes oficios cancelados.',
            miId: miId,
            onTapTrabajo: (t) => _abrirTrabajo(t, true, true, esRecibo: false), onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, true), onCalcularAlertas: (_) => 0,
          ),
        ],
      );
    } else {
      final listFinalizadosPro = controlador.historialFinalizadoPro;
      final listCanceladosPro = controlador.historialCanceladoPro;

      return Column(
        children: [
          AcordeonCategoriaHistorial(
            titulo: 'Postulaciones a oficios', 
            icono: Icons.work_outline_rounded,
            trabajos: controlador.postulacionesOficiosActivasPro + controlador.solicitudesDirectasActivasPro,
            colorTema: ColoresApp.terciarioMorado, esDueno: false, textoVacio: 'No tienes postulaciones activas a oficios.',
            miId: miId,
            onTapTrabajo: (t) => _abrirTrabajo(t, false, false), onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, false), onCalcularAlertas: (t) => controlador.calcularAlertasItem(t as ModeloOficioTrabajo, false),
          ),
          AcordeonCategoriaHistorial(
            titulo: 'Historial de oficios finalizados', 
            icono: Icons.check_circle_outline_rounded,
            trabajos: listFinalizadosPro,
            colorTema: ColoresApp.primarioVerde, esDueno: false, esHistorial: true, textoVacio: 'Aún no completaste oficios.',
            miId: miId,
            onTapTrabajo: (t) => _abrirTrabajo(t, false, true, esRecibo: true), onDeleteTrabajo: (t) {}, onCalcularAlertas: (_) => 0,
          ),
          AcordeonCategoriaHistorial(
            titulo: 'Oficios cancelados', 
            icono: Icons.cancel_outlined,
            trabajos: listCanceladosPro,
            colorTema: ColoresApp.errorRojo, esDueno: false, esHistorial: true, textoVacio: 'No tienes oficios cancelados.',
            miId: miId,
            onTapTrabajo: (t) => _abrirTrabajo(t, false, true), onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, false), onCalcularAlertas: (_) => 0,
          ),
        ],
      );
    }
  }

  void _abrirTrabajo(dynamic t, bool esDueno, bool esHistorial, {bool esRecibo = false}) {
    final trabajo = t as ModeloOficioTrabajo;
    ControladorActividadOficios().marcarItemComoVisto(trabajo, esDueno);
    
    final estadoLimpio = trabajo.estado.toLowerCase().trim();
    final bool esEstadoFinalizado = estadoLimpio == 'finalizado' || estadoLimpio == 'finalizada';

    if (esRecibo || (esHistorial && esEstadoFinalizado)) {
      final gestor = context.read<GestorSesionGlobal>();
      final miNombre = gestor.perfilUsuario?.apodo ?? 'Usuario';
      final miAvatar = gestor.perfilUsuario?.fotoUrl ?? ''; 
      ModalReciboTransaccion.mostrar(context, trabajo, esDueno, miNombre, miAvatar);
      return;
    }

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => PantallaNegociacionOficio(jobData: trabajo.toJson(), esHistorial: esHistorial)
      )
    ).then((_) => ControladorActividadOficios().recargarDatosDesdeCero());
  }

  Future<void> _eliminarTrabajoLocal(dynamic t, bool esDueno) async {
    final trabajo = t as ModeloOficioTrabajo;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: 'Eliminar registro',
        mensaje: '¿Estás seguro de que quieres eliminar o retirarte de "${trabajo.titulo}"?',
        textoBotonConfirmar: 'Eliminar',
        colorConfirmar: ColoresApp.errorRojo,
        onCancelar: () => Navigator.pop(ctx, false),
        onConfirmar: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirm == true) {
      ControladorActividadOficios().eliminarRegistro(trabajo, esDueno);
    }
  }
}
