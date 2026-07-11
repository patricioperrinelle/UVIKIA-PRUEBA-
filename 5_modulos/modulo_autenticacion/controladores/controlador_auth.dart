// lib/5_modulos/modulo_autenticacion/controladores/controlador_auth.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../servicios/servicio_auth_supabase.dart';
import '../../modulo_perfil_usuario/servicios/servicio_perfil_supabase.dart'; 
import '../../../1_nucleo/servicio_supabase_base.dart';

class ControladorAuth extends ChangeNotifier {
  static final ControladorAuth instancia = ControladorAuth._();
  ControladorAuth._();

  // Bóveda de Estado
  bool isLoading = false;
  int fastLoginLoading = -1; 
  bool esRegistroProfesional = false;
  
  // Variables del Registro
  String dniEscaneado = '';
  DateTime? fechaNacimiento;
  List<String> nombresPublicosDisponibles = [];
  String nombrePublicoElegido = '';
  String fotoPerfilPath = ''; 
  List<String> portfolioImagesPaths = [];

  final PageController pageController = PageController();
  int currentIndex = 0;
  bool abrirScanner = false; 
  bool escaneoExitoso = false; 
  bool ocultarClave = true;

  final TextEditingController regEmailCtrl = TextEditingController();
  final TextEditingController regPassCtrl = TextEditingController();
  
  // 🛡️ REGLA DATA INTEGRITY (Provincias Estrictas)
  String? provinciaSeleccionada;
  final TextEditingController localidadCtrl = TextEditingController();
  final TextEditingController barrioCtrl = TextEditingController();

  // 🛡️ REGLA DATA INTEGRITY (Oficios)
  String? oficioPrincipal;
  List<String> oficiosSecundarios = [];

  final TextEditingController habEspecialesCtrl = TextEditingController();
  final TextEditingController certsCtrl = TextEditingController();
  final TextEditingController zonaCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();
  final TextEditingController horariosCtrl = TextEditingController();
  final TextEditingController tiempoRespCtrl = TextEditingController();
  final TextEditingController expCtrl = TextEditingController();
  final TextEditingController garantiaCtrl = TextEditingController();

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // ==========================================
  // 🔐 FLUJOS DE LOGIN Y RECUPERACIÓN 
  // ==========================================

  Future<void> iniciarSesion(String email, String password) async {
    _setLoading(true);
    try {
      await ServicioAuthSupabase.iniciarSesion(email, password);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginRapido(int index, String email) async {
    fastLoginLoading = index;
    notifyListeners();
    try {
      await ServicioAuthSupabase.iniciarSesion(email, '123456');
    } catch (e) {
      throw Exception("Error de Testing: ${e.toString()}");
    } finally {
      fastLoginLoading = -1;
      notifyListeners();
    }
  }

  Future<void> recuperarPassword(String email) async {
    _setLoading(true);
    try {
      await ServicioAuthSupabase.recuperarPassword(email);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> recuperarPasswordConDni(String rawData) async {
    _setLoading(true);
    try {
      final parts = rawData.split('@');
      if (parts.length < 7) throw Exception("Código no reconocido.");
      String dniStr = parts[4].trim();
      await ServicioAuthSupabase.recuperarPasswordPorDni(dniStr);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cerrarSesion() async {
    await ServicioAuthSupabase.cerrarSesion();
  }

  // ==========================================
  // 👤 ORQUESTACIÓN DE LA VISTA DE REGISTRO
  // ==========================================

  void iniciarFlujoRegistro(bool comoProfesional) {
    esRegistroProfesional = comoProfesional;
    currentIndex = 0;
    abrirScanner = false;
    escaneoExitoso = false;
    ocultarClave = true;

    dniEscaneado = '';
    nombresPublicosDisponibles.clear();
    nombrePublicoElegido = '';
    fotoPerfilPath = '';
    portfolioImagesPaths.clear();
    
    oficioPrincipal = null;
    oficiosSecundarios.clear();
    provinciaSeleccionada = null; // 🛡️ Vaciado estricto
    
    regEmailCtrl.clear(); regPassCtrl.clear(); 
    localidadCtrl.clear(); barrioCtrl.clear(); habEspecialesCtrl.clear(); certsCtrl.clear();
    zonaCtrl.clear(); bioCtrl.clear(); horariosCtrl.clear();
    tiempoRespCtrl.clear(); expCtrl.clear(); garantiaCtrl.clear();
    
    notifyListeners();
    if (pageController.hasClients) pageController.jumpToPage(0);
  }

  void setIndex(int idx) {
    currentIndex = idx;
    notifyListeners();
  }

  void setAbrirScanner(bool val) {
    abrirScanner = val;
    notifyListeners();
  }

  void setEscaneoExitoso(bool val) {
    escaneoExitoso = val;
    notifyListeners();
  }

  void toggleOcultarClave() {
    ocultarClave = !ocultarClave;
    notifyListeners();
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

  void validarAvance() {
    if (currentIndex == 2) {
      if (fotoPerfilPath.isEmpty) throw Exception('Debes subir una foto de perfil real.');
      if (nombrePublicoElegido.isEmpty) throw Exception('Selecciona cómo quieres que te llamemos.');
      
      // 🛡️ Validación Estricta de Geografía
      if (provinciaSeleccionada == null || provinciaSeleccionada!.isEmpty || localidadCtrl.text.trim().isEmpty) {
        throw Exception('La Provincia y la Localidad son obligatorias.');
      }
    } else if (currentIndex == 3 && esRegistroProfesional) {
      if (oficioPrincipal == null || oficioPrincipal!.isEmpty) throw Exception('Tu Oficio Principal es obligatorio.');
      if (zonaCtrl.text.trim().isEmpty) throw Exception('Tu Zona de Trabajo es obligatoria.');
    }
  }

  void avanzarPagina() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (pageController.hasClients) {
      pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void retrocederPagina() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (currentIndex == 1 && abrirScanner) {
      setAbrirScanner(false);
      return;
    }
    if (pageController.hasClients) {
      pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void setNombreElegido(String val) {
    nombrePublicoElegido = val;
    notifyListeners();
  }

  // ==========================================
  // 📸 GESTIÓN DE HARDWARE (CÁMARA / GALERÍA)
  // ==========================================

  Future<void> tomarFotoRegistro(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      fotoPerfilPath = image.path;
      notifyListeners();
    }
  }

  Future<void> tomarFotoPortfolio() async {
    if (portfolioImagesPaths.length >= 5) {
      throw Exception('Máximo 5 fotos permitidas.');
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      portfolioImagesPaths.insert(0, image.path);
      notifyListeners();
    }
  }

  void removerFotoPortfolio(String path) {
    portfolioImagesPaths.remove(path);
    notifyListeners();
  }

  Future<void> procesarEscaneoDni(String rawData) async {
    if (escaneoExitoso || isLoading) return;
    
    try {
      _setLoading(true);
      final parts = rawData.split('@');
      if (parts.length < 7) throw Exception("Formato de DNI no reconocido.");

      String apellido = parts[1].trim();
      String nombre = parts[2].trim();
      String dniStr = parts[4].trim();
      String fechaNacStr = parts[6].trim();

      if (int.tryParse(dniStr) == null) throw Exception("Lectura defectuosa.");
      
      bool existe = await ServicioAuthSupabase.existeDni(dniStr);
      if (existe) throw Exception("Este DNI ya está registrado.");

      final partesFecha = fechaNacStr.split('/');
      if (partesFecha.length == 3) {
        int? anio = int.tryParse(partesFecha[2]);
        int? mes = int.tryParse(partesFecha[1]);
        int? dia = int.tryParse(partesFecha[0]);
        if (anio != null && mes != null && dia != null) {
          fechaNacimiento = DateTime(anio, mes, dia);
        }
      }

      String inicialApellido = apellido.isNotEmpty ? "${apellido[0]}." : "";
      final nombres = nombre.split(' ');
      nombresPublicosDisponibles.clear();
      
      if (nombres.isNotEmpty) {
        nombresPublicosDisponibles.add("${nombres[0]} $inicialApellido");
        if (nombres.length > 1) {
          nombresPublicosDisponibles.add("${nombres[1]} $inicialApellido");
        }
      }
      
      if (nombresPublicosDisponibles.isNotEmpty) {
        nombrePublicoElegido = nombresPublicosDisponibles.first;
      }

      dniEscaneado = dniStr;
      setEscaneoExitoso(true);
    } catch (e) {
      setEscaneoExitoso(false);
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  String _generarCodigoInteligente(String nombre) {
    String letras = nombre.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    if (letras.length > 3) letras = letras.substring(0, 3);
    if (letras.length < 3) letras = letras.padRight(3, 'X');
    final rng = Random();
    String numeros = (rng.nextInt(90000) + 10000).toString();
    return "#$letras-$numeros";
  }

  // ==========================================
  // ⚡ EJECUCIÓN ATÓMICA DE REGISTRO
  // ==========================================

  Future<String> ejecutarRegistroFinal() async {
    final email = regEmailCtrl.text.trim();
    final password = regPassCtrl.text.trim();

    if (email.isEmpty || password.length < 6) {
      throw Exception('Ingresa un correo válido y una contraseña segura de mínimo 6 caracteres.');
    }

    _setLoading(true);
    List<String> urlsSubidasAR2 = []; 
    
    try {
      String uid = await ServicioAuthSupabase.crearCuentaAuth(email, password);

      String urlFotoSubida = await ServicioPerfilSupabase.subirImagen(fotoPerfilPath);
      urlsSubidasAR2.add(urlFotoSubida);

      List<String> urlsPortfolioNube = [];
      if (esRegistroProfesional && portfolioImagesPaths.isNotEmpty) {
        for (String path in portfolioImagesPaths) {
          String urlPort = await ServicioPerfilSupabase.subirImagen(path);
          urlsSubidasAR2.add(urlPort);
          urlsPortfolioNube.add(urlPort);
        }
      }

      String codigoGenerado = _generarCodigoInteligente(nombrePublicoElegido);
      
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error obteniendo FCM Token durante el registro: $e');
      }
      
      // Formateo de Payload SQL V5.4 (Oficios)
      String oficiosConcatenados = '';
      if (esRegistroProfesional && oficioPrincipal != null) {
        final listaPura = [oficioPrincipal!];
        listaPura.addAll(oficiosSecundarios);
        oficiosConcatenados = listaPura.join(',');
      }

      Map<String, dynamic> payload = {
        'id': uid,
        'email': email,
        'apodo': nombrePublicoElegido,
        'dni': dniEscaneado,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'foto_url': urlFotoSubida, 
        'fcm_token': fcmToken,
        
        // 🛡️ REGLA DATA INTEGRITY (Provincias Estrictas)
        'ciudad': provinciaSeleccionada,
        
        'localidad': localidadCtrl.text.trim(),
        'barrio': barrioCtrl.text.trim(),
        'codigo_compartible': codigoGenerado,
        'es_profesional': esRegistroProfesional,

        'promedio_estrellas': 5.0,
        'score_confiabilidad_cliente': 100.0,
        'recomendacion_trabajadores': 100.0, 

        if (esRegistroProfesional) ...{
          'habilidad_principal': oficioPrincipal,
          'habilidades_secundarias': oficiosSecundarios,
          'habilidades_especiales': habEspecialesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'certificaciones': certsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'oficios': oficiosConcatenados, 
          'bio': bioCtrl.text.trim(),
          'zona_trabajo': zonaCtrl.text.trim(),
          'horarios': horariosCtrl.text.trim(),
          'experiencia_anos': expCtrl.text.trim(),
          'garantia_dias': garantiaCtrl.text.trim(),
          'tiempo_respuesta': tiempoRespCtrl.text.trim(),
          'fotos_portafolio': urlsPortfolioNube,

          'rating_profesional': 5.0,
          'score_confiabilidad_pro': 100.0,
          'puntualidad': 100.0,
          'asistencia': 100.0,
          'jornadas_completadas': 100.0,
          'recomendacion_clientes': 100.0,
        }
      };

      await ServicioAuthSupabase.insertarPerfil(payload);
      return codigoGenerado;

    } catch (e) {
      for (String urlBasura in urlsSubidasAR2) { await SupabaseService.deleteImage(urlBasura); }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }
}