// lib/3_modelos/modelo_resena.dart

class ModeloResena {
  final String id;
  final String trabajoId;
  final String evaluadorId;
  final String evaluadoId;
  final String evaluadorNombre;
  final String evaluadorAvatar;
  final double rating;
  final String comentario;
  final String fechaCreacion;
  final String rolEvaluado; 

  ModeloResena({
    required this.id, 
    required this.trabajoId, 
    required this.evaluadorId, 
    required this.evaluadoId,
    required this.evaluadorNombre, 
    required this.evaluadorAvatar, 
    required this.rating,
    required this.comentario, 
    required this.fechaCreacion,
    required this.rolEvaluado,
  });

  factory ModeloResena.fromJson(Map<String, dynamic> json) {
    return ModeloResena(
      id: json['id']?.toString() ?? '',
      trabajoId: json['trabajo_id']?.toString() ?? '',
      evaluadorId: json['evaluador_id']?.toString() ?? '',
      evaluadoId: json['evaluado_id']?.toString() ?? '',
      evaluadorNombre: json['evaluador_nombre']?.toString() ?? 'Usuario',
      evaluadorAvatar: json['evaluador_avatar']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comentario: json['comentario']?.toString() ?? '',
      // 🛡️ LECTURA EXACTA: Mapeado al SQL 'fecha_creacion'
      fechaCreacion: json['fecha_creacion']?.toString() ?? '',
      // 🛡️ LECTURA EXACTA: Mapeado al SQL 'rol_evaluado'
      rolEvaluado: json['rol_evaluado']?.toString().toLowerCase().trim() ?? 'profesional', 
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 
    'trabajo_id': trabajoId, 
    'evaluador_id': evaluadorId, 
    'evaluado_id': evaluadoId,
    'evaluador_nombre': evaluadorNombre, 
    'evaluador_avatar': evaluadorAvatar, 
    'rating': rating,
    'comentario': comentario, 
    // 🛡️ ESCRITURA EXACTA: Mapeado al SQL 'fecha_creacion'
    'fecha_creacion': fechaCreacion,
    'rol_evaluado': rolEvaluado,
  };
}