// lib/5_modulos/modulo_servicios_catalogo/controladores/extension_catalogo_checkout.dart

part of 'controlador_catalogo_cliente.dart';


extension ExtensionCatalogoCheckout on ControladorCatalogoCliente {

  ModeloNivelServicio? get nivelActivo => servicioActivo?.niveles.firstWhere((n) => n.idNivel == idNivelSeleccionado);

  void abrirDetalleServicio(ModeloServicioCatalogo servicio) {
    servicioActivo = servicio;
    perfilVendedor = null;
    if (servicio.niveles.isNotEmpty) idNivelSeleccionado = servicio.niveles.first.idNivel;
    horaSeleccionada = null;
    notasController.clear();
    direccionController.clear();
    calleCtrl.clear();
    numeroCtrl.clear();
    localidadCtrl.clear();
    barrioCtrl.clear();
    paisCtrl.clear();
    provinciaSeleccionada = null;

    // 🆕 Limpieza previa de la reserva pendiente (evita colisión con el servicio anterior en RAM).
    limpiarReservaPendienteRAM();

    // 🆕 Consulta a la BD (única fuente de verdad) para saber si el cliente ya tiene
    // una reserva pendiente_pago para este servicio → banner anti-duplicado.
    final miId = GestorSesionGlobal().miIdUsuario;
    if (miId.isNotEmpty) {
      cargarReservaPendienteDesdeBD(servicio.id, miId);
    }

    ServicioCatalogoSupabase.obtenerPerfilVendedor(servicio.profesionalId).then((perfilCompleto) {
      perfilVendedor = perfilCompleto;
      actualizarUI();
    }).catchError((_) {});

    extrasDisponibles = servicio.extrasOpcionales.map((extra) => {
      'nombre': extra['nombre'],
      'precio': (extra['precio'] is num) ? (extra['precio'] as num).toDouble() : double.tryParse(extra['precio'].toString()) ?? 0.0,
      'seleccionado': false, 
    }).toList();

    faqsDisponibles = servicio.preguntasFrecuentes.map((faq) => {
      'pregunta': faq['pregunta']?.toString() ?? '',
      'respuesta': faq['respuesta']?.toString() ?? '',
    }).toList();

    try {
      final primerDiaLaboral = diasDisponibles.firstWhere((dia) => servicio.reglasDisponibilidad.diasLaborales.contains(dia.weekday));
      seleccionarFecha(primerDiaLaboral);
    } catch(_) { seleccionarFecha(diasDisponibles.first); }
  }

  void toggleExtra(int index) {
    extrasDisponibles[index]['seleccionado'] = !extrasDisponibles[index]['seleccionado'];
    actualizarUI();
  }

  double get totalCalculado {
    double total = nivelActivo?.precioFijo ?? 0.0;
    for (var extra in extrasDisponibles) {
      if (extra['seleccionado'] == true) total += extra['precio'];
    }
    return total;
  }

  String get fechaResumenFormateada {
    if (horaSeleccionada == null) return '';
    final fecha = horaSeleccionada!;
    final hoy = DateTime.now();
    final manana = hoy.add(const Duration(days: 1));
    final esHoy = fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
    final esManana = fecha.year == manana.year && fecha.month == manana.month && fecha.day == manana.day;
    
    final meses = ['', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    final mesStr = meses[fecha.month];
    
    if (esHoy) return 'Hoy, ${fecha.day} de $mesStr';
    if (esManana) return 'Mañana, ${fecha.day} de $mesStr';
    
    final dias = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${dias[fecha.weekday]}, ${fecha.day} de $mesStr';
  }
  
  String formatearFechaRelativa(DateTime fecha) {
    final hoy = DateTime.now();
    final manana = hoy.add(const Duration(days: 1));
    final esHoy = fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
    final esManana = fecha.year == manana.year && fecha.month == manana.month && fecha.day == manana.day;
    final meses = const ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final mes = meses[fecha.month];
    final diaStr = '${fecha.day} $mes';
    if (esHoy) return 'Hoy\n$diaStr';
    if (esManana) return 'Mañana\n$diaStr';
    final dias = const ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${dias[fecha.weekday]}\n$diaStr';
  }

  String get horaResumenFormateada {
    if (horaSeleccionada == null) return '';
    return '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')} hs';
  }

  void seleccionarNivel(String idNivel) { idNivelSeleccionado = idNivel; _recalcularHorasDisponibles(); }
  void seleccionarFecha(DateTime fecha) { fechaSeleccionada = fecha; horaSeleccionada = null; _recalcularHorasDisponibles(); }
  void seleccionarHora(DateTime hora) { horaSeleccionada = hora; actualizarUI(); }

  Future<void> _recalcularHorasDisponibles() async {
    if (servicioActivo == null) return;
    isLoadingHoras = true; horasHabilitadas = []; todasLasHoras = []; actualizarUI();
    List<BloqueOcupado> bloquesOcupados = [];
    try { bloquesOcupados = await ServicioCatalogoSupabase.obtenerBloquesOcupados(servicioActivo!.profesionalId, fechaSeleccionada); } catch (_) {}
    try {
      final nivelElegido = servicioActivo!.niveles.firstWhere((n) => n.idNivel == idNivelSeleccionado);
      
      todasLasHoras = ControladorDisponibilidadAgenda.generarTodosLosSlotsBase(
        fechaDeseada: fechaSeleccionada, 
        reglas: servicioActivo!.reglasDisponibilidad,
      );

      horasHabilitadas = ControladorDisponibilidadAgenda.generarSlotsDisponibles(
        fechaDeseada: fechaSeleccionada, fechaActual: DateTime.now(), reglas: servicioActivo!.reglasDisponibilidad,
        nivel: nivelElegido, anticipacionMinimaHoras: servicioActivo!.tiempoMinimoAnticipacionHoras,
        capacidadSimultanea: servicioActivo!.modalidad == 'en_local' ? servicioActivo!.capacidadSimultanea : 1,
        reservasYaConfirmadas: bloquesOcupados,
      );
    } catch (_) {} finally { isLoadingHoras = false; actualizarUI(); }
  }

  bool validarPasoConfiguracion(Function(String) onError) {
    if (horaSeleccionada == null) {
      onError('Por favor, seleccioná una fecha y hora.'); return false;
    }
    if (servicioActivo!.modalidad == 'a_domicilio') {
      if (calleCtrl.text.trim().isEmpty || numeroCtrl.text.trim().isEmpty || provinciaSeleccionada == null || localidadCtrl.text.trim().isEmpty) {
        onError('Para el servicio a domicilio, debes completar Calle, Número, Provincia y Localidad.'); return false;
      }
    }
    return true;
  }

  // 🚨 CONSOLIDACIÓN PREVIA (Inversión del Flujo - Bloqueo Optimista)
  // 🚨 CONSOLIDACIÓN PREVIA (Inversión del Flujo - Bloqueo Optimista)
  Future<bool> prepararReservaAtomica({required Function(String) onError}) async {
    if (GestorSesionGlobal().esInvitado) {
      GestorSesionGlobal.requerirAuth(() {});
      return false;
    }

    if (servicioActivo == null || horaSeleccionada == null) {
      onError('Faltan datos para procesar la reserva.');
      return false;
    }
    
    isProcesandoCheckout = true;
    actualizarUI();

    try {
      // Limpiar cualquier reserva fantasma previa de esta misma sesión antes de intentar otra vez
      if (idReservaTemporalActiva != null) {
        try {
          await ServicioCatalogoSupabase.liberarBloqueoTemporal(idReservaTemporalActiva!);
        } catch (_) {}
      }

      // 1. Generar el UUID temporal en memoria
      idReservaTemporalActiva = const Uuid().v4();

      final nivelElegido = servicioActivo!.niveles.firstWhere((n) => n.idNivel == idNivelSeleccionado);
      final horaFinCalculada = horaSeleccionada!.add(Duration(minutes: nivelElegido.duracionMinutos));
      final miId = GestorSesionGlobal().miIdUsuario;

      final String direccionFormateada = '${calleCtrl.text.trim()} ${numeroCtrl.text.trim()}, ${barrioCtrl.text.trim()}, ${localidadCtrl.text.trim()}, ${provinciaSeleccionada ?? ''}';

      final direccionFinal = servicioActivo!.modalidad == 'a_domicilio' 
          ? direccionFormateada 
          : servicioActivo!.direccionLocal;

      final extrasSeleccionados = extrasDisponibles.where((e) => e['seleccionado'] == true).toList();
      String textoExtras = '';
      if (extrasSeleccionados.isNotEmpty) {
        textoExtras = '\n\n✅ EXTRAS CONTRATADOS:\n' + extrasSeleccionados.map((e) => '• ${e['nombre']} (+\$${e['precio'].toInt()})').join('\n');
      }

      final notasFinales = notasController.text.trim() + textoExtras;
      final precioTotalFinal = totalCalculado; 

      // 2. Invocar servicio para lograr el Bloqueo Optimista (15 min)
      await ServicioCatalogoSupabase.iniciarCheckoutBloqueadoTemporal(
        reservaId: idReservaTemporalActiva!,
        servicio: servicioActivo!,
        nivelElegido: nivelElegido,
        fechaInicio: horaSeleccionada!,
        fechaFin: horaFinCalculada,
        clienteId: miId,
        direccionReal: direccionFinal,
        notasCliente: notasFinales,
        precioFinal: precioTotalFinal,
      );

      // 🆕 Cachear la reserva en RAM inmediatamente (banner instantáneo sin esperar al webhook).
      reservaPendienteServicioActivo = {
        'id': idReservaTemporalActiva,
        'fecha_hora': horaSeleccionada!.toIso8601String(),
        'hora_fin': horaFinCalculada.toIso8601String(),
        'fecha_vencimiento': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        'estado': 'pendiente_pago',
      };

      isProcesandoCheckout = false;
      actualizarUI();
      return true; // Luz verde para abrir el checkout

    } catch (e) {
      debugPrint('🚨 ERROR CRÍTICO AL INICIAR RESERVA ATÓMICA: $e');
      await abortarCheckoutTemporalYBorrar();
      isProcesandoCheckout = false;
      actualizarUI();
      onError(e.toString().replaceAll('Exception: ', ''));
      return false; // Chocó o falló
    }
  }

  // 🚨 PURGA DE MEMORIA (Si el pago falla o abandona, se ejecuta DELETE)
  Future<void> abortarCheckoutTemporalYBorrar() async {
    if (idReservaTemporalActiva != null) {
      try {
        await ServicioCatalogoSupabase.liberarBloqueoTemporal(idReservaTemporalActiva!);
      } catch (e) {
        debugPrint('Error silencioso al intentar limpiar la reserva fantasma: $e');
      }
      idReservaTemporalActiva = null;
    }
    // 🆕 Limpiar también la RAM de la reserva pendiente (la liberamos del banner).
    limpiarReservaPendienteRAM();
    isProcesandoCheckout = false;
    actualizarUI();
  }

  // 🆕 Verifica el estado REAL de la reserva temporal contra la BD.
  // 🛡️ REGLA: 'trabajos.estado' es la ÚNICA fuente de verdad del estado de la RESERVA.
  //          'wallet_transactions.estado' es solo info complementaria del PAGO (no decide el flujo).
  // Retorna un enum-like de string para que la UI decida qué panel mostrar:
  //   - 'confirmada'   → trabajos.estado mutó a 'asignado' (el webhook consolidó el pago).
  //   - 'pendiente'    → sigue como 'pendiente_pago' dentro del plazo de 15 min.
  //   - 'expirada'     → trabajos.estado = 'expirada' o se pasó del vencimiento.
  //   - 'desconocido'  → no se pudo determinar (error de red).
  Future<String> verificarEstadoReserva({String? idOpcional}) async {
    final idTarget = idOpcional ?? idReservaTemporalActiva;
    if (idTarget == null) return 'desconocido';

    final estado = await ServicioCatalogoSupabase.verificarEstadoReservaBD(idTarget);
    final String? estadoReserva = estado['estadoReserva']; // ← fuente de verdad
    final String? fechaVencIso = estado['fechaVencimiento'];

    // 1. Confirmada: el webhook mutó trabajos.estado a 'asignado'.
    if (estadoReserva == 'asignado' || estadoReserva == 'en_curso' || estadoReserva == 'finalizado') {
      return 'confirmada';
    }

    // 2. Expirada: trabajos.estado = 'expirada' (lo hace el cron) o se pasó del vencimiento.
    if (estadoReserva == 'expirada') return 'expirada';
    if (fechaVencIso != null) {
      final venc = DateTime.tryParse(fechaVencIso);
      if (venc != null && DateTime.now().isAfter(venc)) return 'expirada';
    }

    // 3. Pendiente: sigue como 'pendiente_pago' dentro del plazo.
    if (estadoReserva == 'pendiente_pago') return 'pendiente';

    // 4. Fallback.
    return 'desconocido';
  }


  void _generarDiasDisponibles() {
    final hoy = DateTime.now(); diasDisponibles = List.generate(14, (i) => hoy.add(Duration(days: i)));
  }
}