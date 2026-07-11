// lib/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_ejecucion_catalogo.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../4_componentes_globales/botones/boton_accion_lista.dart';

import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/modelo_resena_payload.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_validacion_pin.dart';
import '../../../4_componentes_globales/estados/pantalla_cargando_bloqueante.dart';

import '../../../4_componentes_globales/tarjetas/tarjeta_perfil_usuario.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_puja_postulante.dart';

import '../../../4_componentes_globales/indicadores/linea_tiempo_estados.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_estado_contratado_pro.dart';
import '../../../4_componentes_globales/paneles_ejecucion/panel_acciones_finales_cliente.dart';
import '../componentes/panel_ejecucion_catalogo_viajero.dart';
import '../componentes/panel_ejecucion_catalogo_esperando.dart';
import '../../../4_componentes_globales/modales_y_alertas/flujo_calificacion/modal_finalizar_y_calificar.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_constructor_presupuesto.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_evaluar_ticket_adicional.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';

import '../../../4_componentes_globales/motor_cancelaciones_visuales/motor_cancelaciones.dart';
import '../../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';

import '../../modulo_chat_mensajes/componentes/seccion_chat_colapsable.dart';
import '../../modulo_chat_mensajes/controladores/controlador_chat.dart';
import '../controladores/controlador_actividad_catalogo.dart';

import '../controladores/controlador_ejecucion_catalogo.dart';
import '../componentes/seccion_detalles_catalogo.dart'; 
import '../componentes/carousel_imagenes.dart';

class PantallaEjecucionCatalogo extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const PantallaEjecucionCatalogo({Key? key, required this.jobData}) : super(key: key);

  @override
  State<PantallaEjecucionCatalogo> createState() => _PantallaEjecucionCatalogoState();
}

class _PantallaEjecucionCatalogoState extends State<PantallaEjecucionCatalogo> {
  late ControladorEjecucionCatalogo _controlador;
  final ControladorChat _controladorChat = ControladorChat();
  
  bool _modalCalificacionAbierto = false; 
  bool _modalCancelacionProAbierto = false;
  int _indiceSubPantalla = 0; // 0 = Gestión, 1 = Ver detalles

  @override
  void initState() {
    super.initState();
    final String jobId = widget.jobData['id'].toString();
    ControladorActividadCatalogo.pantallaActivaId = jobId;

    _controlador = ControladorEjecucionCatalogo(widget.jobData);
    _controlador.onRequerirAccionUI = _manejarEventosUI; 
    _controlador.addListener(_verificarAutoCalificacion);
    _controlador.addListener(_actualizarIdsChat);

    final miId = GestorSesionGlobal().miIdUsuario;
    final contraparteId = miId == _controlador.clienteId ? _controlador.profesionalId : _controlador.clienteId;
    _controladorChat.inicializar(pTrabajoId: jobId, pMiId: miId, pContraparteId: contraparteId);
  }

  void _actualizarIdsChat() {
    if (!mounted) return;
    final miId = GestorSesionGlobal().miIdUsuario;
    final contraparteId = miId == _controlador.clienteId ? _controlador.profesionalId : _controlador.clienteId;
    if (_controladorChat.contraparteId != contraparteId || _controladorChat.miId != miId) {
      _controladorChat.miId = miId;
      _controladorChat.contraparteId = contraparteId;
      if (contraparteId.isNotEmpty && _controladorChat.mensajes.isEmpty) {
        _controladorChat.inicializar(pTrabajoId: _controlador.idReserva, pMiId: miId, pContraparteId: contraparteId);
      }
    }
  }

  @override
  void dispose() {
    if (ControladorActividadCatalogo.pantallaActivaId == widget.jobData['id'].toString()) {
      ControladorActividadCatalogo.pantallaActivaId = null;
    }
    _controlador.removeListener(_actualizarIdsChat);
    _controlador.removeListener(_verificarAutoCalificacion);
    _controlador.dispose();
    _controladorChat.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: ColoresApp.errorRojo));
  }

  void _manejarEventosUI(String tipoEvento, [dynamic payload]) {
    if (tipoEvento == 'EVALUAR_TICKET') {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final acepto = await DialogoEvaluarTicketAdicional.mostrar(
          context, 
          precioBase: _controlador.precioBaseAcordadoLimpio,
          itemsPropuestos: _controlador.adicionalesParaEvaluacionCliente,
        );
        if (acepto != null) _controlador.responderTicketAdicionalBatch(acepto);
      });
    }
    else if (tipoEvento == 'TICKET_RESPONDIDO') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
           showDialog(
             context: context, 
             builder: (ctx) => DialogoConfirmacionEstandar(
               titulo: 'Revisión finalizada',
               mensaje: 'El cliente ha respondido a tu última actualización de presupuesto.',
               textoBotonConfirmar: 'ENTENDIDO',
               colorConfirmar: ColoresApp.terciarioMorado,
               onConfirmar: () => Navigator.pop(ctx),
               onCancelar: () => Navigator.pop(ctx), 
             )
           );
        }
      });
    }
    
    else if (tipoEvento == 'MOSTRAR_MODAL_CANCELACION') {
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

    else if (tipoEvento == 'MOSTRAR_ERROR') {
        _mostrarError(payload.toString());
    }
    else if (tipoEvento == 'CERRAR_MODALES') {
        if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  Future<void> _pedirPin(String tipo) async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoValidacionPin(
        titulo: tipo == 'llegada' ? 'PIN de Llegada' : 'PIN de Finalización',
        subtitulo: 'Solicita a la contraparte que te dicte los 6 dígitos.',
      ),
    );

    if (pin != null) {
      if (tipo == 'llegada') _controlador.procesarPinCheckin(pin, _mostrarError);
      else _controlador.procesarPinCheckout(pin, _mostrarError);
    }
  }

  void _verificarAutoCalificacion() {
    if (!mounted || _controlador.isCargando || _modalCalificacionAbierto) return;
    bool debeCalificar = false;
    
    if (!_controlador.soyElProfesional && _controlador.completada && !_controlador.clienteCalificoLocal) debeCalificar = true;
    else if (_controlador.soyElProfesional && _controlador.completada && !_controlador.proCalificoLocal) debeCalificar = true;

    if (debeCalificar) WidgetsBinding.instance.addPostFrameCallback((_) { _abrirModalCalificacion(!_controlador.soyElProfesional); });
  }

  void _abrirModalCalificacion(bool esCliente) {
    if (!mounted || _modalCalificacionAbierto) return;
    _modalCalificacionAbierto = true;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true, isDismissible: false, enableDrag: false,    
      builder: (ctx) => ModalFinalizarYCalificar(
        profesional: _controlador.generarPujaFantasmaCalificacion, 
        esCliente: esCliente, 
        onConfirmar: (ModeloResenaPayload payload) {
          ControladorActividadCatalogo().blindarTrampaPorCalificacionExitosa(_controlador.idReserva);
          _controlador.marcarCalificacionLocalVisualmente(esCliente);
          Navigator.pop(ctx); 
          
          final perfil = context.read<GestorSesionGlobal>().perfilUsuario;
          _controlador.finalizarYCalificar(payload, perfil?.apodo ?? 'Usuario', perfil?.fotoUrl ?? '', esCliente);
        }
      )
    ).then((_) { _modalCalificacionAbierto = false; });
  }

  Widget _buildTabsToggle(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF161618) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.transparent),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _indiceSubPantalla = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _indiceSubPantalla == 0
                      ? (esOscuro ? const Color(0xFF262629) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _indiceSubPantalla == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Gestión',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _indiceSubPantalla == 0
                          ? (esOscuro ? Colors.white : Colors.black)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _indiceSubPantalla = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _indiceSubPantalla == 1
                      ? (esOscuro ? const Color(0xFF262629) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _indiceSubPantalla == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Ver detalles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _indiceSubPantalla == 1
                          ? (esOscuro ? Colors.white : Colors.black)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPlan(BuildContext context, ModeloNivelServicio nivel) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    final incluye = nivel.caracteristicasProcesadas;
    final noIncluye = nivel.loQueNoCubreProcesado;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF131314) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColoresApp.terciarioMorado.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: ColoresApp.terciarioMorado, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan contratado', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Text(nivel.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (incluye.isNotEmpty) ...[
            const Text('¿Qué incluye?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...incluye.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: ColoresApp.primarioVerde, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: esOscuro ? Colors.white70 : Colors.black87))),
                ],
              ),
            )),
          ],
          if (noIncluye.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('¿Qué NO incluye?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...noIncluye.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_rounded, color: ColoresApp.errorRojo, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: esOscuro ? Colors.white70 : Colors.black87))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTarjetaContraparte(BuildContext context, bool esOscuro) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(_controlador.soyElProfesional ? 'Sobre el cliente' : 'Sobre el profesional', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        _controlador.soyElProfesional 
          ? TarjetaPerfilUsuario( 
              perfil: _controlador.generarPerfilContraparteMock, 
              esCliente: true, 
              onTap: () {
                 Navigator.pushNamed(context, '/perfil_profesional', arguments: {
                    'id': _controlador.clienteId,
                    'name': _controlador.contraparteNombreLimpio,
                    'image': _controlador.reservaActiva?.contraparteAvatar ?? ''
                 });
              } 
            )
          : TarjetaPujaPostulante(
              puja: _controlador.generarPujaContraparteMock,
              ocultarMonto: true,
              onTapPerfil: () {
                 Navigator.pushNamed(context, '/perfil_profesional', arguments: {
                    'id': _controlador.profesionalId,
                    'name': _controlador.contraparteNombreLimpio,
                    'image': _controlador.reservaActiva?.contraparteAvatar ?? ''
                 });
              },
            ),
      ])
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text('Gestión del Servicio', style: TextStyle(color: tema.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: tema.textTheme.bodyLarge?.color),
      ),
      body: ListenableBuilder(
        listenable: _controlador,
        builder: (context, _) {
          if (_controlador.isCargando) return const Center(child: CircularProgressIndicator());

          final reserva = _controlador.reservaActiva!;
          final String estadoVisualParaPaneles = reserva.estado == 'esperando_pin_llegada' ? 'aceptada' : reserva.estado;
          final bool estaCancelada = reserva.estado == 'cancelado';

          return Stack(
            children: [
              Column(
                children: [
                  _buildTabsToggle(context),
                  Expanded(
                    child: IndexedStack(
                      index: _indiceSubPantalla,
                      children: [
                        SingleChildScrollView(
                            key: const PageStorageKey('gestion'),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTarjetaContraparte(context, esOscuro),

                                if (estaCancelada) ...[
                                  MotorCancelaciones.resolverVistaEstatica(
                                    context,
                                    CancelacionContexto(
                                      dominio: DominioApp.catalogo,
                                      accion: TipoAccionCancelacion.vistaInPlace,
                                      actor: _controlador.soyElProfesional ? ActorCancelacion.profesional : ActorCancelacion.cliente,
                                      estadoTransaccional: reserva.estadoNegociacion,
                                    ),
                                  )
                                ] else ...[
                                  if (_controlador.soyElProfesional && (_controlador.enCurso || reserva.estado == 'esperando_pin_llegada'))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: BotonAccionLista(
                                        texto: 'Actualizar Ticket',
                                        icono: Icons.receipt_long_rounded,
                                        colorAcento: ColoresApp.terciarioMorado,
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                            builder: (ctx) => ListenableBuilder(
                                              listenable: _controlador,
                                              builder: (ctx, child) {
                                                return ModalConstructorPresupuesto(
                                                  tituloTrabajo: reserva.titulo,
                                                  precioBase: _controlador.precioBaseAcordadoLimpio,
                                                  itemsDb: _controlador.adicionalesBorradorPro,
                                                  bloqueado: _controlador.tieneAdicionalesPendientes,
                                                  onEnviar: (nuevosItems) => _controlador.enviarTicketAdicionales(nuevosItems),
                                                );
                                              }
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Estado del servicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 20),
                                        LineaTiempoEstados(
                                          llegoAlLugar: _controlador.yaLlego, 
                                          enCurso: _controlador.enCurso, 
                                          completada: _controlador.completada
                                        ),
                                      ]
                                    )
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _controlador.soyElQueViaja
                                      ? PanelEjecucionCatalogoViajero(
                                          estadoPuja: estadoVisualParaPaneles,
                                          profesionalEnCamino: _controlador.enCaminoAutomatico || _controlador.yaLlego, 
                                          coordenadasLlegada: reserva.estado == 'esperando_pin_llegada' ? 'registrada' : null,
                                          codigoCheckout: _controlador.codigoCheckout,
                                          onLlegadaGPS: () => _controlador.registrarLlegadaSatelital(_mostrarError),
                                          onValidarCheckin: () => _pedirPin('llegada'),
                                          onValidarCheckout: () => _pedirPin('salida'),
                                          onFinalizarTarea: () => _controlador.registrarTareaFinalizada(_mostrarError),
                                          onAbrirMapa: _controlador.abrirNavegadorGPS,
                                          onReportarProblema: () {},
                                          esProfesional: _controlador.soyElProfesional,
                                          yaCalifico: _controlador.soyElProfesional ? _controlador.proCalificoLocal : _controlador.clienteCalificoLocal,
                                          onCalificar: () => _abrirModalCalificacion(!_controlador.soyElProfesional),
                                        )
                                      : PanelEjecucionCatalogoEsperando(
                                          estadoPuja: estadoVisualParaPaneles,
                                          yaLlego: _controlador.yaLlego,
                                          codigoCheckin: _controlador.codigoCheckin, 
                                          codigoCheckout: _controlador.codigoCheckout,
                                          yaCalifico: _controlador.soyElProfesional ? _controlador.proCalificoLocal : _controlador.clienteCalificoLocal, 
                                          onCalificar: () => _abrirModalCalificacion(!_controlador.soyElProfesional),
                                          onReportar: () {},
                                          onFinalizarTarea: () => _controlador.registrarTareaFinalizada(_mostrarError),
                                          onValidarCheckout: () => _pedirPin('salida'),
                                          esProfesional: _controlador.soyElProfesional,
                                        ),
                                  ),
                                ], 

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), 
                                  child: SeccionChatColapsable(
                                    controlador: _controladorChat, 
                                    isCongelado: _controlador.completada || reserva.estado == 'cancelado', 
                                    colorAcento: _controlador.soyElProfesional ? ColoresApp.terciarioMorado : ColoresApp.primarioVerde
                                  )
                                ),
                                
                                if (reserva.estado == 'aceptada' || reserva.estado == 'esperando_pin_llegada' || reserva.estado == 'esperando_confirmacion_pro')
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                                    child: Column(
                                      children: [
                                        // 🚨 BOTONES DE CANCELACIÓN MOVIDOS AQUÍ (Para ambos lados)
                                        BotonAccionLista(
                                          texto: 'Políticas de cancelación', 
                                          icono: Icons.policy_outlined, 
                                          colorAcento: Colors.grey, 
                                          onTap: _controlador.solicitarVerPoliticasCancelacion
                                        ),
                                        BotonAccionLista(
                                          texto: 'Cancelar asistencia', 
                                          icono: Icons.cancel_outlined, 
                                          colorAcento: ColoresApp.errorRojo, 
                                          iconoDerecho: null, 
                                          onTap: _controlador.soyElProfesional ? _controlador.solicitarCancelacionPro : _controlador.solicitarCancelacionCliente
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        SingleChildScrollView(
                            key: const PageStorageKey('detalles'),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CarouselImagenes(imagenes: _controlador.servicioAsociado?.imagenes ?? reserva.imagenes),

                                SeccionDetallesCatalogo(
                                  titulo: reserva.titulo,
                                  precio: _controlador.precioTotalConAdicionales.toStringAsFixed(0),
                                  fechaFormateada: _controlador.fechaReservaFormateada,
                                  horarioFormateado: _controlador.horarioReservaFormateado,
                                  descripcion: (_controlador.servicioAsociado?.descripcion != null && _controlador.servicioAsociado!.descripcion.isNotEmpty)
                                      ? _controlador.servicioAsociado!.descripcion
                                      : reserva.descripcion,
                                  imagenes: reserva.imagenes,
                                  ubicacionLimpia: _controlador.ubicacionLimpia,
                                ),

                                if (_controlador.servicioAsociado != null) ...[
                                  Builder(
                                    builder: (context) {
                                      ModeloNivelServicio? nivelElegido;
                                      final titulo = reserva.titulo;
                                      for (var nivel in _controlador.servicioAsociado!.niveles) {
                                        if (titulo.endsWith(nivel.nombre) || titulo.contains(nivel.nombre)) {
                                          nivelElegido = nivel;
                                          break;
                                        }
                                      }
                                      if (nivelElegido == null && _controlador.servicioAsociado!.niveles.isNotEmpty) {
                                        nivelElegido = _controlador.servicioAsociado!.niveles.first;
                                      }
                                      
                                      if (nivelElegido != null) {
                                        return _buildSeccionPlan(context, nivelElegido);
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],

                                _buildTarjetaContraparte(context, esOscuro),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_controlador.isProcesandoAccion)
                const PantallaCargandoBloqueante(mensaje: 'Procesando...'),
            ],
          );
        },
      ),
    );
  }
}