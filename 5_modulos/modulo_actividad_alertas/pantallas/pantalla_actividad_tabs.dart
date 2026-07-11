// lib/5_modulos/modulo_actividad_alertas/pantallas/pantalla_actividad_tabs.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_recibo_transaccion.dart';

import '../componentes/acordeon_categoria_historial.dart';
import '../componentes/calendario_mensual.dart';

import '../../../4_componentes_globales/contratos/fuente_de_actividad.dart';
import '../../../3_modelos/contratos/trabajo_contratable.dart';

class PantallaActividadTabs extends StatefulWidget {
  final bool isActive;
  const PantallaActividadTabs({Key? key, this.isActive = true}) : super(key: key);

  @override
  State<PantallaActividadTabs> createState() => _PantallaActividadTabsState();
}

class _PantallaActividadTabsState extends State<PantallaActividadTabs> {
  DateTime _fechaSeleccionada = DateTime.now();
  String? _acordeonAbierto;
  bool _diaFiltradoPorClick = false;

  @override
  void didUpdateWidget(PantallaActividadTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {
        _fechaSeleccionada = DateTime.now();
        _acordeonAbierto = null;
        _diaFiltradoPorClick = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refrescarTodo(); 
    });
  }

  Future<void> _refrescarTodo() async {
    await Future.wait(
      RegistroFuentesActividad.fuentes.map((fuente) => fuente.recargarDatosDesdeCero())
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _manejarFechaSeleccionada(DateTime d, bool esCliente) {
    setState(() {
      bool mismaFecha = _fechaSeleccionada.year == d.year && _fechaSeleccionada.month == d.month && _fechaSeleccionada.day == d.day;
      _fechaSeleccionada = d;
      _diaFiltradoPorClick = true;
      
      List<String> contenedoresConEventos = [];

      for (final fuente in RegistroFuentesActividad.fuentes) {
        final lista = esCliente ? fuente.obtenerActivosCliente() : fuente.obtenerActivosPro();
        bool tieneEvento = lista.any((t) {
          DateTime? dt = DateTime.tryParse(t.fechaHora);
          dt ??= DateTime.tryParse(t.fechaCreacion);
          return dt != null && dt.year == d.year && dt.month == d.month && dt.day == d.day;
        });
        if (tieneEvento) {
          contenedoresConEventos.add(esCliente ? fuente.tituloActivoCliente : fuente.tituloActivoPro);
        }
      }

      final List<TrabajoContratable> listFinalizados = [];
      final List<TrabajoContratable> listCancelados = [];
      for (final fuente in RegistroFuentesActividad.fuentes) {
        listFinalizados.addAll(esCliente ? fuente.obtenerFinalizadosCliente() : fuente.obtenerFinalizadosPro());
        listCancelados.addAll(esCliente ? fuente.obtenerCanceladosCliente() : fuente.obtenerCanceladosPro());
      }
      
      bool tieneFinalizado = listFinalizados.any((t) {
        DateTime? dt = DateTime.tryParse(t.fechaHora);
        dt ??= DateTime.tryParse(t.fechaCreacion);
        return dt != null && dt.year == d.year && dt.month == d.month && dt.day == d.day;
      });
      if (tieneFinalizado) {
        contenedoresConEventos.add('finalizados');
      }

      bool tieneCancelado = listCancelados.any((t) {
        DateTime? dt = DateTime.tryParse(t.fechaHora);
        dt ??= DateTime.tryParse(t.fechaCreacion);
        return dt != null && dt.year == d.year && dt.month == d.month && dt.day == d.day;
      });
      if (tieneCancelado) {
        contenedoresConEventos.add('cancelados');
      }

      if (contenedoresConEventos.isEmpty) {
        _acordeonAbierto = null;
        return;
      }

      if (mismaFecha && _acordeonAbierto != null && contenedoresConEventos.contains(_acordeonAbierto)) {
        int indexActual = contenedoresConEventos.indexOf(_acordeonAbierto!);
        int siguienteIndex = (indexActual + 1) % contenedoresConEventos.length;
        _acordeonAbierto = contenedoresConEventos[siguienteIndex];
      } else {
        _acordeonAbierto = contenedoresConEventos.first;
      }
    });
  }

  DateTime _obtenerFechaActividadMasReciente(TrabajoContratable trabajo) {
    DateTime fechaMaxima = DateTime.tryParse(trabajo.fechaCreacion) ?? DateTime(2000);
    for (var puja in trabajo.pujas) {
      DateTime fechaPuja = DateTime.tryParse(puja.fechaCreacion) ?? DateTime(2000);
      if (fechaPuja.isAfter(fechaMaxima)) {
        fechaMaxima = fechaPuja;
      }
    }
    return fechaMaxima;
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _ordenarPorFechaProgramadaAscendente(List<TrabajoContratable> lista) {
    lista.sort((a, b) {
      DateTime fechaA = DateTime.tryParse(a.fechaHora) ?? DateTime.tryParse(a.fechaCreacion) ?? DateTime(2000);
      DateTime fechaB = DateTime.tryParse(b.fechaHora) ?? DateTime.tryParse(b.fechaCreacion) ?? DateTime(2000);

      if (_diaFiltradoPorClick) {
        bool aEsSeleccionado = _esMismoDia(fechaA, _fechaSeleccionada);
        bool bEsSeleccionado = _esMismoDia(fechaB, _fechaSeleccionada);

        if (aEsSeleccionado && !bEsSeleccionado) {
          return -1;
        } else if (!aEsSeleccionado && bEsSeleccionado) {
          return 1;
        }
      }

      return fechaA.compareTo(fechaB);
    });
  }

  void _ordenarPorFechaProgramadaDescendente(List<TrabajoContratable> lista) {
    lista.sort((a, b) {
      DateTime fechaA = DateTime.tryParse(a.fechaHora) ?? DateTime.tryParse(a.fechaCreacion) ?? DateTime(2000);
      DateTime fechaB = DateTime.tryParse(b.fechaHora) ?? DateTime.tryParse(b.fechaCreacion) ?? DateTime(2000);

      if (_diaFiltradoPorClick) {
        bool aEsSeleccionado = _esMismoDia(fechaA, _fechaSeleccionada);
        bool bEsSeleccionado = _esMismoDia(fechaB, _fechaSeleccionada);

        if (aEsSeleccionado && !bEsSeleccionado) {
          return -1;
        } else if (!aEsSeleccionado && bEsSeleccionado) {
          return 1;
        }
      }

      return fechaB.compareTo(fechaA);
    });
  }

  void _abrirTrabajo(TrabajoContratable trabajo, bool esDueno, bool esHistorial, {bool esRecibo = false}) {
    final fuente = RegistroFuentesActividad.obtenerPorDominio(trabajo.dominio);
    if (fuente != null) {
      fuente.marcarItemComoVisto(trabajo, esDueno);
    }
    
    final estadoLimpio = trabajo.estado.toLowerCase().trim();
    final bool esEstadoFinalizado = estadoLimpio == 'finalizado' || estadoLimpio == 'finalizada';

    if (esRecibo || (esHistorial && esEstadoFinalizado)) {
      final gestor = context.read<GestorSesionGlobal>();
      final miNombre = gestor.perfilUsuario?.apodo ?? 'Usuario';
      final miAvatar = gestor.perfilUsuario?.fotoUrl ?? ''; 
      ModalReciboTransaccion.mostrar(context, trabajo, esDueno, miNombre, miAvatar);
      return;
    }

    if (fuente != null) {
      final pantalla = fuente.construirPantallaDetalle(trabajo, esHistorial);
      Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla)).then((_) => _refrescarTodo());
    }
  }

  Future<void> _eliminarTrabajoLocal(TrabajoContratable trabajo, bool esDueno) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: 'Eliminar registro',
        mensaje: '¿Estás seguro de que quieres eliminar o retirarte de "${trabajo.titulo}"?',
        textoBotonConfirmar: 'Eliminar',
        colorConfirmar: ColoresApp.errorRojo,
        onCancelar: () => Navigator.pop(ctx, false),
        onConfirmar: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirm == true) {
      final fuente = RegistroFuentesActividad.obtenerPorDominio(trabajo.dominio);
      if (fuente != null) {
        fuente.eliminarRegistro(trabajo, esDueno);
      }
    }
  }

  Map<DateTime, int> _obtenerFechasConEventos(List<TrabajoContratable> trabajos) {
    Map<DateTime, int> conteo = {};
    for (var t in trabajos) {
      DateTime? dt = DateTime.tryParse(t.fechaHora);
      dt ??= DateTime.tryParse(t.fechaCreacion); // Fallback por si fechaHora no es parseable o está vacía
      if (dt != null) {
        final dateKey = DateTime(dt.year, dt.month, dt.day);
        conteo[dateKey] = (conteo[dateKey] ?? 0) + 1;
      }
    }
    return conteo;
  }

  int _onCalcularAlertas(TrabajoContratable trabajo, bool esDueno) {
    final fuente = RegistroFuentesActividad.obtenerPorDominio(trabajo.dominio);
    if (fuente != null) {
      return fuente.calcularAlertasItem(trabajo, esDueno);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gestor = context.watch<GestorSesionGlobal>();
    final modoActual = gestor.modoActual;
    final esCliente = modoActual == ModoUsuario.cliente;
    
    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: tema.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(esCliente ? 'Contratos' : 'Mi agenda', style: EstilosTextoApp.h2.copyWith(color: tema.colorScheme.onSurface, fontSize: 18)),
      ),
      body: SafeArea(
        bottom: true,
        child: AnimatedBuilder(
          animation: Listenable.merge(RegistroFuentesActividad.fuentes),
          builder: (context, _) {
            return RefreshIndicator(
              color: ColoresApp.primarioVerde,
              backgroundColor: tema.colorScheme.surface,
              onRefresh: _refrescarTodo,
              child: esCliente ? _buildVistaCliente() : _buildVistaProfesional(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVistaCliente() {
    final List<TrabajoContratable> listFinalizados = [];
    final List<TrabajoContratable> listCancelados = [];
    final List<TrabajoContratable> listActivos = [];

    for (final fuente in RegistroFuentesActividad.fuentes) {
      listActivos.addAll(fuente.obtenerActivosCliente());
      listFinalizados.addAll(fuente.obtenerFinalizadosCliente());
      listCancelados.addAll(fuente.obtenerCanceladosCliente());
    }
    _ordenarPorFechaProgramadaDescendente(listFinalizados);
    _ordenarPorFechaProgramadaDescendente(listCancelados);

    final gestor = context.read<GestorSesionGlobal>();
    final miId = gestor.miIdUsuario;

    final fechasEventos = _obtenerFechasConEventos([...listActivos, ...listFinalizados, ...listCancelados]);

    final List<Widget> acordeonesActivos = RegistroFuentesActividad.fuentes.map((fuente) {
      final titulo = fuente.tituloActivoCliente;
      final trabajos = List<TrabajoContratable>.from(fuente.obtenerActivosCliente());
      _ordenarPorFechaProgramadaAscendente(trabajos);

      return AcordeonCategoriaHistorial(
        titulo: titulo,
        icono: fuente.iconoActivoCliente,
        trabajos: trabajos,
        colorTema: fuente.colorTemaCliente,
        esDueno: true,
        textoVacio: fuente.textoVacioCliente,
        miId: miId,
        isExpanded: _acordeonAbierto == titulo,
        onExpansionChanged: (exp) {
          setState(() {
            if (exp) _acordeonAbierto = titulo;
            else if (_acordeonAbierto == titulo) _acordeonAbierto = null;
          });
        },
        onTapTrabajo: (t) => _abrirTrabajo(t, true, false),
        onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, true),
        onCalcularAlertas: (t) => _onCalcularAlertas(t, true),
      );
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children:[
        CalendarioMensual(
          fechaSeleccionada: _fechaSeleccionada,
          fechasConEventos: fechasEventos,
          onFechaSeleccionada: (d) => _manejarFechaSeleccionada(d, true),
        ),
        const SizedBox(height: 16),
        ...acordeonesActivos,
        AcordeonCategoriaHistorial(
          titulo: 'Historial de trabajos finalizados', 
          icono: Icons.check_circle_outline_rounded,
          trabajos: listFinalizados,
          colorTema: ColoresApp.primarioVerde, esDueno: true, esHistorial: true, textoVacio: 'Aún no finalizaste contratos.',
          miId: miId,
          isExpanded: _acordeonAbierto == 'finalizados',
          onExpansionChanged: (exp) {
            setState(() {
              if (exp) _acordeonAbierto = 'finalizados';
              else if (_acordeonAbierto == 'finalizados') _acordeonAbierto = null;
            });
          },
          onTapTrabajo: (t) => _abrirTrabajo(t, true, true, esRecibo: true), onDeleteTrabajo: (t) {}, onCalcularAlertas: (_) => 0,
        ),
        AcordeonCategoriaHistorial(
          titulo: 'Trabajos cancelados', 
          icono: Icons.cancel_outlined,
          trabajos: listCancelados,
          colorTema: ColoresApp.errorRojo, esDueno: true, esHistorial: true, textoVacio: 'No tienes trabajos cancelados.',
          miId: miId,
          isExpanded: _acordeonAbierto == 'cancelados',
          onExpansionChanged: (exp) {
            setState(() {
              if (exp) _acordeonAbierto = 'cancelados';
              else if (_acordeonAbierto == 'cancelados') _acordeonAbierto = null;
            });
          },
          onTapTrabajo: (t) => _abrirTrabajo(t, true, true, esRecibo: false), onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, true), onCalcularAlertas: (_) => 0,
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildVistaProfesional() {
    final List<TrabajoContratable> listFinalizadosPro = [];
    final List<TrabajoContratable> listCanceladosPro = [];
    final List<TrabajoContratable> listActivosPro = [];

    for (final fuente in RegistroFuentesActividad.fuentes) {
      listActivosPro.addAll(fuente.obtenerActivosPro());
      listFinalizadosPro.addAll(fuente.obtenerFinalizadosPro());
      listCanceladosPro.addAll(fuente.obtenerCanceladosPro());
    }
    _ordenarPorFechaProgramadaDescendente(listFinalizadosPro);
    _ordenarPorFechaProgramadaDescendente(listCanceladosPro);

    final gestor = context.read<GestorSesionGlobal>();
    final miId = gestor.miIdUsuario;

    final fechasEventos = _obtenerFechasConEventos([...listActivosPro, ...listFinalizadosPro, ...listCanceladosPro]);

    final List<Widget> acordeonesActivosPro = RegistroFuentesActividad.fuentes.map((fuente) {
      final titulo = fuente.tituloActivoPro;
      final trabajos = List<TrabajoContratable>.from(fuente.obtenerActivosPro());
      _ordenarPorFechaProgramadaAscendente(trabajos);

      return AcordeonCategoriaHistorial(
        titulo: titulo,
        icono: fuente.iconoActivoPro,
        trabajos: trabajos,
        colorTema: fuente.colorTemaPro,
        esDueno: false,
        textoVacio: fuente.textoVacioPro,
        miId: miId,
        isExpanded: _acordeonAbierto == titulo,
        onExpansionChanged: (exp) {
          setState(() {
            if (exp) _acordeonAbierto = titulo;
            else if (_acordeonAbierto == titulo) _acordeonAbierto = null;
          });
        },
        onTapTrabajo: (t) => _abrirTrabajo(t, false, false),
        onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, false),
        onCalcularAlertas: (t) => _onCalcularAlertas(t, false),
      );
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children:[
        CalendarioMensual(
          fechaSeleccionada: _fechaSeleccionada,
          fechasConEventos: fechasEventos,
          colorAcento: ColoresApp.terciarioMorado,
          onFechaSeleccionada: (d) => _manejarFechaSeleccionada(d, false),
        ),
        const SizedBox(height: 16),
        ...acordeonesActivosPro,
        AcordeonCategoriaHistorial(
          titulo: 'Historial de trabajos finalizados', 
          icono: Icons.check_circle_outline_rounded,
          trabajos: listFinalizadosPro,
          colorTema: ColoresApp.primarioVerde, esDueno: false, esHistorial: true, textoVacio: 'Aún no completaste trabajos.',
          miId: miId,
          isExpanded: _acordeonAbierto == 'finalizados',
          onExpansionChanged: (exp) {
            setState(() {
              if (exp) _acordeonAbierto = 'finalizados';
              else if (_acordeonAbierto == 'finalizados') _acordeonAbierto = null;
            });
          },
          onTapTrabajo: (t) => _abrirTrabajo(t, false, true, esRecibo: true), onDeleteTrabajo: (t) {}, onCalcularAlertas: (_) => 0,
        ),
        AcordeonCategoriaHistorial(
          titulo: 'Trabajos cancelados', 
          icono: Icons.cancel_outlined,
          trabajos: listCanceladosPro,
          colorTema: ColoresApp.errorRojo, esDueno: false, esHistorial: true, textoVacio: 'No tienes trabajos cancelados o rechazados.',
          miId: miId,
          isExpanded: _acordeonAbierto == 'cancelados',
          onExpansionChanged: (exp) {
            setState(() {
              if (exp) _acordeonAbierto = 'cancelados';
              else if (_acordeonAbierto == 'cancelados') _acordeonAbierto = null;
            });
          },
          onTapTrabajo: (t) => _abrirTrabajo(t, false, true), onDeleteTrabajo: (t) => _eliminarTrabajoLocal(t, false), onCalcularAlertas: (_) => 0,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
