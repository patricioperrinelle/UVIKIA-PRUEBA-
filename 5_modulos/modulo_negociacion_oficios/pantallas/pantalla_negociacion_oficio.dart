// lib/5_modulos/modulo_negociacion_oficios/pantallas/pantalla_negociacion_oficio.dart

import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart'; 
import '../../../2_tema/colores_app.dart'; 
import '../../../3_modelos/modelo_resena_payload.dart'; 
import '../../../4_componentes_globales/modales_y_alertas/flujo_calificacion/modal_finalizar_y_calificar.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_evaluar_ticket_adicional.dart';
import '../../modulo_resolucion_conflictos/pantallas/pantalla_sala_mediacion.dart';
import '../controladores/controlador_negociacion.dart'; 
import '../../modulo_chat_mensajes/controladores/controlador_chat.dart'; 
import '../componentes/ensamblador_negociacion_inmersiva.dart'; 
import '../componentes/ensamblador_negociacion_gestion.dart'; 
import '../controladores/controlador_actividad_oficios.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/motor_cancelaciones.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

class PantallaNegociacionOficio extends StatefulWidget { 
  final Map<String, dynamic> jobData; 
  final bool esHistorial;

  const PantallaNegociacionOficio({Key? key, required this.jobData, this.esHistorial = false}) : super(key: key);

  @override 
  State<PantallaNegociacionOficio> createState() => _PantallaNegociacionOficioState(); 
}

class _PantallaNegociacionOficioState extends State<PantallaNegociacionOficio> { 
  final ControladorNegociacion _controlador = ControladorNegociacion(); 
  final ControladorChat _controladorChat = ControladorChat();

  bool _modalCalificacionAbierto = false; 
  bool _modalCancelacionProAbierto = false; 
  bool _calificacionExitosaLocal = false;
  bool _chatInicializado = false;

  static final Set<String> _trabajosCalificadosEnRam = {};

  @override 
  void initState() { 
    super.initState(); 
    final String jobId = widget.jobData['id'].toString(); 
    ControladorActividadOficios.pantallaActivaId = jobId;

    if (_trabajosCalificadosEnRam.contains(jobId)) _calificacionExitosaLocal = true;

    _controlador.onRequerirAccionUI = _manejarEventosUI;
    _controlador.addListener(_verificarAvisosAutomaticos); 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final miIdUsuario = Supabase.instance.client.auth.currentUser?.id ?? '';
      try {
        _controladorChat.onMensajeSistemaDetectado = (codigoSys, esCargaInicial) {
          if (!esCargaInicial) {
            _controlador.cargarDatos(silencioso: true);
          }
        };

        _controlador.inicializar(widget.jobData, miIdUsuario);
        
        if (_controlador.contraparteIdFija.isNotEmpty && !_chatInicializado) {
           _controladorChat.inicializar(pTrabajoId: _controlador.idTrabajoReal.toString(), pMiId: _controlador.miId, pContraparteId: _controlador.contraparteIdFija);
           _chatInicializado = true; 
        }
      } catch (e) {
        if (mounted) { _controlador.isLoading = false; setState(() {}); }
      }
    });
  }

  void _verificarAvisosAutomaticos() { 
    if (!mounted || _controlador.isLoading || _calificacionExitosaLocal) return;

    bool debeCalificar = false;
    if (_controlador.soyElDueno) {
      if (_controlador.tratoFinalizado && !_controlador.clienteCalifico) debeCalificar = true;
    } else {
      if (_controlador.tratoFinalizado && !_controlador.proCalifico && _controlador.miPuja?.estadoPuja == 'finalizada') debeCalificar = true;
    }

    if (debeCalificar && !_modalCalificacionAbierto && !widget.esHistorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirModalCalificacion(_controlador.soyElDueno));
      return; 
    }
  }

  void _abrirModalCalificacion(bool esCliente) { 
    if (!mounted || _modalCalificacionAbierto || _calificacionExitosaLocal) return;
    _modalCalificacionAbierto = true;

    final pujaObjetivo = _controlador.soyElDueno ? _controlador.pujaAceptada! : _controlador.miPuja!;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true, isDismissible: false, enableDrag: false,    
      builder: (ctx) => ModalFinalizarYCalificar(
        profesional: pujaObjetivo, 
        esCliente: esCliente, 
        onConfirmar: (ModeloResenaPayload payload) {
          setState(() { _calificacionExitosaLocal = true; });
          _trabajosCalificadosEnRam.add(widget.jobData['id'].toString());
          ControladorActividadOficios().blindarTrampaPorCalificacionExitosa(widget.jobData['id'].toString());
          _controlador.marcarCalificacionLocalVisualmente();
          Navigator.pop(ctx); 
          final perfil = context.read<GestorSesionGlobal>().perfilUsuario;
          if (esCliente) _controlador.finalizarYCalificar(pujaObjetivo, payload, perfil?.apodo ?? 'Usuario', perfil?.fotoUrl ?? '');
          else _controlador.calificarComoProfesional(payload, perfil?.apodo ?? 'Usuario', perfil?.fotoUrl ?? '');
        }
      )
    ).then((_) {
      _modalCalificacionAbierto = false;
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => _verificarAvisosAutomaticos());
    });
  }

  @override 
  void dispose() { 
    if (ControladorActividadOficios.pantallaActivaId == widget.jobData['id'].toString()) ControladorActividadOficios.pantallaActivaId = null; 
    _controlador.dispose(); 
    _controladorChat.dispose(); 
    super.dispose(); 
  }

  void _manejarEventosUI(String tipoEvento, [dynamic payload]) { 
    if (tipoEvento == 'INICIALIZAR_CHAT') { 
      final nuevaContraparte = payload.toString(); 
      if (!_chatInicializado || _controladorChat.contraparteId != nuevaContraparte) {
        _controladorChat.inicializar(pTrabajoId: _controlador.idTrabajoReal.toString(), pMiId: _controlador.miId, pContraparteId: nuevaContraparte); 
        _chatInicializado = true; 
      } 
    } else if (tipoEvento == 'NAVEGAR_SALA_MEDIACION') {
      WidgetsBinding.instance.addPostFrameCallback((_) { 
        if (!mounted) return; 
        final String contraparteId = payload.toString(); 
        Navigator.push(context, MaterialPageRoute( builder: (context) => PantallaSalaMediacion( trabajoId: _controlador.idTrabajoReal.toString(), contraparteId: contraparteId, ), )); 
      }); 
    }
    else if (tipoEvento == 'EVALUAR_TICKET') {
      WidgetsBinding.instance.addPostFrameCallback((_) async { 
        if (!mounted) return;
        final acepto = await DialogoEvaluarTicketAdicional.mostrar(context, precioBase: _controlador.precioBaseAcordadoLimpio, itemsPropuestos: _controlador.adicionalesParaEvaluacionCliente); 
        if (acepto != null) _controlador.responderTicketAdicionalBatch(acepto); 
      }); 
    } 
    else if (tipoEvento == 'MOSTRAR_MODAL_CANCELACION') { 
      final ctxContext = payload as CancelacionContexto; 
      if (ctxContext.accion == TipoAccionCancelacion.avisoProCanceladoPorCliente || ctxContext.accion == TipoAccionCancelacion.avisoClienteCanceladoPorPro) {
        if (_modalCancelacionProAbierto) return;
        _modalCancelacionProAbierto = true;
        MotorCancelaciones.resolverYMostrarModal(context, ctxContext).then((_) {
            if (mounted) _modalCancelacionProAbierto = false;
        });
      } else {
        MotorCancelaciones.resolverYMostrarModal(context, ctxContext);
      }
    }
    else if (tipoEvento == 'MOSTRAR_ERROR') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(payload.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
          backgroundColor: ColoresApp.errorRojo,
          duration: const Duration(seconds: 4),
        ));
      });
    }
    else if (tipoEvento == 'MOSTRAR_MENSAJE_EXITO') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(payload.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
          backgroundColor: ColoresApp.primarioVerde,
          duration: const Duration(seconds: 4),
        ));
      });
    }
    else if (tipoEvento == 'CERRAR_MODALES') {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
    else if (tipoEvento == 'CERRAR_PANTALLA') {
      if (Navigator.canPop(context)) Navigator.pop(context, true); 
    }
  }

  void _navegarAPerfil(String id, String nombre, String avatar, double rating, int reviews) { 
    if (id.isEmpty || id == 'null') return; 
    Navigator.pushNamed(context, '/perfil_profesional', arguments: {'id': id, 'name': nombre, 'image': avatar, 'rating': rating, 'reviews': reviews}); 
  }

  @override 
  Widget build(BuildContext context) { 
    final tema = Theme.of(context);

    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, child) {
        if (_controlador.isLoading) return Scaffold(backgroundColor: tema.scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde)));

        // 🛡️ ARQUITECTURA LIMPIA: La pantalla ahora es un enrutador ciego. Las decisiones viven en el controlador.
        final bool vistaMinimalista = _controlador.esVistaMinimalista(widget.esHistorial);

        if (!vistaMinimalista) {
          return EnsambladorNegociacionInmersiva(
            controlador: _controlador, 
            calificacionLocalExitosa: _calificacionExitosaLocal, 
            onNavegarAPerfil: _navegarAPerfil, 
            onAbrirCalificacion: _abrirModalCalificacion
          );
        }
        
        return EnsambladorNegociacionGestion(
          controlador: _controlador, 
          controladorChat: _controladorChat, 
          calificacionLocalExitosa: _calificacionExitosaLocal, 
          onNavegarAPerfil: _navegarAPerfil, 
          onAbrirCalificacion: _abrirModalCalificacion
        );
      }
    );
  }
}