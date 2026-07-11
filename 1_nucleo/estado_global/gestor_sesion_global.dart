// lib/1_nucleo/estado_global/gestor_sesion_global.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'repositorio_cache_local.dart';
import '../../3_modelos/modelo_perfil.dart';
import '../../4_componentes_globales/modales_y_alertas/modal_requiere_registro.dart';

// 🔥 LLAVE DE NAVEGACIÓN GLOBAL (El Teletransportador)
final GlobalKey<NavigatorState> navigatorKeyGlobal = GlobalKey<NavigatorState>();

enum ModoUsuario { cliente, profesional }

class GestorSesionGlobal extends ChangeNotifier with WidgetsBindingObserver {
  static final GestorSesionGlobal _instancia = GestorSesionGlobal._interno();
  factory GestorSesionGlobal() => _instancia;
  
  GestorSesionGlobal._interno() {
    WidgetsBinding.instance.addObserver(this);
  }

  ModeloPerfil? perfilUsuario;
  bool isTemaOscuro = true;
  bool isCargando = true;
  ModoUsuario modoActual = ModoUsuario.cliente;
  StreamSubscription<String>? _subscriptionTokenRefresh;
  
  final StreamController<String> _busEventosReactivos = StreamController<String>.broadcast();
  Stream<String> get streamEventos => _busEventosReactivos.stream;

  bool get estaLogueado => Supabase.instance.client.auth.currentUser != null;
  bool get esInvitado => !estaLogueado;
  String get miIdUsuario => Supabase.instance.client.auth.currentUser?.id ?? '';

  // ============================================================================
  // 🛡️ ARQUITECTURA SWR PURA (Stale-While-Revalidate + Ciclo de Vida)
  // 🚀 Se destruyó el Timer.periodic de 5s. Ahora se actualiza inteligentemente
  // ============================================================================
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && estaLogueado) {
      debugPrint('[LIFECYCLE] Gestor Sesión en primer plano. Sincronizando perfil SWR...');
      sincronizarPerfilConBaseDeDatos();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _busEventosReactivos.close();
    super.dispose();
  }

  // 🛡️ EL INTERCEPTOR GLOBAL (Auth Guard)
  static void requerirAuth(VoidCallback accionPermitida) {
    if (_instancia.estaLogueado) {
      accionPermitida(); 
    } else {
      final context = navigatorKeyGlobal.currentContext;
      if (context != null) {
        ModalRequiereRegistro.mostrar(context);
      }
    }
  }

  bool intentarCambiarModo(ModoUsuario nuevoModo) {
    if (nuevoModo == ModoUsuario.profesional) {
      if (perfilUsuario?.esProfesional != true) {
        return false; 
      }
    }
    modoActual = nuevoModo;
    RepositorioCacheLocal.guardarModoUsuario(modoActual);
    notifyListeners();
    return true; 
  }

  Future<void> cargarSesionDesdeCache() async {
    isCargando = true;
    notifyListeners();

    try {
      perfilUsuario = await RepositorioCacheLocal.obtenerPerfil();
      isTemaOscuro = await RepositorioCacheLocal.obtenerPreferenciaTema();
      modoActual = await RepositorioCacheLocal.obtenerModoUsuario();
      
      // En lugar del Polling, hacemos una validación estática SWR al abrir la app.
      sincronizarPerfilConBaseDeDatos();
      
    } catch (e) {
      debugPrint('Error leyendo caché local: $e');
    } finally {
      isCargando = false;
      notifyListeners();
    }
  }

  Future<void> sincronizarPerfilConBaseDeDatos() async {
    if (!estaLogueado) return;
    try {
      // 🚀 OBTENER Y ACTUALIZAR FCM_TOKEN EN SUPABASE
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          final token = await messaging.getToken();
          if (token != null) {
            await Supabase.instance.client
                .from('perfiles')
                .update({'fcm_token': token})
                .eq('id', miIdUsuario);
            debugPrint('FCM Token sincronizado con éxito para $miIdUsuario: $token');
          }
        }

        _subscriptionTokenRefresh ??= messaging.onTokenRefresh.listen((newToken) async {
          if (estaLogueado) {
            try {
              await Supabase.instance.client
                  .from('perfiles')
                  .update({'fcm_token': newToken})
                  .eq('id', miIdUsuario);
              debugPrint('FCM Token refrescado y sincronizado para $miIdUsuario: $newToken');
            } catch (err) {
              debugPrint('Error actualizando token refrescado: $err');
            }
          }
        });
      } catch (fcmErr) {
        debugPrint('Error de FCM en sincronización de perfil: $fcmErr');
      }

      final res = await Supabase.instance.client
          .from('perfiles')
          .select() 
          .eq('id', miIdUsuario)
          .maybeSingle();

      if (res != null) {
        res['id'] = miIdUsuario;
        final perfilFresco = ModeloPerfil.fromJson(res);

        if (perfilUsuario == null || _perfilHaCambiado(perfilUsuario!, perfilFresco)) {
          perfilUsuario = perfilFresco;
          await RepositorioCacheLocal.guardarPerfil(perfilFresco);
          _busEventosReactivos.add('perfil_actualizado');
          notifyListeners(); 
        }
      }
    } catch (e) {}
  }

  bool _perfilHaCambiado(ModeloPerfil viejo, ModeloPerfil nuevo) {
    return jsonEncode(viejo.toJson()) != jsonEncode(nuevo.toJson());
  }

  Future<void> actualizarDatosLocales(ModeloPerfil nuevoPerfil) async {
    perfilUsuario = nuevoPerfil;
    await RepositorioCacheLocal.guardarPerfil(nuevoPerfil);
    notifyListeners(); 
  }

  Future<void> destruirSesionCompletamente() async {
    perfilUsuario = null;
    modoActual = ModoUsuario.cliente; 
    await _subscriptionTokenRefresh?.cancel();
    _subscriptionTokenRefresh = null;
    await RepositorioCacheLocal.limpiarDatosUsuario();
    notifyListeners();
  }

  Future<void> toggleTemaOscuro() async {
    isTemaOscuro = !isTemaOscuro;
    await RepositorioCacheLocal.guardarPreferenciaTema(isTemaOscuro);
    notifyListeners();
  }
}