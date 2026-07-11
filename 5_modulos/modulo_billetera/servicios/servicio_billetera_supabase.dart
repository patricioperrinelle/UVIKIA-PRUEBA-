// lib/5_modulos/modulo_billetera/servicios/servicio_billetera_supabase.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_wallet.dart';
import '../../../3_modelos/modelo_wallet_transaction.dart';

class ServicioBilleteraSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Extrae la billetera principal del usuario.
  /// 🚨 ARQUITECTURA SWR: Lanza excepción en lugar de devolver null o saldos inventados.
  static Future<ModeloWallet> obtenerWalletUsuario(String usuarioId) async {
    try {
      final respuesta = await _client
          .from('wallets')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('tipo_wallet', 'USER')
          .maybeSingle();

      if (respuesta == null) {
        throw Exception('Wallet no encontrada para el usuario.');
      }

      return ModeloWallet.fromJson(respuesta);
    } catch (e) {
      // Relanzamos la excepción cruda para que el Controlador (SWR) decida si muestra la caché local
      throw Exception('Error al obtener la billetera: $e');
    }
  }

  /// Extrae el Ledger inmutable ordenado cronológicamente.
  /// 🚨 ARQUITECTURA SWR: Lanza excepción pura en fallo de red. Cero mutaciones permitidas.
  static Future<List<ModeloWalletTransaction>> obtenerTransaccionesLedger(String walletId, {int limite = 50}) async {
    try {
      final respuesta = await _client
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false)
          .limit(limite);

      return (respuesta as List)
          .map((json) => ModeloWalletTransaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las transacciones: $e');
    }
  }
}