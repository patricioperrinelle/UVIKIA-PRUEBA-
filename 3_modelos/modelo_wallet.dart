// lib/3_modelos/modelo_wallet.dart

enum TipoWallet { user, revenue, taxes, desconocido }

class ModeloWallet {
  final String id;
  final String? usuarioId;
  final TipoWallet tipoWallet;
  final double saldo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ModeloWallet({
    required this.id,
    this.usuarioId,
    this.tipoWallet = TipoWallet.user,
    this.saldo = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  static TipoWallet _parseTipoWallet(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'USER': return TipoWallet.user;
      case 'REVENUE': return TipoWallet.revenue;
      case 'TAXES': return TipoWallet.taxes;
      default: return TipoWallet.desconocido;
    }
  }

  static String _tipoWalletToString(TipoWallet tipo) {
    switch (tipo) {
      case TipoWallet.user: return 'USER';
      case TipoWallet.revenue: return 'REVENUE';
      case TipoWallet.taxes: return 'TAXES';
      default: return 'USER';
    }
  }

  factory ModeloWallet.fromJson(Map<String, dynamic> json) {
    return ModeloWallet(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString(),
      tipoWallet: _parseTipoWallet(json['tipo_wallet']?.toString()),
      
      // 🚨 PARSEO DEFENSIVO MATEMÁTICO: Estrictamente aplicado
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'tipo_wallet': _tipoWalletToString(tipoWallet),
    'saldo': saldo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}