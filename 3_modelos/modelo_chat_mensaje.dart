// lib/3_modelos/modelo_chat_mensaje.dart

class ModeloMensaje {
  final String id;
  final String trabajoId;
  final String emisorId;
  final String? receptorId;
  final String texto;
  final bool leido;
  final String fecha;

  ModeloMensaje({
    required this.id, required this.trabajoId, required this.emisorId,
    this.receptorId, required this.texto, this.leido = false, required this.fecha,
  });

  factory ModeloMensaje.fromJson(Map<String, dynamic> json) {
    return ModeloMensaje(
      id: json['id']?.toString() ?? '',
      trabajoId: json['trabajo_id']?.toString() ?? '',
      emisorId: json['emisor_id']?.toString() ?? '',
      receptorId: json['receptor_id']?.toString(),
      texto: json['texto']?.toString() ?? '',
      leido: json['leido'] == true,
      fecha: json['fecha']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'trabajo_id': trabajoId, 'emisor_id': emisorId,
    'receptor_id': receptorId, 'texto': texto, 'leido': leido, 'fecha': fecha,
  };
  
  bool get esMensajeSistema => texto.startsWith('SYS_');
}