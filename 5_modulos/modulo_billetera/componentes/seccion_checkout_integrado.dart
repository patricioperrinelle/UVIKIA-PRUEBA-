import 'package:flutter/material.dart'; // Componente de checkout integrado
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/boton_delineado_secundario.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_minimalista_base.dart';
import '../controladores/controlador_checkout_pagos.dart';
import '../controladores/controlador_billetera.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

class SeccionCheckoutIntegrado extends StatefulWidget {
  final String trabajoId;
  final String tituloTrabajo;
  final String nombreProfesional;
  final String? idProfesional;
  final double subtotal;
  final double tarifaPlataforma;
  final String tipoTrabajo; // 'jornada' o 'oficio'
  final String? fecha;
  final String? horaInicio;
  final String? horaFin;
  final String? totalHoras;
  final String? descripcion;
  final VoidCallback onPagoCompletado;

  const SeccionCheckoutIntegrado({
    Key? key,
    required this.trabajoId,
    required this.tituloTrabajo,
    required this.nombreProfesional,
    this.idProfesional,
    required this.subtotal,
    required this.tarifaPlataforma,
    required this.tipoTrabajo,
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.totalHoras,
    this.descripcion,
    required this.onPagoCompletado,
  }) : super(key: key);

  @override
  State<SeccionCheckoutIntegrado> createState() => _SeccionCheckoutIntegradoState();
}

class _SeccionCheckoutIntegradoState extends State<SeccionCheckoutIntegrado> {
  final ControladorCheckoutPagos _controladorCheckout = ControladorCheckoutPagos();
  final ControladorBilletera _controladorBilletera = ControladorBilletera();
  String _metodoPagoSeleccionado = 'wallet';
  bool _esperandoConfirmacionAsincrona = false;
  bool _mostrarPanelPendiente = false;
  bool _esperaPasivaActiva = false;

  double get montoTotal => widget.subtotal + widget.tarifaPlataforma;

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

  void _iniciarPago() {
    _controladorCheckout.procesarPago(
      trabajoId: widget.trabajoId,
      monto: montoTotal,
      metodoPago: _metodoPagoSeleccionado,
      onSuccess: (datosPasarela) {
        if (!mounted) return;
        
        if (_metodoPagoSeleccionado == 'mercadopago') {
          // Si es Mercado Pago, la URL ya se abrió externamente.
          // Mostramos panel de espera pasiva
          setState(() {
            _mostrarPanelPendiente = true;
          });
          return;
        }

        final String llaveIdempotencia = datosPasarela['llave_idempotencia'];
        
        setState(() {
          _esperandoConfirmacionAsincrona = true;
        });

        _controladorCheckout.observarEstadoAsincrono(
          llaveIdempotencia: llaveIdempotencia,
          onCompletado: () {
            if (!mounted) return;
            setState(() {
              _esperandoConfirmacionAsincrona = false;
              _mostrarPanelPendiente = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Pago confirmado con éxito!'), backgroundColor: ColoresApp.primarioVerde),
            );
            widget.onPagoCompletado(); 
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controladorCheckout,
      builder: (context, _) {
        final bool estaBloqueado = _controladorCheckout.isSubmitting || _esperandoConfirmacionAsincrona;

        if (_mostrarPanelPendiente) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 64, color: ColoresApp.terciarioMorado),
                const SizedBox(height: 24),
                const Text('¿Ya completaste el pago?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                
                if (!_esperaPasivaActiva) ...[
                  const Text('Avisanos para verificar el estado de la transacción.', style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  BotonAccionPrincipal(
                    texto: 'Sí, ya pagué',
                    onPressed: () {
                      setState(() => _esperaPasivaActiva = true);
                    },
                  ),
                  const SizedBox(height: 16),
                  BotonDelineadoSecundario(
                    texto: 'TODAVIA NO',
                    colorPrimario: ColoresApp.terciarioMorado, 
                    onPressed: () {
                      setState(() {
                        _mostrarPanelPendiente = false;
                        _esperaPasivaActiva = false;
                      });
                    },
                  ),
                ] else ...[
                  TarjetaMinimalistaBase(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.security_rounded, size: 48, color: ColoresApp.terciarioMorado),
                          const SizedBox(height: 16),
                          const Text(
                            'Pago reportado exitosamente',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Reserva temporal de horario.\n\nEste horario quedará reservado exclusivamente para vos mientras se procesa el pago. La reserva se confirmará únicamente cuando recibamos la aprobación oficial de MercadoPago.\n\nSi el pago no se acredita en ese plazo, el horario volverá a estar disponible para otros usuarios.',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          BotonAccionPrincipal(
                            texto: 'Hecho',
                            onPressed: () {
                              widget.onPagoCompletado();
                            },
                          ),
                          const SizedBox(height: 12),
                          BotonDelineadoSecundario(
                            texto: 'Me equivoqué, quiero pagar',
                            colorPrimario: ColoresApp.terciarioMorado,
                            onPressed: () {
                              setState(() {
                                _esperaPasivaActiva = false;
                                _mostrarPanelPendiente = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return AbsorbPointer(
          absorbing: estaBloqueado,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColoresApp.secundarioCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColoresApp.secundarioCyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: ColoresApp.secundarioCyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('¡Profesional disponible!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ColoresApp.secundarioCyan)),
                          const SizedBox(height: 4),
                          Text('Ingresa el pago para confirmar y cerrar la operación. El dinero estará seguro.', style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('¿Qué estás pagando?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TarjetaMinimalistaBase(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColoresApp.terciarioMorado.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(widget.tipoTrabajo == 'jornada' ? Icons.access_time_filled_rounded : Icons.handyman_rounded, color: ColoresApp.terciarioMorado, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.tipoTrabajo == 'jornada' ? 'MODALIDAD JORNADAS' : 'MODALIDAD OFICIOS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: ColoresApp.terciarioMorado)),
                                const SizedBox(height: 4),
                                Text(widget.tituloTrabajo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Cliente: ${GestorSesionGlobal().perfilUsuario?.apodo ?? "Tú"} (ID: #${GestorSesionGlobal().miIdUsuario.length > 8 ? GestorSesionGlobal().miIdUsuario.substring(0, 8).toUpperCase() : GestorSesionGlobal().miIdUsuario.toUpperCase()})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800])),
                      const SizedBox(height: 4),
                      Text('Profesional contratado: ${widget.nombreProfesional}${widget.idProfesional != null ? ' (ID: #${widget.idProfesional!.length > 8 ? widget.idProfesional!.substring(0, 8).toUpperCase() : widget.idProfesional!.toUpperCase()})' : ''}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800])),
                      
                      if (widget.tipoTrabajo == 'jornada' || widget.descripcion != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FilaDetalleTrabajo(etiqueta: 'Nº de Trabajo', valor: '#${widget.trabajoId.length > 8 ? widget.trabajoId.substring(0, 8).toUpperCase() : widget.trabajoId.toUpperCase()}'),
                              const SizedBox(height: 8),
                              if (widget.fecha != null && widget.fecha!.isNotEmpty) ...[
                                _FilaDetalleTrabajo(etiqueta: widget.tipoTrabajo == 'jornada' ? 'Fecha' : 'Fecha estimada', valor: widget.fecha!),
                                const SizedBox(height: 8),
                              ],
                              if (widget.tipoTrabajo == 'jornada' && widget.horaInicio != null && widget.horaFin != null) ...[
                                _FilaDetalleTrabajo(etiqueta: 'Horario', valor: '${widget.horaInicio!} - ${widget.horaFin!}'),
                                const SizedBox(height: 8),
                              ],
                              if (widget.tipoTrabajo == 'oficio' && widget.horaInicio != null && widget.horaInicio!.isNotEmpty) ...[
                                _FilaDetalleTrabajo(etiqueta: 'Horario estimado', valor: widget.horaInicio!),
                                const SizedBox(height: 8),
                              ],
                              if (widget.tipoTrabajo == 'jornada' && widget.totalHoras != null) ...[
                                _FilaDetalleTrabajo(etiqueta: 'Total de horas', valor: widget.totalHoras!),
                                const SizedBox(height: 8),
                              ],
                              if (widget.descripcion != null && widget.descripcion!.isNotEmpty) ...[
                                const Text('Descripción del trabajo', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(widget.descripcion!, style: const TextStyle(fontSize: 13)),
                              ]
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const Text('Detalle de cobro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _FilaMontoDesglose(etiqueta: 'Presupuesto acordado', monto: widget.subtotal),
                      const SizedBox(height: 8),
                      _FilaMontoDesglose(etiqueta: 'Tarifa de plataforma', monto: widget.tarifaPlataforma, esInfo: true),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: '\$ ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: ColoresApp.terciarioMorado)),
                                TextSpan(text: montoTotal.toStringAsFixed(2), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColoresApp.terciarioMorado)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('¿Con qué querés pagar?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _controladorBilletera,
                builder: (context, _) {
                  final saldo = _controladorBilletera.walletActual?.saldo ?? 0.0;
                  final bool saldoSuficiente = saldo >= montoTotal;
                  
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
              
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: ColoresApp.terciarioMorado, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transacción cifrada y 100% segura.\nTu pago está protegido bajo nuestro sistema.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: BotonAccionPrincipal(
                  texto: 'Confirmar Pago',
                  isLoading: _controladorCheckout.isSubmitting,
                  onPressed: _iniciarPago,
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Al confirmar, aceptás nuestros Términos y Condiciones.', style: const TextStyle(fontSize: 12, color: Colors.grey))),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _FilaMontoDesglose extends StatelessWidget {
  final String etiqueta;
  final double monto;
  final bool esInfo;
  
  const _FilaMontoDesglose({required this.etiqueta, required this.monto, this.esInfo = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(etiqueta, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            if (esInfo) ...[
              const SizedBox(width: 8),
              const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
            ]
          ],
        ),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '\$', style: TextStyle(fontWeight: FontWeight.normal)),
              TextSpan(text: monto.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
          color: seleccionado ? ColoresApp.terciarioMorado.withOpacity(0.05) : Colors.transparent,
          borderRadius: DimensionesApp.radioTarjetas,
          border: Border.all(
            color: seleccionado ? ColoresApp.terciarioMorado : Colors.grey.withOpacity(0.2),
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionado ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: seleccionado ? ColoresApp.terciarioMorado : Colors.grey,
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: seleccionado ? ColoresApp.terciarioMorado : Colors.grey[700], size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
