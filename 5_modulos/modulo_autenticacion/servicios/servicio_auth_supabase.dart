// lib/5_modulos/modulo_autenticacion/servicios/servicio_auth_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicioAuthSupabase {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<String> iniciarSesion(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      if (res.user == null) throw Exception("La respuesta del servidor es nula.");
      return res.user!.id;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw Exception('Credenciales incorrectas. Verifica tu correo y contraseña.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  static Future<bool> existeDni(String dni) async {
    try {
      final response = await _client.from('perfiles').select('id').eq('dni', dni).maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Error al verificar DNI en la base de datos.');
    }
  }

  // 🚀 PASO 1: Crea el usuario y nos da el ID (Token) para subir fotos a R2
  static Future<String> crearCuentaAuth(String email, String password) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      if (res.user == null) throw Exception("No se pudo crear la cuenta de usuario.");
      return res.user!.id;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 🚀 PASO 2: Guarda el perfil en PostgreSQL
  static Future<void> insertarPerfil(Map<String, dynamic> payload) async {
    try {
      // El select().single() es OBLIGATORIO por la política Data-Miser
      await _client.from('perfiles').insert(payload).select().single();
    } on PostgrestException catch (e) {
      throw Exception("Error de BD: ${e.message}");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  static Future<void> recuperarPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  static Future<void> recuperarPasswordPorDni(String dni) async {
    try {
      final response = await _client.from('perfiles').select('email').eq('dni', dni).maybeSingle();
      if (response == null || response['email'] == null || response['email'].toString().isEmpty) {
        throw Exception('No existe ninguna cuenta registrada con este DNI.');
      }
      await _client.auth.resetPasswordForEmail(response['email']);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  static Future<String?> obtenerApodoPorId(String id) async {
    try {
      final response = await _client.from('perfiles').select('apodo').eq('id', id).maybeSingle();
      return response?['apodo']?.toString();
    } catch (e) {
      return null;
    }
  }
}