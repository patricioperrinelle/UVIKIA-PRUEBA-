// lib/3_modelos/modelo_perfil.dart

class DatosProfesionales {
  // ==========================================
  // 🏛️ VARIABLES LEGACY (CLÁSICAS)
  // ==========================================
  final String bio;
  final List<String> tagsOficios;
  final List<String> fotosPortafolio;
  final String horarios;
  final String experienciaAnos;
  final String garantiaDias;
  final List<String> serviciosDetalle;
  final List<String> habilidades;
  final String? resenaDestacadaId;
  final String zonaTrabajo;
  final String tiempoRespuesta;
  final int strikes;
  final double ratingProfesional;
  final int cantidadResenasProfesional;
  
  final double scoreConfiabilidadPro;
  final double puntualidad;
  final double asistencia;
  final double jornadasCompletadas;
  final double cancelacionesPro;
  final int jornadasRealizadas;
  final double recomendacionClientes;

  // ==========================================
  // 🧠 NUEVAS VARIABLES: ALGORITMO MATCHMAKING
  // ==========================================
  final String habilidadPrincipal;
  final List<String> habilidadesSecundarias;
  final List<String> habilidadesEspeciales;
  final List<String> certificaciones;

  DatosProfesionales({
    this.bio = '',
    this.tagsOficios = const[],
    this.fotosPortafolio = const[],
    this.horarios = 'Lunes a Sábados de 08:00 a 18:00 hs',
    this.experienciaAnos = '0',
    this.garantiaDias = '0',
    this.serviciosDetalle = const[],
    this.habilidades = const[],
    this.resenaDestacadaId,
    this.zonaTrabajo = '',
    this.tiempoRespuesta = '',
    this.strikes = 0,
    this.ratingProfesional = 0.0,
    this.cantidadResenasProfesional = 0,
    
    this.scoreConfiabilidadPro = 0.0,
    this.puntualidad = 0.0,
    this.asistencia = 0.0,
    this.jornadasCompletadas = 0.0,
    this.cancelacionesPro = 0.0,
    this.jornadasRealizadas = 0,
    this.recomendacionClientes = 0.0,

    this.habilidadPrincipal = '',
    this.habilidadesSecundarias = const[],
    this.habilidadesEspeciales = const[],
    this.certificaciones = const[],
  });

  factory DatosProfesionales.fromJson(Map<String, dynamic> json) {
    return DatosProfesionales(
      bio: json['bio']?.toString() ?? json['biography']?.toString() ?? '',
      tagsOficios: ModeloPerfil.parsearLista(json['oficios'] ?? json['tagsOficios'] ?? json['tags']),
      fotosPortafolio: ModeloPerfil.parsearLista(json['fotos_portafolio'] ?? json['fotosPortafolio'] ?? json['portfolioImages']),
      horarios: json['horarios']?.toString() ?? 'Lunes a Sábados de 08:00 a 18:00 hs',
      experienciaAnos: json['experiencia_anos']?.toString() ?? json['experienciaAnos']?.toString() ?? '0',
      garantiaDias: json['garantia_dias']?.toString() ?? json['garantiaDias']?.toString() ?? '0',
      serviciosDetalle: ModeloPerfil.parsearLista(json['servicios_detalle'] ?? json['serviciosDetalle']),
      habilidades: ModeloPerfil.parsearLista(json['habilidades']),
      resenaDestacadaId: json['resena_destacada_id']?.toString() ?? json['resenaDestacadaId']?.toString(),
      zonaTrabajo: json['zona_trabajo']?.toString() ?? json['zonaTrabajo']?.toString() ?? '',
      tiempoRespuesta: json['tiempo_respuesta']?.toString() ?? json['tiempoRespuesta']?.toString() ?? '',
      strikes: (json['strikes'] as num?)?.toInt() ?? 0,
      
      // 🚨 FIX ALPHA-CORE: Parseo Hermético para Estrellas y Reseñas
      ratingProfesional: (json['rating_profesional'] as num?)?.toDouble() ?? (json['ratingProfesional'] as num?)?.toDouble() ?? (json['rating'] as num?)?.toDouble() ?? 0.0,
      cantidadResenasProfesional: (json['cantidad_resenas_profesional'] as num?)?.toInt() ?? (json['cantidadResenasProfesional'] as num?)?.toInt() ?? (json['cantidad_resenas'] as num?)?.toInt() ?? 0,
      
      scoreConfiabilidadPro: (json['score_confiabilidad_pro'] as num?)?.toDouble() ?? (json['scoreConfiabilidadPro'] as num?)?.toDouble() ?? 0.0,
      puntualidad: (json['puntualidad'] as num?)?.toDouble() ?? 0.0,
      asistencia: (json['asistencia'] as num?)?.toDouble() ?? 0.0,
      jornadasCompletadas: (json['jornadas_completadas'] as num?)?.toDouble() ?? (json['jornadasCompletadas'] as num?)?.toDouble() ?? 0.0,
      cancelacionesPro: (json['cancelaciones_pro'] as num?)?.toDouble() ?? (json['cancelacionesPro'] as num?)?.toDouble() ?? 0.0,
      jornadasRealizadas: (json['jornadas_realizadas'] as num?)?.toInt() ?? (json['jornadasRealizadas'] as num?)?.toInt() ?? 0,
      recomendacionClientes: (json['recomendacion_clientes'] as num?)?.toDouble() ?? (json['recomendacionClientes'] as num?)?.toDouble() ?? 0.0,
      
      habilidadPrincipal: json['habilidad_principal']?.toString() ?? '',
      habilidadesSecundarias: ModeloPerfil.parsearLista(json['habilidades_secundarias']),
      habilidadesEspeciales: ModeloPerfil.parsearLista(json['habilidades_especiales']),
      certificaciones: ModeloPerfil.parsearLista(json['certificaciones']),
    );
  }

  Map<String, dynamic> toJson() => {
    'bio': bio, 'tagsOficios': tagsOficios, 'fotos_portafolio': fotosPortafolio,
    'horarios': horarios, 'experiencia_anos': experienciaAnos, 'garantia_dias': garantiaDias,
    'servicios_detalle': serviciosDetalle, 'habilidades': habilidades,
    'resena_destacada_id': resenaDestacadaId, 'zona_trabajo': zonaTrabajo,
    'tiempo_respuesta': tiempoRespuesta, 'strikes': strikes,
    
    // Nombres unificados para que el fromJson no se pierda al leer del disco
    'rating_profesional': ratingProfesional, 'cantidad_resenas_profesional': cantidadResenasProfesional,
    'score_confiabilidad_pro': scoreConfiabilidadPro, 'puntualidad': puntualidad, 'asistencia': asistencia,
    'jornadas_completadas': jornadasCompletadas, 'cancelaciones_pro': cancelacionesPro,
    'jornadas_realizadas': jornadasRealizadas, 'recomendacion_clientes': recomendacionClientes,
    
    'habilidad_principal': habilidadPrincipal, 'habilidades_secundarias': habilidadesSecundarias,
    'habilidades_especiales': habilidadesEspeciales, 'certificaciones': certificaciones,
  };
}

class ModeloPerfil {
  final String id;
  final String apodo;
  final String fotoUrl;
  
  final double ratingCliente;
  final int cantidadResenasCliente;

  final bool esProfesional;
  final DatosProfesionales? perfilProfesional;

  final DateTime? miembroDesde;
  final double scoreConfiabilidadCliente;
  final double cancelacionesCliente;
  final int tiempoRespuestaMinutos;
  final double disputasAbiertas;
  final int trabajosPublicados;
  final int trabajadoresContratados;
  final double recomendacionTrabajadores;

  final String? dni;
  final String? codigoCompartible;
  final DateTime? fechaNacimiento;
  final String email;
  final String ciudad;
  final String localidad;
  final String barrio;

  ModeloPerfil({
    required this.id, required this.apodo, this.fotoUrl = '', 
    this.ratingCliente = 0.0, this.cantidadResenasCliente = 0,
    this.esProfesional = false, this.perfilProfesional,
    this.miembroDesde,
    this.scoreConfiabilidadCliente = 0.0,
    this.cancelacionesCliente = 0.0,
    this.tiempoRespuestaMinutos = 0,
    this.disputasAbiertas = 0.0,
    this.trabajosPublicados = 0,
    this.trabajadoresContratados = 0,
    this.recomendacionTrabajadores = 0.0,
    
    this.dni, this.codigoCompartible, this.fechaNacimiento, this.email = '',
    this.ciudad = '', this.localidad = '', this.barrio = '',
  });

  int get edadCalculada {
    if (fechaNacimiento == null) return 0;
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento!.year;
    if (hoy.month < fechaNacimiento!.month || (hoy.month == fechaNacimiento!.month && hoy.day < fechaNacimiento!.day)) {
      edad--;
    }
    return edad;
  }

  static List<String> parsearLista(dynamic valor) {
    if (valor == null) return List<String>.empty(growable: true);
    if (valor is List) return valor.map((e) => e.toString()).toList();
    if (valor is String && valor.trim().isNotEmpty) {
      return valor.split(',').map((e) => e.trim()).toList();
    }
    return List<String>.empty(growable: true);
  }

  factory ModeloPerfil.fromJson(Map<String, dynamic> json) {
    final oficiosRaw = json['oficios'] ?? json['tagsOficios'] ?? json['tags'];
    final bool esProReal = (json['es_profesional'] == true) || 
                           (json['esProfesional'] == true) || 
                           (oficiosRaw != null && oficiosRaw.toString().trim().isNotEmpty && oficiosRaw.toString() != '[]');

    // 🚨 FIX ALPHA-CORE: EL EXTRACTOR DE CACHÉ
    // Si venimos del disco duro, la info del pro está guardada dentro de la cajita 'perfilProfesional'.
    // Si venimos de Supabase, la info está plana en el 'json' raíz.
    final Map<String, dynamic> proData = json['perfilProfesional'] != null 
        ? Map<String, dynamic>.from(json['perfilProfesional']) 
        : json;

    return ModeloPerfil(
      id: json['id']?.toString() ?? '',
      apodo: json['apodo']?.toString() ?? json['name']?.toString() ?? 'Usuario',
      fotoUrl: json['foto_url']?.toString() ?? json['fotoUrl']?.toString() ?? json['image']?.toString() ?? '',
      
      ratingCliente: (json['rating_cliente'] as num?)?.toDouble() ?? (json['ratingCliente'] as num?)?.toDouble() ?? 0.0,
      cantidadResenasCliente: (json['cantidad_resenas_cliente'] as num?)?.toInt() ?? (json['cantidadResenasCliente'] as num?)?.toInt() ?? 0,
      
      esProfesional: esProReal,
      // 🚨 Ahora le pasamos el `proData` que es capaz de leer tanto de DB como de Disco Duro
      perfilProfesional: esProReal ? DatosProfesionales.fromJson(proData) : null,
      
      // 🚨 Fix al parseo de fecha que se perdía en disco duro
      miembroDesde: json['miembro_desde'] != null 
          ? DateTime.tryParse(json['miembro_desde']) 
          : (json['miembroDesde'] != null ? DateTime.tryParse(json['miembroDesde']) : null),
      
      scoreConfiabilidadCliente: (json['score_confiabilidad_cliente'] as num?)?.toDouble() ?? (json['scoreConfiabilidadCliente'] as num?)?.toDouble() ?? 0.0,
      cancelacionesCliente: (json['cancelaciones_cliente'] as num?)?.toDouble() ?? (json['cancelacionesCliente'] as num?)?.toDouble() ?? 0.0,
      tiempoRespuestaMinutos: (json['tiempo_respuesta_minutos'] as num?)?.toInt() ?? (json['tiempoRespuestaMinutos'] as num?)?.toInt() ?? 0,
      disputasAbiertas: (json['disputas_abiertas'] as num?)?.toDouble() ?? (json['disputasAbiertas'] as num?)?.toDouble() ?? 0.0,
      trabajosPublicados: (json['trabajos_publicados'] as num?)?.toInt() ?? (json['trabajosPublicados'] as num?)?.toInt() ?? 0,
      trabajadoresContratados: (json['trabajadores_contratados'] as num?)?.toInt() ?? (json['trabajadoresContratados'] as num?)?.toInt() ?? 0,
      recomendacionTrabajadores: (json['recomendacion_trabajadores'] as num?)?.toDouble() ?? (json['recomendacionTrabajadores'] as num?)?.toDouble() ?? 0.0,
      
      dni: json['dni']?.toString(),
      codigoCompartible: json['codigo_compartible']?.toString(),
      fechaNacimiento: json['fecha_nacimiento'] != null ? DateTime.tryParse(json['fecha_nacimiento']) : null,
      email: json['email']?.toString() ?? '',
      ciudad: json['ciudad']?.toString() ?? '',
      localidad: json['localidad']?.toString() ?? '',
      barrio: json['barrio']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'apodo': apodo, 'fotoUrl': fotoUrl,
    'ratingCliente': ratingCliente, 'cantidadResenasCliente': cantidadResenasCliente,
    'esProfesional': esProfesional,
    'perfilProfesional': perfilProfesional?.toJson(),
    'miembroDesde': miembroDesde?.toIso8601String(),
    'scoreConfiabilidadCliente': scoreConfiabilidadCliente, 'cancelacionesCliente': cancelacionesCliente,
    'tiempoRespuestaMinutos': tiempoRespuestaMinutos, 'disputasAbiertas': disputasAbiertas,
    'trabajosPublicados': trabajosPublicados, 'trabajadoresContratados': trabajadoresContratados,
    'recomendacionTrabajadores': recomendacionTrabajadores,
    
    'dni': dni, 'codigo_compartible': codigoCompartible, 
    'fecha_nacimiento': fechaNacimiento?.toIso8601String(), 
    'email': email, 'ciudad': ciudad, 'localidad': localidad, 'barrio': barrio,
  };
}