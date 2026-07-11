// lib/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_detalle_servicio.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; 

import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_perfil_usuario.dart';
import '../../../4_componentes_globales/tarjetas/visor_imagen_pantalla_completa.dart'; 
import '../../../1_nucleo/estado_global/gestor_rutas_globales.dart';
import '../controladores/controlador_catalogo_cliente.dart';
import '../componentes/selector_nivel_servicio.dart';
import '../componentes/selector_fecha_hora_inteligente.dart';
import '../../modulo_publicaciones/componentes/seccion_direccion_maps.dart';
import '../../modulo_billetera/controladores/controlador_checkout_pagos.dart';
import 'pantalla_resumen_pago.dart'; 

class PantallaDetalleServicio extends StatefulWidget {
  final ControladorCatalogoCliente controlador;

  const PantallaDetalleServicio({Key? key, required this.controlador}) : super(key: key);

  @override
  State<PantallaDetalleServicio> createState() => _PantallaDetalleServicioState();
}

class _PantallaDetalleServicioState extends State<PantallaDetalleServicio> {
  ControladorCatalogoCliente get controlador => widget.controlador;
  bool _condicionesAceptadas = false;
  bool _isCargandoContinuar = false;

  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: ColoresApp.errorRojo));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorAcento = tema.colorScheme.primary;
    final servicio = controlador.servicioActivo!;

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Detalles del servicio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22), 
            onPressed: () {
              Share.share(servicio.payloadCompartir, subject: servicio.titulo);
            }
          ),
          
          ListenableBuilder(
            listenable: controlador,
            builder: (context, _) {
              final esFav = controlador.misFavoritosIds.contains(servicio.id);
              return IconButton(
                icon: Icon(esFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: esFav ? Colors.redAccent : tema.iconTheme.color, size: 22), 
                onPressed: () => controlador.toggleFavoritoGlobal(context, servicio)
              );
            }
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controlador,
        builder: (context, _) {
          // 🆕 BANNER ANTI-DUPLICADO: si el cliente ya tiene una reserva pendiente_pago
          // para este servicio, se muestra arriba. No bloquea TODO el servicio (solo ese horario).
          final bool tieneReserva = controlador.tieneReservaPendienteActiva;

          if (tieneReserva) {
            return _VistaReservaPendienteActiva(controlador: controlador);
          }

          return Column(
            children: [
              Expanded(child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (servicio.imagenes.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VisorImagenPantallaCompleta(
                                      imagenes: servicio.imagenes, 
                                      indiceInicial: 0
                                    )
                                  )
                                );
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: servicio.imagenes.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: servicio.imagenes.first, 
                                      height: 180, 
                                      width: double.infinity, 
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 180, width: double.infinity, 
                                        color: esOscuro ? Colors.grey[800] : Colors.grey[200], 
                                        child: const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde))
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        height: 180, width: double.infinity, 
                                        color: esOscuro ? Colors.grey[800] : Colors.grey[200], 
                                        child: const Icon(Icons.broken_image, color: Colors.grey)
                                      ),
                                    )
                                  : Container(height: 180, width: double.infinity, color: esOscuro ? Colors.grey[800] : Colors.grey[200]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Text(servicio.titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                          const SizedBox(height: 16),
                          
                          Text(
                            servicio.descripcion.isEmpty ? 'Sin descripción provista.' : servicio.descripcion,
                            style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Elegí tu plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    SelectorNivelServicio(
                      niveles: servicio.niveles,
                      idSeleccionado: controlador.idNivelSeleccionado,
                      onNivelSeleccionado: controlador.seleccionarNivel,
                    ),

                    const SizedBox(height: 32),

                    if (controlador.extrasDisponibles.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Mejorá tu servicio (Opcional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: esOscuro ? Colors.white24 : Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: controlador.extrasDisponibles.asMap().entries.map((entry) {
                              int idx = entry.key;
                              var extra = entry.value;
                              return Column(
                                children: [
                                  CheckboxListTile(
                                    title: Text(extra['nombre'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                    subtitle: Text('+\$${extra['precio'].toInt()}', style: TextStyle(color: ColoresApp.terciarioMorado, fontWeight: FontWeight.bold, fontSize: 14)),
                                    value: extra['seleccionado'],
                                    activeColor: colorAcento,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    onChanged: (val) => controlador.toggleExtra(idx),
                                  ),
                                  if (idx < controlador.extrasDisponibles.length - 1)
                                    Divider(height: 1, color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Información del lugar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorAcento.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorAcento.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(servicio.modalidad == 'a_domicilio' ? Icons.home_rounded : Icons.storefront_rounded, color: colorAcento, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      servicio.modalidad == 'a_domicilio' ? 'Este servicio se realiza: A domicilio' : 'Este servicio se realiza: En el local',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorAcento),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined, color: Colors.grey.shade600, size: 18),
                                    const SizedBox(width: 8),
                                    
                                    // 🛡️ REGLA DATA INTEGRITY (Adiós Texto Quemado)
                                    Expanded(
                                      child: Text(
                                        servicio.modalidad == 'a_domicilio' 
                                            ? 'Zona de cobertura: ${servicio.ubicacionBaseCortada}' 
                                            : 'Dirección base: ${servicio.ubicacionBaseCortada}',
                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.3),
                                      ),
                                    ),

                                  ],
                                ),
                                if (servicio.modalidad == 'en_local' && servicio.referenciaDireccionLocal.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text('Referencias del lugar:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          servicio.referenciaDireccionLocal,
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          const Text('¿Quién brinda este servicio?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (controlador.perfilVendedor == null)
                            const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
                          else
                            TarjetaPerfilUsuario(
                              perfil: controlador.perfilVendedor!, 
                              esCliente: false, 
                              onTap: () {
                                GestorRutasGlobales.abrirPerfilPublico(
                                  context,
                                  id: servicio.profesionalId,
                                  name: servicio.profesionalNombre,
                                  image: servicio.profesionalAvatar,
                                );
                              }, 
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    
                    const Text('Elegí fecha y hora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SelectorFechaHoraInteligente(
                      diasDisponibles: controlador.diasDisponibles,
                      diasLaborales: servicio.reglasDisponibilidad.diasLaborales, 
                      fechaSeleccionada: controlador.fechaSeleccionada,
                      onFechaSeleccionada: controlador.seleccionarFecha,
                      horasHabilitadas: controlador.horasHabilitadas,
                      todasLasHoras: controlador.todasLasHoras,
                      horaSeleccionada: controlador.horaSeleccionada,
                      onHoraSeleccionada: controlador.seleccionarHora,
                      isLoadingHoras: controlador.isLoadingHoras,
                      formateadorFecha: controlador.formatearFechaRelativa,
                    ),

                    const SizedBox(height: 32),

                    if (servicio.modalidad == 'a_domicilio') ...[
                      const Text('Dirección del servicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text('Ingresá la dirección exacta donde el profesional debe asistir:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      SeccionDireccionMaps(
                        calleCtrl: controlador.calleCtrl,
                        numeroCtrl: controlador.numeroCtrl,
                        provinciaSeleccionada: controlador.provinciaSeleccionada,
                        onProvinciaChanged: controlador.onProvinciaChanged,
                        localidadCtrl: controlador.localidadCtrl,
                        barrioCtrl: controlador.barrioCtrl,
                        paisCtrl: controlador.paisCtrl,
                      ),
                      const SizedBox(height: 24),
                      const Text('Notas adicionales para el profesional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      CampoTextoCristal(
                        controller: controlador.notasController,
                        hintText: 'Ej: Hay un portón negro al frente, o el timbre no funciona...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (controlador.faqsDisponibles.isNotEmpty) ...[
                      const Text('Preguntas frecuentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...controlador.faqsDisponibles.map((faq) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(border: Border.all(color: esOscuro ? Colors.white24 : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: Theme(
                          data: tema.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(faq['pregunta']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            iconColor: colorAcento,
                            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            children: [Text(faq['respuesta']!, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4))],
                          ),
                        ),
                      )).toList(),
                    ],

                    const SizedBox(height: 32),

                    // 🆕 BANNER CONDICIONES RESERVA TEMPORAL, CHECKBOX Y BOTON CONTINUAR AL FINAL DEL SCROLL
                    if (!controlador.tieneReservaPendienteActiva) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColoresApp.advertenciaAmarillo.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColoresApp.advertenciaAmarillo.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: ColoresApp.advertenciaAmarillo, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'El horario seleccionado permanecerá reservado durante 15 minutos mientras completas el pago.\n\nSi el pago se acredita después del vencimiento de la reserva, el turno puede no estar disponible y el importe podrá acreditarse como saldo en tu cuenta.',
                                style: TextStyle(fontSize: 11, height: 1.4, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 🆕 CHECKBOX DE CONDICIONES
                      InkWell(
                        onTap: _isCargandoContinuar ? null : () => setState(() => _condicionesAceptadas = !_condicionesAceptadas),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _condicionesAceptadas,
                                  onChanged: _isCargandoContinuar ? null : (val) => setState(() => _condicionesAceptadas = val ?? false),
                                  activeColor: colorAcento,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Entiendo y acepto que al continuar crearé una reserva temporal de 15 minutos.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: BotonAccionPrincipal(
                          texto: _isCargandoContinuar ? 'Reservando...' : 'Continuar',
                          isLoading: _isCargandoContinuar,
                          onPressed: (!_condicionesAceptadas || _isCargandoContinuar)
                              ? null
                              : () async {
                                  if (controlador.validarPasoConfiguracion((error) => _mostrarError(context, error))) {
                                    setState(() => _isCargandoContinuar = true);
                                    final exitoReserva = await controlador.prepararReservaAtomica(
                                      onError: (error) {
                                        _mostrarError(context, error);
                                      },
                                    );
                                    if (mounted) {
                                      setState(() => _isCargandoContinuar = false);
                                    }
                                    if (exitoReserva && mounted) {
                                      await Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => PantallaResumenPago(controlador: controlador)
                                      ));
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    }
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Pago seguro • Podés cancelar sin cargo hasta 2 hs antes', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ), // ← fin CustomScrollView (dentro del Expanded)
              ), // ← fin Expanded
            ], // ← fin children del Column (banner + contenido)
          ); // ← fin Column
        },
      ),
    );
  }
}

class _VistaReservaPendienteActiva extends StatefulWidget {
  final ControladorCatalogoCliente controlador;
  const _VistaReservaPendienteActiva({required this.controlador});

  @override
  State<_VistaReservaPendienteActiva> createState() => _VistaReservaPendienteActivaState();
}

class _VistaReservaPendienteActivaState extends State<_VistaReservaPendienteActiva> with WidgetsBindingObserver {
  bool _isPolling = false;
  final ControladorCheckoutPagos _controladorCheckout = ControladorCheckoutPagos();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarPolling();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isPolling = false;
    _controladorCheckout.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkearEstadoReserva();
    }
  }

  void _iniciarPolling() async {
    _isPolling = true;
    while (_isPolling && mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted || !_isPolling) break;
      await _checkearEstadoReserva();
    }
  }

  Future<void> _checkearEstadoReserva() async {
    final reservaId = widget.controlador.reservaPendienteServicioActivo?['id']?.toString();
    if (reservaId == null) return;
    
    final estado = await widget.controlador.verificarEstadoReserva(idOpcional: reservaId);
    if (!mounted) return;
    
    if (estado == 'confirmada') {
      _isPolling = false;
      widget.controlador.limpiarReservaPendienteRAM();
      widget.controlador.actualizarUI();
      _mostrarModalExito(context);
    } else if (estado == 'expirada') {
      _isPolling = false;
      widget.controlador.limpiarReservaPendienteRAM();
      widget.controlador.actualizarUI();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La reserva expiró por falta de pago.'), backgroundColor: ColoresApp.advertenciaAmarillo),
      );
    }
  }

  void _mostrarModalExito(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: esOscuro ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: ColoresApp.primarioVerde, size: 56),
            SizedBox(height: 16),
            Text('¡Pago y Reserva Exitosa!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tu reserva fue confirmada con éxito y el dinero está protegido. Ya puedes gestionarla desde tu Agenda.', 
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: BotonAccionPrincipal(
              texto: 'Ir a mi Agenda',
              onPressed: () {
                Navigator.pop(ctx); 
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded, color: ColoresApp.advertenciaAmarillo, size: 64),
            const SizedBox(height: 24),
            const Text('Reserva Pendiente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Estamos esperando que impacte el pago para la fecha y hora del servicio seleccionado.\n\nSi no pagaste, ve a pagar. Si te arrepentiste y no quieres el turno, espera a que pasen los 15 minutos de la reserva para poder elegir otro horario.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ListenableBuilder(
                listenable: _controladorCheckout,
                builder: (context, _) {
                  final bool isCargando = _controladorCheckout.isSubmitting;
                  return Column(
                    children: [
                      BotonAccionPrincipal(
                        texto: isCargando ? 'Redirigiendo...' : 'Ir a pagar',
                        isLoading: isCargando,
                        onPressed: isCargando ? null : () {
                          final idRes = widget.controlador.reservaPendienteServicioActivo?['id']?.toString();
                          final precioRaw = widget.controlador.reservaPendienteServicioActivo?['precio'];
                          double monto = widget.controlador.totalCalculado;
                          if (precioRaw != null) {
                            if (precioRaw is num) {
                              monto = precioRaw.toDouble();
                            } else {
                              monto = double.tryParse(precioRaw.toString()) ?? monto;
                            }
                          }
                          
                          if (idRes != null) {
                            _controladorCheckout.procesarPago(
                              trabajoId: idRes,
                              monto: monto,
                              metodoPago: 'mercadopago', // Lo mandamos directamente por MP
                              onSuccess: (datos) {
                                // No hacemos nada, el polling lo detectará cuando pague
                              },
                              onError: (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e), backgroundColor: ColoresApp.errorRojo),
                                );
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: isCargando ? null : () async {
                          await widget.controlador.abortarCheckoutTemporalYBorrar();
                          if (mounted) {
                            // The widget tree will rebuild because we cleared it
                            // but we also want to trigger an update in the parent.
                            // The parent `PantallaDetalleServicio` listens to the controller.
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColoresApp.errorRojo,
                          side: const BorderSide(color: ColoresApp.errorRojo),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar Reserva'),
                      ),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}