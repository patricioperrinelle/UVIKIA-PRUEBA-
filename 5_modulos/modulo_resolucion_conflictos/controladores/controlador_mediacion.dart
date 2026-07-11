// lib/5_modulos/modulo_resolucion_conflictos/controladores/controlador_mediacion.dart

import 'package:flutter/material.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../servicios/servicio_mediacion_supabase.dart';

class ControladorMediacion extends ChangeNotifier {
  final String trabajoId;
  
  bool isLoading = true;
  bool isProcessing = false;
  
  Map<String, dynamic> trabajoData = {};
  Map<String, dynamic>? disputaData;
  
  late String miId;
  bool soyElReportador = false;

  void Function(String evento, [dynamic payload])? onRequerirAccionUI;

  ControladorMediacion(this.trabajoId) {
    miId = GestorSesionGlobal().miIdUsuario;
    cargarDatos();
  }

  // GETTERS DE UI Ciega
  String get tituloTrabajo => trabajoData['titulo'] ?? 'Trabajo';
  String get precioTrabajo => trabajoData['precio']?.toString() ?? '\$ 0';
  
  String get categoriaProblema => disputaData?['categoria'] ?? 'Problema reportado';
  String get descripcionProblema => disputaData?['descripcion'] ?? '';
  String get solucionEsperada => disputaData?['solucion_esperada'] ?? '';
  List<String> get fotosEvidencia => List<String>.from(disputaData?['evidencia_urls'] ?? []);
  
  String get estadoMediacion => disputaData?['estado'] ?? 'desconocido';

  Future<void> cargarDatos() async {
    isLoading = true;
    notifyListeners();
    try {
      final datos = await ServicioMediacionSupabase.obtenerDatosMediacion(trabajoId);
      trabajoData = datos['trabajo'];
      disputaData = datos['disputa'];
      
      if (disputaData != null) {
        soyElReportador = disputaData!['reportador_id'] == miId;
      }
    } catch (e) {
      onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error al cargar la mediación.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void aceptarSolucion() {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true;
      notifyListeners();
      try {
        await ServicioMediacionSupabase.aceptarSolucion(disputaData!['id'], trabajoId, solucionEsperada);
        await cargarDatos();
        onRequerirAccionUI?.call('MOSTRAR_EXITO', 'Acuerdo logrado. El trabajo vuelve a estar en curso para su corrección.');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'No se pudo registrar el acuerdo.');
      } finally {
        isProcessing = false;
        notifyListeners();
      }
    });
  }

  void rechazarYElevarSoporte() {
    GestorSesionGlobal.requerirAuth(() async {
      isProcessing = true;
      notifyListeners();
      try {
        await ServicioMediacionSupabase.elevarASoporte(disputaData!['id'], 'El profesional no está de acuerdo con el reclamo.');
        await cargarDatos();
        onRequerirAccionUI?.call('MOSTRAR_EXITO', 'El caso ha sido elevado. Soporte se contactará a la brevedad.');
      } catch (e) {
        onRequerirAccionUI?.call('MOSTRAR_ERROR', 'Error al elevar a soporte.');
      } finally {
        isProcessing = false;
        notifyListeners();
      }
    });
  }
}