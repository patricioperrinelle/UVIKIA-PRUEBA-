// lib/5_modulos/modulo_gestion_jornadas/pantallas/pantalla_gestion_jornada.dart

import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart'; 
import '../../../2_tema/colores_app.dart'; 
import '../../../3_modelos/modelo_puja.dart'; 
import '../../../3_modelos/modelo_jornada.dart'; 
import '../../../3_modelos/modelo_resena_payload.dart'; 
import '../../modulo_chat_mensajes/controladores/controlador_chat.dart'; 
import '../controladores/controlador_jornadas.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_centro_resolucion.dart';
import '../../modulo_resolucion_conflictos/pantallas/pantalla_sala_mediacion.dart';
import '../modales/modal_gestion_postulante.dart'; 
import '../../../4_componentes_globales/modales_y_alertas/flujo_calificacion/modal_finalizar_y_calificar.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_acciones_finales_cliente.dart';
import '../componentes/ensamblador_vista_inmersiva.dart'; 
import '../componentes/ensamblador_vista_gestion.dart'; 
import '../controladores/controlador_actividad_jornadas.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/motor_cancelaciones.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

class PantallaGestionJornada extends StatefulWidget { 
  final Map<String, dynamic> jobData; 
  final ModeloJornada? trabajoTipado; 
  final bool esHistorial;

  const PantallaGestionJornada({ 
    Key? key, 
    required this.jobData,
    this.trabajoTipado, 
    this.esHistorial = false 
  }) : super(key: key);

  @override 
  State<PantallaGestionJornada> createState() => _PantallaGestionJornadaState(); 
}

class _PantallaGestionJornadaState extends State<PantallaGestionJornada> { 
  final ControladorJornadas _controlador = ControladorJornadas(); 
  final ControladorChat _controladorChat = ControladorChat();

  bool _modalCalificacionAbierto = false; 
  bool _modalCancelacionProAbierto = false;

  final Set<String> _pujasCalificadasExitosamente = {}; 
  static final Set<String> _pujasCalificadasEnRam = {};

  @override 
  void initState() { 
    super.initState(); 
    final String jobId = widget.jobData['id'].toString(); 
    ControladorActividadJornadas.pantallaActivaId = jobId;

    _controlador.onRequerirAccionUI = _manejarEventosUI;
    _controlador.addListener(_verificarAutoCalificacion); 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sesion = context.read<GestorSesionGlobal>();
      _controlador.inicializar(widget.jobData, sesion.miIdUsuario, esHistorial: widget.esHistorial, trabajoTipado: widget.trabajoTipado);
      if (!_controlador.soyElDueno) _controladorChat.inicializar(pTrabajoId: jobId, pMiId: sesion.miIdUsuario, pContraparteId: _controlador.clienteId);
    });
  }

  void _verificarAutoCalificacion() { 
    if (!mounted || _controlador.isLoading || _modalCalificacionAbierto || widget.esHistorial) return;

    bool debeCalificar = false;
    ModeloPuja? pujaObjetivo;

    if (_controlador.soyElDueno) {
      try { 
        pujaObjetivo = _controlador.pujas.firstWhere((p) => 
          p.estadoPuja == 'finalizada' && 
          !p.clienteCalificoPuja && 
          !_pujasCalificadasExitosamente.contains(p.id) &&
          !_pujasCalificadasEnRam.contains(p.id)
        ); 
        debeCalificar = true;
      } catch(_) {}
    } else {
      if (_controlador.miPuja?.estadoPuja == 'finalizada' && 
          !_controlador.miPuja!.proCalificoPuja && 
          !_pujasCalificadasExitosamente.contains(_controlador.miPuja!.id) &&
          !_pujasCalificadasEnRam.contains(_controlador.miPuja!.id)) {
        debeCalificar = true;
        pujaObjetivo = _controlador.miPuja;
      }
    }

    if (debeCalificar && pujaObjetivo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirModalCalificacion(_controlador.soyElDueno, pujaObjetivo!);
      });
    }
  }

  void _manejarEventosUI(String accion, dynamic payload) { 
    if (!mounted) return;
    if (accion == 'mostrar_mensaje') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
      Text(payload['mensaje'], style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: payload['esError'] == true ? ColoresApp.errorRojo :
      ColoresApp.primarioVerde)); 
    } 
    else if (accion == 'cerrar_pantalla') Navigator.pop(context, true); 
    else if (accion == 'abrir_calificacion') _abrirModalCalificacion(_controlador.soyElDueno, payload as ModeloPuja);
    else if (accion == 'NAVEGAR_SALA_MEDIACION') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final String contraparteId = payload.toString();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => PantallaSalaMediacion(
            trabajoId: _controlador.trabajoId.toString(),
            contraparteId: contraparteId,
          ),
        ));
      });
    }
    else if (accion == 'MOSTRAR_MODAL_CANCELACION') {
        final ctxContext = payload as CancelacionContexto;
        if (ctxContext.accion == TipoAccionCancelacion.avisoProCanceladoPorCliente || 
            ctxContext.accion == TipoAccionCancelacion.avisoClienteCanceladoPorPro) {
            
            if (_modalCancelacionProAbierto) return;
            _modalCancelacionProAbierto = true;
            
            MotorCancelaciones.resolverYMostrarModal(context, ctxContext).then((_) {
                if (mounted) _modalCancelacionProAbierto = false;
            });
        } else {
            MotorCancelaciones.resolverYMostrarModal(context, ctxContext);
        }
    }
    else if (accion == 'CERRAR_MODALES') {
        if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override 
  void dispose() { 
    if (ControladorActividadJornadas.pantallaActivaId == widget.jobData['id'].toString()) {
      ControladorActividadJornadas.pantallaActivaId = null; 
    } 
    _controlador.dispose();
    _controladorChat.dispose(); 
    super.dispose(); 
  }

  void _abrirModalGestion(ModeloPuja pujaInicial) {
    _controlador.seleccionarChatPro(pujaInicial.profesionalId);
    _controlador.marcarNotificacionLeidaCliente(pujaInicial.id); 
    if (pujaInicial.estadoPuja != 'esperando' && pujaInicial.estadoPuja != 'pendiente' && pujaInicial.estadoPuja != 'esperando_confirmacion_pro') {
      _controladorChat.inicializar(pTrabajoId: widget.jobData['id'].toString(), pMiId: _controlador.miId, pContraparteId: pujaInicial.profesionalId); 
    }

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _controlador,
          builder: (context, _) {
            final pujaActualizada = _controlador.pujas.firstWhere((p) => p.id == pujaInicial.id, orElse: () => pujaInicial);
            final isCongelada = _controlador.tratoFinalizado || pujaActualizada.estadoPuja == 'finalizada' || pujaActualizada.estadoPuja == 'rechazada' || pujaActualizada.estadoPuja == 'rechazada_por_pro' || pujaActualizada.estadoPuja == 'cancelada' || pujaActualizada.estadoPuja == 'desestimada' || pujaActualizada.estadoPuja == 'en_disputa' || pujaActualizada.estadoPuja == 'cancelada_por_cliente' || pujaActualizada.estadoPuja == 'cancelada_vista_pro' || pujaActualizada.estadoPuja == 'cancelada_por_pro';

            return ModalGestionPostulante(
              puja: pujaActualizada, 
              controladorChat: _controladorChat,
              isCongelado: isCongelada,
              trabajoId: _controlador.trabajoId,
              tituloTrabajo: _controlador.tituloTrabajo,
              sueldo: _controlador.sueldoNumerico,
              tipoTrabajo: 'jornada',
              fecha: _controlador.fechaFormateada,
              horaInicio: _controlador.horaInicioExtraida.isNotEmpty ? _controlador.horaInicioExtraida : null,
              horaFin: _controlador.horaFinExtraida.isNotEmpty ? _controlador.horaFinExtraida : null,
              totalHoras: _controlador.horarioSubLabel != 'Horario estimado' ? _controlador.horarioSubLabel : null,
              descripcion: _controlador.descripcionLimpia,
              onContratar: () { 
                Navigator.pop(ctx); 
                _controlador.contratarProfesional(pujaActualizada); 
              },
              onRechazar: () { 
                Navigator.pop(ctx); 
                _controlador.rechazarPostulante(pujaActualizada); 
              },
              onConfirmarPago: () {
                Navigator.pop(ctx);
                _controlador.confirmarPagoYLiberarTurno(pujaActualizada);
              },
              accionesFinales: PanelAccionesFinalesCliente(
                  estadoPuja: pujaActualizada.estadoPuja, 
                  yaLlego: pujaActualizada.coordenadasLlegada != null && pujaActualizada.coordenadasLlegada!.isNotEmpty,
                  codigoCheckin: pujaActualizada.codigoCheckin, 
                  codigoCheckout: pujaActualizada.codigoCheckout,
                  clienteCalificoPuja: pujaActualizada.clienteCalificoPuja || _pujasCalificadasEnRam.contains(pujaActualizada.id),
                  enMediacion: pujaActualizada.estadoPuja == 'en_disputa', 
                  onFinalizar: () { 
                    Navigator.pop(ctx); 
                    _abrirModalCalificacion(true, pujaActualizada); 
                  },
                  onReportar: () async { 
                    final result = await showModalBottomSheet<Map<String, dynamic>>(
                      context: context, 
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const ModalCentroResolucion(esCliente: true)
                    );
                    if (result != null) { 
                      _controlador.abrirDisputaYMediar(pujaActualizada, result['categoria'], result['solucion_esperada'], result['descripcion']); 
                    }
                  },
                  onCancelar: () {
                    Navigator.pop(ctx);
                    _controlador.solicitarCancelacionCliente(pujaActualizada);
                  },
                  onVerPoliticas: () {
                    _controlador.solicitarVerPoliticasCancelacion();
                  },
              ),
            );
          },
        );
      }
    );
  }

  void _abrirModalCalificacion(bool esCliente, ModeloPuja? pujaObjetivo) { 
    if (!mounted || _modalCalificacionAbierto) return; 
    if (_pujasCalificadasExitosamente.contains(pujaObjetivo?.id ?? _controlador.miPuja!.id)) return;

    _modalCalificacionAbierto = true;

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      isDismissible: false, 
      enableDrag: false,    
      builder: (ctx) => ModalFinalizarYCalificar(
        profesional: pujaObjetivo ?? _controlador.miPuja!, 
        esCliente: esCliente, 
        onConfirmar: (ModeloResenaPayload payload) {
          
          final String idPujaAnotada = pujaObjetivo?.id ?? _controlador.miPuja!.id;
          setState(() { _pujasCalificadasExitosamente.add(idPujaAnotada); });
          _pujasCalificadasEnRam.add(idPujaAnotada);

          ControladorActividadJornadas().blindarTrampaPorCalificacionExitosa(widget.jobData['id'].toString());

          _controlador.marcarCalificacionLocalVisualmente(idPujaAnotada, esCliente);

          Navigator.pop(ctx); 
          final perfil = context.read<GestorSesionGlobal>().perfilUsuario;
          
          if (esCliente) _controlador.finalizarYCalificar(pujaObjetivo!, payload, perfil?.apodo ?? 'Usuario', perfil?.fotoUrl ?? '');
          else _controlador.calificarComoProfesional(payload, perfil?.apodo ?? 'Usuario', perfil?.fotoUrl ?? '');
        }
      )
    ).then((_) {
      _modalCalificacionAbierto = false;
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => _verificarAutoCalificacion());
    });
  }

  @override 
  Widget build(BuildContext context) { 
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, child) {
        if (_controlador.isLoading) {
          return Scaffold(backgroundColor: tema.scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde)));
        }
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        
        // 🛡️ ARQUITECTURA LIMPIA: La UI ahora delega la evaluación estructural al controlador.
        if (_controlador.esVistaInmersiva) {
          return EnsambladorVistaInmersiva(controlador: _controlador, tema: tema, esOscuro: esOscuro, isKeyboardOpen: isKeyboardOpen);
        } else {
          return EnsambladorVistaGestion(controlador: _controlador, controladorChat: _controladorChat, tema: tema, esOscuro: esOscuro, onAbrirModalGestion: _abrirModalGestion, onAbrirCalificacion: _abrirModalCalificacion);
        }
      },
    );
  } 
}