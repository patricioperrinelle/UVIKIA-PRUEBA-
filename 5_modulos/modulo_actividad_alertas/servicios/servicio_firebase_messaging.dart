// lib/5_modulos/modulo_actividad_alertas/servicios/servicio_firebase_messaging.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../1_nucleo/opciones_firebase.dart';

// 🚨 HANDLER BACKGROUND: Debe permanecer a nivel Top-Level para que iOS/Android lo ejecuten con la app cerrada.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🚨 FCM Background Mensaje Recibido: ${message.messageId}");
  // La notificación se mostrará automáticamente en la bandeja del SO.
}

class ServicioFirebaseMessaging {
  /// Inicializa los permisos, escucha los tokens y mapea los callbacks en Foreground.
  static Future<void> inicializar(String uid, {required Function(RemoteMessage) onMensajeRecibido}) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 1. Obtener y guardar token inicial
        String? token = await messaging.getToken();
        if (token != null) {
          await Supabase.instance.client.from('perfiles').update({'fcm_token': token}).eq('id', uid);
        }

        // 2. Escuchar cambios de token
        messaging.onTokenRefresh.listen((newToken) {
          Supabase.instance.client.from('perfiles').update({'fcm_token': newToken}).eq('id', uid);
        });

        // 3. Escuchar mensajes cuando la app está abierta (Foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          // Delegamos la acción visual (Vibrar, Snackbar) al controlador
          onMensajeRecibido(message);
        });
      }
    } catch (e) {
      debugPrint('Error inicializando Firebase FCM: $e');
    }
  }
}