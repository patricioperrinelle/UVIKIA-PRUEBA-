// lib/5_modulos/modulo_servicios_catalogo/controladores/controlador_creador_servicio.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart';
import '../servicios/servicio_gestion_catalogo_supabase.dart';
import '../../../1_nucleo/servicio_supabase_base.dart'; 

class ControladorCreadorServicio extends ChangeNotifier {
  final PageController pageController = PageController();
  int pasoActual = 0;

  bool modoLectura = false; 
  String? idServicioEditando; 

  final int limiteFotos = 2; 

  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  
  // 🛡️ REGLA DATA INTEGRITY (Inputs Geográficos)
  final TextEditingController calleCtrl = TextEditingController();
  final TextEditingController numeroCtrl = TextEditingController();
  String? provinciaSeleccionada;
  final TextEditingController localidadCtrl = TextEditingController();
  final TextEditingController barrioCtrl = TextEditingController();
  final TextEditingController paisCtrl = TextEditingController(text: 'Argentina');
  final TextEditingController referenciaLocalCtrl = TextEditingController();

  final TextEditingController anticipacionController = TextEditingController(text: '2'); 
  final TextEditingController capacidadController = TextEditingController(text: '1');
  
  final TextEditingController zonaModalController = TextEditingController();
  final TextEditingController planDescModalController = TextEditingController();
  final TextEditingController planPrecioModalController = TextEditingController();
  final TextEditingController planNoCubreModalController = TextEditingController();
  final TextEditingController extraNombreModalController = TextEditingController();
  final TextEditingController extraPrecioModalController = TextEditingController();
  final TextEditingController faqPreguntaModalController = TextEditingController();
  final TextEditingController faqRespuestaModalController = TextEditingController();
  final TextEditingController tiempoAntesController = TextEditingController();
  final TextEditingController tiempoDespuesController = TextEditingController();
  final TextEditingController tiempoAntesHorasController = TextEditingController(text: '0');
  final TextEditingController tiempoAntesMinutosController = TextEditingController(text: '40');
  final TextEditingController tiempoDespuesHorasController = TextEditingController(text: '0');
  final TextEditingController tiempoDespuesMinutosController = TextEditingController(text: '40');
  final TextEditingController frecuenciaSlotsController = TextEditingController(text: '60');

  String planDuracionModalSeleccionada = '1 hora aprox.'; 
  String categoriaSeleccionada = ''; 
  String duracionEstimada = '1 hora aprox.'; 
  String modalidadSeleccionada = 'a_domicilio';
  
  List<String> contratosSoportados = ['unico'];
  bool usaProductosPremium = false;

  final List<String> opcionesEtiquetasConfianza = [
    'Trabajo garantizado', 'Precios justos', 'Atención rápida', 'Profesional verificado',
    'Respuesta inmediata', 'Servicio 24/7', 'Puntualidad asegurada', 'Materiales premium',
    'Técnicos certificados', '+10 años experiencia', 'Atención personalizada', 'Servicio a domicilio',
    'Reparación express', 'Alta satisfacción', 'Asistencia urgente', 'Pago seguro',
    'Clientes satisfechos', 'Soluciones efectivas', 'Disponibilidad inmediata', 'Mejor calidad-precio'
  ];
  
  List<String> etiquetasConfianzaSeleccionadas = [];
  
  final List<ModeloNivelServicio> _nivelesBase = [
    ModeloNivelServicio(idNivel: '1', nombre: 'Básico', descripcionCorta: '', precioFijo: 0, duracionMinutos: 60, duracionEstimada: '1 hora aprox.'),
    ModeloNivelServicio(idNivel: '2', nombre: 'Medio', descripcionCorta: '', precioFijo: 0, duracionMinutos: 90, duracionEstimada: '1 hora aprox.'),
    ModeloNivelServicio(idNivel: '3', nombre: 'Premium', descripcionCorta: '', precioFijo: 0, duracionMinutos: 120, duracionEstimada: '1 hora aprox.'),
  ];

  List<ModeloNivelServicio> nivelesAgregados = [];
  Set<String> nivelesSeleccionados = {};

  List<Map<String, dynamic>> extrasOpcionalesMock = [];
  List<Map<String, String>> faqMock = [];
  
  List<File> fotosSeleccionadas = [];
  List<String> fotosExistentesUrls = []; 
  List<String> urlsAEliminarDeR2 = [];

  bool isGuardando = false;

  List<int> diasLaboralesSeleccionados = [1, 2, 3, 4, 5];
  TimeOfDay horarioApertura = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay horarioCierre = const TimeOfDay(hour: 20, minute: 0);
  bool dobleJornada = false;
  TimeOfDay horarioApertura2 = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay horarioCierre2 = const TimeOfDay(hour: 20, minute: 0);
  
  // 🚨 NUEVOS ESTADOS: Tiempos Muertos y Horario Libre (o centrado)
  int tiempoMuertoAntesMinutos = 40;
  int tiempoMuertoDespuesMinutos = 40;
  int frecuenciaSlotsMinutos = 60;
  String unidadTiempoAntes = 'Minutos';
  String unidadTiempoDespues = 'Minutos';

  // 🚀 GETTERS GEOGRÁFICOS DINÁMICOS
  String get zonaConcatenada {
    if (provinciaSeleccionada == null) return 'Zona no configurada';
    return localidadCtrl.text.trim().isEmpty 
        ? 'Toda la provincia ($provinciaSeleccionada)' 
        : '${localidadCtrl.text.trim()}, $provinciaSeleccionada';
  }

  String get direccionConcatenada {
    return '${calleCtrl.text.trim()} ${numeroCtrl.text.trim()}, ${barrioCtrl.text.trim()}, ${localidadCtrl.text.trim()}, ${provinciaSeleccionada ?? ''}';
  }

  ControladorCreadorServicio() {
    descripcionController.addListener(() { notifyListeners(); });
    nivelesAgregados = List.from(_nivelesBase);
  }

  @override
  void dispose() {
    pageController.dispose();
    tituloController.dispose();
    descripcionController.dispose();
    
    calleCtrl.dispose();
    numeroCtrl.dispose();
    localidadCtrl.dispose();
    barrioCtrl.dispose();
    paisCtrl.dispose();
    referenciaLocalCtrl.dispose();

    anticipacionController.dispose();
    capacidadController.dispose();
    
    zonaModalController.dispose();
    planDescModalController.dispose();
    planPrecioModalController.dispose();
    planNoCubreModalController.dispose();
    extraNombreModalController.dispose();
    extraPrecioModalController.dispose();
    faqPreguntaModalController.dispose();
    faqRespuestaModalController.dispose();
    
    tiempoAntesController.dispose();
    tiempoDespuesController.dispose();
    tiempoAntesHorasController.dispose();
    tiempoAntesMinutosController.dispose();
    tiempoDespuesHorasController.dispose();
    tiempoDespuesMinutosController.dispose();
    frecuenciaSlotsController.dispose();
    super.dispose();
  }

  void prepararEditorZona() {}

  void guardarEditorZona() {
    notifyListeners(); 
  }

  void setProvincia(String prov) {
    provinciaSeleccionada = prov;
    notifyListeners();
  }

  void prepararEditorPlan(ModeloNivelServicio nivel) {
    planDescModalController.text = nivel.descripcionCorta;
    planPrecioModalController.text = nivel.precioFijo > 0 ? nivel.precioFijo.toInt().toString() : '';
    planDuracionModalSeleccionada = nivel.duracionEstimada; 
    planNoCubreModalController.text = nivel.loQueNoCubre ?? '';
  }

  void actualizarDuracionPlanModal(String nuevaDuracion) {
    planDuracionModalSeleccionada = nuevaDuracion;
    notifyListeners();
  }

  void guardarEditorPlan(String idNivel) {
    if (planPrecioModalController.text.isEmpty) return;
    guardarNivelDesdeUI(
      idNivelExistente: idNivel,
      descripcionCorta: planDescModalController.text.trim(),
      precioFijo: double.tryParse(planPrecioModalController.text) ?? 0,
      duracionEstimadaNueva: planDuracionModalSeleccionada, 
      loQueNoCubreNuevo: planNoCubreModalController.text.trim(),
    );
    if (!nivelesSeleccionados.contains(idNivel)) {
      nivelesSeleccionados.add(idNivel);
      notifyListeners();
    }
  }

  String obtenerHintParaPlan(String nombrePlan) {
    if (nombrePlan == 'Básico') return 'Ej: Solo exterior (Lavado simple)';
    if (nombrePlan == 'Medio') return 'Ej: Exterior + Interior';
    if (nombrePlan == 'Premium') return 'Ej: Exterior + Interior + Encerado VIP';
    return 'Ej: Beneficios incluidos...';
  }

  void prepararEditorExtra({int? index}) {
    if (index != null) {
      extraNombreModalController.text = extrasOpcionalesMock[index]['nombre'] ?? '';
      extraPrecioModalController.text = extrasOpcionalesMock[index]['precio'].toInt().toString();
    } else {
      extraNombreModalController.clear();
      extraPrecioModalController.clear();
    }
  }

  void guardarEditorExtra({int? index}) {
    if (extraNombreModalController.text.isEmpty || extraPrecioModalController.text.isEmpty) return;
    
    final nombre = extraNombreModalController.text.trim();
    final precio = double.tryParse(extraPrecioModalController.text) ?? 0;
    
    if (index != null) {
      editarExtra(index, nombre, precio);
    } else {
      agregarExtra(nombre, precio);
    }
  }

  void prepararEditorFaq({int? index}) {
    if (index != null) {
      faqPreguntaModalController.text = faqMock[index]['pregunta'] ?? '';
      faqRespuestaModalController.text = faqMock[index]['respuesta'] ?? '';
    } else {
      faqPreguntaModalController.clear();
      faqRespuestaModalController.clear();
    }
  }

  void guardarEditorFaq({int? index}) {
    if (faqPreguntaModalController.text.isEmpty || faqRespuestaModalController.text.isEmpty) return;
    
    final preg = faqPreguntaModalController.text.trim();
    final resp = faqRespuestaModalController.text.trim();
    
    if (index != null) {
      editarFaq(index, preg, resp);
    } else {
      agregarFaq(preg, resp);
    }
  }

  double get ratingProfesionalVistaPrevia {
    final p = GestorSesionGlobal().perfilUsuario;
    if (p == null) return 0.0;
    return p.perfilProfesional?.ratingProfesional ?? 0.0;
  }

  int get reviewsProfesionalVistaPrevia {
    final p = GestorSesionGlobal().perfilUsuario;
    if (p == null) return 0;
    return p.perfilProfesional?.cantidadResenasProfesional ?? 0;
  }

  void inicializarParaEdicion(ModeloServicioCatalogo servicio, bool lectura) {
    modoLectura = lectura;
    idServicioEditando = servicio.id;
    tituloController.text = servicio.titulo;
    descripcionController.text = servicio.descripcion;
    categoriaSeleccionada = servicio.categoria; 
    modalidadSeleccionada = servicio.modalidad;
    duracionEstimada = servicio.duracionEstimada;
    capacidadController.text = servicio.capacidadSimultanea.toString();
    anticipacionController.text = servicio.tiempoMinimoAnticipacionHoras.toString();
    usaProductosPremium = servicio.usaProductosPremium;

    // 🛡️ REGLA DATA INTEGRITY: Mapeo Inverso desde strings concatenados
    if (servicio.modalidad == 'en_local') {
      List<String> partes = servicio.direccionLocal.split(',');
      calleCtrl.text = partes.isNotEmpty ? partes[0].trim() : '';
      barrioCtrl.text = partes.length > 1 ? partes[1].trim() : '';
      localidadCtrl.text = partes.length > 2 ? partes[2].trim() : '';
      provinciaSeleccionada = partes.length > 3 ? partes[3].trim() : null;
      referenciaLocalCtrl.text = servicio.referenciaDireccionLocal;
    } else {
      String zonaDesc = servicio.zonasCoberturaDescripcion;
      if (zonaDesc.startsWith('Toda la provincia')) {
        localidadCtrl.text = '';
        final prov = zonaDesc.replaceAll('Toda la provincia (', '').replaceAll(')', '').trim();
        provinciaSeleccionada = prov.isNotEmpty ? prov : null;
      } else {
        List<String> partes = zonaDesc.split(',');
        localidadCtrl.text = partes.isNotEmpty ? partes[0].trim() : '';
        provinciaSeleccionada = partes.length > 1 ? partes[1].trim() : null;
      }
    }

    etiquetasConfianzaSeleccionadas = List.from(servicio.etiquetasConfianza);
    fotosExistentesUrls = List.from(servicio.imagenes);
    urlsAEliminarDeR2.clear(); 
    
    nivelesSeleccionados = servicio.niveles.map((e) => e.idNivel).toSet();
    nivelesAgregados = _nivelesBase.map((base) {
      final dataDeSupabase = servicio.niveles.where((n) => n.idNivel == base.idNivel).firstOrNull;
      return dataDeSupabase ?? base;
    }).toList();
    
    extrasOpcionalesMock = servicio.extrasOpcionales.map((e) => {
      'nombre': e['nombre'], 
      'precio': e['precio'], 
      'seleccionado': true
    }).toList();
    
    faqMock = servicio.preguntasFrecuentes.map((e) => {
      'pregunta': e['pregunta']?.toString() ?? '', 
      'respuesta': e['respuesta']?.toString() ?? ''
    }).toList();

    diasLaboralesSeleccionados = List.from(servicio.reglasDisponibilidad.diasLaborales);
    tiempoMuertoAntesMinutos = servicio.reglasDisponibilidad.tiempoMuertoAntesMinutos;
    tiempoMuertoDespuesMinutos = servicio.reglasDisponibilidad.tiempoMuertoDespuesMinutos;
    frecuenciaSlotsMinutos = servicio.reglasDisponibilidad.frecuenciaSlotsMinutos;
    frecuenciaSlotsController.text = frecuenciaSlotsMinutos.toString();
    
    final ap = servicio.reglasDisponibilidad.horarioInicio.split(':');
    if (ap.length >= 2) horarioApertura = TimeOfDay(hour: int.tryParse(ap[0]) ?? 8, minute: int.tryParse(ap[1]) ?? 0);
    
    final ci = servicio.reglasDisponibilidad.horarioFin.split(':');
    if (ci.length >= 2) horarioCierre = TimeOfDay(hour: int.tryParse(ci[0]) ?? 20, minute: int.tryParse(ci[1]) ?? 0);

    dobleJornada = servicio.reglasDisponibilidad.dobleJornada;
    final ap2 = servicio.reglasDisponibilidad.horarioInicio2.split(':');
    if (ap2.length >= 2) horarioApertura2 = TimeOfDay(hour: int.tryParse(ap2[0]) ?? 16, minute: int.tryParse(ap2[1]) ?? 0);
    final ci2 = servicio.reglasDisponibilidad.horarioFin2.split(':');
    if (ci2.length >= 2) horarioCierre2 = TimeOfDay(hour: int.tryParse(ci2[0]) ?? 20, minute: int.tryParse(ci2[1]) ?? 0);

    final antesHoras = tiempoMuertoAntesMinutos ~/ 60;
    final antesMinutos = tiempoMuertoAntesMinutos % 60;
    tiempoAntesHorasController.text = antesHoras.toString();
    tiempoAntesMinutosController.text = antesMinutos.toString();

    final despuesHoras = tiempoMuertoDespuesMinutos ~/ 60;
    final despuesMinutos = tiempoMuertoDespuesMinutos % 60;
    tiempoDespuesHorasController.text = despuesHoras.toString();
    tiempoDespuesMinutosController.text = despuesMinutos.toString();

    tiempoAntesController.text = _obtenerValorMostrar(tiempoMuertoAntesMinutos, true);
    tiempoDespuesController.text = _obtenerValorMostrar(tiempoMuertoDespuesMinutos, false);
  }

  String _obtenerValorMostrar(int minutos, bool esAntes) {
    if (minutos == 0) return '';
    if (minutos >= 60 && minutos % 60 == 0) {
      if (esAntes) unidadTiempoAntes = 'Horas'; else unidadTiempoDespues = 'Horas';
      return (minutos ~/ 60).toString();
    }
    if (esAntes) unidadTiempoAntes = 'Minutos'; else unidadTiempoDespues = 'Minutos';
    return minutos.toString();
  }

  void habilitarEdicion() {
    modoLectura = false;
    notifyListeners();
  }

  void toggleEtiquetaConfianza(String etiqueta) {
    if (etiquetasConfianzaSeleccionadas.contains(etiqueta)) {
      etiquetasConfianzaSeleccionadas.remove(etiqueta);
    } else {
      if (etiquetasConfianzaSeleccionadas.length < 3) {
        etiquetasConfianzaSeleccionadas.add(etiqueta);
      }
    }
    notifyListeners();
  }

  void validarPaso1(Function(String) onError) {
    if (tituloController.text.trim().isEmpty) {
      onError('Por favor, ingresá un título para tu servicio.'); return;
    }
    if (modalidadSeleccionada == 'a_domicilio') {
      if (provinciaSeleccionada == null || provinciaSeleccionada!.isEmpty) {
        onError('Debes seleccionar tu Provincia en el Paso 2 para configurar tu zona de cobertura a domicilio.'); return;
      }
    } else {
      if (provinciaSeleccionada == null || provinciaSeleccionada!.isEmpty || localidadCtrl.text.trim().isEmpty || calleCtrl.text.trim().isEmpty) {
        onError('Para un servicio en local, debes completar Provincia, Localidad y Calle en el Paso 2.'); return;
      }
    }
    if (categoriaSeleccionada.trim().isEmpty) {
      onError('Debes seleccionar una Categoría Global obligatoria.'); return;
    }
    if (etiquetasConfianzaSeleccionadas.length != 3) {
      onError('Debes elegir exactamente 3 Etiquetas de Confianza para avanzar.'); return;
    }
    siguientePaso();
  }

  void validarPaso2(Function(String) onError) {
    if (nivelesSeleccionados.isEmpty) {
      onError('Debes habilitar y configurar al menos 1 plan.'); return;
    }
    for (var idNivel in nivelesSeleccionados) {
      final plan = nivelesAgregados.firstWhere((n) => n.idNivel == idNivel);
      if (plan.precioFijo <= 0) {
        onError('El plan "${plan.nombre}" está habilitado pero su precio es \$0. Edítalo o deshabilítalo.'); return;
      }
    }
    siguientePaso();
  }

  void siguientePaso() {
    if (pasoActual < 2) {
      pasoActual++;
      pageController.animateToPage(pasoActual, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      notifyListeners();
    }
  }

  void pasoAnterior() {
    if (pasoActual > 0) {
      pasoActual--;
      pageController.animateToPage(pasoActual, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      notifyListeners();
    }
  }

  void irAlPaso(int pasoDestino) {
    if (pasoDestino >= 0 && pasoDestino <= 2) {
      pasoActual = pasoDestino;
      pageController.animateToPage(pasoActual, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      notifyListeners();
    }
  }

  void inyectarFormatoDescripcion(String prefijo, String sufijo) {
    final text = descripcionController.text;
    final selection = descripcionController.selection;

    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$prefijo$selectedText$sufijo');
      descripcionController.text = newText;
      descripcionController.selection = TextSelection.collapsed(offset: selection.start + prefijo.length + selectedText.length + sufijo.length);
    } else {
      final cursor = selection.isValid && selection.start >= 0 ? selection.start : text.length;
      final newText = text.replaceRange(cursor, cursor, '$prefijo$sufijo');
      descripcionController.text = newText;
      descripcionController.selection = TextSelection.collapsed(offset: cursor + prefijo.length);
    }
    notifyListeners();
  }

  Future<void> seleccionarFotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70); 
    if (images.isNotEmpty) {
      final espaciosDisponibles = limiteFotos - (fotosExistentesUrls.length + fotosSeleccionadas.length);
      final seleccion = images.take(espaciosDisponibles).map((e) => File(e.path));
      fotosSeleccionadas.addAll(seleccion);
      notifyListeners();
    }
  }
  
  void eliminarFotoLocal(int index) {
    fotosSeleccionadas.removeAt(index);
    notifyListeners();
  }

  void eliminarFotoExistente(int index) {
    final String urlObjetivo = fotosExistentesUrls[index];
    if (urlObjetivo.startsWith('http')) {
      urlsAEliminarDeR2.add(urlObjetivo);
    }
    fotosExistentesUrls.removeAt(index);
    notifyListeners();
  }

  void cambiarModalidad(String nuevaModalidad) {
    modalidadSeleccionada = nuevaModalidad; notifyListeners();
  }

  void cambiarCategoria(String nuevaCategoria) { 
    categoriaSeleccionada = nuevaCategoria;
    notifyListeners();
  }

  void cambiarDuracionEstimada(String nuevaDuracion) {
    duracionEstimada = nuevaDuracion; notifyListeners();
  }

  void togglePremium(bool valor) {
    usaProductosPremium = valor; notifyListeners();
  }

  void toggleDiaLaboral(int diaId) {
    if (diasLaboralesSeleccionados.contains(diaId)) {
      diasLaboralesSeleccionados.remove(diaId);
    } else {
      diasLaboralesSeleccionados.add(diaId);
    }
    diasLaboralesSeleccionados.sort();
    notifyListeners();
  }

  void actualizarHorarioApertura(TimeOfDay nuevaHora) {
    horarioApertura = nuevaHora; notifyListeners();
  }

  void actualizarHorarioCierre(TimeOfDay nuevaHora) {
    horarioCierre = nuevaHora; notifyListeners();
  }

  void toggleDobleJornada(bool valor) {
    dobleJornada = valor; notifyListeners();
  }

  void actualizarHorarioApertura2(TimeOfDay nuevaHora) {
    horarioApertura2 = nuevaHora; notifyListeners();
  }

  void actualizarHorarioCierre2(TimeOfDay nuevaHora) {
    horarioCierre2 = nuevaHora; notifyListeners();
  }
  
  void actualizarTiempoMuertoAntes([String? valorStr]) {
    int horas = int.tryParse(tiempoAntesHorasController.text) ?? 0;
    int minutos = int.tryParse(tiempoAntesMinutosController.text) ?? 0;
    tiempoMuertoAntesMinutos = (horas * 60) + minutos;
    notifyListeners();
  }

  void actualizarUnidadTiempoAntes(String unidad) {
    unidadTiempoAntes = unidad;
    actualizarTiempoMuertoAntes();
  }

  void actualizarTiempoMuertoDespues([String? valorStr]) {
    int horas = int.tryParse(tiempoDespuesHorasController.text) ?? 0;
    int minutos = int.tryParse(tiempoDespuesMinutosController.text) ?? 0;
    tiempoMuertoDespuesMinutos = (horas * 60) + minutos;
    notifyListeners();
  }

  void actualizarFrecuenciaSlots([String? valorStr]) {
    int mins = int.tryParse(frecuenciaSlotsController.text) ?? 60;
    if (mins < 30) mins = 30; // Minimum 30
    frecuenciaSlotsMinutos = mins;
    notifyListeners();
  }

  void actualizarUnidadTiempoDespues(String unidad) {
    unidadTiempoDespues = unidad;
    actualizarTiempoMuertoDespues();
  }
  
  void toggleSeleccionNivel(String idNivel) {
    if (nivelesSeleccionados.contains(idNivel)) {
      nivelesSeleccionados.remove(idNivel);
    } else {
      nivelesSeleccionados.add(idNivel);
    }
    notifyListeners();
  }

  void guardarNivelDesdeUI({
    required String idNivelExistente, 
    required String descripcionCorta, 
    required double precioFijo, 
    required String duracionEstimadaNueva,
    String? loQueNoCubreNuevo,
  }) {
    final idx = nivelesAgregados.indexWhere((n) => n.idNivel == idNivelExistente);
    if (idx != -1) {
      final anterior = nivelesAgregados[idx];
      nivelesAgregados[idx] = ModeloNivelServicio(
        idNivel: anterior.idNivel,
        nombre: anterior.nombre, 
        descripcionCorta: descripcionCorta,
        precioFijo: precioFijo,
        duracionMinutos: anterior.duracionMinutos, 
        duracionEstimada: duracionEstimadaNueva, 
        loQueNoCubre: loQueNoCubreNuevo,
      );
    }
    notifyListeners();
  }

  void agregarExtra(String nombre, double precio) {
    extrasOpcionalesMock.add({'nombre': nombre, 'precio': precio, 'seleccionado': true});
    notifyListeners();
  }

  void editarExtra(int index, String nombre, double precio) {
    extrasOpcionalesMock[index]['nombre'] = nombre;
    extrasOpcionalesMock[index]['precio'] = precio;
    notifyListeners();
  }

  void toggleExtra(int index, bool valor) {
    extrasOpcionalesMock[index]['seleccionado'] = valor;
    notifyListeners();
  }

  void agregarFaq(String pregunta, String respuesta) {
    faqMock.add({'pregunta': pregunta, 'respuesta': respuesta});
    notifyListeners();
  }

  void editarFaq(int index, String pregunta, String respuesta) {
    faqMock[index] = {'pregunta': pregunta, 'respuesta': respuesta};
    notifyListeners();
  }

  void eliminarFaq(int index) {
    faqMock.removeAt(index);
    notifyListeners();
  }

  String _formatearHoraParaBD(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }

  Future<void> ejecutarGuardado({required bool esBorrador, required VoidCallback onSuccess, required Function(String) onError}) async {
    isGuardando = true; notifyListeners();
    final error = await _procesarGuardadoBD(esBorrador: esBorrador);
    isGuardando = false; notifyListeners();

    if (error == null) {
      for (String urlBasura in urlsAEliminarDeR2) {
        await SupabaseService.deleteImage(urlBasura);
      }
      urlsAEliminarDeR2.clear();

      onSuccess(); 
    } else {
      onError(error);
    }
  }

  Future<String?> _procesarGuardadoBD({bool esBorrador = false}) async { 
    if (tituloController.text.trim().isEmpty) return 'Debes escribir al menos el Título para guardar tu servicio.';
    
    if (modalidadSeleccionada == 'a_domicilio') {
      if (provinciaSeleccionada == null || provinciaSeleccionada!.isEmpty) {
        return 'Debes seleccionar tu Provincia en el Paso 2 para configurar tu zona de cobertura a domicilio.';
      }
    } else {
      if (provinciaSeleccionada == null || provinciaSeleccionada!.isEmpty || localidadCtrl.text.trim().isEmpty || calleCtrl.text.trim().isEmpty) {
        return 'Para un servicio en local, debes completar Provincia, Localidad y Calle en el Paso 2.';
      }
    }

    if (!esBorrador && (nivelesSeleccionados.isEmpty || diasLaboralesSeleccionados.isEmpty || etiquetasConfianzaSeleccionadas.length != 3 || categoriaSeleccionada.trim().isEmpty)) {
      return 'Faltan campos obligatorios para poder publicarlo (Asegúrate de elegir Categoría y 3 etiquetas de confianza).';
    }
    
    final miId = GestorSesionGlobal().miIdUsuario;
    
    if (idServicioEditando == null || idServicioEditando!.isEmpty) {
      try {
        final cantidadActivos = await ServicioGestionCatalogoSupabase.contarServiciosTotalesActivos(miId);
        const int limiteServicios = 1; 
        if (cantidadActivos >= limiteServicios) return 'Límite alcanzado: Ya tienes un servicio publicado o en borradores. Para crear más deberás adquirir la versión Pro.';
      } catch (e) {
        return 'Error verificando tu límite de servicios: $e';
      }
    }

    try {
      final reglasReales = ModeloReglasDisponibilidad(
        diasLaborales: diasLaboralesSeleccionados, 
        horarioInicio: _formatearHoraParaBD(horarioApertura), 
        horarioFin: _formatearHoraParaBD(horarioCierre), 
        dobleJornada: dobleJornada,
        horarioInicio2: _formatearHoraParaBD(horarioApertura2),
        horarioFin2: _formatearHoraParaBD(horarioCierre2),
        bloqueosManuales: [],
        tiempoMuertoAntesMinutos: tiempoMuertoAntesMinutos,
        tiempoMuertoDespuesMinutos: tiempoMuertoDespuesMinutos,
        frecuenciaSlotsMinutos: frecuenciaSlotsMinutos,
      );
      
      final planesParaGuardar = nivelesAgregados.where((n) => nivelesSeleccionados.contains(n.idNivel)).toList();
      final extrasParaGuardar = extrasOpcionalesMock.where((e) => e['seleccionado'] == true).toList();
      
      final nuevoServicio = ModeloServicioCatalogo(
        id: idServicioEditando ?? '', 
        profesionalId: miId, 
        categoria: categoriaSeleccionada.trim(), 
        titulo: tituloController.text.trim(), 
        descripcion: descripcionController.text.trim(), 
        modalidad: modalidadSeleccionada,
        
        // 🛡️ REGLA APLICADA: Uso exclusivo de las columnas originales para evitar el error PGRST204
        direccionLocal: modalidadSeleccionada == 'en_local' ? direccionConcatenada : '',
        referenciaDireccionLocal: modalidadSeleccionada == 'en_local' ? referenciaLocalCtrl.text.trim() : '',
        zonasCoberturaDescripcion: modalidadSeleccionada == 'a_domicilio' ? zonaConcatenada : '',
        
        duracionEstimada: duracionEstimada, 
        capacidadSimultanea: modalidadSeleccionada == 'en_local' ? (int.tryParse(capacidadController.text) ?? 1) : 1,
        tiempoMinimoAnticipacionHoras: int.tryParse(anticipacionController.text) ?? 2, 
        tiposContratoSoportados: contratosSoportados,
        usaProductosPremium: usaProductosPremium, 
        profesionalVerificado: true, 
        etiquetasConfianza: etiquetasConfianzaSeleccionadas,
        niveles: planesParaGuardar,
        reglasDisponibilidad: reglasReales, 
        extrasOpcionales: extrasParaGuardar, 
        preguntasFrecuentes: faqMock,
      );
      
      await ServicioGestionCatalogoSupabase.guardarServicio(
        servicio: nuevoServicio, 
        nuevasFotosLocales: fotosSeleccionadas,
        fotosExistentesUrls: fotosExistentesUrls,
        esBorrador: esBorrador,
      );
      return null; 
    } catch (e) { 
      return 'Hubo un error guardando el servicio: $e'; 
    }
  }
}