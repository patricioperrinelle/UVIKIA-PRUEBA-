// lib/5_modulos/modulo_billetera/componentes/tarjeta_transaccion_ledger.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../3_modelos/modelo_wallet_transaction.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_minimalista_base.dart';

class TarjetaTransaccionLedger extends StatelessWidget {
  final ModeloWalletTransaction transaccion;

  const TarjetaTransaccionLedger({
    super.key,
    required this.transaccion,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    // Colores adaptables al tema para máxima visibilidad (evita bimetización en blanco)
    final Color colorTextoPrincipal = esOscuro ? Colors.white : const Color(0xFF1D1D1F);
    final Color colorTextoSecundario = esOscuro ? const Color(0xFFB0B0B0) : const Color(0xFF6E6E73);

    // 🛡️ REGLA VISUAL ESTRICTA: El color y el signo dependen incondicionalmente del Modelo Inmutable
    final bool esCredito = transaccion.tipoOperacion == TipoOperacion.credito;
    final Color colorMonto = esCredito ? ColoresApp.primarioVerde : ColoresApp.errorRojo;
    final String signo = esCredito ? '+' : '-';
    final IconData icono = esCredito ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    // Formateo visual ciego de la fecha
    final String dia = transaccion.createdAt.day.toString().padLeft(2, '0');
    final String mes = transaccion.createdAt.month.toString().padLeft(2, '0');
    final String anio = transaccion.createdAt.year.toString();
    final String hora = transaccion.createdAt.hour.toString().padLeft(2, '0');
    final String min = transaccion.createdAt.minute.toString().padLeft(2, '0');
    final String fechaVisual = "$dia/$mes/$anio • $hora:$min hs";

    // 💡 DETERMINAR TÍTULO HUMANIZADO Y EXPLICATIVO SEGÚN EL REQUERIMIENTO
    String tituloExplicativo = 'Pago de servicio';
    if (transaccion.metadata.containsKey('descripcion') && transaccion.metadata['descripcion']?.toString().isNotEmpty == true) {
      tituloExplicativo = transaccion.metadata['descripcion'].toString();
    } else if (transaccion.metadata.containsKey('concepto') && transaccion.metadata['concepto']?.toString().isNotEmpty == true) {
      tituloExplicativo = transaccion.metadata['concepto'].toString();
    } else {
      switch (transaccion.tipoOperacion) {
        case TipoOperacion.credito:
          // Analizar metadata del trabajo para clasificar dinámicamente
          final String? tipoTrabajo = transaccion.metadata['tipo_trabajo']?.toString().toLowerCase() ?? 
                                      transaccion.metadata['modalidad']?.toString().toLowerCase() ??
                                      transaccion.metadata['tipo_servicio']?.toString().toLowerCase() ??
                                      transaccion.metadata['categoria']?.toString().toLowerCase();
          if (tipoTrabajo != null) {
            if (tipoTrabajo.contains('jornada')) {
              tituloExplicativo = 'Pago de jornada';
            } else if (tipoTrabajo.contains('oficio')) {
              tituloExplicativo = 'Pago de oficio';
            } else if (tipoTrabajo.contains('servicio')) {
              tituloExplicativo = 'Pago de servicio';
            } else {
              // Convertir "pintor" a "pago de pintor" o mantener formato
              tituloExplicativo = 'Pago de ${tipoTrabajo}';
            }
          } else {
            tituloExplicativo = 'Pago de servicio';
          }
          break;
        case TipoOperacion.debito:
          tituloExplicativo = 'Pago realizado';
          break;
        case TipoOperacion.retiro:
          tituloExplicativo = 'Retiro de fondos';
          break;
        case TipoOperacion.comision:
          tituloExplicativo = 'Comisión de plataforma';
          break;
        default:
          tituloExplicativo = 'Movimiento de saldo';
      }
    }

    // Formateador premium de importes (ej: 25.000,00)
    String _formatearMontoLocal(double valor) {
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
      return "${buffer.toString()},$decimales";
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Icono de flecha de color (sin círculo de fondo)
          SizedBox(
            width: 38,
            height: 38,
            child: Icon(icono, color: colorMonto, size: 24),
          ),
          const SizedBox(width: 14),
          
          // Textos descriptivos de la transacción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloExplicativo,
                  style: TextStyle(
                    fontFamily: EstilosTextoApp.fuentePrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Negrita explícita
                    color: colorTextoPrincipal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      fechaVisual,
                      style: TextStyle(
                        fontFamily: EstilosTextoApp.fuentePrincipal,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: colorTextoSecundario,
                      ),
                    ),
                    if (esCredito && transaccion.estado == EstadoTransaccion.completado)
                      _construirBadgeLiquidado(transaccion.liquidadoAdmin),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // 🚨 AISLAMIENTO TIPOGRÁFICO ESTRICTO (Moneda vs Matemática) con colores visibles
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$signo\$ ',
                  style: TextStyle(
                    fontFamily: EstilosTextoApp.fuentePrincipal,
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: colorMonto.withOpacity(0.8),
                  ),
                ),
                TextSpan(
                  text: _formatearMontoLocal(transaccion.monto),
                  style: TextStyle(
                    fontFamily: EstilosTextoApp.fuentePrincipal,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorMonto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBadgeLiquidado(bool liquidado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: liquidado 
            ? Colors.blue.withOpacity(0.08) 
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: liquidado 
              ? Colors.blue.withOpacity(0.3) 
              : Colors.orange.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            liquidado ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
            size: 10,
            color: liquidado ? Colors.blue : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            liquidado ? 'Liquidado' : 'Por Liquidar',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: liquidado ? Colors.blue : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
