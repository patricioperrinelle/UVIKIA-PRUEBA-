// lib/1_nucleo/arranque_app.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'opciones_firebase.dart';
import 'gestor_conectividad.dart';
import 'estado_global/gestor_sesion_global.dart'; 
import '../2_tema/tema_global.dart';
import '../2_tema/colores_app.dart'; 

import '../5_modulos/modulo_autenticacion/pantallas/pantalla_login.dart';
import '../5_modulos/modulo_explorar_feed/pantallas/pantalla_home_hub.dart';
import '../5_modulos/modulo_explorar_feed/pantallas/pantalla_categorias_oficios.dart';
import '../5_modulos/modulo_explorar_feed/pantallas/pantalla_feed_trabajos.dart';
import '../5_modulos/modulo_explorar_feed/pantallas/pantalla_feed_profesionales.dart';
import '../5_modulos/modulo_publicaciones/pantallas/pantalla_publicar_trabajo.dart';
import '../5_modulos/modulo_perfil_usuario/pantallas/pantalla_perfil_publico.dart';
import '../5_modulos/modulo_servicios_catalogo/controladores/controlador_actividad_catalogo.dart';
import '../5_modulos/modulo_gestion_jornadas/controladores/controlador_actividad_jornadas.dart';
import '../5_modulos/modulo_negociacion_oficios/controladores/controlador_actividad_oficios.dart';
import '../5_modulos/modulo_actividad_alertas/controladores/controlador_bandeja_notificaciones.dart';
import '../5_modulos/modulo_servicios_catalogo/pantallas/pantalla_ejecucion_catalogo.dart';
import '../5_modulos/modulo_gestion_jornadas/pantallas/pantalla_gestion_jornada.dart';
import '../5_modulos/modulo_negociacion_oficios/pantallas/pantalla_negociacion_oficio.dart';
import '../3_modelos/modelo_jornada.dart';
import '../3_modelos/modelo_reserva_catalogo.dart';
import '../3_modelos/modelo_oficio_trabajo.dart';
import '../4_componentes_globales/contratos/fuente_de_actividad.dart';
import '../4_componentes_globales/contratos/analizador_estado.dart';
import '../5_modulos/modulo_servicios_catalogo/analizador_estado_catalogo.dart';
import '../5_modulos/modulo_gestion_jornadas/analizador_estado_jornadas.dart';
import '../5_modulos/modulo_negociacion_oficios/analizador_estado_oficios.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void _procesarRutaNotificacion(RemoteMessage message) {
  final context = navigatorKeyGlobal.currentContext;
  if (context == null) {
    debugPrint('⚠️ No se puede enrutar, navigatorKeyGlobal.currentContext es nulo');
    return;
  }
  
  final trabajoId = message.data['trabajo_id'];
  if (trabajoId != null && trabajoId.toString().isNotEmpty) {
    debugPrint('🚀 Enrutando a trabajo_id: $trabajoId');
    ControladorBandejaNotificaciones().enrutarDesdeNotificacion(context, trabajoId.toString());
  } else {
    debugPrint('⚠️ Notificación no contiene trabajo_id válido para enrutar');
  }
}

void _inicializarFuentesActividad() {
  ControladorActividadCatalogo.constructorPantallaDetalle = (trabajo, esHistorial) {
    return PantallaEjecucionCatalogo(jobData: (trabajo as ModeloReservaCatalogo).toJson());
  };

  ControladorActividadJornadas.constructorPantallaDetalle = (trabajo, esHistorial) {
    return PantallaGestionJornada(
      jobData: (trabajo as ModeloJornada).toJson(),
      trabajoTipado: trabajo as ModeloJornada,
      esHistorial: esHistorial,
    );
  };

  ControladorActividadOficios.constructorPantallaDetalle = (trabajo, esHistorial) {
    return PantallaNegociacionOficio(
      jobData: (trabajo as ModeloOficioTrabajo).toJson(),
      esHistorial: esHistorial,
    );
  };

  RegistroFuentesActividad.registrar(ControladorActividadCatalogo());
  RegistroFuentesActividad.registrar(ControladorActividadJornadas());
  RegistroFuentesActividad.registrar(ControladorActividadOficios());

  RegistroAnalizadoresEstado.registrar(AnalizadorEstadoCatalogo());
  RegistroAnalizadoresEstado.registrar(AnalizadorEstadoJornadas());
  RegistroAnalizadoresEstado.registrar(AnalizadorEstadoOficios());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _inicializarFuentesActividad();

  // Registrar callback desacoplado de enrutamiento de notificaciones
  ControladorBandejaNotificaciones.registrarCallbackAlEnrutar(() {
    for (var fuente in RegistroFuentesActividad.fuentes) {
      fuente.recargarSilenciosoGlobal();
    }
  });

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    final messaging = FirebaseMessaging.instance;
    
    // 🚀 CONFIGURACIÓN DE PERMISOS FCM
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // 🚀 PRESENTACIÓN EN PRIMER PLANO PARA IOS/MACOS
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🚀 ESCUCHAR MENSAJES EN PRIMER PLANO (FOREGROUND)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🚨 FCM Foreground Mensaje Recibido: ${message.messageId}');
      
      // Recargar la bandeja local en tiempo real si el usuario está logueado
      try {
        ControladorBandejaNotificaciones().cargarNotificaciones();
        
        // Recargar silenciosamente las fuentes de actividad para mantener la agenda sincronizada
        for (var fuente in RegistroFuentesActividad.fuentes) {
          fuente.recargarSilenciosoGlobal();
        }
      } catch (e) {
        debugPrint('Error recargando bandeja: $e');
      }
      
      final context = navigatorKeyGlobal.currentContext;
      if (context != null) {
        final notification = message.notification;
        if (notification != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E1B4B), // Fondo morado muy oscuro
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
              ),
              margin: const EdgeInsets.all(16),
              elevation: 8,
              duration: const Duration(seconds: 5),
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title ?? 'Nueva Notificación',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (notification.body != null)
                          Text(
                            notification.body!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'VER',
                textColor: const Color(0xFFA78BFA),
                onPressed: () {
                  final trabajoId = message.data['trabajo_id'];
                  if (trabajoId != null && trabajoId.toString().isNotEmpty) {
                    ControladorBandejaNotificaciones().enrutarDesdeNotificacion(context, trabajoId.toString());
                  }
                },
              ),
            ),
          );
        }
      }
    });

    // 🚀 ENRUTAMIENTO DESDE SEGUNDO PLANO (BACKGROUND TAP)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚨 FCM Notificación tocada (Background): ${message.messageId}');
      _procesarRutaNotificacion(message);
    });

    // 🚀 ENRUTAMIENTO DESDE ESTADO CERRADO (TERMINATED TAP)
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚨 FCM App abierta desde notificación (Terminated): ${message.messageId}');
        Future.delayed(const Duration(milliseconds: 1200), () {
          _procesarRutaNotificacion(message);
        });
      }
    });

    await Supabase.initialize(
      url: 'https://bjmofljovgekyhqbdomq.supabase.co',
      anonKey: 'sb_publishable_A2tiX031bwBJoX0rG6h7Fg_B3DWU2RP',
    );
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Error inicializando servicios críticos: $e');
  }

  final gestorSesion = GestorSesionGlobal();
  await gestorSesion.cargarSesionDesdeCache();

  runApp(
    ChangeNotifierProvider.value(
      value: gestorSesion,
      child: const AntigravityBootstrapper(),
    ),
  );
}

class AntigravityBootstrapper extends StatelessWidget {
  const AntigravityBootstrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gestorSesion = context.watch<GestorSesionGlobal>();

    return MaterialApp(
      navigatorKey: navigatorKeyGlobal, 
      title: 'Antigravity Services',
      debugShowCheckedModeBanner: false,
      theme: TemaGlobal.obtenerTemaClaro(),
      darkTheme: TemaGlobal.obtenerTemaOscuro(),
      themeMode: gestorSesion.isTemaOscuro ? ThemeMode.dark : ThemeMode.light,
      
      builder: (context, child) {
        final colorBorde = gestorSesion.modoActual == ModoUsuario.cliente 
            ? ColoresApp.primarioVerde.withOpacity(0.3) 
            : ColoresApp.terciarioMorado.withOpacity(0.4);

        return Directionality(
          textDirection: TextDirection.ltr,
          child: GlobalConnectivityWrapper(
            child: Container(
              foregroundDecoration: BoxDecoration(
                border: Border.all(color: colorBorde, width: 1.5),
              ),
              child: child!,
            ),
          ),
        );
      },
      
      home: Builder(
        builder: (context) {
          // 🚨 EL MOTOR AHORA EVALÚA QUÉ DESPERTAR, PERO DEJA PASAR A TODOS AL HOME
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (gestorSesion.estaLogueado) {
              context.read<GestorSesionGlobal>().sincronizarPerfilConBaseDeDatos();
              ControladorActividadCatalogo().recargarDatosDesdeCero();
              ControladorActividadJornadas().recargarDatosDesdeCero();
              ControladorActividadOficios().recargarDatosDesdeCero();
            }
          });
          
          // 🔥 LA PUERTA ESTÁ ABIERTA: Invitados y logueados van al Hub Principal
          return const PantallaHomeHub(); 
        },
      ),
      
      routes: <String, WidgetBuilder>{
        '/login': (context) => const PantallaLogin(),
        '/categorias_oficios': (context) => const PantallaCategoriasOficios(),
        '/feed_trabajos': (context) => const PantallaFeedTrabajos(),
        '/feed_profesionales': (context) => const PantallaFeedProfesionales(),
        '/publicar_trabajo': (context) => const PantallaPublicarTrabajo(),
        '/perfil_profesional': (context) => const PantallaPerfilPublico(),
        '/catalogo_ejecucion': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PantallaEjecucionCatalogo(jobData: args);
        },
        '/jornada_gestion': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PantallaGestionJornada(
            jobData: args['jobData'] as Map<String, dynamic>,
            trabajoTipado: args['trabajoTipado'] as ModeloJornada,
          );
        },
        '/negociacion_oficio': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PantallaNegociacionOficio(jobData: args);
        },
      },
    );
  }
}