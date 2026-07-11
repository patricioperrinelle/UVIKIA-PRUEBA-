// lib/5_modulos/modulo_billetera/controladores/controlador_billetera.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/servicio_billetera_supabase.dart';
import '../../../3_modelos/modelo_wallet.dart';
import '../../../3_modelos/modelo_wallet_transaction.dart';

class ControladorBilletera extends ChangeNotifier {
  bool isLoading = true;
  ModeloWallet? walletActual;
  List<ModeloWalletTransaction> transacciones = [];
  String miId = '';

  void inicializar(String usuarioId) {
    miId = usuarioId;
    if (miId.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }
    _ejecutarFlujoSWR();
  }

  // 🛡️ CÁLCULOS FINANCIEROS DINÁMICOS Y SEGUROS (BASADOS EN EL LEDGER REAL)
  
  /// Suma de transacciones de retiro o débito que siguen pendientes ("En proceso").
  double get totalEnProceso {
    double total = 0.0;
    for (var tx in transacciones) {
      if (tx.estado == EstadoTransaccion.pendiente && 
          (tx.tipoOperacion == TipoOperacion.retiro || tx.tipoOperacion == TipoOperacion.debito)) {
        total += tx.monto;
      }
    }
    return total;
  }

  /// Suma de transacciones de crédito que siguen pendientes ("Por cobrar").
  double get totalPorCobrar {
    double total = 0.0;
    for (var tx in transacciones) {
      if (tx.estado == EstadoTransaccion.pendiente && tx.tipoOperacion == TipoOperacion.credito) {
        total += tx.monto;
      }
    }
    return total;
  }

  /// Suma de ingresos (crédito) completados durante el mes en curso.
  double get totalIngresosMes {
    double total = 0.0;
    final ahora = DateTime.now();
    for (var tx in transacciones) {
      if (tx.estado == EstadoTransaccion.completado && 
          tx.tipoOperacion == TipoOperacion.credito &&
          tx.createdAt.year == ahora.year && 
          tx.createdAt.month == ahora.month) {
        total += tx.monto;
      }
    }
    return total;
  }

  /// Suma de egresos (débito, retiro, comisiones) completados durante el mes en curso.
  double get totalEgresosMes {
    double total = 0.0;
    final ahora = DateTime.now();
    for (var tx in transacciones) {
      if (tx.estado == EstadoTransaccion.completado && 
          (tx.tipoOperacion == TipoOperacion.debito || 
           tx.tipoOperacion == TipoOperacion.retiro || 
           tx.tipoOperacion == TipoOperacion.comision) &&
          tx.createdAt.year == ahora.year && 
          tx.createdAt.month == ahora.month) {
        total += tx.monto;
      }
    }
    return total;
  }

  /// Proporción matemática de ingresos frente al volumen total (ingresos + egresos). Clampeada [0.0, 1.0].
  double get proporcionIngresos {
    final ing = totalIngresosMes;
    final egr = totalEgresosMes.abs();
    final totalVolumen = ing + egr;
    if (totalVolumen == 0.0) return 0.5; // Valor medio neutral por defecto
    return (ing / totalVolumen).clamp(0.0, 1.0);
  }

  Future<void> _ejecutarFlujoSWR() async {
    // 1. Fase 0ms: Cargar disco duro y liberar UI instantáneamente
    await _cargarCacheSWR();

    // 2. Fase Red: Fetch silencioso en background
    try {
      final walletFresca = await ServicioBilleteraSupabase.obtenerWalletUsuario(miId);
      final transaccionesFrescas = await ServicioBilleteraSupabase.obtenerTransaccionesLedger(walletFresca.id);

      // 🛡️ BARRERA ANTI-DESTRUCCIÓN: Solo sobreescribimos si la red tuvo éxito absoluto
      walletActual = walletFresca;
      transacciones = transaccionesFrescas;

      // 3. Fase Persistencia: Guardar éxito en disco
      await _guardarCacheSWR();
    } catch (e) {
      debugPrint('[SWR Billetera] Falla de red o sin datos: $e. Conservando caché local de supervivencia.');
    } finally {
      // 🛡️ LA LEY DEL FINALLY: Liberar UI sin importar excepciones de red
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletStr = prefs.getString('cache_wallet_$miId');
      final transaccionesStr = prefs.getString('cache_wallet_tx_$miId');

      bool hayCache = false;

      if (walletStr != null && walletStr.isNotEmpty) {
        walletActual = ModeloWallet.fromJson(jsonDecode(walletStr));
        hayCache = true;
      }

      if (transaccionesStr != null && transaccionesStr.isNotEmpty) {
        final List<dynamic> decodificado = jsonDecode(transaccionesStr);
        transacciones = decodificado.map((e) => ModeloWalletTransaction.fromJson(e)).toList();
        hayCache = true;
      }

      if (hayCache) {
        isLoading = false; 
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SWR Billetera] Error leyendo caché: $e');
    }
  }

  Future<void> _guardarCacheSWR() async {
    if (walletActual == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_wallet_$miId', jsonEncode(walletActual!.toJson()));
      
      final txJsonList = transacciones.map((e) => e.toJson()).toList();
      await prefs.setString('cache_wallet_tx_$miId', jsonEncode(txJsonList));
    } catch (e) {
      debugPrint('[SWR Billetera] Error guardando caché: $e');
    }
  }
}