// lib/5_modulos/modulo_actividad_alertas/controladores/controlador_bandeja_notificaciones.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../3_modelos/modelo_notificacion.dart';
import '../../../3_modelos/modelo_jornada.dart';
import '../servicios/servicio_actividad_supabase.dart';

class ControladorBandejaNotificaciones extends ChangeNotifier {
  static final ControladorBandejaNotificaciones _instancia = ControladorBandejaNotificaciones._interno();
  factory ControladorBandejaNotificaciones() => _instancia;
  ControladorBandejaNotificaciones._interno();

  List<ModeloNotificacion> notificaciones = [];
  bool isLoading = true;

  int get totalNoLeidas => notificaciones.where((n) => !n.leida).length;

  static final List<VoidCallback> _onNotificationRoutedCallbacks = [];
  static void registrarCallbackAlEnrutar(VoidCallback callback) {
    _onNotificationRoutedCallbacks.add(callback);
  }

  void inicializar(BuildContext context) {
    cargarNotificaciones();
  }

  Future<void> cargarNotificaciones() async {
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      notificaciones = await ServicioActividadSupabase.obtenerNotificaciones(miId);
    } catch (_) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marcarTodasComoLeidas(BuildContext context) async {
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId == null) return;

    bool hayCambios = false;
    for (var i = 0; i < notificaciones.length; i++) {
      if (!notificaciones[i].leida) {
        notificaciones[i].leida = true;
        hayCambios = true;
      }
    }
    
    if (hayCambios) {
      notifyListeners();
      // Recargar agenda para que si una de las no leídas afectaba la agenda, se refresque
      for (var cb in _onNotificationRoutedCallbacks) {
        try { cb(); } catch (_) {}
      }
      try {
        await Supabase.instance.client
            .from('notificaciones')
            .update({'leida': true})
            .eq('usuario_id', miId)
            .eq('leida', false);
      } catch (_) {}
    }
  }

  Future<void> eliminarTodasLasNotificaciones(BuildContext context) async {
    final miId = Supabase.instance.client.auth.currentUser?.id;
    if (miId == null) return;

    notificaciones.clear();
    notifyListeners();

    try {
      await ServicioActividadSupabase.borrarTodasLasNotificaciones(miId);
    } catch (_) {}
  }

  Future<void> eliminarNotificacion(BuildContext context, String notifId) async {
    notificaciones.removeWhere((n) => n.id == notifId);
    notifyListeners();

    try {
      await ServicioActividadSupabase.borrarNotificacionUnica(notifId);
    } catch (_) {}
  }

  Future<void> eliminarMultiplesNotificaciones(BuildContext context, List<String> ids) async {
    if (ids.isEmpty) return;
    notificaciones.removeWhere((n) => ids.contains(n.id));
    notifyListeners();

    try {
      await ServicioActividadSupabase.borrarMultiplesNotificaciones(ids);
    } catch (_) {}
  }

  Future<void> marcarComoLeida(String notifId) async {
    final index = notificaciones.indexWhere((n) => n.id == notifId);
    if (index != -1 && !notificaciones[index].leida) {
      notificaciones[index].leida = true;
      notifyListeners();
      // Refrescar agenda silenciosamente
      for (var cb in _onNotificationRoutedCallbacks) {
        try { cb(); } catch (_) {}
      }
      try {
        await Supabase.instance.client
            .from('notificaciones')
            .update({'leida': true})
            .eq('id', notifId);
      } catch (e) {
        debugPrint('Error al marcar como leída: $e');
      }
    }
  }

  Future<void> enrutarDesdeNotificacion(BuildContext context, String? idTrabajo) async {
    if (idTrabajo == null || idTrabajo.isEmpty) return;

    // 1. Apagamos la burbuja roja
    final index = notificaciones.indexWhere((n) => n.trabajoId == idTrabajo);
    if (index != -1 && !notificaciones[index].leida) {
      notificaciones[index].leida = true;
      notifyListeners();
      try {
        await Supabase.instance.client.from('notificaciones').update({'leida': true}).eq('id', notificaciones[index].id);
      } catch (_) {}
    }

    // 2. Buscamos el Trabajo Completo en Supabase para obtener el jobData
    final respuesta = await Supabase.instance.client
        .from('trabajos')
        // 🛡️ REFACTOR: Se agregaron explícitamente rating_cliente y cantidad_resenas_cliente al alias de cliente.
        .select('*, pujas(*, perfiles!profesional_id(apodo, foto_url, rating, cantidad_resenas)), perfiles_solicitado:perfiles!profesional_solicitado_id(apodo, foto_url, rating, cantidad_resenas), cliente:perfiles!cliente_id(apodo, foto_url, rating, rating_cliente, cantidad_resenas, cantidad_resenas_cliente)')
        .eq('id', idTrabajo) 
        .maybeSingle();

    if (respuesta == null || !context.mounted) return;

    // 🛡️ REFACTOR: Inyección de Alias y métricas en el diccionario base para que los controladores operativos no crasheen.
    if (respuesta['cliente'] != null && respuesta['cliente'] is Map) {
      respuesta['perfiles'] = respuesta['cliente']; // Asegura compatibilidad con los Getters antiguos
      respuesta['rating_cliente'] = respuesta['cliente']['rating_cliente'];
      respuesta['cantidad_resenas_cliente'] = respuesta['cliente']['cantidad_resenas_cliente'];
    }

    final String dificultad = respuesta['dificultad']?.toString() ?? '1';

    // Disparar los callbacks registrados para que la data en background (agenda) se actualice
    // MIENTRAS el usuario está en la vista de detalle.
    for (var cb in _onNotificationRoutedCallbacks) {
      try {
        cb();
      } catch (_) {}
    }

    // 3. ENRUTAMIENTO ARQUITECTÓNICAMENTE CORRECTO MEDIANTE ENRUTADORES DESACOPLADOS (URL / Named Routing)
    if (dificultad == 'catalogo') {
      await Navigator.pushNamed(
        context,
        '/catalogo_ejecucion',
        arguments: respuesta,
      );
    } else if (dificultad == 'jornada') {
      final modelo = ModeloJornada.fromJson(respuesta);
      await Navigator.pushNamed(
        context,
        '/jornada_gestion',
        arguments: {
          'jobData': respuesta,
          'trabajoTipado': modelo,
        },
      );
    } else {
      await Navigator.pushNamed(
        context,
        '/negociacion_oficio',
        arguments: respuesta,
      );
    }
  }
}