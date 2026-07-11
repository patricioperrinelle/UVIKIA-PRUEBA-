// lib/3_modelos/modelo_resena_payload.dart

class ModeloResenaPayload {
  final int rating;
  final String comentario;
  final String metodoPago;
  
  // Chips Reactivos de UX (Mapeados para el backend histórico)
  final bool esPuntualORespetuoso;
  final bool esRecomendadoOClaro;

  // Nuevas Métricas Granulares de Calificación
  final bool esPuntual; 
  final bool loRecomienda; 
  final bool? tratoRespetuoso; 
  final bool descripcionPrecisa; 

  // 🛡️ EL ESCUDO DE RESEÑAS HÍBRIDO
  final bool esComentarioPrivado;
  final List<String> etiquetasNegativas;

  // 🚨 LA TRAMPA DEL COMPILADOR:
  // Al poner esto como "required", Flutter te marcará en rojo el archivo 
  // exacto donde se crea este payload porque le faltará este dato.
  final String rolEvaluado; 

  ModeloResenaPayload({
    required this.rating,
    this.comentario = '',
    required this.metodoPago,
    required this.esPuntualORespetuoso,
    required this.esRecomendadoOClaro,
    this.esPuntual = false,
    this.loRecomienda = false,
    this.tratoRespetuoso,
    this.descripcionPrecisa = false,
    this.esComentarioPrivado = false, // Por defecto público
    this.etiquetasNegativas = const [], // Vacío por defecto
    required this.rolEvaluado, // 🚨 EXIGIDO ESTRICTAMENTE AHORA
  });
}