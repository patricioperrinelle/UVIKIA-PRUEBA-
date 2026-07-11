// lib/5_modulos/modulo_gestion_jornadas/servicios/servicio_gps_localizacion.dart

import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; 

class ServicioGpsLocalizacion {
  
  static Future<Position> obtenerCoordenadasActuales() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('gps_disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('permissions_denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('permissions_permanently_denied');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // 🚨 REPARADO (FALLA 5): Método nativo para abrir Google Maps / Apple Maps
  static Future<void> abrirEnMapa(String query) async {
    if (query.isEmpty) return;
    final String encoded = Uri.encodeComponent(query);
    final Uri url = Platform.isIOS
        ? Uri.parse('https://maps.apple.com/?q=$encoded')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
        
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir el mapa.');
    }
  }
}