// lib/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_resumen_pago.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../controladores/controlador_catalogo_cliente.dart';
import '../../modulo_billetera/controladores/controlador_checkout_pagos.dart';
import '../../modulo_billetera/controladores/controlador_billetera.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

class PantallaResumenPago extends StatefulWidget {
  final ControladorCatalogoCliente controlador;

  const PantallaResumenPago({Key? key, required this.controlador}) : super(key: key);

  @override
  State<PantallaResumenPago> createState() => _PantallaResumenPagoState();
}

class _PantallaResumenPagoState extends State<PantallaResumenPago> {
  ControladorCatalogoCliente get controlador => widget.controlador;
  final ControladorCheckoutPagos _controladorCheckout = ControladorCheckoutPagos();
  final ControladorBilletera _controladorBilletera = ControladorBilletera();

  String _metodoPagoSeleccionado = 'wallet';
  bool _esperandoConfirmacionAsincrona = false;

  // 🆕 Estado del panel "Reserva pendiente" (al volver de MP sin confirmación).
  bool _mostrarPanelPendiente = false;

  // 🆕 Estado del panel "Reserva expirada" (cuando el cron venció la reserva).
  bool _mostrarPanelExpirada = false;
  
  bool _iniciandoPago = false;

  @override
  void initState() {
    super.initState();
    _controladorBilletera.inicializar(GestorSesionGlobal().miIdUsuario);
  }

  @override
  void dispose() {
    _controladorCheckout.dispose();
    _controladorBilletera.dispose();
    super.dispose();
  }

  void _procesarPago(double total) {
    _controladorCheckout.procesarPago(
      trabajoId: controlador.idReservaTemporalActiva!,
      monto: total,
      metodoPago: _metodoPagoSeleccionado,
      onSuccess: (datosPasarela) {
        if (!mounted) return;

        if (_metodoPagoSeleccionado == 'mercadopago') {
          // Si es Mercado Pago, la URL ya se abrió externamente.
          // Regresamos inmediatamente a la PantallaDetalleServicio.
          // Al volver, PantallaDetalleServicio detectará automáticamente que hay una reserva pendiente activa
          // y mostrará la _VistaReservaPendienteActiva (la cual tiene polling y didChangeAppLifecycleState para verificar el pago de forma limpia y bloqueada).
          // 🛡️ BARRERA EVITAR DOBLE POP: solo hacemos pop si la ruta actual sigue siendo esta pantalla.
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.pop(context);
          }
          return;
        }

        final String llaveIdempotencia = datosPasarela['llave_idempotencia'];
        
        setState(() => _esperandoConfirmacionAsincrona = true);

        _controladorCheckout.observarEstadoAsincrono(
          llaveIdempotencia: llaveIdempotencia,
          onCompletado: () {
            if (!mounted) return;
            setState(() {
              _esperandoConfirmacionAsincrona = false;
              _mostrarPanelPendiente = false;
            });
            controlador.idReservaTemporalActiva = null;
            _mostrarModalExito(context);
          },
          onFallido: (error) {
            if (!mounted) return;
            setState(() {
              _esperandoConfirmacionAsincrona = false;
              _mostrarPanelPendiente = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: ColoresApp.errorRojo),
            );
          },
          onPendiente: () {
            if (!mounted) return;
            setState(() {
              _esperandoConfirmacionAsincrona = false;
              _mostrarPanelPendiente = true;
            });
          },
        );
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: ColoresApp.errorRojo),
        );
      },
    );
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
          'Tu reserva fue confirmada con éxito y el dinero está protegido bajo Escrow. Ya puedes gestionarla desde tu Agenda.', 
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: BotonAccionPrincipal(
              texto: 'Entendido',
              onPressed: () {
                Navigator.pop(ctx); 
                Navigator.pop(context); 
                Navigator.pop(context); 
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
    final esOscuro = tema.brightness == Brightness.dark;
    final colorAcento = tema.colorScheme.primary;

    final servicio = controlador.servicioActivo!;
    final nivelElegido = controlador.nivelActivo!;
    final extrasActivos = controlador.extrasDisponibles.where((e) => e['seleccionado'] == true).toList();
    final total = controlador.totalCalculado;
    
    final horaStr = controlador.horaResumenFormateada;
    final fechaStr = controlador.fechaResumenFormateada;

    // 🆕 Si el usuario volvió de MP sin confirmación, mostramos el panel "Reserva pendiente"
    // en lugar del body normal. No se borra la reserva (fluirá con el cron de 15 min).
    if (_mostrarPanelPendiente && !_mostrarPanelExpirada) {
      return _construirPanelReservaPendiente(context, tema, esOscuro, fechaStr, horaStr);
    }

    // 🆕 FASE 5: Si la reserva expiró (cron la venció), mostramos el panel "Reserva expirada".
    if (_mostrarPanelExpirada) {
      return _construirPanelReservaExpirada(context, esOscuro);
    }

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: Column(
          children: [
            const Text('Revisar y Confirmar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Transacción 100% segura', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: controlador,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Qué estás contratando?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _SeccionBlanca(
                  esOscuro: esOscuro,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: servicio.imagenes.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: servicio.imagenes.first, 
                                    width: 64, 
                                    height: 64, 
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(width: 64, height: 64, color: esOscuro ? Colors.grey[800] : Colors.grey[200], child: const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde, strokeWidth: 2))),
                                    errorWidget: (context, url, error) => Container(width: 64, height: 64, color: esOscuro ? Colors.grey[800] : Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                                  )
                                : Container(width: 64, height: 64, color: Colors.grey.shade300),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(servicio.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(servicio.profesionalNombre, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                const Text('¿Dónde se realizará?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _SeccionBlanca(
                  esOscuro: esOscuro,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(servicio.modalidad == 'a_domicilio' ? Icons.home_rounded : Icons.storefront_rounded, size: 20, color: colorAcento),
                          const SizedBox(width: 8),
                          Text(
                            servicio.modalidad == 'a_domicilio' ? 'Servicio a domicilio' : 'Servicio en el local del profesional',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorAcento),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servicio.modalidad == 'a_domicilio' 
                                      ? 'Dirección registrada por ti:' 
                                      : 'Debes acercarte a:', 
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  servicio.modalidad == 'a_domicilio' ? controlador.direccionConcatenada : servicio.direccionLocal, 
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('¿Cuándo se realizará?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _SeccionBlanca(
                  esOscuro: esOscuro,
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Expanded(child: Text(fechaStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 24, color: esOscuro ? Colors.white24 : Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(horaStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Resumen del pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _SeccionBlanca(
                  esOscuro: esOscuro,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MODALIDAD CATÁLOGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: ColoresApp.primarioVerde)),
                            const SizedBox(height: 12),
                            Text('Cliente: ${GestorSesionGlobal().perfilUsuario?.apodo ?? "Tú"} (ID: #${GestorSesionGlobal().miIdUsuario.length > 8 ? GestorSesionGlobal().miIdUsuario.substring(0, 8).toUpperCase() : GestorSesionGlobal().miIdUsuario.toUpperCase()})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: esOscuro ? Colors.grey[300] : Colors.grey[800])),
                            const SizedBox(height: 4),
                            Text('Prestador del servicio: ${servicio.profesionalNombre} (ID: #${servicio.profesionalId.length > 8 ? servicio.profesionalId.substring(0, 8).toUpperCase() : servicio.profesionalId.toUpperCase()})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: esOscuro ? Colors.grey[300] : Colors.grey[800])),
                            const SizedBox(height: 16),
                            _FilaDetalleTrabajo(etiqueta: 'Nº de Trabajo', valor: '#${controlador.idReservaTemporalActiva!.length > 8 ? controlador.idReservaTemporalActiva!.substring(0, 8).toUpperCase() : controlador.idReservaTemporalActiva!.toUpperCase()}'),
                            const SizedBox(height: 8),
                            _FilaDetalleTrabajo(etiqueta: 'Fecha reservada', valor: fechaStr),
                            const SizedBox(height: 8),
                            _FilaDetalleTrabajo(etiqueta: 'Hora de llegada', valor: horaStr),
                            const SizedBox(height: 8),
                            _FilaDetalleTrabajo(etiqueta: 'Plan elegido', valor: nivelElegido.nombre),
                            const SizedBox(height: 8),
                            _FilaDetalleTrabajo(etiqueta: 'Duración aprox.', valor: nivelElegido.duracionEstimada),
                            
                            const SizedBox(height: 16),
                            Divider(height: 1, color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                            const SizedBox(height: 16),
                            
                            if (servicio.descripcion.isNotEmpty) ...[
                              const Text('Descripción del servicio:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(servicio.descripcion, style: const TextStyle(fontSize: 13, height: 1.4)),
                              const SizedBox(height: 16),
                              Divider(height: 1, color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                              const SizedBox(height: 16),
                            ],
                            
                            if (nivelElegido.caracteristicasProcesadas.isNotEmpty || nivelElegido.descripcionCorta.isNotEmpty) ...[
                              Text('Qué incluye el plan "${nivelElegido.nombre}":', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              if (nivelElegido.caracteristicasProcesadas.isNotEmpty)
                                ...nivelElegido.caracteristicasProcesadas.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 15, color: ColoresApp.primarioVerde),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(c, style: const TextStyle(fontSize: 13))),
                                    ],
                                  ),
                                ))
                              else
                                Text(nivelElegido.descripcionCorta, style: const TextStyle(fontSize: 13, height: 1.4)),
                              const SizedBox(height: 16),
                              Divider(height: 1, color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                              const SizedBox(height: 16),
                            ],
                            
                            if (nivelElegido.loQueNoCubreProcesado.isNotEmpty || (nivelElegido.loQueNoCubre != null && nivelElegido.loQueNoCubre!.trim().isNotEmpty)) ...[
                              const Text('No incluye:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              if (nivelElegido.loQueNoCubreProcesado.isNotEmpty)
                                ...nivelElegido.loQueNoCubreProcesado.map((nc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.cancel_outlined, size: 15, color: Colors.redAccent),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(nc, style: const TextStyle(fontSize: 13))),
                                    ],
                                  ),
                                ))
                              else
                                Text(nivelElegido.loQueNoCubre!, style: const TextStyle(fontSize: 13, height: 1.4)),
                              const SizedBox(height: 16),
                              Divider(height: 1, color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                              const SizedBox(height: 16),
                            ],
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Plan: ${nivelElegido.nombre}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text('\$${nivelElegido.precioFijo.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            
                            if (extrasActivos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...extrasActivos.map((extra) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('+ ${extra['nombre']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text('\$${extra['precio'].toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )).toList(),
                            ],
                            
                            const SizedBox(height: 16),
                            Divider(height: 1, color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL A PAGAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('\$${total.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: colorAcento)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('¿Con qué querés pagar?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: _controladorBilletera,
                  builder: (context, _) {
                    final saldo = _controladorBilletera.walletActual?.saldo ?? 0.0;
                    final bool saldoSuficiente = saldo >= total;
                    
                    // Auto-seleccionar MP si wallet no alcanza
                    if (!saldoSuficiente && _metodoPagoSeleccionado == 'wallet') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _metodoPagoSeleccionado = 'mercadopago');
                      });
                    }

                    return _MetodoPagoSelector(
                      titulo: 'Saldo de mi billetera (\$${saldo.toInt()})',
                      subtitulo: saldoSuficiente ? 'Pago instantáneo sin comisiones.' : 'Saldo insuficiente.',
                      icono: Icons.account_balance_wallet_rounded,
                      seleccionado: _metodoPagoSeleccionado == 'wallet',
                      habilitado: saldoSuficiente,
                      onTap: saldoSuficiente ? () => setState(() => _metodoPagoSeleccionado = 'wallet') : null,
                    );
                  }
                ),
                const SizedBox(height: 12),
                _MetodoPagoSelector(
                  titulo: 'Mercado Pago',
                  subtitulo: 'Dinero en cuenta, débito o crédito (Impacto instantáneo).',
                  icono: Icons.credit_card_rounded,
                  seleccionado: _metodoPagoSeleccionado == 'mercadopago',
                  habilitado: true,
                  onTap: () => setState(() => _metodoPagoSeleccionado = 'mercadopago'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ListenableBuilder(
                    listenable: _controladorCheckout,
                    builder: (context, _) {
                      bool isCargando = controlador.isProcesandoCheckout || _esperandoConfirmacionAsincrona || _controladorCheckout.isSubmitting || _iniciandoPago;
                      String textoBoton = 'Confirmar y Pagar \$${total.toInt()}';
                      if (_controladorCheckout.isSubmitting) textoBoton = 'Redirigiendo...';
                      else if (isCargando) textoBoton = 'Procesando...';

                      return BotonAccionPrincipal(
                        texto: textoBoton,
                        isLoading: isCargando,
                        onPressed: !isCargando ? () async {
                          setState(() => _iniciandoPago = true);
                          _procesarPago(total);
                          if (mounted) {
                            setState(() => _iniciandoPago = false);
                          }
                        } : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text('Al confirmar aceptás nuestros Términos y Condiciones.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      // Muestra loading bloqueante si se está procesando
      bottomNavigationBar: _esperandoConfirmacionAsincrona ? const SizedBox.shrink() : null,
    );
  }

  // 🆕 Construye el panel "Reserva pendiente" cuando el usuario vuelve de MP sin confirmación.
  // El estado lo decide 'trabajos.estado' (única fuente de verdad).
  Widget _construirPanelReservaPendiente(BuildContext context, ThemeData tema, bool esOscuro, String fechaStr, String horaStr) {
    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Reserva pendiente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _PanelReservaPendiente(
            fechaStr: fechaStr,
            horaStr: horaStr,
            onVerificarEstado: () async {
              final estado = await controlador.verificarEstadoReserva();
              if (!mounted) return;
              if (estado == 'confirmada') {
                // El webhook ya consolidó: limpiamos RAM y celebramos.
                controlador.idReservaTemporalActiva = null;
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
                        Text('¡Reserva confirmada!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: const Text('Tu turno fue reservado correctamente.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: BotonAccionPrincipal(
                          texto: 'Aceptar',
                          onPressed: () {
                            Navigator.pop(ctx); // cierra diálogo
                            Navigator.pop(context); // sale de resumen pago
                          },
                        ),
                      )
                    ],
                  ),
                );
              } else if (estado == 'expirada') {
                // El cron la marcó expirada: mostramos estado expirado.
                setState(() => _mostrarPanelExpirada = true);
              } else {
                // Sigue pendiente o no se pudo determinar.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El pago aún no se confirmó. Intentá nuevamente en unos segundos.'),
                    backgroundColor: ColoresApp.advertenciaAmarillo,
                  ),
                );
              }
            },
            onIrAPagar: () {
              setState(() => _mostrarPanelPendiente = false);
              _procesarPago(controlador.totalCalculado);
            },
          ),
        ),
      ),
    );
  }

  // 🆕 FASE 5: Construye el panel "Reserva expirada" cuando el cron venció la reserva.
  Widget _construirPanelReservaExpirada(BuildContext context, bool esOscuro) {
    // Limpieza de RAM: la reserva ya no es recuperable.
    controlador.idReservaTemporalActiva = null;
    controlador.limpiarReservaPendienteRAM();

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Reserva expirada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.timer_off_rounded, size: 64, color: ColoresApp.errorRojo),
              const SizedBox(height: 24),
              const Text('La reserva ha expirado.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'El tiempo para completar el pago finalizó y el horario quedó liberado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: BotonAccionPrincipal(
                  texto: 'Reservar nuevamente',
                  onPressed: () {
                    // Vuelve al detalle para elegir un horario nuevo.
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaDetalleTrabajo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  
  const _FilaDetalleTrabajo({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.constrainWidth();
              const dashWidth = 3.0;
              const dashHeight = 1.0;
              final dashCount = (boxWidth / (2 * dashWidth)).floor();
              return Flex(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                direction: Axis.horizontal,
                children: List.generate(dashCount, (_) {
                  return SizedBox(
                    width: dashWidth,
                    height: dashHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.grey),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
      ],
    );
  }
}

/// 🆕 Dumb Component: panel "Reserva pendiente".
/// Recibe datos pre-formateados y emite callbacks. Cero lógica de negocio.
/// Reutilizable para Jornadas/Oficios cuando se pulan (misma lógica de pago).
class _PanelReservaPendiente extends StatelessWidget {
  final String fechaStr;
  final String horaStr;
  final VoidCallback onVerificarEstado;
  final VoidCallback onIrAPagar;

  const _PanelReservaPendiente({
    required this.fechaStr,
    required this.horaStr,
    required this.onVerificarEstado,
    required this.onIrAPagar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.hourglass_top_rounded, size: 64, color: ColoresApp.advertenciaAmarillo),
        const SizedBox(height: 24),
        const Text('Estamos esperando la confirmación del pago.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _FilaDato(icono: Icons.calendar_today_outlined, etiqueta: 'Fecha', valor: fechaStr),
        const SizedBox(height: 12),
        _FilaDato(icono: Icons.access_time, etiqueta: 'Hora', valor: horaStr),
        const SizedBox(height: 12),
        const _FilaDato(icono: Icons.hourglass_empty, etiqueta: 'Reserva', valor: 'Válida por 15 minutos'),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: BotonAccionPrincipal(texto: 'Verificar estado', onPressed: onVerificarEstado),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onIrAPagar,
            child: const Text('Ir a pagar nuevamente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _FilaDato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaDato({required this.icono, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$etiqueta: ', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Expanded(child: Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _SeccionBlanca extends StatelessWidget {
  final Widget child;
  final bool esOscuro;
  const _SeccionBlanca({required this.child, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esOscuro ? Colors.white24 : Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _MetodoPagoSelector extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback? onTap;
  final bool habilitado;

  const _MetodoPagoSelector({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: Opacity(
        opacity: habilitado ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: seleccionado ? ColoresApp.primarioVerde.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado ? ColoresApp.primarioVerde : Colors.grey.withOpacity(0.2),
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                seleccionado ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: seleccionado ? ColoresApp.primarioVerde : Colors.grey,
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: seleccionado ? ColoresApp.primarioVerde : Colors.grey[700], size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}