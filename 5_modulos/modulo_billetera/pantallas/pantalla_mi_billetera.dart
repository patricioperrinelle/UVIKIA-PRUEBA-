// lib/5_modulos/modulo_billetera/pantallas/pantalla_mi_billetera.dart

import 'package:flutter/material.dart';

import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_minimalista_base.dart';
import '../../../4_componentes_globales/estados/estado_vacio_ilustrado.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';
import '../componentes/modal_agregar_cuenta_bancaria.dart';

import '../controladores/controlador_billetera.dart';
import '../controladores/controlador_cuentas_bancarias.dart';
import '../componentes/tarjeta_transaccion_ledger.dart';

class PantallaMiBilletera extends StatefulWidget {
  const PantallaMiBilletera({super.key});

  @override
  State<PantallaMiBilletera> createState() => _PantallaMiBilleteraState();
}

class _PantallaMiBilleteraState extends State<PantallaMiBilletera> {
  // Instanciación local de las Máquinas de Estado
  final ControladorBilletera _ctrlBilletera = ControladorBilletera();
  final ControladorCuentasBancarias _ctrlCuentas = ControladorCuentasBancarias();

  // Estado para ocultar/mostrar saldos de forma premium
  bool _mostrarSaldos = true;

  @override
  void initState() {
    super.initState();
    final miId = GestorSesionGlobal().miIdUsuario;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrlBilletera.inicializar(miId);
      _ctrlCuentas.inicializar(miId);
    });
  }

  @override
  void dispose() {
    _ctrlBilletera.dispose();
    _ctrlCuentas.dispose();
    super.dispose();
  }

  /// Formateador local de moneda respetando el ocultamiento del saldo y estilo visual premium
  String _formatearMoneda(double valor) {
    if (!_mostrarSaldos) return '••••';
    
    String valorFijo = valor.toStringAsFixed(2);
    List<String> partes = valorFijo.split('.');
    String enteros = partes[0];
    String decimales = partes[1];
    
    StringBuffer buffer = StringBuffer();
    int longitud = enteros.length;
    for (int i = 0; i < longitud; i++) {
      if (i > 0 && (longitud - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(enteros[i]);
    }
    
    return "\$ ${buffer.toString()},$decimales";
  }

  /// Formatea la fecha y hora de la última sincronización
  String _formatearFechaActualizacion() {
    final DateTime fecha = _ctrlBilletera.walletActual?.updatedAt ?? DateTime.now();
    final String hora = fecha.hour.toString().padLeft(2, '0');
    final String min = fecha.minute.toString().padLeft(2, '0');
    return "Actualizado hoy, $hora:$min hs";
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    // ListenableBuilder anidado para reaccionar a ambos controladores sin mezclar estados
    return ListenableBuilder(
      listenable: _ctrlBilletera,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: _ctrlCuentas,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: tema.scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(
                  'Mi Billetera', 
                  style: EstilosTextoApp.h3.copyWith(
                    color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
                  ),
                ),
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(
                    _mostrarSaldos ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: tema.appBarTheme.iconTheme?.color ?? ColoresApp.textoPrincipal,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarSaldos = !_mostrarSaldos;
                    });
                  },
                ),
                actions: const [], // Se quita la campanita de notificación según el requerimiento del usuario
              ),
              body: SafeArea(
                child: RefreshIndicator(
                  color: ColoresApp.primarioVerde,
                  onRefresh: () async {
                    final miId = GestorSesionGlobal().miIdUsuario;
                    _ctrlBilletera.inicializar(miId);
                    _ctrlCuentas.inicializar(miId);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: DimensionesApp.paddingPantalla,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _construirTarjetaSaldoPrincipal(tema),
                        _construirFilaMetricasProceso(tema),
                        const SizedBox(height: 32),
                        
                        _construirSeccionEstadoGeneral(tema),
                        const SizedBox(height: 32),
                        
                        _construirSeccionCuentasBancarias(tema),
                        const SizedBox(height: 32),
                        
                        _construirSeccionHistorialMovimientos(tema),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 🎨 DISEÑO TERCER EJEMPLO (DERECHO DE LA IMAGEN): Tarjeta de Saldo disponible minimalista y premium
  Widget _construirTarjetaSaldoPrincipal(ThemeData tema) {
    if (_ctrlBilletera.isLoading && _ctrlBilletera.walletActual == null) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
    }

    final double saldo = _ctrlBilletera.walletActual?.saldo ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo disponible',
                style: EstilosTextoApp.cuerpoPequeno.copyWith(
                  color: Colors.grey, 
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Icono de billetera encuadrado
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.0),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined, 
                  color: Colors.grey, 
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _mostrarSaldos ? '\$ ' : '',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.normal, 
                          color: tema.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                      TextSpan(
                        text: _formatearMoneda(saldo).replaceAll('\$ ', ''),
                        style: TextStyle(
                          fontSize: 34, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: -0.5,
                          color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded, 
                color: Colors.grey, 
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatearFechaActualizacion(),
            style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 🎨 DISEÑO TERCER EJEMPLO: Fila horizontal de En Proceso y Por Cobrar
  Widget _construirFilaMetricasProceso(ThemeData tema) {
    if (_ctrlBilletera.isLoading && _ctrlBilletera.walletActual == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En proceso',
                  style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatearMoneda(_ctrlBilletera.totalEnProceso),
                  style: EstilosTextoApp.cuerpoDestacado.copyWith(
                    fontSize: 16,
                    color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: Colors.grey.withOpacity(0.15),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Por cobrar',
                  style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatearMoneda(_ctrlBilletera.totalPorCobrar),
                  style: EstilosTextoApp.cuerpoDestacado.copyWith(
                    fontSize: 16,
                    color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 DISEÑO TERCER EJEMPLO: Sección Estado General con barra de progreso circular o lineal, Ingresos y Egresos
  Widget _construirSeccionEstadoGeneral(ThemeData tema) {
    final double ratio = _ctrlBilletera.proporcionIngresos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estado general', 
              style: EstilosTextoApp.h3.copyWith(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
              ),
            ),
            Text('Este mes', style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        
        // Barra de progreso lineal sutil y moderna
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(tema.brightness == Brightness.dark ? 0.9 : 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        
        // Etiquetas de ingresos y egresos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatearMoneda(_ctrlBilletera.totalIngresosMes),
                  style: const TextStyle(
                    color: ColoresApp.primarioVerde, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingresos', 
                  style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _mostrarSaldos 
                      ? "- ${_formatearMoneda(_ctrlBilletera.totalEgresosMes).replaceAll('\$ ', '')}"
                      : "••••",
                  style: const TextStyle(
                    color: ColoresApp.errorRojo, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Egresos', 
                  style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 🎨 DISEÑO TERCER EJEMPLO: Listado vertical de cuentas bancarias
  Widget _construirSeccionCuentasBancarias(ThemeData tema) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis cuentas', 
              style: EstilosTextoApp.h3.copyWith(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ModalAgregarCuentaBancaria.mostrar(context, _ctrlCuentas);
              },
              icon: const Icon(Icons.add_rounded, color: Colors.blue, size: 16),
              label: const Text(
                'Agregar', 
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_ctrlCuentas.isLoading && _ctrlCuentas.cuentas.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (_ctrlCuentas.cuentas.isEmpty)
          const Text('Aún no has agregado ninguna cuenta bancaria.', style: TextStyle(color: Colors.grey))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ctrlCuentas.cuentas.length,
            itemBuilder: (context, index) {
              final cuenta = _ctrlCuentas.cuentas[index];
              
              final cbuOculto = cuenta.cbuCvu.length > 4 
                  ? '**** **** **** ${cuenta.cbuCvu.substring(cuenta.cbuCvu.length - 4)}'
                  : cuenta.cbuCvu;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onLongPress: () {
                    // Diálogo de eliminación con confirmación reutilizable
                    showDialog(
                      context: context,
                      builder: (context) => DialogoConfirmacionEstandar(
                        titulo: 'Desvincular Cuenta',
                        mensaje: '¿Estás seguro de que deseas eliminar la cuenta ${cuenta.bancoProveedor ?? ''}?',
                        textoBotonConfirmar: 'Eliminar',
                        onConfirmar: () {
                          Navigator.pop(context);
                          _ctrlCuentas.eliminarCuentaBancaria(
                            cuenta.id,
                            onError: (err) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err), backgroundColor: ColoresApp.errorRojo),
                              );
                            },
                            onSuccess: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cuenta desvinculada con éxito.'), backgroundColor: ColoresApp.primarioVerde),
                              );
                            },
                          );
                        },
                        onCancelar: () => Navigator.pop(context),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        // Icono del banco con fondo esmerilado suave
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 14),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cuenta.bancoProveedor ?? 'Banco/Billetera',
                                style: EstilosTextoApp.cuerpoDestacado.copyWith(
                                  fontSize: 15,
                                  color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alias: ${cuenta.aliasBancario ?? 'No asignado'}',
                                style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'CBU: $cbuOculto',
                                style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        
                        // Badge Principal
                        if (index == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Principal',
                              style: EstilosTextoApp.cuerpoPequeno.copyWith(
                                color: tema.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// 🎨 DISEÑO TERCER EJEMPLO: Historial de movimientos vertical
  Widget _construirSeccionHistorialMovimientos(ThemeData tema) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actividad reciente', 
              style: EstilosTextoApp.h3.copyWith(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: tema.brightness == Brightness.dark ? Colors.white : const Color(0xFF1D1D1F),
              ),
            ),
            Text('Ver todas', style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_ctrlBilletera.isLoading && _ctrlBilletera.transacciones.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (_ctrlBilletera.transacciones.isEmpty)
          const EstadoVacioIlustrado(
            titulo: 'Sin Movimientos',
            subtitulo: 'Tu historial del Ledger está limpio.',
            icono: Icons.receipt_long_rounded,
          )
        else
          TarjetaMinimalistaBase(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _ctrlBilletera.transacciones.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: tema.brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.grey.withOpacity(0.15),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                return TarjetaTransaccionLedger(
                  transaccion: _ctrlBilletera.transacciones[index],
                );
              },
            ),
          ),
      ],
    );
  }
}