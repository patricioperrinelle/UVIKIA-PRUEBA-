// lib/5_modulos/modulo_perfil_usuario/controladores/controlador_visualizacion_perfil.dart

import 'package:flutter/material.dart';
import '../servicios/servicio_perfil_supabase.dart';
import '../../../3_modelos/modelo_perfil.dart';
import '../../../3_modelos/modelo_resena.dart';

class ControladorVisualizacionPerfil extends ChangeNotifier {
  bool isLoading = true;
  bool isDisponibleLocal = true; 
  bool isFavorito = false; 
  
  ModeloPerfil? perfilActual;
  
  List<ModeloResena> misResenasProfesional = [];
  List<ModeloResena> misResenasCliente = [];
  List<dynamic> misFavoritos = [];

  // ==========================================
  // 🥇 GETTERS MATEMÁTICOS (Baseline Perfecto)
  // ==========================================

  String getOficioPrincipal(bool viendoPro) {
    if (!viendoPro) return '';
    return perfilActual?.perfilProfesional?.tagsOficios.isNotEmpty == true 
        ? perfilActual!.perfilProfesional!.tagsOficios.first 
        : '';
  }
  
  int getReviewsCount(bool viendoPro) => viendoPro 
      ? (perfilActual?.perfilProfesional?.cantidadResenasProfesional ?? 0) 
      : (perfilActual?.cantidadResenasCliente ?? 0);

  double getRating(bool viendoPro) {
    if (getReviewsCount(viendoPro) == 0) return 5.0; // 🥇 Presunción de Inocencia
    return viendoPro 
        ? (perfilActual?.perfilProfesional?.ratingProfesional ?? 5.0) 
        : (perfilActual?.ratingCliente ?? 5.0);
  }

  double getScore(bool viendoPro) {
    if (getReviewsCount(viendoPro) == 0) return 100.0; // 🥇 Presunción de Inocencia
    return viendoPro 
        ? (perfilActual?.perfilProfesional?.scoreConfiabilidadPro ?? 100.0) 
        : (perfilActual?.scoreConfiabilidadCliente ?? 100.0);
  }

  int getTrabajosPublicados() => perfilActual?.trabajosPublicados ?? 0;
  
  int getTasaContratacion() {
    final int pubs = perfilActual?.trabajosPublicados ?? 0;
    final int cont = perfilActual?.trabajadoresContratados ?? 0;
    return pubs > 0 ? ((cont / pubs) * 100).toInt() : 100;
  }
  
  double getCancelacionesCliente() => perfilActual?.cancelacionesCliente ?? 0.0; 
  
  double getBuenTratoPersonal() {
    if (getReviewsCount(false) == 0) return 100.0;
    return perfilActual?.recomendacionTrabajadores ?? 100.0;
  }

  // ==========================================
  // 🧹 GETTERS DE FORMATO PARA MANTENER LA UI CIEGA
  // ==========================================

  String get formatearUbicacionCliente {
    if (perfilActual == null) return '';
    if (perfilActual!.localidad.isNotEmpty && perfilActual!.ciudad.isNotEmpty) {
      return '${perfilActual!.localidad}, ${perfilActual!.ciudad}';
    }
    return perfilActual!.ciudad.isNotEmpty ? perfilActual!.ciudad : '';
  }

  String get formatearMesAnio {
    final fecha = perfilActual?.miembroDesde;
    if (fecha == null) return '';
    const meses =['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  List<String> get habilidadesYCertificados {
    final pro = perfilActual?.perfilProfesional;
    return [...(pro?.habilidadesSecundarias ?? []), ...(pro?.certificaciones ?? [])];
  }

  List<String> get serviciosExtras {
    return perfilActual?.perfilProfesional?.habilidadesEspeciales ?? [];
  }

  // ==========================================
  // ⚙️ MÉTODOS DE LÓGICA Y ESTADO
  // ==========================================

  void _separarResenas(List<dynamic> resenasRaw) {
    misResenasProfesional.clear();
    misResenasCliente.clear();
    
    // 🧠 Lógica mejorada: Parseo directo sin cruzar IDs para evitar crasheos,
    // y normalización del rol para atrapar 'cliente', 'Cliente' o 'contratante'.
    for (var r in resenasRaw) {
      try {
        final resena = ModeloResena.fromJson(r);
        final rol = r['rol_evaluado']?.toString().toLowerCase().trim() ?? 'profesional'; 
        
        if (rol == 'cliente' || rol == 'contratante') {
          misResenasCliente.add(resena);
        } else {
          misResenasProfesional.add(resena);
        }
      } catch (e) {
        debugPrint('Error parseando reseña individual: $e');
      }
    }
    
    // Ordenamiento cronológico seguro para que la UI ciega siempre dibuje la más reciente primero
    misResenasProfesional.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    misResenasCliente.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  Future<void> cargarDatosPrivados(String miId) async {
    if (miId.isEmpty) return;
    try {
      final resResenas = await ServicioPerfilSupabase.obtenerResenasPrivadas(miId);
      _separarResenas(resResenas);

      misFavoritos = await ServicioPerfilSupabase.obtenerFavoritos(miId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando listas privadas: $e');
    }
  }

  Future<void> cargarPerfilPublico(String uid, String miId) async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await ServicioPerfilSupabase.obtenerPerfilConResenas(uid);
      if (data != null) {
        final perfilRaw = data['perfil'] as Map<String, dynamic>;
        perfilRaw['id'] = uid; 
        perfilActual = ModeloPerfil.fromJson(perfilRaw);
        
        _separarResenas(data['resenas'] as List<dynamic>);

        if (miId.isNotEmpty) {
          final favRes = await ServicioPerfilSupabase.obtenerFavoritos(miId);
          isFavorito = favRes.any((fav) => fav['profesional_id'] == uid);
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil público: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleDisponibilidad() {
    isDisponibleLocal = !isDisponibleLocal;
    notifyListeners();
  }

  // 🛡️ MUTACIONES BLINDADAS QUE LANZAN EXCEPCIONES PARA LA UI
  
  Future<bool> toggleFavoritoGlobal(String proId, String miId) async {
    if (miId.isEmpty || proId.isEmpty) throw Exception("ID inválido");
    try {
      isFavorito = await ServicioPerfilSupabase.toggleFavorito(miId, proId);
      notifyListeners();
      return isFavorito;
    } catch (e) {
      throw Exception('Error al actualizar favoritos: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> destacarResenaGlobal(String resenaId, String miId) async {
    if (miId.isEmpty) throw Exception("No autorizado");
    try {
      await ServicioPerfilSupabase.destacarResena(miId, resenaId);
      notifyListeners();
    } catch (e) {
      throw Exception('Error al destacar: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> enviarDenuncia(String proId, String miId, String motivo) async {
    if (motivo.trim().isEmpty) throw Exception('Debes escribir un motivo.');
    if (miId.isEmpty || proId.isEmpty) throw Exception("Error de validación de usuarios.");
    
    try {
      await ServicioPerfilSupabase.enviarDenuncia(miId, proId, motivo.trim());
    } catch (e) {
      throw Exception('Error al enviar reporte: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}