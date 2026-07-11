// lib/5_modulos/modulo_billetera/servicios/servicio_checkout_supabase.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ServicioCheckoutSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Invoca el Stored Procedure (RPC) para crear de forma atómica la intención de pago
  /// e impactar el Ledger o la pasarela. 
  /// 🚨 FASE 6: Ahora el backend devuelve obligatoriamente un 'url_pago' para el Posnet Virtual.
  static Future<Map<String, dynamic>> crearIntencionPago({
    required String usuarioId,
    required String trabajoId,
    required double monto,
    required String llaveIdempotencia,
    required String metodoPago,
  }) async {
    try {
      // 🛡️ CORRECCIÓN ARQUITECTÓNICA: Llamada directa a la Edge Function (No a la DB)
      final respuesta = await _client.functions.invoke('iniciar_checkout_pago', body: {
        'p_usuario_id': usuarioId,
        'p_trabajo_id': trabajoId,
        'p_monto': monto,
        'p_llave_idempotencia': llaveIdempotencia,
        'p_metodo_pago': metodoPago,
      });
      
      return Map<String, dynamic>.from(respuesta.data);
    } catch (e) {
      throw Exception('Fallo al conectar con la pasarela financiera: $e');
    }
  }

  /// Verifica el estado de la transacción en la base de datos de manera ligera.
  /// Usado por el Watchdog y el Lifecycle Sync al salir del Posnet Virtual.
  static Future<String> verificarEstadoTransaccion(String llaveIdempotencia) async {
    try {
      final respuesta = await _client
          .from('wallet_transactions')
          .select('estado')
          .eq('llave_idempotencia', llaveIdempotencia)
          .maybeSingle();

      if (respuesta == null) {
        return 'pendiente'; 
      }
      
      return respuesta['estado'].toString();
    } catch (e) {
      throw Exception('Fallo al recuperar el estado de la transacción: $e');
    }
  }
}