// lib/1_nucleo/estado_global/gestor_cache_lectura.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Funciones Top-Level requeridas por `compute` para Isolates.
dynamic _decodificarJson(String source) => jsonDecode(source);
String _codificarJson(dynamic data) => jsonEncode(data);

class GestorCacheLectura {
  
  /// Optimizador de CPU: Evalúa si vale la pena abrir un Isolate para el parseo.
  static Future<dynamic> _parsearInteligente(String jsonStr) async {
    if (jsonStr.length > 15000) { 
      return await compute(_decodificarJson, jsonStr);
    }
    return jsonDecode(jsonStr);
  }

  /// Optimizador de CPU Inverso: Protege el Main Thread al codificar (Anti-Jank).
  static Future<String> _codificarInteligente(dynamic data) async {
    if (data is List && data.isNotEmpty) {
      // Las listas (como Feeds masivos) se codifican en un hilo secundario
      return await compute(_codificarJson, data);
    }
    return jsonEncode(data);
  }

  /// Motor SWR (Stale-While-Revalidate) V5.2 Alpha-Core.
  /// Carga instantánea 0ms + Protección Anti-Jank en background + Barrera Anti-Destrucción.
  static Stream<T> ejecutarSWR<T>({
    required String cacheKey,
    required Future<T> Function() redFetcher,
    required T Function(dynamic) deserializer,
    required dynamic Function(T) serializer,
  }) async* {
    final prefs = await SharedPreferences.getInstance();
    final cacheStr = prefs.getString(cacheKey);

    // 1. FASE STALE: Escupir caché local en 0ms
    if (cacheStr != null && cacheStr.isNotEmpty) {
      try {
        final dynamic jsonDecodificado = await _parsearInteligente(cacheStr);
        yield deserializer(jsonDecodificado);
      } catch (e) {
        debugPrint('SWR-Titan: Error decodificando caché para $cacheKey. Ignorando.');
      }
    }

    // 2. FASE REVALIDATE: Golpe silencioso a la red
    try {
      final freshData = await redFetcher();
      
      // 🛡️ BARRERA ANTI-DESTRUCCIÓN 
      // Si la BD devuelve una lista vacía (por micro-corte o falta de datos), 
      // la emitimos a la UI pero ABORTAMOS la sobreescritura del disco duro.
      if (freshData is List && freshData.isEmpty) {
        yield freshData;
        return; 
      }
      
      // Serializar y guardar en disco de forma segura (Isolate inverso)
      final serializedData = serializer(freshData);
      final String jsonString = await _codificarInteligente(serializedData);
      
      await prefs.setString(cacheKey, jsonString);
      
      // Emitir el dato fresco a la UI
      yield freshData;
    } catch (e) {
      debugPrint('SWR-Titan: Falla de red detectada para $cacheKey. Supervivencia garantizada usando caché. Error: $e');
    }
  }

  /// Método para que los controladores guarden exclusivamente la página 1 en disco.
  static Future<void> actualizarCacheManual<T>({
    required String cacheKey,
    required T data,
    required dynamic Function(T) serializer,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final serializedData = serializer(data);
      final String jsonString = await _codificarInteligente(serializedData);
      
      await prefs.setString(cacheKey, jsonString);
    } catch (e) {
      debugPrint('SWR-Titan: Error al actualizar caché manual para $cacheKey: $e');
    }
  }
}