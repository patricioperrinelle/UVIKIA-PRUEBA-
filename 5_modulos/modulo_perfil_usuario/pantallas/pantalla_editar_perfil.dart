// lib/5_modulos/modulo_perfil_usuario/pantallas/pantalla_editar_perfil.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/modales_y_alertas/bottom_sheet_selector_imagen.dart';
import '../../../4_componentes_globales/modales_y_alertas/dialogo_bienvenida_premium.dart';
import '../../modulo_explorar_feed/pantallas/pantalla_home_hub.dart';

import '../controladores/controlador_edicion_perfil.dart';
import '../componentes/tab_edicion_cliente.dart';
import '../componentes/tab_edicion_profesional.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

class PantallaEditarPerfil extends StatefulWidget {
  final bool esPrimerOnboarding; 

  const PantallaEditarPerfil({
    Key? key,
    this.esPrimerOnboarding = false,
  }) : super(key: key);

  @override
  State<PantallaEditarPerfil> createState() => _PantallaEditarPerfilState();
}

class _PantallaEditarPerfilState extends State<PantallaEditarPerfil> {
  final ControladorEdicionPerfil _controlador = ControladorEdicionPerfil();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perfil = context.read<GestorSesionGlobal>().perfilUsuario;
      if (perfil != null) _controlador.inicializar(perfil);
    });
  }

  @override
  void dispose() {
    _controlador.disposeControllers();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool esExito = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: esExito ? ColoresApp.primarioVerde : ColoresApp.errorRojo,
      ),
    );
  }

  Future<void> _seleccionarFoto(bool esPerfil) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BottomSheetSelectorImagen(
        titulo: esPerfil ? 'Cambiar Foto de Perfil' : 'Añadir al Portfolio',
        onCameraTap: () async {
          Navigator.pop(ctx);
          try {
            if (esPerfil) {
              await _controlador.cambiarFotoPerfil(ImageSource.camera);
            } else {
              await _controlador.agregarFotoPortfolioCamara();
            }
          } catch (e) {
            _mostrarMensaje(e.toString());
          }
        },
        onGalleryTap: () async {
          Navigator.pop(ctx);
          try {
            if (esPerfil) {
              await _controlador.cambiarFotoPerfil(ImageSource.gallery);
            } else {
              int allowed = 5 - _controlador.portfolioImages.length;
              if (allowed <= 0) {
                _mostrarMensaje('Máximo 5 fotos permitidas.');
                return;
              }
              final List<AssetEntity>? images = await AssetPicker.pickAssets(
                context,
                pickerConfig: AssetPickerConfig(maxAssets: allowed, requestType: RequestType.image),
              );
              if (images != null && images.isNotEmpty) {
                List<String> paths = [];
                for (AssetEntity entity in images) {
                  final File? file = await entity.file;
                  if (file != null) paths.add(file.path);
                }
                _controlador.agregarMultiplesFotosPortfolio(paths);
              }
            }
          } catch (e) {
            _mostrarMensaje(e.toString());
          }
        },
      ),
    );
  }

  Future<void> _ejecutarGuardado() async {
    try {
      final gestor = context.read<GestorSesionGlobal>();
      final miId = gestor.miIdUsuario;
      
      await _controlador.guardarCambios(miId: miId, esPrimerOnboarding: widget.esPrimerOnboarding);
      
      if (!mounted) return; // 🛡️ QA-Terminator: Prevención Memory Leak
      await gestor.sincronizarPerfilConBaseDeDatos();
      
      if (!mounted) return;
      
      if (widget.esPrimerOnboarding) {
        gestor.intentarCambiarModo(ModoUsuario.profesional);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => DialogoBienvenidaPremium(
            esProfesional: true,
            codigoGenerado: gestor.perfilUsuario?.codigoCompartible ?? 'Listo',
            onComenzar: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PantallaHomeHub()), (r) => false);
            },
          )
        );
      } else {
        _mostrarMensaje('Perfil actualizado correctamente.', esExito: true);
        Navigator.pop(context, true); 
      }
    } catch (e) {
      _mostrarMensaje(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gestor = context.watch<GestorSesionGlobal>();
    
    final bool mostrarTabsPro = gestor.perfilUsuario?.esProfesional == true || widget.esPrimerOnboarding;
    
    final String nombreLegal = gestor.perfilUsuario?.apodo ?? 'Usuario';
    final String userId = gestor.miIdUsuario.length > 8 
        ? '#${gestor.miIdUsuario.substring(0, 8).toUpperCase()}' 
        : gestor.miIdUsuario;

    return DefaultTabController(
      length: mostrarTabsPro ? 2 : 1,
      initialIndex: widget.esPrimerOnboarding ? 1 : 0, 
      child: ListenableBuilder(
        listenable: _controlador,
        builder: (context, child) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: tema.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: tema.colorScheme.surface,
                elevation: 0,
                centerTitle: true,
                title: Text('Editar Perfil', style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: Icon(Icons.close_rounded, color: tema.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context, false),
                ),
                bottom: mostrarTabsPro ? TabBar(
                  indicatorColor: ColoresApp.primarioVerde,
                  labelColor: ColoresApp.primarioVerde,
                  unselectedLabelColor: tema.textTheme.bodyMedium?.color,
                  tabs: const [
                    Tab(text: 'Mi Cuenta (Base)'),
                    Tab(text: 'Mi Perfil Profesional'),
                  ],
                ) : null,
              ),
              body: TabBarView(
                children: [
                  TabEdicionCliente(
                    controlador: _controlador, 
                    onCambiarFoto: () => _seleccionarFoto(true),
                    nombreLegal: nombreLegal,
                    userId: userId,
                  ),
                  if (mostrarTabsPro) TabEdicionProfesional(
                    controlador: _controlador, 
                    onAddPortfolio: () => _seleccionarFoto(false),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomBar(tema),
            ),
          );
        }
      ),
    );
  }

  Widget _buildBottomBar(ThemeData tema) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: tema.brightness == Brightness.dark ? ColoresApp.bordeCristal : Colors.black12,
          ),
        ),
      ),
      child: SafeArea(
        child: BotonAccionPrincipal(
          texto: 'GUARDAR CAMBIOS',
          isLoading: _controlador.isSubmitting,
          onPressed: _ejecutarGuardado,
        ),
      ),
    );
  }
}