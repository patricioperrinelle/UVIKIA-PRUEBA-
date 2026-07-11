// lib/5_modulos/modulo_servicios_catalogo/servicios/servicio_gestion_catalogo_supabase.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../../../1_nucleo/servicio_supabase_base.dart'; // 🚨 IMPORTAMOS NUESTRO MOTOR R2
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

class ServicioGestionCatalogoSupabase {
  static final _supabase = Supabase.instance.client;

  static Future<List<ModeloServicioCatalogo>> obtenerMisServicios(String profesionalId) async {
    final respuesta = await _supabase
        .from('servicios_catalogo')
        .select()
        .eq('profesional_id', profesionalId)
        .order('created_at', ascending: false);

    Map<String, dynamic>? perfilMap;
    try {
      final resPerfil = await _supabase.from('perfiles')
          .select('id, apodo, foto_url, rating_profesional, cantidad_resenas_profesional, promedio_estrellas, rating, cantidad_resenas')
          .eq('id', profesionalId)
          .maybeSingle();
      if (resPerfil != null) {
        perfilMap = resPerfil;
      }
    } catch (e) {
      debugPrint('Error obteniendo perfil para mis servicios: $e');
    }

    List<ModeloServicioCatalogo> list = [];
    
    for (var row in (respuesta as List<dynamic>)) {
      try {
        final Map<String, dynamic> rowMod = Map<String, dynamic>.from(row);
        if (perfilMap != null) {
          rowMod['profesional_nombre'] = perfilMap['apodo'] ?? '';
          rowMod['profesional_avatar'] = perfilMap['foto_url'] ?? '';
          rowMod['profesional_rating'] = (perfilMap['rating_profesional'] as num?)?.toDouble() ?? 0.0;
          rowMod['profesional_reviews'] = (perfilMap['cantidad_resenas_profesional'] as num?)?.toInt() ?? 0;
        } else {
          // fallback to GestorSesionGlobal
          final p = GestorSesionGlobal().perfilUsuario;
          if (p != null && p.id == profesionalId) {
            rowMod['profesional_nombre'] = p.apodo;
            rowMod['profesional_avatar'] = p.fotoUrl;
            rowMod['profesional_rating'] = p.perfilProfesional?.ratingProfesional ?? 0.0;
            rowMod['profesional_reviews'] = p.perfilProfesional?.cantidadResenasProfesional ?? 0;
          }
        }
        list.add(ModeloServicioCatalogo.fromJson(rowMod));
      } catch (e) {
        debugPrint('🚨 ERROR CRÍTICO parseando un servicio (Omitido de la lista): $e');
      }
    }
    
    return list.where((s) => s.estado != 'eliminado').toList();
  }

  static Future<int> contarServiciosTotalesActivos(String profesionalId) async {
    final respuesta = await _supabase
        .from('servicios_catalogo')
        .select('id, estado')
        .eq('profesional_id', profesionalId);
    
    final activos = (respuesta as List).where((r) => r['estado'] != 'eliminado').toList();
    return activos.length;
  }

  static Future<void> guardarServicio({
    required ModeloServicioCatalogo servicio,
    required List<File> nuevasFotosLocales,
    required List<String> fotosExistentesUrls,
    required bool esBorrador,
  }) async {
    List<String> urlsFinales = List.from(fotosExistentesUrls);

    // 🚨 REEMPLAZAMOS LA SUBIDA PESADA POR NUESTRO MOTOR COMPRESOR A R2
    for (var foto in nuevasFotosLocales) {
      final String publicUrl = await SupabaseService.uploadImage(
        foto, 
        'perfiles/${servicio.profesionalId}/catalogo'
      );
      
      if (publicUrl.isNotEmpty) {
        urlsFinales.add(publicUrl);
      }
    }

    final payload = servicio.toJson();
    payload['imagenes'] = urlsFinales;
    payload['estado'] = esBorrador ? 'borrador' : 'publicado';
    payload['activo'] = !esBorrador; 

    if (servicio.id.isEmpty) {
      payload.remove('id');
      final confirmacionBD = await _supabase.from('servicios_catalogo').insert(payload).select().single();
      debugPrint('✅ Nuevo servicio CREADO en base de datos con ID: ${confirmacionBD['id']}');
    } else {
      final confirmacionBD = await _supabase.from('servicios_catalogo').update(payload).eq('id', servicio.id).select().single();
      debugPrint('✅ Servicio ACTUALIZADO en base de datos con ID: ${confirmacionBD['id']}');
    }
  }

  static Future<void> eliminarServicio(String servicioId) async {
    await _supabase.from('servicios_catalogo').update({
      'estado': 'eliminado',
      'activo': false
    }).eq('id', servicioId);
  }

  static Future<void> pausarServicio(String servicioId) async {
    await _supabase.from('servicios_catalogo').update({
      'estado': 'pausado',
      'activo': false
    }).eq('id', servicioId);
  }

  static Future<void> reanudarServicio(String servicioId) async {
    await _supabase.from('servicios_catalogo').update({
      'estado': 'publicado',
      'activo': true
    }).eq('id', servicioId);
  }
}