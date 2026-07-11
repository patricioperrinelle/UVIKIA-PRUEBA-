// lib/3_modelos/modelo_servicio_catalogo.dart
import 'dart:convert'; 

class ModeloServicioCatalogo {
  final String id;
  final String profesionalId;
  final String categoria; 
  final String titulo;
  final String descripcion;
  final List<String> imagenes;
  
  final String modalidad; 
  final int radioCoberturaKm; 
  final String zonasCoberturaDescripcion;
  final String direccionLocal;
  final String referenciaDireccionLocal;
  final String duracionEstimada; 
  
  final int capacidadSimultanea;
  final int tiempoMinimoAnticipacionHoras;
  final List<String> tiposContratoSoportados; 
  
  final bool usaProductosPremium;
  final bool profesionalVerificado;

  final List<String> etiquetasConfianza;

  final List<ModeloNivelServicio> niveles;
  final ModeloReglasDisponibilidad reglasDisponibilidad;
  
  final List<Map<String, dynamic>> extrasOpcionales; 
  final List<Map<String, dynamic>> preguntasFrecuentes; 

  final String profesionalNombre;
  final String profesionalAvatar;
  final double profesionalRating;
  final int profesionalReviews;
  
  final String estado;
  final List<Map<String, dynamic>> adicionalesPresupuesto;

  ModeloServicioCatalogo({
    required this.id,
    required this.profesionalId,
    this.categoria = 'Otros', 
    required this.titulo,
    required this.descripcion,
    this.imagenes = const [],
    this.modalidad = 'a_domicilio',
    this.radioCoberturaKm = 0,
    this.zonasCoberturaDescripcion = '',
    this.direccionLocal = '',
    this.referenciaDireccionLocal = '',
    this.duracionEstimada = '1 hora aprox.',
    this.capacidadSimultanea = 1,
    this.tiempoMinimoAnticipacionHoras = 2,
    this.tiposContratoSoportados = const ['unico'],
    this.usaProductosPremium = false,
    this.profesionalVerificado = false,
    this.etiquetasConfianza = const [], 
    this.niveles = const [],
    required this.reglasDisponibilidad,
    this.extrasOpcionales = const [],
    this.preguntasFrecuentes = const [],
    this.profesionalNombre = '',
    this.profesionalAvatar = '',
    this.profesionalRating = 0.0,
    this.profesionalReviews = 0,
    this.estado = 'publicado',
    this.adicionalesPresupuesto = const [],
  });

  String get descripcionCortaFeed {
    if (descripcion.isEmpty) return 'Sin descripción detallada.';
    return descripcion.replaceAll('\n', ' ').trim();
  }

  String get diasLaboralesResumen {
    final dias = reglasDisponibilidad.diasLaborales;
    if (dias.isEmpty) return 'A convenir';
    
    final sortedDias = List<int>.from(dias)..sort();
    const iniciales = {1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'};
    
    final diasLetras = sortedDias.map((d) => iniciales[d] ?? '').toList();
    return diasLetras.join(', ');
  }

  String get horarioLaboralResumen {
    return 'De ${reglasDisponibilidad.horarioInicio} a ${reglasDisponibilidad.horarioFin} hs';
  }

  double get precioMinimo {
    if (niveles.isEmpty) return 0.0;
    return niveles.map((e) => e.precioFijo).reduce((a, b) => a < b ? a : b);
  }

  String get duracionAproxBase {
    final planesMostrar = niveles.take(3).toList();
    return planesMostrar.isNotEmpty ? planesMostrar.first.duracionEstimada : 'A convenir';
  }

  // 🛡️ REGLA DATA INTEGRITY (Limpieza del Hardcodeo)
  String get ubicacionBaseCortada {
    if (modalidad == 'a_domicilio') {
      return zonasCoberturaDescripcion.isNotEmpty 
          ? zonasCoberturaDescripcion 
          : 'A domicilio';
    } else {
      if (direccionLocal.isNotEmpty) {
        return direccionLocal.split(',').first.trim();
      }
      return 'En local profesional';
    }
  }

  String get payloadCompartir {
    return '✨ ¡Mirá este servicio!\n\n'
        '📌 $titulo\n'
        '👤 Por: ${profesionalNombre.isEmpty ? "Profesional Independiente" : profesionalNombre}\n'
        '💵 Precio base: \$${precioMinimo.toInt()}\n'
        '📍 Ubicación: $ubicacionBaseCortada\n\n'
        '📲 Búscalo en la app para contratarlo.';
  }

  factory ModeloServicioCatalogo.fromJson(Map<String, dynamic> json) {
    List<String> parsearImagenes = [];
    if (json['imagenes'] is List) {
      parsearImagenes = List<String>.from(json['imagenes'].map((e) => e.toString()));
    }

    List<String> parsearContratos = ['unico'];
    if (json['tipos_contrato_soportados'] is List) {
      parsearContratos = List<String>.from(json['tipos_contrato_soportados'].map((e) => e.toString()));
    }

    List<String> parsearEtiquetas = [];
    if (json['etiquetas_confianza'] is List) {
      parsearEtiquetas = List<String>.from(json['etiquetas_confianza'].map((e) => e.toString()));
    }

    dynamic nivelesData = json['niveles'];
    if (nivelesData is String) { try { nivelesData = jsonDecode(nivelesData); } catch(_) { nivelesData = []; } }
    List<ModeloNivelServicio> parsearNiveles = [];
    if (nivelesData is List) { parsearNiveles = nivelesData.map((e) => ModeloNivelServicio.fromJson(e)).toList(); }

    dynamic reglasData = json['reglas_disponibilidad'];
    if (reglasData is String) { try { reglasData = jsonDecode(reglasData); } catch(_) { reglasData = null; } }

    dynamic extrasData = json['extras_opcionales'];
    if (extrasData is String) { try { extrasData = jsonDecode(extrasData); } catch(_) { extrasData = []; } }
    List<Map<String, dynamic>> parsearExtras = extrasData is List ? List<Map<String, dynamic>>.from(extrasData) : [];

    dynamic faqData = json['preguntas_frecuentes'];
    if (faqData is String) { try { faqData = jsonDecode(faqData); } catch(_) { faqData = []; } }
    List<Map<String, dynamic>> parsearFaq = faqData is List ? List<Map<String, dynamic>>.from(faqData) : [];

    dynamic adicData = json['adicionales_presupuesto'];
    if (adicData is String) { try { adicData = jsonDecode(adicData); } catch(_) { adicData = []; } }
    List<Map<String, dynamic>> parsearAdicionales = adicData is List ? List<Map<String, dynamic>>.from(adicData) : [];

    return ModeloServicioCatalogo(
      id: json['id']?.toString() ?? '',
      profesionalId: json['profesional_id']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Otros', 
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      imagenes: parsearImagenes,
      modalidad: json['modalidad']?.toString() ?? 'a_domicilio',
      radioCoberturaKm: int.tryParse(json['radio_cobertura_km']?.toString() ?? '0') ?? 0,
      zonasCoberturaDescripcion: json['zonas_cobertura_descripcion']?.toString() ?? '',
      direccionLocal: json['direccion_local']?.toString() ?? '',
      referenciaDireccionLocal: json['referencia_direccion_local']?.toString() ?? '',
      duracionEstimada: json['duracion_estimada']?.toString() ?? '1 hora aprox.',
      capacidadSimultanea: int.tryParse(json['capacidad_simultanea']?.toString() ?? '1') ?? 1,
      tiempoMinimoAnticipacionHoras: int.tryParse(json['tiempo_minimo_anticipacion_horas']?.toString() ?? '2') ?? 2,
      tiposContratoSoportados: parsearContratos.isNotEmpty ? parsearContratos : ['unico'],
      usaProductosPremium: json['usa_productos_premium'] == true,
      profesionalVerificado: json['profesional_verificado'] == true,
      etiquetasConfianza: parsearEtiquetas, 
      niveles: parsearNiveles,
      reglasDisponibilidad: reglasData != null ? ModeloReglasDisponibilidad.fromJson(reglasData) : ModeloReglasDisponibilidad.vacia(),
      extrasOpcionales: parsearExtras,
      preguntasFrecuentes: parsearFaq,
      profesionalNombre: json['profesional_nombre']?.toString() ?? '',
      profesionalAvatar: json['profesional_avatar']?.toString() ?? '',
      profesionalRating: double.tryParse(json['profesional_rating']?.toString() ?? '0') ?? 0.0,
      profesionalReviews: int.tryParse(json['profesional_reviews']?.toString() ?? '0') ?? 0,
      estado: json['estado']?.toString() ?? 'publicado',
      adicionalesPresupuesto: parsearAdicionales,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profesional_id': profesionalId,
      'categoria': categoria,
      'titulo': titulo,
      'descripcion': descripcion,
      'imagenes': imagenes,
      'modalidad': modalidad,
      'radio_cobertura_km': radioCoberturaKm,
      'zonas_cobertura_descripcion': zonasCoberturaDescripcion,
      'direccion_local': direccionLocal,
      'referencia_direccion_local': referenciaDireccionLocal,
      'duracion_estimada': duracionEstimada,
      'capacidad_simultanea': capacidadSimultanea,
      'tiempo_minimo_anticipacion_horas': tiempoMinimoAnticipacionHoras,
      'tipos_contrato_soportados': tiposContratoSoportados,
      'usa_productos_premium': usaProductosPremium,
      'profesional_verificado': profesionalVerificado,
      'etiquetas_confianza': etiquetasConfianza, 
      'niveles': niveles.map((e) => e.toJson()).toList(),
      'reglas_disponibilidad': reglasDisponibilidad.toJson(),
      'extras_opcionales': extrasOpcionales,
      'preguntas_frecuentes': preguntasFrecuentes,
      'estado': estado,
      'adicionales_presupuesto': adicionalesPresupuesto,
   
    };
  }
}

class ModeloNivelServicio {
  final String idNivel; 
  final String nombre; 
  final String descripcionCorta; 
  final double precioFijo;
  final int duracionMinutos; 
  final int bufferAntesMinutos; 
  final int bufferDespuesMinutos; 
  final List<String> caracteristicas;
  final String duracionEstimada; 
  final String? loQueNoCubre;

  ModeloNivelServicio({
    required this.idNivel, 
    required this.nombre, 
    this.descripcionCorta = '', 
    required this.precioFijo, 
    required this.duracionMinutos, 
    this.bufferAntesMinutos = 0, 
    this.bufferDespuesMinutos = 0, 
    this.caracteristicas = const [],
    this.duracionEstimada = '1 hora aprox.', 
    this.loQueNoCubre,
  });

  List<String> get caracteristicasProcesadas {
    if (descripcionCorta.isNotEmpty) { 
      String normalizado = descripcionCorta.replaceAll('+', ',');
      return normalizado.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (caracteristicas.isNotEmpty) return caracteristicas;
    return [];
  }

  List<String> get loQueNoCubreProcesado {
    if (loQueNoCubre == null || loQueNoCubre!.trim().isEmpty) return [];
    String normalizado = loQueNoCubre!.replaceAll('+', ',');
    return normalizado.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  factory ModeloNivelServicio.fromJson(Map<String, dynamic> json) {
    return ModeloNivelServicio(
      idNivel: json['id_nivel']?.toString() ?? '', 
      nombre: json['nombre']?.toString() ?? '', 
      descripcionCorta: json['descripcion_corta']?.toString() ?? '',
      precioFijo: double.tryParse(json['precio_fijo']?.toString() ?? '0') ?? 0.0, 
      duracionMinutos: int.tryParse(json['duracion_minutos']?.toString() ?? '60') ?? 60,
      bufferAntesMinutos: int.tryParse(json['buffer_antes_minutos']?.toString() ?? '0') ?? 0, 
      bufferDespuesMinutos: int.tryParse(json['buffer_despues_minutos']?.toString() ?? '0') ?? 0,
      caracteristicas: (json['caracteristicas'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      duracionEstimada: json['duracion_estimada']?.toString() ?? '1 hora aprox.', 
      loQueNoCubre: json['lo_que_no_cubre']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => { 
    'id_nivel': idNivel, 
    'nombre': nombre, 
    'descripcion_corta': descripcionCorta, 
    'precio_fijo': precioFijo, 
    'duracion_minutos': duracionMinutos, 
    'buffer_antes_minutos': bufferAntesMinutos, 
    'buffer_despues_minutos': bufferDespuesMinutos, 
    'caracteristicas': caracteristicas,
    'duracion_estimada': duracionEstimada, 
    'lo_que_no_cubre': loQueNoCubre,
  };
}

class ModeloReglasDisponibilidad {
  final List<int> diasLaborales; 
  final String horarioInicio; 
  final String horarioFin; 
  final bool dobleJornada;
  final String horarioInicio2;
  final String horarioFin2;
  final List<ModeloBloqueoManual> bloqueosManuales;
  final int tiempoMuertoAntesMinutos;
  final int tiempoMuertoDespuesMinutos;
  final int frecuenciaSlotsMinutos;

  ModeloReglasDisponibilidad({
    required this.diasLaborales, 
    required this.horarioInicio, 
    required this.horarioFin, 
    this.dobleJornada = false,
    this.horarioInicio2 = '16:00',
    this.horarioFin2 = '20:00',
    this.bloqueosManuales = const [],
    this.tiempoMuertoAntesMinutos = 0,
    this.tiempoMuertoDespuesMinutos = 0,
    this.frecuenciaSlotsMinutos = 60,
  });

  factory ModeloReglasDisponibilidad.vacia() => ModeloReglasDisponibilidad(diasLaborales: [1, 2, 3, 4, 5, 6], horarioInicio: '09:00', horarioFin: '18:00');

  factory ModeloReglasDisponibilidad.fromJson(Map<String, dynamic> json) { 
    return ModeloReglasDisponibilidad( 
      diasLaborales: (json['dias_laborales'] as List<dynamic>? ?? []).map((e) => int.tryParse(e.toString()) ?? 1).toList(), 
      horarioInicio: json['horario_inicio']?.toString() ?? '09:00', 
      horarioFin: json['horario_fin']?.toString() ?? '18:00', 
      dobleJornada: json['doble_jornada'] == true,
      horarioInicio2: json['horario_inicio_2']?.toString() ?? '16:00',
      horarioFin2: json['horario_fin_2']?.toString() ?? '20:00',
      bloqueosManuales: (json['bloqueos_manuales'] as List<dynamic>? ?? []).map((e) => ModeloBloqueoManual.fromJson(e)).toList(),
      tiempoMuertoAntesMinutos: int.tryParse(json['tiempo_muerto_antes_minutos']?.toString() ?? '0') ?? 0,
      tiempoMuertoDespuesMinutos: int.tryParse(json['tiempo_muerto_despues_minutos']?.toString() ?? '0') ?? 0,
      frecuenciaSlotsMinutos: int.tryParse(json['frecuencia_slots_minutos']?.toString() ?? '60') ?? 60,
    ); 
  }
  
  Map<String, dynamic> toJson() => { 
    'dias_laborales': diasLaborales, 
    'horario_inicio': horarioInicio, 
    'horario_fin': horarioFin, 
    'doble_jornada': dobleJornada,
    'horario_inicio_2': horarioInicio2,
    'horario_fin_2': horarioFin2,
    'bloqueos_manuales': bloqueosManuales.map((e) => e.toJson()).toList(),
    'tiempo_muerto_antes_minutos': tiempoMuertoAntesMinutos,
    'tiempo_muerto_despues_minutos': tiempoMuertoDespuesMinutos,
    'frecuencia_slots_minutos': frecuenciaSlotsMinutos,
  };
}

class ModeloBloqueoManual {
  final DateTime inicio; final DateTime fin; final String motivo;
  ModeloBloqueoManual({required this.inicio, required this.fin, required this.motivo});
  factory ModeloBloqueoManual.fromJson(Map<String, dynamic> json) { return ModeloBloqueoManual(inicio: DateTime.tryParse(json['inicio']?.toString() ?? '') ?? DateTime.now(), fin: DateTime.tryParse(json['fin']?.toString() ?? '') ?? DateTime.now(), motivo: json['motivo']?.toString() ?? 'Bloqueo manual'); }
  Map<String, dynamic> toJson() => { 'inicio': inicio.toIso8601String(), 'fin': fin.toIso8601String(), 'motivo': motivo };
}