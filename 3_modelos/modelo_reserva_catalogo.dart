// lib/3_modelos/modelo_reserva_catalogo.dart
import 'dart:convert';
import 'modelo_puja.dart';
import 'contratos/dominio_app.dart';
import 'contratos/trabajo_contratable.dart';

class ModeloReservaCatalogo implements TrabajoContratable {
  final String id;
  final String titulo;
  final String descripcion;
  final String requisitos; 
  final String precio;
  final String fechaHora;
  final String? horaFin; 
  final String fechaCreacion;
  final List<String> imagenes;
  final String estado;
  final String ownerId;
  
  final String localidad;
  final String ubicacionExacta;
  
  final String categoria;
  final String oficio;
  final String dificultad; 
  final String whatsapp;
  
  final String contraparteNombre;
  final String contraparteAvatar;
  final double ratingContraparte;
  final int reviewsContraparte;
  
  final List<ModeloPuja> pujas;
  final int cantidadPujasTotales;
  final String? miOferta;
  final bool? aceptoPrecioBase;
  final String? estadoNegociacion; 
  final String? pujaId; 
  
  final String? profesionalSolicitadoId; 
  final String? profesionalAsignadoId;
  final String? precioFinalAcordado;
  final String metodoPago;
  
  final int mensajesNoLeidos;
  final bool clienteCalifico;
  final bool proCalifico;

  final List<Map<String, dynamic>> adicionalesPresupuesto;
  final String? servicioCatalogoId;

  ModeloReservaCatalogo({
    required this.id, required this.titulo, required this.descripcion, required this.precio,
    required this.fechaHora, this.horaFin, required this.fechaCreacion, required this.estado, required this.ownerId,
    this.requisitos = '',
    this.imagenes = const[], this.localidad = '', this.ubicacionExacta = '', 
    this.categoria = 'Otros', this.oficio = '',
    this.dificultad = '1', this.whatsapp = '', this.contraparteNombre = '', this.contraparteAvatar = '',
    this.ratingContraparte = 0.0, this.reviewsContraparte = 0, this.pujas = const[], this.cantidadPujasTotales = 0,
    this.miOferta, this.aceptoPrecioBase, this.estadoNegociacion, this.pujaId, this.profesionalSolicitadoId,
    this.profesionalAsignadoId, this.precioFinalAcordado, this.metodoPago = 'transferencia',
    this.mensajesNoLeidos = 0, this.clienteCalifico = false, this.proCalifico = false,
    this.adicionalesPresupuesto = const [],
    this.servicioCatalogoId,
  });

  DominioApp get dominio {
    return DominioApp.catalogo;
  }

  String get fechaLimpia {
    if (fechaHora.isEmpty) return 'Fecha sin definir';
    try {
      final dt = DateTime.parse(fechaHora).toLocal();
      final meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${dt.day} de ${meses[dt.month - 1]}. ${dt.year}';
    } catch (e) {
      return fechaHora.split('T').first.split(' ').first;
    }
  }

  String get horaLimpia {
    if (fechaHora.isEmpty) return '';
    try {
      final dt = DateTime.parse(fechaHora).toLocal();
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hora:$min hs';
    } catch (e) {
      final partes = fechaHora.split('T');
      if (partes.length > 1) {
        return '${partes.last.substring(0, 5)} hs';
      }
      return fechaHora.split(' ').last;
    }
  }

  ModeloPuja? get ganadorPuja {
    if (pujas.isEmpty) return null;
    try {
      return pujas.firstWhere((p) => 
        p.estadoPuja == 'esperando_confirmacion_pro' || 
        p.estadoPuja == 'esperando_pago_cliente' ||     
        p.estadoPuja == 'aceptada' || 
        p.estadoPuja == 'en_curso' ||
        p.estadoPuja == 'finalizada' || 
        p.estadoPuja == 'en_disputa' ||
        p.estadoPuja == 'cancelada_por_cliente' || 
        p.estadoPuja == 'cancelada_vista_pro' || 
        p.estadoPuja == 'cancelada_por_pro' ||         
        p.estadoPuja == 'cancelada_vista_cliente' ||   
        (profesionalAsignadoId != null && p.profesionalId == profesionalAsignadoId)
      );
    } catch (_) {
      return null;
    }
  }

  bool get tuvoContratoAlgunaVez {
    if (profesionalAsignadoId != null && profesionalAsignadoId!.isNotEmpty) return true;
    if (ganadorPuja != null) return true;
    
    final estadosContrato = [
      'aceptada', 'en_curso', 'finalizada', 'en_disputa',
      'cancelada_por_pro', 'cancelada_por_cliente', 
      'cancelada_vista_pro', 'cancelada_vista_cliente'
    ];
    
    if (estadoNegociacion != null && estadosContrato.contains(estadoNegociacion)) return true;
    if (pujas.any((p) => estadosContrato.contains(p.estadoPuja))) return true;
    
    return false;
  }

  double get precioBaseCalculado {
    double base = 0.0;
    if (precioFinalAcordado != null && precioFinalAcordado!.isNotEmpty) {
      base = double.tryParse(precioFinalAcordado!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else {
      base = double.tryParse(precio.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    if (base == 0.0 && ganadorPuja != null) {
      base = double.tryParse(ganadorPuja!.montoOfrecido.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    if (base == 0.0 && miOferta != null && miOferta!.isNotEmpty) {
      base = double.tryParse(miOferta!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return base;
  }

  List<Map<String, dynamic>> get extrasAceptados {
    return adicionalesPresupuesto.where((ad) => ad['estado'] == 'aceptado').toList();
  }

  double get totalExtras {
    double extras = 0.0;
    for (var ad in extrasAceptados) {
      extras += double.tryParse(ad['monto']?.toString() ?? '0') ?? 0.0;
    }
    return extras;
  }

  double get precioTotalFinal {
    return precioBaseCalculado + totalExtras;
  }

  factory ModeloReservaCatalogo.fromJson(Map<String, dynamic> json) {
    dynamic descRaw = json['descripcion'];
    String desc = '';
    String req = json['requisitos']?.toString() ?? '';
    String precio = json['precio']?.toString() ?? '';
    String localidad = json['localidad']?.toString() ?? '';
    String dificultad = json['dificultad']?.toString() ?? '1';
    List<String> imagenes = [];

    if (json['imagenes'] is List) {
      imagenes = List<String>.from(json['imagenes']);
    }

    if (descRaw is Map) {
      desc = descRaw['desc']?.toString() ?? descRaw['descripcion']?.toString() ?? '';
      if (req.isEmpty) req = descRaw['requisitos']?.toString() ?? '';
      if (precio.isEmpty) precio = descRaw['price']?.toString() ?? descRaw['precio']?.toString() ?? '';
      if (localidad.isEmpty) localidad = descRaw['localidad']?.toString() ?? descRaw['location']?.toString() ?? '';
      if (dificultad == '1') dificultad = descRaw['dificultad']?.toString() ?? '1';
      if (imagenes.isEmpty && descRaw['images'] is List) {
        imagenes = List<String>.from(descRaw['images']);
      }
    } else {
      desc = descRaw?.toString() ?? '';
      if (desc.trim().startsWith('{')) {
        try {
          final Map<String, dynamic> map = jsonDecode(desc);
          desc = map['desc']?.toString() ?? map['descripcion']?.toString() ?? desc;
          if (req.isEmpty) req = map['requisitos']?.toString() ?? '';
          if (precio.isEmpty) precio = map['price']?.toString() ?? map['precio']?.toString() ?? '';
          if (localidad.isEmpty) localidad = map['localidad']?.toString() ?? map['location']?.toString() ?? '';
          if (dificultad == '1') dificultad = map['dificultad']?.toString() ?? '1';
          if (imagenes.isEmpty && map['images'] is List) {
            imagenes = List<String>.from(map['images']);
          }
        } catch (_) {}
      }
    }

    dynamic adicData = json['adicionales_presupuesto'];
    if (adicData is String) { 
      try { adicData = jsonDecode(adicData); } catch(_) { adicData = []; } 
    }
    List<Map<String, dynamic>> parsearAdicionales = adicData is List ? List<Map<String, dynamic>>.from(adicData) : [];

    final String? servId = json['servicio_catalogo_id']?.toString() ?? json['servicioCatalogoId']?.toString();

    return ModeloReservaCatalogo(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? json['title']?.toString() ?? '',
      descripcion: desc,
      requisitos: req,
      precio: precio,
      fechaHora: json['fecha_hora']?.toString() ?? json['fechaHora']?.toString() ?? json['date']?.toString() ?? '',
      horaFin: json['hora_fin']?.toString() ?? json['horaFin']?.toString(),
      fechaCreacion: json['created_at']?.toString() ?? json['fechaCreacion']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'abierto',
      ownerId: json['cliente_id']?.toString() ?? json['ownerId']?.toString() ?? '',
      imagenes: imagenes,
      localidad: localidad,
      ubicacionExacta: json['ubicacion_exacta']?.toString() ?? json['ubicacionExacta']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Otros',
      oficio: json['oficio']?.toString() ?? '',
      dificultad: dificultad,
      whatsapp: json['telefono_contacto']?.toString() ?? json['whatsapp']?.toString() ?? '',
      contraparteNombre: json['contraparteNombre']?.toString() ?? json['counterpart']?.toString() ?? '',
      contraparteAvatar: json['contraparteAvatar']?.toString() ?? json['avatarUrl']?.toString() ?? '',
      ratingContraparte: double.tryParse(json['ratingContraparte']?.toString() ?? json['rating']?.toString() ?? '') ?? 0.0,
      reviewsContraparte: int.tryParse(json['reviewsContraparte']?.toString() ?? json['reviews']?.toString() ?? '') ?? 0,
      pujas: (json['pujas'] as List<dynamic>? ??[]).map((e) => ModeloPuja.fromJson(e)).toList(),
      cantidadPujasTotales: int.tryParse(json['cantidad_pujas']?.toString() ?? '0') ?? 0,
      miOferta: json['miOferta']?.toString(),
      aceptoPrecioBase: json['aceptoPrecioBase'] == true || json['aceptoPrecioBase'] == 'true',
      
      estadoNegociacion: json['estado_negociacion']?.toString() ?? json['estadoNegociacion']?.toString(),
      pujaId: json['puja_id']?.toString() ?? json['pujaId']?.toString(),
      profesionalSolicitadoId: json['profesional_solicitado_id']?.toString() ?? json['profesionalSolicitadoId']?.toString(),
      profesionalAsignadoId: json['profesional_asignado_id']?.toString() ?? json['profesionalAsignadoId']?.toString(),
      precioFinalAcordado: json['precio_final_acordado']?.toString() ?? json['precioFinalAcordado']?.toString(),
      metodoPago: json['metodo_pago']?.toString() ?? json['metodoPago']?.toString() ?? 'transferencia',
      
      mensajesNoLeidos: int.tryParse(json['mensajesNoLeidos']?.toString() ?? '0') ?? 0,
      clienteCalifico: json['cliente_califico'] == true || json['clienteCalifico'] == true,
      proCalifico: json['pro_califico'] == true || json['proCalifico'] == true,
      adicionalesPresupuesto: parsearAdicionales,
      servicioCatalogoId: servId,
    );
  }

  Map<String, dynamic> toJson() {
    final String descFusionada = requisitos.isNotEmpty ? '$descripcion\n\n🛠️ Requisitos: $requisitos' : descripcion;

    return {
      'id': id, 'titulo': titulo, 'descripcion': descripcion, 'requisitos': requisitos, 'precio': precio, 
      'fechaHora': fechaHora, 'hora_fin': horaFin, 'fechaCreacion': fechaCreacion, 'estado': estado, 'ownerId': ownerId, 
      'imagenes': imagenes, 'localidad': localidad, 'ubicacionExacta': ubicacionExacta, 
      'categoria': categoria, 'oficio': oficio, 'dificultad': dificultad,
      'whatsapp': whatsapp, 'contraparteNombre': contraparteNombre, 'contraparteAvatar': contraparteAvatar,
      'ratingContraparte': ratingContraparte, 'reviewsContraparte': reviewsContraparte,
      'pujas': pujas.map((p) => p.toJson()).toList(), 'cantidadPujasTotales': cantidadPujasTotales,
      'miOferta': miOferta, 'aceptoPrecioBase': aceptoPrecioBase, 'estadoNegociacion': estadoNegociacion,
      'pujaId': pujaId, 'profesionalSolicitadoId': profesionalSolicitadoId, 'profesionalAsignadoId': profesionalAsignadoId,
      'precioFinalAcordado': precioFinalAcordado, 'metodoPago': metodoPago, 'mensajesNoLeidos': mensajesNoLeidos,
      'clienteCalifico': clienteCalifico, 'proCalifico': proCalifico, 'adicionales_presupuesto': adicionalesPresupuesto,
      'servicio_catalogo_id': servicioCatalogoId,
      'servicioCatalogoId': servicioCatalogoId,
      
      'title': titulo, 'description': descFusionada, 'price': precio, 'date': fechaHora, 'createdAt': fechaCreacion,
      'location': localidad, 'images': imagenes, 'counterpart': contraparteNombre, 'avatarUrl': contraparteAvatar,
      'rating': ratingContraparte, 'reviews': reviewsContraparte, 'cantidad_pujas': cantidadPujasTotales,
    };
  }
}
