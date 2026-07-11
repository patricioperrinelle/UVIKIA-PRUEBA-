// lib/1_nucleo/utilidades/mixin_paginacion_cursores.dart
import 'package:flutter/material.dart';

/// --------------------------------------------------------------------------
/// 1. CURSOR UNIVERSAL V5.2 (Sincronizado con SQL Alpha-Core)
/// --------------------------------------------------------------------------
class CursorTuplaV5 {
  bool esOficio;
  bool esCiudad;
  bool esLocalidad;
  double rank;
  String fecha;
  num score;
  num estrellas;
  String actividad;
  int rotacion;
  String id;

  CursorTuplaV5({
    this.esOficio = true,
    this.esCiudad = true,
    this.esLocalidad = true,
    this.rank = 0.0,
    this.fecha = '9999-12-31T23:59:59Z',
    this.score = 100.0,
    this.estrellas = 5.0,
    this.actividad = '9999-12-31T23:59:59Z',
    this.rotacion = 2147483647,
    this.id = '00000000-0000-0000-0000-000000000000',
  });

  void reiniciar() {
    esOficio = true;
    esCiudad = true;
    esLocalidad = true;
    rank = 0.0;
    fecha = '9999-12-31T23:59:59Z';
    score = 100.0;
    estrellas = 5.0;
    actividad = '9999-12-31T23:59:59Z';
    rotacion = 2147483647;
    id = '00000000-0000-0000-0000-000000000000';
  }
}

/// --------------------------------------------------------------------------
/// 2. MOTOR AUTÓNOMO DE PAGINACIÓN ALPHA (Protección Anti-Jank y SWR)
/// --------------------------------------------------------------------------
class MotorPaginacionAlpha<T> {
  final ScrollController scrollController = ScrollController();
  final CursorTuplaV5 cursor = CursorTuplaV5();
  
  List<T> elementos = [];
  bool isLoadingMore = false;
  bool hasReachedMax = false;
  
  final int limiteMaximoRam;
  final Future<void> Function() fetchSiguientePagina;
  final VoidCallback onNotificarUI;
  final bool Function() isDisposed;

  MotorPaginacionAlpha({
    required this.fetchSiguientePagina,
    required this.onNotificarUI,
    required this.isDisposed,
    this.limiteMaximoRam = 1000, // Bloqueo blando alto para no dañar UX
  }) {
    scrollController.addListener(_manejarScroll);
  }

  void _manejarScroll() {
    if (!scrollController.hasClients || isDisposed()) return;
    // Si faltan 300px para el final, pedimos más
    if (scrollController.position.pixels >= (scrollController.position.maxScrollExtent - 300)) {
      ejecutarFetch();
    }
  }

  Future<void> ejecutarFetch() async {
    if (isLoadingMore || hasReachedMax || isDisposed()) return;

    isLoadingMore = true;
    _notificarSeguro();

    await fetchSiguientePagina();

    isLoadingMore = false;
    _notificarSeguro();
  }

  /// 🛡️ INYECTOR SEGURO: Compatible con Caché SWR y Scroll Infinito
  void anexarPaginaSegura(List<T> nuevosElementos, {bool esRefresh = false}) {
    if (esRefresh) {
      // SWR REPLACE: Caché o Refresh Manual (Reemplaza y no duplica)
      elementos = List.from(nuevosElementos);
      hasReachedMax = nuevosElementos.isEmpty; 
      return;
    }

    if (nuevosElementos.isEmpty) {
      // Se acabó la base de datos
      hasReachedMax = true;
      return;
    }
    
    // PAGINATION APPEND: Anexa abajo
    elementos.addAll(nuevosElementos);

    // ESCUDO OOM (Out Of Memory) BLANDO
    // Si pasamos de 1000 elementos, paramos de pedir en vez de borrar 
    // y destruir la posición de lectura del usuario (Scroll Jump).
    if (elementos.length >= limiteMaximoRam) {
      hasReachedMax = true;
    }
  }

  void reiniciarMotor() {
    hasReachedMax = false;
    isLoadingMore = false;
    cursor.reiniciar();
    if (scrollController.hasClients && scrollController.position.pixels > 0) {
      scrollController.jumpTo(0);
    }
  }

  void _notificarSeguro() {
    if (!isDisposed()) {
      Future.microtask(() => onNotificarUI());
    }
  }

  void destruir() {
    scrollController.removeListener(_manejarScroll);
    scrollController.dispose();
  }
}

/// --------------------------------------------------------------------------
/// 3. EL MIXIN PARA CONTROLADORES
/// --------------------------------------------------------------------------
mixin MixinPaginacionCursores on ChangeNotifier {
  bool _isDisposedLocal = false;
  final List<MotorPaginacionAlpha> _motoresActivos = [];

  MotorPaginacionAlpha<T> crearMotorPaginacion<T>({
    required Future<void> Function() fetchSiguientePagina,
    int limiteMaximoRam = 1000,
  }) {
    final motor = MotorPaginacionAlpha<T>(
      fetchSiguientePagina: fetchSiguientePagina,
      onNotificarUI: notifyListeners,
      isDisposed: () => _isDisposedLocal,
      limiteMaximoRam: limiteMaximoRam,
    );
    _motoresActivos.add(motor);
    return motor;
  }

  @override
  void dispose() {
    _isDisposedLocal = true;
    for (var motor in _motoresActivos) {
      motor.destruir();
    }
    _motoresActivos.clear();
    super.dispose();
  }
}