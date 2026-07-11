// lib/3_modelos/modelo_cuenta_bancaria.dart

class ModeloCuentaBancaria {
  final String id;
  final String usuarioId;
  final String cbuCvu;
  final String? aliasBancario;
  final String? bancoProveedor;
  final String? titularCuenta;
  final String? cuitDniTitular;
  final bool esActiva;
  final DateTime? fechaEliminacion;
  final DateTime fechaAlta;

  const ModeloCuentaBancaria({
    required this.id,
    required this.usuarioId,
    required this.cbuCvu,
    this.aliasBancario,
    this.bancoProveedor,
    this.titularCuenta,
    this.cuitDniTitular,
    this.esActiva = true,
    this.fechaEliminacion,
    required this.fechaAlta,
  });

  factory ModeloCuentaBancaria.fromJson(Map<String, dynamic> json) {
    return ModeloCuentaBancaria(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString() ?? '',
      cbuCvu: json['cbu_cvu']?.toString() ?? '',
      aliasBancario: json['alias_bancario']?.toString(),
      bancoProveedor: json['banco_proveedor']?.toString(),
      titularCuenta: json['titular_cuenta']?.toString(),
      cuitDniTitular: json['cuit_dni_titular']?.toString(),
      esActiva: json['es_activa'] == true,
      fechaEliminacion: json['fecha_eliminacion'] != null ? DateTime.tryParse(json['fecha_eliminacion'].toString()) : null,
      fechaAlta: json['fecha_alta'] != null ? DateTime.tryParse(json['fecha_alta'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'cbu_cvu': cbuCvu,
    'alias_bancario': aliasBancario,
    'banco_proveedor': bancoProveedor,
    'titular_cuenta': titularCuenta,
    'cuit_dni_titular': cuitDniTitular,
    'es_activa': esActiva,
    'fecha_eliminacion': fechaEliminacion?.toIso8601String(),
    'fecha_alta': fechaAlta.toIso8601String(),
  };
}