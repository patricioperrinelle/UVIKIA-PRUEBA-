// lib/1_nucleo/utilidades/mixin_gestor_tickets.dart

import 'package:flutter/foundation.dart';

mixin MixinGestorTickets on ChangeNotifier {
  List<Map<String, dynamic>> adicionalesPresupuesto = [];
  final Set<String> _adicionalesMostrados = {};
  bool wasPendingLocal = false;

  // 🚨 CONTRATO ARQUITECTÓNICO: Obliga al Controlador hijo a proveer estos datos
  double get precioBaseAcordadoLimpio;
  Future<void> guardarAdicionalesBd(List<Map<String, dynamic>> adicionales);
  
  void notificarUI() => notifyListeners();

  List<Map<String, dynamic>> get adicionalesParaEvaluacionCliente {
    return adicionalesPresupuesto.where((a) => !a['id'].toString().startsWith('SYS_BACKUP')).toList();
  }

  List<Map<String, dynamic>> get adicionalesBorradorPro {
    return adicionalesPresupuesto.where((a) => !a['id'].toString().startsWith('SYS_')).toList();
  }

  bool get tieneAdicionalesPendientes => adicionalesPresupuesto.any((a) => a['estado'] == 'pendiente');

  // 🚨 CEREBRO MATEMÁTICO PURO
  double get precioTotalConAdicionales {
    double base = precioBaseAcordadoLimpio;
    double extras = 0.0;
    
    bool hayPendientes = tieneAdicionalesPendientes;
    if (hayPendientes) {
      final backupItem = adicionalesPresupuesto.firstWhere((a) => a['id'] == 'SYS_BACKUP', orElse: () => {});
      if (backupItem.isNotEmpty && backupItem['data'] != null) {
        final backupList = List<Map<String, dynamic>>.from(backupItem['data']);
        for (var adic in backupList) {
          extras += double.tryParse(adic['monto'].toString()) ?? 0.0;
        }
        return base + extras;
      }
    }

    for (var adic in adicionalesPresupuesto) {
      if (adic['estado'] == 'aceptado') {
        extras += double.tryParse(adic['monto'].toString()) ?? 0.0;
      }
    }
    return base + extras;
  }

  // 🚨 SISTEMA DE ROLLBACKS Y MUTACIONES
  Future<void> enviarTicketAdicionales(List<Map<String, dynamic>> itemsBorrador) async {
    final estadoAnteriorAceptado = adicionalesPresupuesto
        .where((a) => a['estado'] == 'aceptado' && !a['id'].toString().startsWith('SYS_'))
        .toList();
    
    List<Map<String, dynamic>> nuevoArray = [];
    
    if (estadoAnteriorAceptado.isNotEmpty) {
      nuevoArray.add({ 'id': 'SYS_BACKUP', 'concepto': 'Backup interno', 'monto': 0, 'estado': 'oculto', 'data': estadoAnteriorAceptado });
    }

    if (itemsBorrador.isEmpty) {
      nuevoArray.add({ 'id': 'SYS_EMPTY_${DateTime.now().millisecondsSinceEpoch}', 'concepto': 'Anular todos los ítems extra', 'monto': 0, 'estado': 'pendiente' });
    } else {
      nuevoArray.addAll(itemsBorrador.map((e) {
        return { 'id': e['id'] ?? '${DateTime.now().millisecondsSinceEpoch}_${e['concepto'].hashCode}', 'concepto': e['concepto'], 'monto': e['monto'], 'estado': 'pendiente' };
      }));
    }
    
    adicionalesPresupuesto = nuevoArray;
    wasPendingLocal = true; 
    await guardarAdicionalesBd(adicionalesPresupuesto);
    notificarUI();
  }

  Future<void> responderTicketAdicionalBatch(bool aceptado) async {
    if (aceptado) {
      if (adicionalesPresupuesto.any((a) => a['id'].toString().startsWith('SYS_EMPTY'))) {
        adicionalesPresupuesto = [];
      } else {
        adicionalesPresupuesto.removeWhere((a) => a['id'].toString().startsWith('SYS_')); 
        for (var a in adicionalesPresupuesto) { a['estado'] = 'aceptado'; }
      }
    } else {
      final backupItem = adicionalesPresupuesto.firstWhere((a) => a['id'] == 'SYS_BACKUP', orElse: () => {});
      if (backupItem.isNotEmpty && backupItem['data'] != null) {
        adicionalesPresupuesto = List<Map<String, dynamic>>.from(backupItem['data']);
      } else { adicionalesPresupuesto = []; }
    }
    
    await guardarAdicionalesBd(adicionalesPresupuesto);
    notificarUI();
  }

  // 🚨 DETECTOR DE ALERTAS UNIFICADO PARA AMBOS MÓDULOS
  void procesarAlertasTickets(bool soyElDueno, Function(String) onRequerirAccionUI) {
    final bool isPendingNow = tieneAdicionalesPendientes;
    if (soyElDueno) {
      if (isPendingNow) {
        final hash = adicionalesPresupuesto.map((e) => e['id']).join('_');
        if (!_adicionalesMostrados.contains(hash)) {
          _adicionalesMostrados.add(hash);
          onRequerirAccionUI('EVALUAR_TICKET');
        }
      }
    } else {
      if (wasPendingLocal && !isPendingNow) {
        wasPendingLocal = false; 
        onRequerirAccionUI('TICKET_RESPONDIDO'); 
      } else if (isPendingNow) {
        wasPendingLocal = true; 
      }
    }
  }
}