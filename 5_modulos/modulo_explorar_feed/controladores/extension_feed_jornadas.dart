// lib/5_modulos/modulo_explorar_feed/controladores/extension_feed_jornadas.dart
part of 'controlador_feed_jornadas.dart';

extension ExtensionJornadas on ControladorFeedJornadas {

  Future<void> _fetchJornadasSiguientePagina() async {
    final genActual = _generacionJornadas;
    try {
      final ciudadBusqueda = provinciaFiltro;
      final localidadBusqueda = localidadFiltro;
      
      List<Map<String, dynamic>> rawJobs = await ServicioFeedSupabase.obtenerJornadasPaginadasV5(
        ciudad: ciudadBusqueda, 
        localidad: localidadBusqueda,
        categoria: categoriaFiltro,
        keyword: palabraClave,
        cursorEsCiudad: _motorJornadas.cursor.esCiudad,
        cursorEsLocalidad: _motorJornadas.cursor.esLocalidad,
        cursorRank: _motorJornadas.cursor.rank,
        cursorRotacion: _motorJornadas.cursor.rotacion,
        cursorFecha: _motorJornadas.cursor.fecha, 
        cursorId: _motorJornadas.cursor.id,
        limit: 20, 
      );

      if (genActual != _generacionJornadas) return;

      if (_isRefreshJornadas) {
        _motorJornadas.elementos.clear(); 
        _isRefreshJornadas = false;
      }

      rawJobs.removeWhere((job) => misPostulacionesIds.contains(job['id']));

      if (rawJobs.isNotEmpty) {
        final last = rawJobs.last;
        
        _motorJornadas.cursor.esCiudad = ciudadBusqueda.isNotEmpty && (last['ciudad'] == ciudadBusqueda);
        _motorJornadas.cursor.esLocalidad = localidadBusqueda.isNotEmpty && (last['localidad'] == localidadBusqueda);
        
        _motorJornadas.cursor.rank = (last['rank_calc'] as num?)?.toDouble() ?? 0.0;
        _motorJornadas.cursor.rotacion = (last['rotacion_calc'] as num?)?.toInt() ?? 2147483647;
        _motorJornadas.cursor.fecha = last['fecha_hora'] ?? '2000-01-01T00:00:00Z'; 
        _motorJornadas.cursor.id = last['id'] ?? '00000000-0000-0000-0000-000000000000';
        
        final nuevos = await compute(_mapearListaJornadasBackground, rawJobs);
        
        _motorJornadas.anexarPaginaSegura(nuevos, esRefresh: false);
        
      } else {
        _motorJornadas.hasReachedMax = true;
        _motorJornadas.anexarPaginaSegura([], esRefresh: false);
      }
    } catch (e) { debugPrint('Error Jornadas V5.7: $e'); }
  }

  Future<List<ModeloJornada>> obtenerPagina1JornadasSilenciosa() async {
    try {
      final cursorLimpio = CursorTuplaV5();
      
      List<Map<String, dynamic>> rawJobs = await ServicioFeedSupabase.obtenerJornadasPaginadasV5(
        ciudad: provinciaFiltro, 
        localidad: localidadFiltro,
        categoria: categoriaFiltro, 
        keyword: palabraClave,      
        cursorEsCiudad: cursorLimpio.esCiudad,
        cursorEsLocalidad: cursorLimpio.esLocalidad,
        cursorRank: cursorLimpio.rank,
        cursorRotacion: cursorLimpio.rotacion,
        cursorFecha: cursorLimpio.fecha, 
        cursorId: cursorLimpio.id,
        limit: 20, 
      );

      rawJobs.removeWhere((job) => misPostulacionesIds.contains(job['id']));

      if (rawJobs.isEmpty) return [];

      return await compute(_mapearListaJornadasBackground, rawJobs);
    } catch (e) {
      debugPrint('SWR-Titan: Error Extracción SWR Silenciosa (Jornadas): $e');
      return [];
    }
  }
}

List<ModeloJornada> _mapearListaJornadasBackground(List<Map<String, dynamic>> rawList) {
  return rawList.map((row) => _mapearJornadaUnica(row)).toList();
}

ModeloJornada _mapearJornadaUnica(Map<String, dynamic> row) {
  String baseDesc = row['descripcion']?.toString() ?? '';
  String mappedPrice = row['precio']?.toString() ?? '\$ 0';
  String mappedUbicacionExacta = row['ubicacion_exacta']?.toString() ?? '';
  String mappedLocalidad = row['localidad']?.toString() ?? '';
  String mappedOficio = row['oficio']?.toString() ?? '';
  String mappedCategoria = row['categoria']?.toString() ?? 'Otros'; 
  String mappedDificultad = row['dificultad']?.toString() ?? '1';
  String mappedHoraFin = row['hora_fin']?.toString() ?? '';
  String mappedRequisitos = row['requisitos']?.toString() ?? '';
  
  List<String> mappedImages = [];
  if (row['imagenes'] != null && row['imagenes'] is List) {
    mappedImages = (row['imagenes'] as List).map((e) => e.toString().trim()).toList();
  }

  try {
    if (baseDesc.trim().startsWith('{')) {
      final mapped = jsonDecode(baseDesc);
      if (mapped is Map) {
        baseDesc = mapped['desc']?.toString() ?? baseDesc;
        if (mappedPrice == '\$ 0' || mappedPrice.isEmpty) mappedPrice = mapped['price']?.toString() ?? '\$ 0';
        if (mappedUbicacionExacta.isEmpty) mappedUbicacionExacta = mapped['ubicacion_exacta']?.toString() ?? '';
        if (mappedLocalidad.isEmpty) mappedLocalidad = mapped['localidad']?.toString() ?? '';
        if (mappedRequisitos.isEmpty && mapped['requisitos'] != null) mappedRequisitos = mapped['requisitos'].toString();
        if (mappedLocalidad.isEmpty && mappedUbicacionExacta.isNotEmpty) {
          final partes = mappedUbicacionExacta.split(',');
          mappedLocalidad = partes.length >= 2 ? 'Aprox. 2.5km · ${partes[1].trim()}' : 'Aprox. 2.5km · Cercanías';
        }
        if (mappedImages.isEmpty && mapped['images'] != null && mapped['images'] is List) {
          mappedImages = (mapped['images'] as List).map((e) => e.toString().trim()).toList();
        }
        if (mappedOficio.isEmpty) mappedOficio = mapped['oficio']?.toString() ?? '';
        if (mappedDificultad == '1') mappedDificultad = mapped['dificultad']?.toString() ?? '1';
      }
    }
  } catch (_) {}

  final p = row['perfil'] is Map ? row['perfil'] as Map : {};
  final double finalRating = (p['promedio_estrellas'] as num?)?.toDouble() ?? 5.0;
  final int finalReviews = (p['cantidad_resenas_cliente'] as num?)?.toInt() ?? 0;

  final jobMap = {
    'id': row['id'].toString(), 
    'titulo': row['titulo']?.toString() ?? '', 
    'localidad': mappedLocalidad, 
    'ubicacionExacta': mappedUbicacionExacta, 
    'precio': mappedPrice, 
    'descripcion': baseDesc, 
    'requisitos': mappedRequisitos,
    'fechaHora': row['fecha_hora'], 
    'hora_fin': mappedHoraFin,
    'fechaCreacion': row['created_at'] ?? row['fecha_creacion'] ?? row['fecha_hora'], 
    'contraparteNombre': 'Cliente: ${p['apodo']?.toString() ?? p['nombre']?.toString() ?? 'Anónimo'}', 
    'contraparteAvatar': p['avatar_url']?.toString() ?? '', 
    'ratingContraparte': finalRating, 
    'reviewsContraparte': finalReviews, 
    'ownerId': row['cliente_id']?.toString() ?? row['usuario_id']?.toString(), 
    'images': mappedImages, 
    'imagenes': mappedImages, 
    'estado': row['estado']?.toString() ?? 'abierto',
    'oficio': mappedOficio, 
    'categoria': mappedCategoria, 
    'dificultad': mappedDificultad,
    'whatsapp': row['telefono_contacto']?.toString() ?? '',
    'cantidadPujasTotales': row['cantidad_pujas'], 
  };

  return ModeloJornada.fromJson(jobMap);
}
