// lib/3_modelos/modelo_tarjeta_guardada.dart

class ModeloTarjetaGuardada {
  final String id;
  final String usuarioId;
  final String tokenTarjeta;
  final String paymentMethodId;
  final String issuerId;
  final String apodo;
  final String lastFour;
  final String cardName;

  ModeloTarjetaGuardada({
    required this.id, required this.usuarioId, required this.tokenTarjeta, required this.paymentMethodId,
    required this.issuerId, required this.apodo, required this.lastFour, required this.cardName,
  });

  factory ModeloTarjetaGuardada.fromJson(Map<String, dynamic> json) {
    return ModeloTarjetaGuardada(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString() ?? '',
      tokenTarjeta: json['token_tarjeta']?.toString() ?? '',
      paymentMethodId: json['payment_method_id']?.toString() ?? '',
      issuerId: json['issuer_id']?.toString() ?? '',
      apodo: json['apodo']?.toString() ?? 'Tarjeta',
      lastFour: json['last_four']?.toString() ?? '****',
      cardName: json['card_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'usuario_id': usuarioId, 'token_tarjeta': tokenTarjeta, 'payment_method_id': paymentMethodId,
    'issuer_id': issuerId, 'apodo': apodo, 'last_four': lastFour, 'card_name': cardName,
  };
}