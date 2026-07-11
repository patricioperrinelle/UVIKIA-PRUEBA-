// lib/1_nucleo/opciones_firebase.dart
// Archivo generado por FlutterFire CLI, renombrado para la arquitectura.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'opciones_firebase.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA9u3jZfiwM-631WRKHy56vFo9Fdo5EiXw',
    appId: '1:901603644518:web:2addef75d0d9a99d0149a7',
    messagingSenderId: '901603644518',
    projectId: 'conexion-e9746',
    authDomain: 'conexion-e9746.firebaseapp.com',
    storageBucket: 'conexion-e9746.firebasestorage.app',
    measurementId: 'G-H692TFVDZH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDo6oZXeh6Fw6XA0ASdTbTGptBkrAv0BBw',
    appId: '1:901603644518:android:e003fdbf4b9c748b0149a7',
    messagingSenderId: '901603644518',
    projectId: 'conexion-e9746',
    storageBucket: 'conexion-e9746.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBbC3RjUO5LdsLqGkJUnIYKGrdFWwCZPWo',
    appId: '1:901603644518:ios:336f6cd4aed93e750149a7',
    messagingSenderId: '901603644518',
    projectId: 'conexion-e9746',
    storageBucket: 'conexion-e9746.firebasestorage.app',
    iosBundleId: 'com.example.app01',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBbC3RjUO5LdsLqGkJUnIYKGrdFWwCZPWo',
    appId: '1:901603644518:ios:336f6cd4aed93e750149a7',
    messagingSenderId: '901603644518',
    projectId: 'conexion-e9746',
    storageBucket: 'conexion-e9746.firebasestorage.app',
    iosBundleId: 'com.example.app01',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA9u3jZfiwM-631WRKHy56vFo9Fdo5EiXw',
    appId: '1:901603644518:web:7d591d2b2be84f700149a7',
    messagingSenderId: '901603644518',
    projectId: 'conexion-e9746',
    authDomain: 'conexion-e9746.firebaseapp.com',
    storageBucket: 'conexion-e9746.firebasestorage.app',
    measurementId: 'G-Y4N4ZVQFWH',
  );
}