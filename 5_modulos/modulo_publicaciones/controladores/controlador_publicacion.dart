// lib/5_modulos/modulo_publicaciones/controladores/controlador_publicacion.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:provider/provider.dart';

import '../servicios/servicio_publicaciones_supabase.dart';
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_exito_cristal.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../1_nucleo/servicio_supabase_base.dart';

class ControladorPublicacion extends ChangeNotifier {
  bool isSubmitting = false;

  final TextEditingController tituloCtrl = TextEditingController();
  final TextEditingController oficioCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController whatsappCtrl = TextEditingController();
  final TextEditingController sueldoCtrl = TextEditingController();
  
  final TextEditingController calleCtrl = TextEditingController();
  final TextEditingController numeroCtrl = TextEditingController();
  final TextEditingController referenciaCtrl = TextEditingController();
  
  // 🛡️ REGLA DATA INTEGRITY: Variable estricta para la provincia
  String? provinciaSeleccionada;
  final TextEditingController localidadCtrl = TextEditingController();
  final TextEditingController barrioCtrl = TextEditingController();
  final TextEditingController paisCtrl = TextEditingController(text: 'Argentina');
  
  final TextEditingController herramientasCtrl = TextEditingController();

  String categoriaSeleccionada = ''; 
  int dificultad = 1;
  bool traerHerramientas = false;
  
  DateTime? fechaElegida;
  TimeOfDay? horaElegida;
  TimeOfDay? horaFinElegida;
  
  List<String> imagenes = [];
  List<String> urlsAEliminarDeR2 = []; 
  
  String? trabajoAEditarId;
  String? proSolicitadoId; 

  void _mostrarMensaje(BuildContext context, String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: esError ? ColoresApp.errorRojo : ColoresApp.primarioVerde,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarDialogoExito(BuildContext context, String titulo, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogoExitoCristal(
        titulo: titulo,
        mensaje: mensaje,
        onAceptar: () {
          Navigator.pop(ctx); 
          if (context.mounted) Navigator.pop(context); 
        },
      ),
    );
  }

  void setCategoria(String nueva) {
    categoriaSeleccionada = nueva;
    notifyListeners();
  }

  // 🛡️ Callback para el BottomSheet de Provincia
  void setProvincia(String prov) {
    provinciaSeleccionada = prov;
    notifyListeners();
  }

  void setDificultad(int valor) {
    dificultad = valor;
    notifyListeners();
  }

  void toggleHerramientas(bool? valor) {
    traerHerramientas = valor ?? false;
    notifyListeners();
  }

  void setFechaHora(DateTime? f, TimeOfDay? h, {TimeOfDay? hFin}) {
    if (f != null) fechaElegida = f;
    if (h != null) horaElegida = h;
    if (hFin != null) horaFinElegida = hFin;
    notifyListeners();
  }

  Future<void> agregarImagenes(BuildContext context, ImageSource source) async {
    if (imagenes.length >= 5) {
      _mostrarMensaje(context, 'Máximo 5 imágenes permitidas.');
      return;
    }

    if (source == ImageSource.camera) {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        imagenes.add(image.path);
        notifyListeners();
      }
    } else {
      int allowed = 5 - imagenes.length;
      final List<AssetEntity>? pickedFiles = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(maxAssets: allowed, requestType: RequestType.image),
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var entity in pickedFiles) {
          final file = await entity.file;
          if (file != null) imagenes.add(file.path);
        }
        notifyListeners();
      }
    }
  }

  void eliminarImagen(int index) {
    final String urlObjetivo = imagenes[index];
    if (urlObjetivo.startsWith('http')) {
      urlsAEliminarDeR2.add(urlObjetivo);
    }
    imagenes.removeAt(index);
    notifyListeners();
  }

  void precargarDatosEdicion(Map<String, dynamic> data) {
    trabajoAEditarId = data['id']?.toString();
    tituloCtrl.text = data['title'] ?? data['titulo'] ?? '';
    oficioCtrl.text = data['oficio'] ?? '';
    categoriaSeleccionada = data['categoria']?.toString() ?? ''; 
    whatsappCtrl.text = data['whatsapp'] ?? data['telefono_contacto'] ?? '';
    dificultad = int.tryParse(data['dificultad']?.toString() ?? '1') ?? 1;
    
    String rawDesc = data['descripcion'] ?? data['desc'] ?? '';
    if (rawDesc.contains('Notas del cliente:')) {
      final partes = rawDesc.split('Notas del cliente:');
      descCtrl.text = partes[0].trim();
      if (partes.length > 1) {
        referenciaCtrl.text = partes[1].trim();
      }
    } else {
      descCtrl.text = rawDesc;
    }
    
    herramientasCtrl.text = data['requisitos'] ?? '';
    traerHerramientas = herramientasCtrl.text.isNotEmpty;

    String ubicacionPactada = data['ubicacion_exacta'] ?? '';
    if (ubicacionPactada.contains('||')) {
      List<String> partes = ubicacionPactada.split('||');
      if (partes.length >= 6) {
        calleCtrl.text = partes[0];
        numeroCtrl.text = partes[1];
        barrioCtrl.text = partes[2];
        localidadCtrl.text = partes[3];
        provinciaSeleccionada = partes[4]; // 🛡️ Carga inmutable de la provincia vieja
        paisCtrl.text = partes[5];
      }
    } else {
      List<String> partesUbi = ubicacionPactada.split(',');
      calleCtrl.text = partesUbi.isNotEmpty ? partesUbi[0].trim() : '';
      localidadCtrl.text = partesUbi.length > 1 ? partesUbi[1].trim() : '';
      provinciaSeleccionada = partesUbi.length > 2 ? partesUbi[2].trim() : null; // 🛡️
      paisCtrl.text = partesUbi.length > 3 ? partesUbi[3].trim() : 'Argentina';
    }

    String dateStr = data['fecha_hora'] ?? data['date'] ?? '';
    if (dateStr.isNotEmpty) {
      try {
        DateTime parsed = DateTime.parse(dateStr).toLocal();
        fechaElegida = parsed;
        horaElegida = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {}
    }
    
    String horaFinStr = data['hora_fin']?.toString() ?? '';
    if (horaFinStr.isNotEmpty && horaFinStr.contains(':')) {
       final p = horaFinStr.split(':');
       horaFinElegida = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }

    if (data['imagenes'] != null && data['images'] is List) {
      imagenes.addAll(List<String>.from(data['imagenes']));
    }
    urlsAEliminarDeR2.clear(); 
  }

  Future<void> publicarTrabajo(BuildContext context, {required bool esJornada}) async {
    if (tituloCtrl.text.trim().isEmpty || 
        categoriaSeleccionada.trim().isEmpty ||
        oficioCtrl.text.trim().isEmpty ||
        descCtrl.text.trim().isEmpty || 
        calleCtrl.text.trim().isEmpty ||
        numeroCtrl.text.trim().isEmpty ||
        provinciaSeleccionada == null || // 🛡️ Validación Estricta
        provinciaSeleccionada!.isEmpty ||
        localidadCtrl.text.trim().isEmpty ||
        barrioCtrl.text.trim().isEmpty ||
        whatsappCtrl.text.trim().isEmpty ||
        fechaElegida == null || 
        horaElegida == null ||
        (esJornada && (sueldoCtrl.text.trim().isEmpty || horaFinElegida == null))) {
      
      _mostrarMensaje(context, 'Por favor, completa todos los campos obligatorios.');
      return; 
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final clienteId = context.read<GestorSesionGlobal>().miIdUsuario;
      if (clienteId.isEmpty) throw Exception('Usuario no autenticado.');

      final String fechaHoraIso = DateTime(fechaElegida!.year, fechaElegida!.month, fechaElegida!.day, horaElegida!.hour, horaElegida!.minute).toUtc().toIso8601String();
      
      String? horaFinBD;
      if (esJornada && horaFinElegida != null) {
        horaFinBD = '${horaFinElegida!.hour.toString().padLeft(2,'0')}:${horaFinElegida!.minute.toString().padLeft(2,'0')}';
      }
      
      // 🛡️ REGLA DATA INTEGRITY (Provincias Estrictas inyectadas en Criptografía Local)
      final String localidadPublica = '$provinciaSeleccionada / ${localidadCtrl.text.trim()}';
      final String ubicacionExactaDelimitada = '${calleCtrl.text.trim()}||${numeroCtrl.text.trim()}||${barrioCtrl.text.trim()}||${localidadCtrl.text.trim()}||$provinciaSeleccionada||${paisCtrl.text.trim()}';

      String descripcionPura = descCtrl.text.trim();
      if (referenciaCtrl.text.trim().isNotEmpty) {
        descripcionPura += '\n\nNotas del cliente: ${referenciaCtrl.text.trim()}';
      }
      
      String detalleHerramientas = '';
      
      if (traerHerramientas) {
        detalleHerramientas = herramientasCtrl.text.trim().isNotEmpty 
            ? herramientasCtrl.text.trim() 
            : (esJornada ? "Sí, aplica código de vestimenta o requerimientos." : "Sí, traer las herramientas necesarias.");
      }

      List<String> urlsPublicasFinales = [];
      List<String> archivosPorSubir = [];
      
      for (String path in imagenes) {
        if (path.startsWith('http')) urlsPublicasFinales.add(path);
        else archivosPorSubir.add(path);
      }

      if (archivosPorSubir.isNotEmpty) {
        final urlsNuevas = await ServicioPublicacionesSupabase.subirMultiplesImagenes(archivosPorSubir);
        urlsPublicasFinales.addAll(urlsNuevas);
      }

      final Map<String, dynamic> payloadSQL = {
        'titulo': proSolicitadoId != null ? 'Oferta Privada' : tituloCtrl.text.trim(),
        'descripcion': descripcionPura,
        'requisitos': detalleHerramientas,
        'precio': esJornada ? sueldoCtrl.text.trim() : 'A convenir',
        'imagenes': urlsPublicasFinales,
        'localidad': localidadPublica,
        'ubicacion_exacta': ubicacionExactaDelimitada,
        'categoria': categoriaSeleccionada.trim(), 
        'oficio': oficioCtrl.text.trim(),
        
        // 🛡️ REGLA DATA INTEGRITY (Paso 3)
        'ciudad': provinciaSeleccionada, 
        
        'dificultad': esJornada ? 'jornada' : dificultad.toString(),
        'telefono_contacto': whatsappCtrl.text.trim(),
        'fecha_hora': fechaHoraIso, 
        'hora_fin': horaFinBD,      
      };

      if (trabajoAEditarId != null) {
        await ServicioPublicacionesSupabase.actualizarTrabajo(trabajoAEditarId!, clienteId, payloadSQL);
        if (context.mounted) _mostrarDialogoExito(context, '¡Publicación Editada!', 'Se han guardado los cambios exitosamente.');
      } else {
        payloadSQL['cliente_id'] = clienteId;
        payloadSQL['profesional_solicitado_id'] = proSolicitadoId;
        payloadSQL['estado'] = 'abierto';
        payloadSQL['tipo_oferta'] = 'presupuesto';

        await ServicioPublicacionesSupabase.insertarTrabajo(payloadSQL);
        
        final msgModal = esJornada 
            ? 'Se ha publicado tu turno con éxito. Los trabajadores se postularán directamente sin regatear.' 
            : (proSolicitadoId != null ? 'Presupuesto privado enviado correctamente al profesional.' : 'Se ha publicado tu oferta con éxito. Los profesionales interesados te enviarán su cotización.');

        if (context.mounted) _mostrarDialogoExito(context, '¡Publicado!', msgModal);
      }

      for (String urlBasura in urlsAEliminarDeR2) {
        await SupabaseService.deleteImage(urlBasura);
      }
      urlsAEliminarDeR2.clear();

    } catch (e) {
      if (context.mounted) _mostrarMensaje(context, 'Error: $e');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    oficioCtrl.dispose();
    descCtrl.dispose();
    whatsappCtrl.dispose();
    sueldoCtrl.dispose();
    calleCtrl.dispose();
    numeroCtrl.dispose();
    referenciaCtrl.dispose();
    localidadCtrl.dispose();
    barrioCtrl.dispose();
    paisCtrl.dispose();
    herramientasCtrl.dispose();
    super.dispose();
  }
}