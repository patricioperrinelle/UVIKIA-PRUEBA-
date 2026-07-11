// lib/1_nucleo/gestor_sincronizacion_offline.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =================================================================
// OFFLINE SYNC MANAGER — Motor Optimista Global y Cola de Acciones
// =================================================================

class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  factory OfflineSyncManager() => _instance;
  OfflineSyncManager._internal();

  /// 🚀 NUEVO MOTOR GLOBAL: EJECUCIÓN BAJO CAPÓ
  /// Ejecuta la lógica de Supabase en segundo plano. Si falla o no hay internet, 
  /// encola la acción o revierte el estado visual sin bloquear al usuario.
  static void ejecutarBajoCapot({
    required Future<void> Function() operacionRed,
    String? fallbackQueueType,
    Map<String, dynamic>? fallbackPayload,
    Function()? revertirEstado,
  }) {
    Future.microtask(() async {
      try {
        await operacionRed(); // Intenta hacerlo en Supabase en silencio
      } catch (e) {
        debugPrint('Fallo bajo capó (Sin Internet): $e');
        if (fallbackQueueType != null && fallbackPayload != null) {
          // Si es una acción guardable (ej. Postularse), va a la cola offline
          await OfflineSyncManager().queueAction(fallbackQueueType, fallbackPayload);
        } else if (revertirEstado != null) {
          // Si es algo crítico que no se pudo hacer, revertimos el botón sutilmente
          revertirEstado();
        }
      }
    });
  }

  Future<void> queueAction(String actionType, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList('action_queue') ??[];
    
    final action = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': actionType,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    queue.add(jsonEncode(action));
    await prefs.setStringList('action_queue', queue); 
  }

  Future<void> processQueue() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList('action_queue') ??[];
    if (queue.isEmpty) return;

    List<String> remainingQueue =[];

    for (String item in queue) {
      final action = jsonDecode(item);
      try {
        if (action['type'] == 'enviar_mensaje') {
          await Supabase.instance.client.from('mensajes').insert(action['payload']);
        } else if (action['type'] == 'publicar_trabajo') {
          await Supabase.instance.client.from('trabajos').insert(action['payload']);
        } else if (action['type'] == 'insert_puja') {
          await Supabase.instance.client.from('pujas').upsert(action['payload']);
        } else if (action['type'] == 'insert_notificacion') {
          await Supabase.instance.client.from('notificaciones').insert(action['payload']);
        }
      } catch (e) {
        debugPrint("Error procesando acción encolada: $e");
        remainingQueue.add(item); 
      }
    }
    await prefs.setStringList('action_queue', remainingQueue); 
  }
}