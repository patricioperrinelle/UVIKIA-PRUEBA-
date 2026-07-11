// lib/5_modulos/modulo_billetera/controladores/controlador_cuentas_bancarias.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/servicio_cuentas_bancarias_supabase.dart';
import '../../../3_modelos/modelo_cuenta_bancaria.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

class ControladorCuentasBancarias extends ChangeNotifier {
  bool isLoading = true;
  bool isSubmitting = false;
  List<ModeloCuentaBancaria> cuentas = [];
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

  Future<void> _ejecutarFlujoSWR() async {
    // 1. Fase 0ms
    await _cargarCacheSWR();

    // 2. Fase Red
    try {
      final cuentasFrescas = await ServicioCuentasBancariasSupabase.obtenerCuentasUsuario(miId);
      
      // 🛡️ BARRERA ANTI-DESTRUCCIÓN
      cuentas = cuentasFrescas;
      await _guardarCacheSWR();
    } catch (e) {
      debugPrint('[SWR Cuentas] Falla de red: $e. Conservando caché local.');
    } finally {
      // 🛡️ LA LEY DEL FINALLY
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('cache_cuentas_$miId');

      if (cacheStr != null && cacheStr.isNotEmpty) {
        final List<dynamic> decodificado = jsonDecode(cacheStr);
        cuentas = decodificado.map((e) => ModeloCuentaBancaria.fromJson(e)).toList();
        isLoading = false; 
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SWR Cuentas] Error leyendo caché: $e');
    }
  }

  Future<void> _guardarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = cuentas.map((e) => e.toJson()).toList();
      await prefs.setString('cache_cuentas_$miId', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[SWR Cuentas] Error guardando caché: $e');
    }
  }

  /// 🚨 MUTACIÓN ESTRICTA: Agregar CBU (Cero Optimistic UI)
  void agregarCuentaBancaria({
    required String cbuCvu,
    String? aliasBancario,
    String? bancoProveedor,
    String? titularCuenta,
    String? cuitDniTitular,
    required Function(String error)? onError,
    required VoidCallback onSuccess,
  }) {
    // 🛡️ DICTADURA DEL AUTH-GUARD
    GestorSesionGlobal.requerirAuth(() async {
      isSubmitting = true;
      notifyListeners();

      try {
        final nuevaCuenta = await ServicioCuentasBancariasSupabase.insertarCuentaBancaria(
          usuarioId: miId,
          cbuCvu: cbuCvu,
          aliasBancario: aliasBancario,
          bancoProveedor: bancoProveedor,
          titularCuenta: titularCuenta,
          cuitDniTitular: cuitDniTitular,
        );

        // Cero Optimistic UI: Mutamos RAM y caché SOLO tras éxito de red
        cuentas.insert(0, nuevaCuenta);
        await _guardarCacheSWR();
        onSuccess();
      } catch (e) {
        onError?.call(e.toString().replaceAll('Exception: ', ''));
      } finally {
        // 🛡️ LA LEY DEL FINALLY
        isSubmitting = false;
        notifyListeners();
      }
    });
  }

  /// 🚨 MUTACIÓN ESTRICTA: Eliminar CBU (Soft Delete - Cero Optimistic UI)
  void eliminarCuentaBancaria(String cuentaId, {
    required Function(String error)? onError,
    required VoidCallback onSuccess,
  }) {
    // 🛡️ DICTADURA DEL AUTH-GUARD
    GestorSesionGlobal.requerirAuth(() async {
      isSubmitting = true;
      notifyListeners();

      try {
        await ServicioCuentasBancariasSupabase.eliminarCuentaBancaria(cuentaId);

        // Mutamos RAM y caché SOLO tras éxito de red
        cuentas.removeWhere((cuenta) => cuenta.id == cuentaId);
        await _guardarCacheSWR();
        onSuccess();
      } catch (e) {
        onError?.call(e.toString().replaceAll('Exception: ', ''));
      } finally {
        // 🛡️ LA LEY DEL FINALLY
        isSubmitting = false;
        notifyListeners();
      }
    });
  }
}