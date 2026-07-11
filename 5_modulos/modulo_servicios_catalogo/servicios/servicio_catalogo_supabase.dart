// lib/5_modulos/modulo_servicios_catalogo/servicios/servicio_catalogo_supabase.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../../../3_modelos/modelo_perfil.dart'; 
import '../controladores/controlador_disponibilidad_agenda.dart';

class ServicioCatalogoSupabase {
  static final _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> obtenerServiciosPaginadosV5({
    required String ciudad, required String localidad, required String categoria, required String keyword,
    required bool cursorEsCiudad, required bool cursorEsLocalidad, required double cursorRank,
    required String cursorFecha, required int cursorRotacion, required String cursorId, required int limit,
    required Map<String, Map<String, dynamic>> perfilesCache, 
  }) async {
    final resRpc = await _supabase.rpc('obtener_feed_servicios_v5', params: {
      'p_ciudad': ciudad, 'p_localidad': localidad, 'p_filtro_categoria': categoria, 'p_keyword': keyword,
      'p_cursor_es_ciudad': cursorEsCiudad, 'p_cursor_es_localidad': cursorEsLocalidad, 'p_cursor_rank': cursorRank,
      'p_cursor_fecha': cursorFecha, 'p_cursor_rotacion': cursorRotacion, 'p_cursor_id': cursorId, 'p_limit': limit,
    });
    
    final listaCruda = List<Map<String, dynamic>>.from(resRpc);
    if (listaCruda.isEmpty) return [];

    final List<Map<String, dynamic>> listaModificable = listaCruda.map((s) => Map<String, dynamic>.from(s)).toList();

    final Set<String> profesionalesFaltantes = {};
    for (var s in listaModificable) {
      final pId = s['profesional_id']?.toString() ?? '';
      if (pId.isNotEmpty && !perfilesCache.containsKey(pId)) profesionalesFaltantes.add(pId);
    }

    if (profesionalesFaltantes.isNotEmpty) {
      try {
        final resPerfiles = await _supabase.from('perfiles')
            .select('id, apodo, foto_url, rating_profesional, cantidad_resenas_profesional, promedio_estrellas, rating, cantidad_resenas')
            .inFilter('id', profesionalesFaltantes.toList());
        for (var p in (resPerfiles as List)) { 
          perfilesCache[p['id'].toString()] = p; 
        }
      } catch (e) { 
        debugPrint('Error Batch Catálogo: $e'); 
      }
    }

    for (var json in listaModificable) {
      final idPro = json['profesional_id']?.toString() ?? '';
      if (idPro.isNotEmpty && perfilesCache.containsKey(idPro)) {
        final perfil = perfilesCache[idPro]!;
        json['profesional_nombre'] = perfil['apodo'] ?? '';
        json['profesional_avatar'] = perfil['foto_url'] ?? '';
        json['profesional_rating'] = (perfil['rating_profesional'] as num?)?.toDouble() ?? 0.0;
        json['profesional_reviews'] = (perfil['cantidad_resenas_profesional'] as num?)?.toInt() ?? 0;
      }
    }
    return listaModificable;
  }

  static Future<Set<String>> obtenerMisFavoritosIds(String miId) async {
    if (miId.isEmpty) return {};
    try {
      final respuesta = await _supabase.from('favoritos_catalogo').select('servicio_id').eq('usuario_id', miId).order('created_at', ascending: false);
      return (respuesta as List).map((e) => e['servicio_id'].toString()).toSet();
    } catch (e) {
      // 🛡️ BARRERA ANTI-WIPEOUT: Si falla la red, obligamos a que el catch devuelva un error (null arriba) para que la RAM sobreviva.
      throw Exception('Fallo de red al obtener favoritos catálogo. $e');
    }
  }

  static Future<bool> toggleFavorito(String miId, String servicioId, bool esFavoritoActual) async {
    try {
      if (esFavoritoActual) {
        await _supabase.from('favoritos_catalogo').delete().eq('usuario_id', miId).eq('servicio_id', servicioId);
        return false; 
      } else {
        await _supabase.from('favoritos_catalogo').insert({'usuario_id': miId, 'servicio_id': servicioId});
        return true; 
      }
    } catch (e) { return esFavoritoActual; }
  }

  static Future<ModeloPerfil> obtenerPerfilVendedor(String profesionalId) async {
    final respuesta = await _supabase.from('perfiles').select().eq('id', profesionalId).single();
    return ModeloPerfil.fromJson(respuesta);
  }

  static Future<List<BloqueOcupado>> obtenerBloquesOcupados(String profesionalId, DateTime dia) async {
    final inicioDiaISO = DateTime(dia.year, dia.month, dia.day, 0, 0, 0).toIso8601String();
    final finDiaISO = DateTime(dia.year, dia.month, dia.day, 23, 59, 59).toIso8601String();
    
    // Pedimos estado, created_at y fecha_vencimiento para evaluar fantasmas.
    final respuesta = await _supabase.from('trabajos')
        .select('fecha_hora, hora_fin, estado, created_at, fecha_vencimiento')
        .eq('profesional_asignado_id', profesionalId)
        .inFilter('estado', ['asignado', 'aceptada', 'en_curso', 'pendiente_pago', 'esperando_pin_llegada', 'esperando_pin_salida'])
        .gte('fecha_hora', inicioDiaISO)
        .lte('fecha_hora', finDiaISO);

    List<BloqueOcupado> bloques = [];
    final ahoraUtc = DateTime.now().toUtc();

    for (var row in (respuesta as List<dynamic>)) {
      final estado = row['estado'];

      // 🆕 REGLA DE EXPIRACIÓN: reservas pendientes_pago se ignoran si ya vencieron.
      // Usamos fecha_vencimiento (15 min) si existe; si no (legacy), fallback a created_at + 40 min.
      if (estado == 'pendiente_pago') {
        final fechaVenc = DateTime.tryParse(row['fecha_vencimiento']?.toString() ?? '');
        final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
        final limite = fechaVenc ?? createdAt?.add(const Duration(minutes: 40));
        if (limite != null && limite.isBefore(ahoraUtc)) {
          // Reserva vencida: el horario vuelve a estar libre.
          continue;
        }
      }

      final inicio = DateTime.tryParse(row['fecha_hora']?.toString() ?? '');
      final fin = DateTime.tryParse(row['hora_fin']?.toString() ?? '');
      if (inicio != null && fin != null) bloques.add(BloqueOcupado(inicio: inicio, fin: fin));
    }
    return bloques;
  }

  static Future<String> iniciarCheckoutBloqueadoTemporal({
    required String reservaId, 
    required ModeloServicioCatalogo servicio, 
    required ModeloNivelServicio nivelElegido,
    required DateTime fechaInicio, 
    required DateTime fechaFin, 
    required String clienteId,
    required String direccionReal, 
    required String notasCliente, 
    required double precioFinal, 
  }) async {
    final payload = {
      'id': reservaId, 
      'titulo': '${servicio.titulo} - ${nivelElegido.nombre}',
      'descripcion': 'Servicio Catalogado cerrado. Modalidad: ${servicio.modalidad}\nNotas del cliente: $notasCliente',
      'precio': precioFinal.toString(), 
      'fecha_hora': fechaInicio.toIso8601String(), 
      'hora_fin': fechaFin.toIso8601String(),
      // 🆕 El estado 'pendiente_pago' y fecha_vencimiento los setea el RPC atómicamente.
      'cliente_id': clienteId, 
      'profesional_asignado_id': servicio.profesionalId,
      'profesional_solicitado_id': servicio.profesionalId, 
      'metodo_pago': 'a_definir', 
      'dificultad': 'catalogo',
      'ubicacion_exacta': direccionReal, 
      'servicio_catalogo_id': servicio.id, 
      'oficio': servicio.categoria,
      'localidad': 'A convenir', 
      'requisitos': '', 
      'imagenes': servicio.imagenes,
    };
    
    try {
      await _supabase.rpc('iniciar_reserva_catalogo_atomica', params: {
        'p_payload': payload
      });
      return reservaId;
    } catch (e) {
      if (e.toString().contains('horario_ocupado')) {
        throw Exception('El horario seleccionado acaba de ser ocupado por otra persona. Por favor elegí otro.');
      }
      if (e.toString().contains('reserva_duplicada')) {
        throw Exception('Ya tenés una reserva pendiente para este servicio en ese horario. Finalizá el pago o esperá a que expire.');
      }
      throw Exception('Fallo al reservar el horario temporalmente: $e');
    }
  }

  

  static Future<void> liberarBloqueoTemporal(String trabajoId) async {
    await _supabase.from('trabajos')
        .delete()
        .eq('id', trabajoId)
        .eq('estado', 'pendiente_pago');
  }

  // 🆕 Verifica si el cliente ya tiene una reserva pendiente_pago (no expirada) para un servicio.
  // Usado por el banner "⏳ Tienes una reserva pendiente" y el bloqueo anti-duplicado en UI.
  // Cuidado requests: trae solo 1 fila (.maybeSingle) y solo campos mínimos.
  static Future<Map<String, dynamic>?> verificarReservaPendiente({
    required String clienteId,
    required String servicioId,
  }) async {
    try {
      final res = await _supabase
          .from('trabajos')
          .select('id, fecha_hora, hora_fin, fecha_vencimiento, estado, precio')
          .eq('cliente_id', clienteId)
          .eq('servicio_catalogo_id', servicioId)
          .eq('estado', 'pendiente_pago')
          .order('fecha_vencimiento', ascending: false)
          .limit(1)
          .maybeSingle();
      return res;
    } catch (e) {
      // 🛡️ BARRERA ANTI-WIPEOUT: si cae la red, devolvemos null para no bloquear la UI.
      debugPrint('Error verificando reserva pendiente: $e');
      return null;
    }
  }

  // 🆕 Verifica el estado REAL de una reserva temporal y su pago asociado en la BD.
  // Única fuente de verdad (Opción A). Cuidado requests: trae solo 2 campos por tabla.
  // Retorna un mapa con: estadoReserva (trabajos.estado), estadoPago (wallet_transactions.estado).
  static Future<Map<String, String?>> verificarEstadoReservaBD(String reservaId) async {
    try {
      // 1. Estado de la reserva (asignado / pendiente_pago / expirada / etc.)
      final resTrabajo = await _supabase
          .from('trabajos')
          .select('estado, fecha_vencimiento')
          .eq('id', reservaId)
          .maybeSingle();

      // 2. Estado del pago en el ledger (pendiente / completado / fallido / etc.)
      String? estadoPago;
      try {
        final resTx = await _supabase
            .from('wallet_transactions')
            .select('estado')
            .eq('referencia_trabajo_id', reservaId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        estadoPago = resTx?['estado']?.toString();
      } catch (_) {
        estadoPago = null;
      }

      return {
        'estadoReserva': resTrabajo?['estado']?.toString(),
        'fechaVencimiento': resTrabajo?['fecha_vencimiento']?.toString(),
        'estadoPago': estadoPago,
      };
    } catch (e) {
      // 🛡️ BARRERA ANTI-WIPEOUT: si cae la red, devolvemos todo null.
      debugPrint('Error verificando estado de reserva: $e');
      return {'estadoReserva': null, 'fechaVencimiento': null, 'estadoPago': null};
    }
  }

  static Future<void> solicitarReprogramacion(String trabajoId, DateTime nuevaFechaInicio, DateTime nuevaFechaFin) async {
    await _supabase.from('trabajos').update({
          'metadata_reprogramacion': { 'propuesta_inicio': nuevaFechaInicio.toIso8601String(), 'propuesta_fin': nuevaFechaFin.toIso8601String(), 'estado_reprogramacion': 'pendiente' }
        }).eq('id', trabajoId);
  }
}