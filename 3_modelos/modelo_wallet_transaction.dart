// lib/3_modelos/modelo_wallet_transaction.dart

enum TipoOperacion { credito, debito, retiro, comision, desconocido }
enum EstadoTransaccion { pendiente, completado, fallido, reembolsado, desconocido }

class ModeloWalletTransaction {
  final String id;
  final String walletId;
  final double monto;
  final TipoOperacion tipoOperacion;
  final EstadoTransaccion estado;
  final String llaveIdempotencia;
  final String? referenciaTrabajoId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool liquidadoAdmin;

  const ModeloWalletTransaction({
    required this.id,
    required this.walletId,
    this.monto = 0.0,
    this.tipoOperacion = TipoOperacion.desconocido,
    this.estado = EstadoTransaccion.pendiente,
    required this.llaveIdempotencia,
    this.referenciaTrabajoId,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.liquidadoAdmin = false,
  });

  static TipoOperacion _parseTipoOperacion(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'credito': return TipoOperacion.credito;
      case 'debito': return TipoOperacion.debito;
      case 'retiro': return TipoOperacion.retiro;
      case 'comision': return TipoOperacion.comision;
      default: return TipoOperacion.desconocido;
    }
  }

  static String _tipoOperacionToString(TipoOperacion tipo) {
    switch (tipo) {
      case TipoOperacion.credito: return 'credito';
      case TipoOperacion.debito: return 'debito';
      case TipoOperacion.retiro: return 'retiro';
      case TipoOperacion.comision: return 'comision';
      default: return 'desconocido';
    }
  }

  static EstadoTransaccion _parseEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente': return EstadoTransaccion.pendiente;
      case 'completado': return EstadoTransaccion.completado;
      case 'fallido': return EstadoTransaccion.fallido;
      case 'reembolsado': return EstadoTransaccion.reembolsado;
      default: return EstadoTransaccion.desconocido;
    }
  }

  static String _estadoToString(EstadoTransaccion estado) {
    switch (estado) {
      case EstadoTransaccion.pendiente: return 'pendiente';
      case EstadoTransaccion.completado: return 'completado';
      case EstadoTransaccion.fallido: return 'fallido';
      case EstadoTransaccion.reembolsado: return 'reembolsado';
      default: return 'pendiente';
    }
  }

  factory ModeloWalletTransaction.fromJson(Map<String, dynamic> json) {
    return ModeloWalletTransaction(
      id: json['id']?.toString() ?? '',
      walletId: json['wallet_id']?.toString() ?? '',
      
      // 🚨 PARSEO DEFENSIVO MATEMÁTICO: Estrictamente aplicado
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      
      tipoOperacion: _parseTipoOperacion(json['tipo_operacion']?.toString()),
      estado: _parseEstado(json['estado']?.toString()),
      llaveIdempotencia: json['llave_idempotencia']?.toString() ?? '',
      referenciaTrabajoId: json['referencia_trabajo_id']?.toString(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : {},
      
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      liquidadoAdmin: json['liquidado_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'wallet_id': walletId,
    'monto': monto,
    'tipo_operacion': _tipoOperacionToString(tipoOperacion),
    'estado': _estadoToString(estado),
    'llave_idempotencia': llaveIdempotencia,
    'referencia_trabajo_id': referenciaTrabajoId,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'liquidado_admin': liquidadoAdmin,
  };
}