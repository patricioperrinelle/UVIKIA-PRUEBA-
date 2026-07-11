// lib/3_modelos/modelo_notificacion.dart

class ModeloNotificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final String fecha;
  final String tipo;
  final String? trabajoId;
  bool leida; // Es varible porque se muta localmente al verla

  ModeloNotificacion({
    required this.id, required this.titulo, required this.mensaje, required this.fecha,
    required this.tipo, this.trabajoId, this.leida = false,
  });

  factory ModeloNotificacion.fromJson(Map<String, dynamic> json) {
    return ModeloNotificacion(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? json['fecha_creacion']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'sistema',
      trabajoId: json['trabajoId']?.toString() ?? json['trabajo_id']?.toString(),
      leida: json['leida'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'titulo': titulo, 'mensaje': mensaje, 'fecha': fecha,
    'tipo': tipo, 'trabajoId': trabajoId, 'leida': leida,
  };
}