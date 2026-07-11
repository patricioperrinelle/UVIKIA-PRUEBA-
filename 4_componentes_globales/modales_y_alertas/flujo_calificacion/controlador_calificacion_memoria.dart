// lib/4_componentes_globales/modales_y_alertas/flujo_calificacion/controlador_calificacion_memoria.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../3_modelos/modelo_resena_payload.dart';

class ControladorCalificacionMemoria extends ChangeNotifier {
  bool cargandoMemoria = true; 

  int estrellasDadas = 0;
  final TextEditingController resenaController = TextEditingController();

  bool? puntualidad = true;
  bool? loRecomiendaCliente = true;
  bool? tratoRespetuoso = true; 
  bool? loRecomiendaPro = true;
  bool? descripcionPrecisa = true;

  // 🛡️ NUEVO: Lista de etiquetas negativas para el escudo de privacidad
  final List<String> etiquetasNegativas = [];

  late String _idUnicoMemoria;

  Future<void> inicializar(String profesionalId, bool esCliente) async {
    _idUnicoMemoria = '${profesionalId}_${esCliente ? "cli" : "pro"}';
    // 🚨 PURGA LEGACY: Se erradicó la lectura de 'fase' y 'metodo_pago' del disco duro.
    // El modal ahora es de una sola vista (Directo a estrellas).
    
    cargandoMemoria = false;
    notifyListeners();
  }

  void actualizarEstrellas(int estrellas) {
    estrellasDadas = estrellas;
    notifyListeners();
  }

  void setPuntualidad(bool? val) { puntualidad = val; notifyListeners(); }
  void setLoRecomiendaCliente(bool? val) { loRecomiendaCliente = val; notifyListeners(); }
  void setTratoRespetuoso(bool? val) { tratoRespetuoso = val; notifyListeners(); }
  void setLoRecomiendaPro(bool? val) { loRecomiendaPro = val; notifyListeners(); }
  void setDescripcionPrecisa(bool? val) { descripcionPrecisa = val; notifyListeners(); }

  Future<ModeloResenaPayload?> generarPayloadFinal(bool esCliente) async {
    if (estrellasDadas == 0) return null; 

    final bool esPuntualOResp = esCliente ? (puntualidad ?? true) : (tratoRespetuoso ?? true);
    final bool esRecomOClaro = esCliente ? (loRecomiendaCliente ?? true) : (loRecomiendaPro ?? true);

    final payload = ModeloResenaPayload(
      rating: estrellasDadas,
      comentario: resenaController.text.trim(),
      // 🚨 PURGA LEGACY: El método de pago ya no se elige en la UI. Inyectamos "Escrow" por defecto para mantener compatibilidad con la BD.
      metodoPago: 'Escrow',
      esPuntualORespetuoso: esPuntualOResp,
      esRecomendadoOClaro: esRecomOClaro,
      esPuntual: puntualidad ?? true,
      loRecomienda: esCliente ? (loRecomiendaCliente ?? true) : (loRecomiendaPro ?? true),
      tratoRespetuoso: tratoRespetuoso ?? true,
      descripcionPrecisa: descripcionPrecisa ?? true,
      rolEvaluado: esCliente ? 'profesional' : 'cliente',
    );
    
    return payload;
  }

  @override
  void dispose() {
    resenaController.dispose();
    super.dispose();
  }
}