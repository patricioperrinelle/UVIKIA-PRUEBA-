// lib/5_modulos/modulo_actividad_alertas/pantallas/pantalla_notificaciones_bandeja.dart

import 'package:flutter/material.dart';

import '../../../2_tema/estilos_texto.dart';
import '../../../3_modelos/modelo_notificacion.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';

import '../controladores/controlador_bandeja_notificaciones.dart';
import '../componentes/item_notificacion_alerta.dart';

class PantallaNotificacionesBandeja extends StatefulWidget {
  const PantallaNotificacionesBandeja({Key? key}) : super(key: key);

  @override
  State<PantallaNotificacionesBandeja> createState() => _PantallaNotificacionesBandejaState();
}

class _PantallaNotificacionesBandejaState extends State<PantallaNotificacionesBandeja> {
  final ControladorBandejaNotificaciones _controlador = ControladorBandejaNotificaciones();

  bool _modoSeleccion = false;
  final Set<String> _notificacionesSeleccionadas = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controlador.inicializar(context);
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _toggleSeleccion(String id) {
    setState(() {
      if (_notificacionesSeleccionadas.contains(id)) {
        _notificacionesSeleccionadas.remove(id);
        if (_notificacionesSeleccionadas.isEmpty) {
          _modoSeleccion = false;
        }
      } else {
        _notificacionesSeleccionadas.add(id);
      }
    });
  }

  void _desactivarModoSeleccion() {
    setState(() {
      _modoSeleccion = false;
      _notificacionesSeleccionadas.clear();
    });
  }

  void _toggleSeleccionarTodas() {
    final list = _controlador.notificaciones;
    setState(() {
      if (_notificacionesSeleccionadas.length == list.length) {
        _notificacionesSeleccionadas.clear();
        _modoSeleccion = false;
      } else {
        _notificacionesSeleccionadas.clear();
        _notificacionesSeleccionadas.addAll(list.map((n) => n.id));
        _modoSeleccion = true;
      }
    });
  }

  Future<void> _eliminarSeleccionadas(BuildContext context) async {
    if (_notificacionesSeleccionadas.isEmpty) return;

    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: 'Eliminar Seleccionadas',
        mensaje: '¿Estás seguro de que quieres eliminar las ${_notificacionesSeleccionadas.length} notificaciones seleccionadas de tu celular y de la base de datos?',
        textoBotonConfirmar: 'Eliminar',
        onCancelar: () => Navigator.pop(ctx, false),
        onConfirmar: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirm == true && mounted) {
      final listIds = _notificacionesSeleccionadas.toList();
      _desactivarModoSeleccion();
      await _controlador.eliminarMultiplesNotificaciones(context, listIds);
    }
  }

  // Agrupa las notificaciones por Hoy, Ayer y Anteriores de forma dinámica
  Map<String, List<ModeloNotificacion>> _agruparNotificaciones(List<ModeloNotificacion> lista) {
    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioAyer = inicioHoy.subtract(const Duration(days: 1));

    List<ModeloNotificacion> delHoy = [];
    List<ModeloNotificacion> delAyer = [];
    List<ModeloNotificacion> anteriores = [];

    for (var n in lista) {
      if (n.fecha.isEmpty) {
        anteriores.add(n);
        continue;
      }
      try {
        final fechaN = DateTime.parse(n.fecha).toLocal();
        if (fechaN.isAfter(inicioHoy)) {
          delHoy.add(n);
        } else if (fechaN.isAfter(inicioAyer)) {
          delAyer.add(n);
        } else {
          anteriores.add(n);
        }
      } catch (_) {
        anteriores.add(n);
      }
    }

    return {
      'Hoy': delHoy,
      'Ayer': delAyer,
      'Anteriores': anteriores,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Fondo súper limpio (blanco roto / gris muy suave en claro, oscuro profundo en oscuro)
    final Color scaffoldBgColor = esOscuro ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, child) {
        final notifs = _controlador.notificaciones;
        final grupos = _agruparNotificaciones(notifs);

        return Scaffold(
          backgroundColor: scaffoldBgColor,
          appBar: AppBar(
            backgroundColor: _modoSeleccion 
                ? (esOscuro ? const Color(0xFF1A1A24) : const Color(0xFFF3E8FF)) 
                : scaffoldBgColor,
            elevation: 0,
            centerTitle: true,
            leading: _modoSeleccion
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8B5CF6)),
                    onPressed: _desactivarModoSeleccion,
                  )
                : Navigator.canPop(context)
                    ? IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: esOscuro ? Colors.white : Colors.black87, size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
            title: _modoSeleccion
                ? Text(
                    '${_notificacionesSeleccionadas.length} seleccionadas',
                    style: EstilosTextoApp.h3.copyWith(
                      color: const Color(0xFF8B5CF6),
                      fontSize: 18,
                    ),
                  )
                : Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: esOscuro ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Inter',
                    ),
                  ),
            actions: [
              if (notifs.isNotEmpty) ...[
                if (_modoSeleccion) ...[
                  IconButton(
                    icon: Icon(
                      _notificacionesSeleccionadas.length == notifs.length 
                          ? Icons.deselect_rounded 
                          : Icons.select_all_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                    tooltip: 'Seleccionar todas',
                    onPressed: _toggleSeleccionarTodas,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                    tooltip: 'Eliminar seleccionadas',
                    onPressed: () => _eliminarSeleccionadas(context),
                  ),
                ] else ...[
                  // Botón de selección múltiple (activa el modo)
                  IconButton(
                    icon: Icon(Icons.checklist_rounded, color: esOscuro ? Colors.white70 : Colors.black87),
                    tooltip: 'Selección múltiple',
                    onPressed: () {
                      setState(() {
                        _modoSeleccion = true;
                      });
                    },
                  ),
                  // Eliminar todas las notificaciones
                  IconButton(
                    icon: Icon(Icons.delete_sweep_rounded, color: esOscuro ? Colors.white70 : Colors.black87),
                    tooltip: 'Eliminar todas',
                    onPressed: () async {
                      final bool? confirm = await showDialog(
                        context: context,
                        builder: (ctx) => DialogoConfirmacionEstandar(
                          titulo: 'Eliminar Notificaciones',
                          mensaje: '¿Estás seguro de que quieres eliminar TODAS tus notificaciones de la base de datos?',
                          textoBotonConfirmar: 'Eliminar Todas',
                          onCancelar: () => Navigator.pop(ctx, false),
                          onConfirmar: () => Navigator.pop(ctx, true),
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        _controlador.eliminarTodasLasNotificaciones(context);
                      }
                    },
                  )
                ]
              ]
            ],
          ),
          body: SafeArea(
            bottom: true,
            child: _controlador.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
              : notifs.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined, 
                          size: 64, 
                          color: esOscuro ? Colors.white24 : Colors.black26
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'No tienes nuevas alertas', 
                          style: TextStyle(
                            color: esOscuro ? Colors.white38 : Colors.black38, 
                            fontSize: 16,
                            fontFamily: 'Inter'
                          )
                        ),
                      ],
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // SECCIÓN: HOY
                      if (grupos['Hoy']!.isNotEmpty) ...[
                        _buildEncabezadoSeccion('Hoy', esOscuro),
                        ...grupos['Hoy']!.map((n) => _buildItemNotificacion(n)),
                      ],

                      // SECCIÓN: AYER
                      if (grupos['Ayer']!.isNotEmpty) ...[
                        _buildEncabezadoSeccion('Ayer', esOscuro),
                        ...grupos['Ayer']!.map((n) => _buildItemNotificacion(n)),
                      ],

                      // SECCIÓN: ANTERIORES
                      if (grupos['Anteriores']!.isNotEmpty) ...[
                        _buildEncabezadoSeccion('Anteriores', esOscuro),
                        ...grupos['Anteriores']!.map((n) => _buildItemNotificacion(n)),
                      ],
                      
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        );
      }
    );
  }

  Widget _buildEncabezadoSeccion(String titulo, bool esOscuro) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 18.0, bottom: 8.0),
      child: Text(
        titulo,
        style: TextStyle(
          color: esOscuro ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
          fontFamily: 'Inter',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildItemNotificacion(ModeloNotificacion n) {
    final esSeleccionada = _notificacionesSeleccionadas.contains(n.id);
    return ItemNotificacionAlerta(
      notificacion: n,
      modoSeleccion: _modoSeleccion,
      esSeleccionado: esSeleccionada,
      onToggleSeleccion: () => _toggleSeleccion(n.id),
      onTap: () async {
        await _controlador.marcarComoLeida(n.id);
        if (n.trabajoId != null && n.trabajoId!.isNotEmpty) {
          await _controlador.enrutarDesdeNotificacion(context, n.trabajoId);
        }
      },
      onLongPress: () {
        if (!_modoSeleccion) {
          setState(() {
            _modoSeleccion = true;
            _notificacionesSeleccionadas.add(n.id);
          });
        }
      },
    );
  }
}
