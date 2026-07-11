// lib/5_modulos/modulo_perfil_usuario/controladores/controlador_edicion_perfil.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../servicios/servicio_perfil_supabase.dart';
import '../../../3_modelos/modelo_perfil.dart';
import '../../../1_nucleo/servicio_supabase_base.dart';

class ControladorEdicionPerfil extends ChangeNotifier {
  bool isSubmitting = false;

  final TextEditingController apodoCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();
  final TextEditingController horariosCtrl = TextEditingController();
  final TextEditingController expCtrl = TextEditingController();
  final TextEditingController garantiaCtrl = TextEditingController();
  final TextEditingController zonaCtrl = TextEditingController();
  final TextEditingController tiempoRespCtrl = TextEditingController();

  // 🛡️ REGLA DATA INTEGRITY (Provincias Estrictas)
  String? provinciaSeleccionada;
  final TextEditingController localidadCtrl = TextEditingController();
  final TextEditingController barrioCtrl = TextEditingController();

  // 🛡️ REGLA DATA INTEGRITY (Oficios Estrictos)
  String? oficioPrincipal;
  List<String> oficiosSecundarios = [];

  final TextEditingController habilidadesEspecialesCtrl = TextEditingController();
  final TextEditingController certificacionesCtrl = TextEditingController();

  String profileImage = '';
  String _avatarOriginalUrl = ''; 
  List<String> portfolioImages = []; 
  List<String> urlsAEliminarDeR2 = []; 

  void inicializar(ModeloPerfil perfilActual) {
    final pro = perfilActual.perfilProfesional;
    apodoCtrl.text = perfilActual.apodo;
    profileImage = perfilActual.fotoUrl;
    _avatarOriginalUrl = perfilActual.fotoUrl; 
    
    // 🛡️ Mapeo a estado inmutable geográfico
    provinciaSeleccionada = perfilActual.ciudad.isNotEmpty ? perfilActual.ciudad : null;
    
    localidadCtrl.text = perfilActual.localidad;
    barrioCtrl.text = perfilActual.barrio;

    bioCtrl.text = pro?.bio ?? '';
    horariosCtrl.text = pro?.horarios ?? 'Lunes a Sábados de 08:00 a 18:00 hs';
    expCtrl.text = (pro?.experienciaAnos == '0' || pro?.experienciaAnos == null) ? '' : pro!.experienciaAnos;
    garantiaCtrl.text = (pro?.garantiaDias == '0' || pro?.garantiaDias == null) ? '' : pro!.garantiaDias;
    zonaCtrl.text = pro?.zonaTrabajo ?? '';
    tiempoRespCtrl.text = pro?.tiempoRespuesta ?? '';
    
    // 🛡️ Mapeo a estado inmutable de oficios
    oficioPrincipal = pro?.habilidadPrincipal;
    oficiosSecundarios = List.from(pro?.habilidadesSecundarias ?? []);

    habilidadesEspecialesCtrl.text = pro?.habilidadesEspeciales.join(', ') ?? '';
    certificacionesCtrl.text = pro?.certificaciones.join(', ') ?? '';
    
    portfolioImages = List<String>.from(pro?.fotosPortafolio ?? []);
    urlsAEliminarDeR2.clear(); 
  }

  void disposeControllers() {
    apodoCtrl.dispose(); bioCtrl.dispose(); horariosCtrl.dispose();
    expCtrl.dispose(); garantiaCtrl.dispose(); zonaCtrl.dispose();
    tiempoRespCtrl.dispose(); 
    localidadCtrl.dispose(); barrioCtrl.dispose(); 
    habilidadesEspecialesCtrl.dispose(); certificacionesCtrl.dispose();
  }

  // 🛡️ MÉTODOS DE ESTADO ESTRICTOS
  void setProvincia(String prov) {
    provinciaSeleccionada = prov;
    notifyListeners();
  }

  void setOficioPrincipal(String oficio) {
    oficioPrincipal = oficio;
    if (oficiosSecundarios.contains(oficio)) {
      oficiosSecundarios.remove(oficio);
    }
    notifyListeners();
  }

  void setOficiosSecundarios(List<String> oficios) {
    oficiosSecundarios = oficios;
    notifyListeners();
  }

  Future<void> cambiarFotoPerfil(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      profileImage = image.path; 
      notifyListeners();
    }
  }

  Future<void> agregarFotoPortfolioCamara() async {
    if (portfolioImages.length >= 5) {
      throw Exception('Límite estricto excedido: Máximo 5 fotos permitidas.');
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      portfolioImages.insert(0, image.path);
      notifyListeners();
    }
  }

  void agregarMultiplesFotosPortfolio(List<String> paths) {
    if (portfolioImages.length + paths.length > 5) {
      throw Exception('Límite estricto excedido: Máximo 5 fotos permitidas en total.');
    }
    for (String path in paths) {
      portfolioImages.insert(0, path);
    }
    notifyListeners();
  }

  void eliminarFotoPortfolio(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) urlsAEliminarDeR2.add(pathOrUrl);
    portfolioImages.remove(pathOrUrl);
    notifyListeners();
  }

  // 🚀 CEREBRO PURO: Retorna void o lanza Excepciones. Cero UI.
  Future<void> guardarCambios({required String miId, bool esPrimerOnboarding = false}) async {
    if (portfolioImages.length > 5) {
      throw Exception('Máximo 5 fotos permitidas en el portfolio.');
    }
    
    // 🛡️ Validación Estricta de Geografía
    if (provinciaSeleccionada == null || provinciaSeleccionada!.isEmpty || localidadCtrl.text.trim().isEmpty) {
      throw Exception('La Provincia y la Localidad son obligatorias.');
    }

    if (esPrimerOnboarding) {
      if (oficioPrincipal == null || oficioPrincipal!.isEmpty) {
        throw Exception('Tu Oficio Principal es obligatorio para crear el perfil.');
      }
      if (zonaCtrl.text.trim().isEmpty) {
        throw Exception('Debes establecer tu Zona de Trabajo para crear el perfil.');
      }
    }

    isSubmitting = true;
    notifyListeners();
    
    List<String> nuevasSubidasEnR2 = []; 

    try {
      String urlPerfilFinal = profileImage;
      if (profileImage.isNotEmpty && !profileImage.startsWith('http')) {
        urlPerfilFinal = await ServicioPerfilSupabase.subirImagen(profileImage);
        nuevasSubidasEnR2.add(urlPerfilFinal); 
        if (_avatarOriginalUrl.startsWith('http')) urlsAEliminarDeR2.add(_avatarOriginalUrl);
      }

      List<String> urlsPortfolioFinales = [];
      for (String path in portfolioImages) {
        if (!path.startsWith('http') && path.trim().isNotEmpty) {
          final url = await ServicioPerfilSupabase.subirImagen(path);
          if (url.isNotEmpty) {
            urlsPortfolioFinales.add(url);
            nuevasSubidasEnR2.add(url); 
          }
        } else if (path.trim().isNotEmpty) {
          urlsPortfolioFinales.add(path);
        }
      }

      List<String> parsearLista(String texto) {
        if (texto.trim().isEmpty) return <String>[];
        return texto.split(',').map((e) => e.trim()).toList();
      }

      // 🛡️ REGLA 2: Formateo Exacto del Payload SQL V5.4 (string_to_array)
      String oficiosConcatenados = '';
      if (oficioPrincipal != null && oficioPrincipal!.isNotEmpty) {
        final listaPura = [oficioPrincipal!];
        listaPura.addAll(oficiosSecundarios);
        oficiosConcatenados = listaPura.join(','); 
      }

      final payload = {
        'apodo': apodoCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'horarios': horariosCtrl.text.trim(),
        'experiencia_anos': expCtrl.text.isEmpty ? '0' : expCtrl.text.trim(),
        'garantia_dias': garantiaCtrl.text.isEmpty ? '0' : garantiaCtrl.text.trim(),
        'zona_trabajo': zonaCtrl.text.trim(),
        'tiempo_respuesta': tiempoRespCtrl.text.trim(),
        'fotos_portafolio': urlsPortfolioFinales,
        'foto_url': urlPerfilFinal,
        
        // 🛡️ REGLA DATA INTEGRITY (Provincias Estrictas)
        'ciudad': provinciaSeleccionada,
        
        'localidad': localidadCtrl.text.trim(),
        'barrio': barrioCtrl.text.trim(),
        
        'habilidad_principal': oficioPrincipal,
        'habilidades_secundarias': oficiosSecundarios,
        'habilidades_especiales': parsearLista(habilidadesEspecialesCtrl.text),
        'certificaciones': parsearLista(certificacionesCtrl.text),
        
        // 🚀 ALGORITMO O(1) PROTEGIDO
        'oficios': oficiosConcatenados,

        if (esPrimerOnboarding) ...{
          'es_profesional': true,
          'rating_profesional': 5.0,
          'score_confiabilidad_pro': 100.0,
          'puntualidad': 100.0,
          'asistencia': 100.0,
          'jornadas_completadas': 100.0,
          'recomendacion_clientes': 100.0,
        }
      };

      await ServicioPerfilSupabase.actualizarPerfil(miId, payload);

      for (String urlBasura in urlsAEliminarDeR2) {
        await SupabaseService.deleteImage(urlBasura);
      }
      urlsAEliminarDeR2.clear();
      nuevasSubidasEnR2.clear();

    } catch (e) {
      for (String urlNueva in nuevasSubidasEnR2) {
        await SupabaseService.deleteImage(urlNueva);
      }
      nuevasSubidasEnR2.clear();
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}