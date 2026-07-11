// lib/5_modulos/modulo_servicios_catalogo/controladores/controlador_mis_servicios_pro.dart

import 'package:flutter/material.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../servicios/servicio_gestion_catalogo_supabase.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/servicio_supabase_base.dart'; // 🚨 IMPORTAMOS EL MOTOR R2

class ControladorMisServiciosPro extends ChangeNotifier {
  List<ModeloServicioCatalogo> misServicios = List.empty(growable: true);
  bool isCargando = true;
  String? errorCarga; 

  List<ModeloServicioCatalogo> get serviciosPublicados => misServicios.where((s) => s.estado == 'publicado').toList();
  List<ModeloServicioCatalogo> get serviciosBorradores => misServicios.where((s) => s.estado == 'borrador').toList();
  List<ModeloServicioCatalogo> get serviciosPausados => misServicios.where((s) => s.estado == 'pausado').toList();

  ControladorMisServiciosPro() {
    cargarMisServicios();
  }

  Future<void> cargarMisServicios() async {
    isCargando = true;
    errorCarga = null;
    notifyListeners();
    
    try {
      final miId = GestorSesionGlobal().miIdUsuario;
      misServicios = await ServicioGestionCatalogoSupabase.obtenerMisServicios(miId);
    } catch (e) {
      errorCarga = e.toString(); 
      debugPrint('Error cargando mis servicios: $e');
    } finally {
      isCargando = false;
      notifyListeners();
    }
  }

  Future<void> eliminarServicio(String id) async {
    try {
      // 🚨 1. Rescatamos el servicio de la memoria antes de borrarlo para extraer sus fotos
      final servicioObjetivo = misServicios.firstWhere((s) => s.id == id);
      
      // 2. Ejecutamos el borrado lógico en la Base de Datos (Soft Delete)
      await ServicioGestionCatalogoSupabase.eliminarServicio(id);
      
      // 3. Lo quitamos de la vista (Optimistic UI)
      misServicios.removeWhere((s) => s.id == id);
      notifyListeners();

      // 🚨 4. Destruimos las fotos huérfanas físicamente de R2 (Hard Delete)
      for (String imageUrl in servicioObjetivo.imagenes) {
        if (imageUrl.startsWith('http')) {
          await SupabaseService.deleteImage(imageUrl);
        }
      }
      
    } catch (e) {
      debugPrint('Error eliminando servicio: $e');
    }
  }

  Future<void> pausarServicio(String id) async {
    try {
      await ServicioGestionCatalogoSupabase.pausarServicio(id);
      
      final index = misServicios.indexWhere((s) => s.id == id);
      if (index != -1) {
        // Clonamos y modificamos para refrescar la UI
        final s = misServicios[index];
        final nuevoJson = s.toJson();
        nuevoJson['estado'] = 'pausado';
        nuevoJson['profesional_nombre'] = s.profesionalNombre;
        nuevoJson['profesional_avatar'] = s.profesionalAvatar;
        nuevoJson['profesional_rating'] = s.profesionalRating;
        nuevoJson['profesional_reviews'] = s.profesionalReviews;
        misServicios[index] = ModeloServicioCatalogo.fromJson(nuevoJson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error pausando servicio: $e');
    }
  }

  Future<void> reanudarServicio(String id) async {
    try {
      await ServicioGestionCatalogoSupabase.reanudarServicio(id);
      
      final index = misServicios.indexWhere((s) => s.id == id);
      if (index != -1) {
        final s = misServicios[index];
        final nuevoJson = s.toJson();
        nuevoJson['estado'] = 'publicado';
        nuevoJson['profesional_nombre'] = s.profesionalNombre;
        nuevoJson['profesional_avatar'] = s.profesionalAvatar;
        nuevoJson['profesional_rating'] = s.profesionalRating;
        nuevoJson['profesional_reviews'] = s.profesionalReviews;
        misServicios[index] = ModeloServicioCatalogo.fromJson(nuevoJson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reanudando servicio: $e');
    }
  }
}