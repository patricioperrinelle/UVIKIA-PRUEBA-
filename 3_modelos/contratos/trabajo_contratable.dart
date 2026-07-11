import '../modelo_puja.dart';
import 'dominio_app.dart';

abstract class TrabajoContratable {
  String get id;
  String get titulo;
  String get descripcion;
  String get precio;
  String get fechaHora;
  String? get horaFin;
  String get fechaCreacion;
  List<String> get imagenes;
  String get estado;
  String get ownerId;
  String get localidad;
  String get ubicacionExacta;
  String get dificultad;

  List<ModeloPuja> get pujas;
  int get cantidadPujasTotales;
  String? get miOferta;
  bool? get aceptoPrecioBase;
  String? get estadoNegociacion;
  String? get pujaId;

  String? get profesionalSolicitadoId;
  String? get profesionalAsignadoId;
  String? get precioFinalAcordado;
  String get metodoPago;

  int get mensajesNoLeidos;
  bool get clienteCalifico;
  bool get proCalifico;

  // Getters comunes calculados
  DominioApp get dominio;
  bool get tuvoContratoAlgunaVez;
  double get precioTotalFinal;

  Map<String, dynamic> toJson();
}
