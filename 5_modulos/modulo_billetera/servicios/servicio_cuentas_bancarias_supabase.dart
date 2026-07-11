// lib/5_modulos/modulo_billetera/servicios/servicio_cuentas_bancarias_supabase.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_cuenta_bancaria.dart';

class ServicioCuentasBancariasSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Extrae las cuentas activas del usuario
  static Future<List<ModeloCuentaBancaria>> obtenerCuentasUsuario(String usuarioId) async {
    try {
      final respuesta = await _client
          .from('cuentas_bancarias_usuarios')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('es_activa', true)
          .order('fecha_alta', ascending: false);

      return (respuesta as List)
          .map((json) => ModeloCuentaBancaria.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener cuentas bancarias: $e');
    }
  }

  /// Registra una nueva cuenta bancaria
  /// 🚨 CANDADO RLS: Usa .select().single() para obligar al backend a validar la escritura y escupir errores.
  static Future<ModeloCuentaBancaria> insertarCuentaBancaria({
    required String usuarioId,
    required String cbuCvu,
    String? aliasBancario,
    String? bancoProveedor,
    String? titularCuenta,
    String? cuitDniTitular,
  }) async {
    try {
      final respuesta = await _client.from('cuentas_bancarias_usuarios').insert({
        'usuario_id': usuarioId,
        'cbu_cvu': cbuCvu,
        'alias_bancario': aliasBancario,
        'banco_proveedor': bancoProveedor,
        'titular_cuenta': titularCuenta,
        'cuit_dni_titular': cuitDniTitular,
        'es_activa': true,
      }).select().single();

      return ModeloCuentaBancaria.fromJson(respuesta);
    } catch (e) {
      throw Exception('Error al registrar cuenta bancaria: $e');
    }
  }

  /// Soft Delete: Marca la cuenta como inactiva conservando el historial forense.
  /// 🚨 CANDADO RLS: Usa .select().single() para forzar la validación de la política RLS FOR UPDATE.
  static Future<void> eliminarCuentaBancaria(String cuentaId) async {
    try {
      await _client.from('cuentas_bancarias_usuarios').update({
        'es_activa': false,
        'fecha_eliminacion': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', cuentaId).select().single();
    } catch (e) {
      throw Exception('Error al eliminar cuenta bancaria: $e');
    }
  }
}