// lib/3_modelos/modelo_puja.dart

class ModeloPuja {
  final String id;
  final String profesionalId;
  final String apodoProfesional;
  final String avatarUrl;
  final double rating;
  final int reviews;
  final String montoOfrecido;
  final String estadoPuja;
  
  final String mensaje;
  
  final String telefono;
  
  // Exclusivos de Jornadas
  final String? coordenadasLlegada;
  final String? checkinHora;
  final bool rechazadoPorCliente;
  final bool notificacionLeidaCliente;
  final bool notificacionLeidaPro;

  // 🚨 NUEVO: Banderas individuales de reseña por turno
  final bool clienteCalificoPuja;
  final bool proCalificoPuja;

  // Códigos de Seguridad y Checkout
  final String? codigoCheckin;
  final String? codigoCheckout;
  final String? checkoutHora;

  // Métricas Premium y Ubicación
  final double puntualidad;
  final double asistencia;
  final double jornadasCompletadas;
  final double cancelacionesPro;
  final double scoreConfiabilidadPro;
  final String zonaTrabajo;

  // Lista de oficios
  final List<String> oficios;
  
  // 🔥 Mapeo real de la fecha para ordenamiento cronológico estricto
  final String fechaCreacion;

  ModeloPuja({
    required this.id,
    required this.profesionalId,
    required this.apodoProfesional,
    required this.avatarUrl,
    required this.rating,
    required this.reviews,
    required this.montoOfrecido,
    this.estadoPuja = 'esperando',
    this.mensaje = '',
    this.telefono = '',
    this.coordenadasLlegada,
    this.checkinHora,
    this.rechazadoPorCliente = false,
    this.notificacionLeidaCliente = false,
    this.notificacionLeidaPro = false,
    this.clienteCalificoPuja = false, 
    this.proCalificoPuja = false,     
    this.codigoCheckin,
    this.codigoCheckout,
    this.checkoutHora,
    this.puntualidad = 0.0,
    this.asistencia = 0.0,
    this.jornadasCompletadas = 0.0,
    this.cancelacionesPro = 0.0,
    this.scoreConfiabilidadPro = 0.0,
    this.zonaTrabajo = '',
    this.oficios = const[], 
    this.fechaCreacion = '', // 🔥 Inicializador
  });

  static List<String> parsearLista(dynamic valor) {
    if (valor == null) return[];
    if (valor is List) return valor.map((e) => e.toString()).toList();
    if (valor is String && valor.trim().isNotEmpty) return valor.split(',').map((e) => e.trim()).toList();
    return[];
  }

  factory ModeloPuja.fromJson(Map<String, dynamic> json) {
    return ModeloPuja(
      id: json['id']?.toString() ?? '',
      profesionalId: json['profesional_id']?.toString() ?? json['profesionalId']?.toString() ?? '',
      apodoProfesional: json['apodo_profesional']?.toString() ?? json['apodoProfesional']?.toString() ?? 'Profesional',
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['cantidad_resenas'] as num?)?.toInt() ?? (json['reviews'] as num?)?.toInt() ?? 0,
      montoOfrecido: json['monto']?.toString() ?? json['montoOfrecido']?.toString() ?? '\$ 0',
      estadoPuja: json['estado']?.toString() ?? json['estadoPuja']?.toString() ?? 'esperando',
      mensaje: json['mensaje']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      coordenadasLlegada: json['coordenadas_llegada']?.toString() ?? json['coordenadasLlegada']?.toString(),
      checkinHora: json['checkin_hora']?.toString() ?? json['checkinHora']?.toString(),
      rechazadoPorCliente: json.containsKey('rechazado_por_cliente') ? json['rechazado_por_cliente'] == true : json['rechazadoPorCliente'] == true,
      notificacionLeidaCliente: json.containsKey('notificacion_leida_cliente') ? json['notificacion_leida_cliente'] == true : json['notificacionLeidaCliente'] == true,
      notificacionLeidaPro: json.containsKey('notificacion_leida_pro') ? json['notificacion_leida_pro'] == true : json['notificacionLeidaPro'] == true,
      clienteCalificoPuja: json.containsKey('cliente_califico_puja') ? json['cliente_califico_puja'] == true : json['clienteCalificoPuja'] == true, 
      proCalificoPuja: json.containsKey('pro_califico_puja') ? json['pro_califico_puja'] == true : json['proCalificoPuja'] == true,             
      codigoCheckin: json['codigo_checkin']?.toString() ?? json['codigoCheckin']?.toString(),
      codigoCheckout: json['codigo_checkout']?.toString() ?? json['codigoCheckout']?.toString(),
      checkoutHora: json['checkout_hora']?.toString() ?? json['checkoutHora']?.toString(),
      puntualidad: (json['puntualidad'] as num?)?.toDouble() ?? 0.0,
      asistencia: (json['asistencia'] as num?)?.toDouble() ?? 0.0,
      jornadasCompletadas: (json['jornadas_completadas'] as num?)?.toDouble() ?? (json['jornadasCompletadas'] as num?)?.toDouble() ?? 0.0,
      cancelacionesPro: (json['cancelaciones_pro'] as num?)?.toDouble() ?? (json['cancelacionesPro'] as num?)?.toDouble() ?? 0.0,
      scoreConfiabilidadPro: (json['score_confiabilidad_pro'] as num?)?.toDouble() ?? (json['scoreConfiabilidadPro'] as num?)?.toDouble() ?? 0.0,
      zonaTrabajo: json['zona_trabajo']?.toString() ?? json['zonaTrabajo']?.toString() ?? '',
      oficios: parsearLista(json['oficios']), 
      fechaCreacion: json['created_at']?.toString() ?? json['fechaCreacion']?.toString() ?? '', // 🔥 Extracción real
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'profesionalId': profesionalId, 'apodoProfesional': apodoProfesional,
    'avatarUrl': avatarUrl, 'rating': rating, 'reviews': reviews,
    'montoOfrecido': montoOfrecido, 'estadoPuja': estadoPuja,
    'mensaje': mensaje, 
    'telefono': telefono, 
    'coordenadasLlegada': coordenadasLlegada, 'checkinHora': checkinHora,
    'rechazadoPorCliente': rechazadoPorCliente, 'notificacionLeidaCliente': notificacionLeidaCliente,
    'notificacionLeidaPro': notificacionLeidaPro,
    'cliente_califico_puja': clienteCalificoPuja, 
    'pro_califico_puja': proCalificoPuja,         
    'codigo_checkin': codigoCheckin, 'codigo_checkout': codigoCheckout, 'checkout_hora': checkoutHora,
    'puntualidad': puntualidad, 'asistencia': asistencia,
    'jornadasCompletadas': jornadasCompletadas, 'cancelacionesPro': cancelacionesPro,
    'scoreConfiabilidadPro': scoreConfiabilidadPro, 'zonaTrabajo': zonaTrabajo,
    'oficios': oficios,
    'fechaCreacion': fechaCreacion, // 🔥 Guardado real
  };
}