// lib/1_nucleo/estado_global/repositorio_cache_local.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../3_modelos/modelo_perfil.dart';
import 'gestor_sesion_global.dart'; 

class RepositorioCacheLocal {
  static const String _keyPerfilUsuario = 'perfil_usuario_actual';
  static const String _keyTemaOscuro = 'preferencia_tema_oscuro';
  static const String _keyModoActual = 'modo_usuario_actual'; 

  static Future<void> guardarPerfil(ModeloPerfil perfil) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(perfil.toJson());
    await prefs.setString(_keyPerfilUsuario, jsonString);
  }

  static Future<ModeloPerfil?> obtenerPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyPerfilUsuario);
    
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return ModeloPerfil.fromJson(jsonMap);
      } catch (e) {
        return null; 
      }
    }
    return null;
  }

  static Future<void> limpiarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPerfilUsuario);
    await prefs.remove(_keyModoActual);
  }

  static Future<void> guardarModoUsuario(ModoUsuario modo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModoActual, modo.name);
  }

  static Future<ModoUsuario> obtenerModoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final String? modoStr = prefs.getString(_keyModoActual);
    if (modoStr == ModoUsuario.profesional.name) {
      return ModoUsuario.profesional;
    }
    return ModoUsuario.cliente; 
  }

  static Future<void> guardarPreferenciaTema(bool esOscuro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTemaOscuro, esOscuro);
  }

  static Future<bool> obtenerPreferenciaTema() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTemaOscuro) ?? true; 
  }
}