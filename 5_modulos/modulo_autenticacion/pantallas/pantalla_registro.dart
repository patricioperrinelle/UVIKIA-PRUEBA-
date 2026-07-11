// lib/5_modulos/modulo_autenticacion/pantallas/pantalla_registro.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../controladores/controlador_auth.dart';
import '../../modulo_explorar_feed/pantallas/pantalla_home_hub.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../2_tema/estilos_texto.dart';

// 🛡️ LEGOS IMPORTADOS CORRECTAMENTE
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/formularios/selector_desplegable_cristal.dart'; 
import '../../../4_componentes_globales/modales_y_alertas/bottom_sheet_selector_imagen.dart';
import '../../../4_componentes_globales/modales_y_alertas/bottom_sheet_provincias.dart'; 
import '../../../4_componentes_globales/modales_y_alertas/dialogo_bienvenida_premium.dart';
import '../../../4_componentes_globales/formularios/formulario_curriculum_pro_base.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {

  void _mostrarAlertaError(String msj) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DimensionesApp.radioTarjetas),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ColoresApp.errorRojo, size: 28),
            SizedBox(width: 10),
            Text('Aviso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(msj, style: EstilosTextoApp.cuerpoRegular),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDIDO', style: TextStyle(color: ColoresApp.errorRojo, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  Widget _construirBarraProgreso(ControladorAuth auth) {
    if (auth.currentIndex == 0) return const SizedBox.shrink(); 
    int totalPasos = auth.esRegistroProfesional ? 4 : 3;
    int pasoActual = auth.currentIndex - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
      child: Row(
        children: List.generate(totalPasos, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= pasoActual ? ColoresApp.terciarioMorado : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ControladorAuth.instancia,
      builder: (context, child) {
        final auth = ControladorAuth.instancia;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                if (auth.currentIndex == 0) {
                  Navigator.pop(context);
                } else {
                  auth.retrocederPagina();
                }
              },
            ),
            title: _construirBarraProgreso(auth),
            centerTitle: true,
          ),
          body: SafeArea(
            child: PageView(
              controller: auth.pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => auth.setIndex(idx),
              children: [
                _construirFase1Rol(auth, context),
                _construirFase2Escaner(auth, context),
                _construirFase3IdentidadUbicacion(auth, context),
                if (auth.esRegistroProfesional) _construirFase4CurriculumPro(auth, context),
                _construirFase5Seguridad(auth, context),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _construirFase1Rol(ControladorAuth auth, BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: DimensionesApp.paddingPantalla,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo quieres usar la app?', style: EstilosTextoApp.h1.copyWith(color: colorTexto)),
          const SizedBox(height: 10),
          Text('Puedes ser Cliente o Profesional.', style: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.grey)),
          const Spacer(),
          BotonAccionPrincipal(
            texto: 'QUIERO CONTRATAR', colorFondo: ColoresApp.primarioVerde, 
            onPressed: () { auth.iniciarFlujoRegistro(false); auth.avanzarPagina(); },
          ),
          const SizedBox(height: 20),
          BotonAccionPrincipal(
            texto: 'QUIERO TRABAJAR', colorFondo: ColoresApp.terciarioMorado,
            onPressed: () { auth.iniciarFlujoRegistro(true); auth.avanzarPagina(); },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _construirFase2Escaner(ControladorAuth auth, BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    if (auth.abrirScanner) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Enfoca el código de barras', style: EstilosTextoApp.h2.copyWith(color: colorTexto)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: auth.isLoading
                  ? const Center(child: CircularProgressIndicator(color: ColoresApp.terciarioMorado))
                  : MobileScanner(
                      onDetect: (capture) async {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final rawValue = barcodes.first.rawValue ?? '';
                          if (rawValue.contains('@')) {
                            try {
                              await auth.procesarEscaneoDni(rawValue);
                              auth.avanzarPagina();
                            } catch (e) {
                              _mostrarAlertaError(e.toString());
                            }
                          }
                        }
                      },
                    ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: DimensionesApp.paddingPantalla,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: ColoresApp.terciarioMorado.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: ColoresApp.terciarioMorado, size: 80),
          ),
          const SizedBox(height: 30),
          Text('Validación de Identidad', style: EstilosTextoApp.h1.copyWith(color: colorTexto)),
          const SizedBox(height: 12),
          Text('Escaneá el código de barras\nde tu DNI para continuar.', textAlign: TextAlign.center, style: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.grey)),
          const Spacer(),
          BotonAccionPrincipal(texto: 'Escanear DNI', colorFondo: ColoresApp.terciarioMorado, onPressed: () => auth.setAbrirScanner(true)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _construirFase3IdentidadUbicacion(ControladorAuth auth, BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final tema = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Tu Identidad Visual', style: EstilosTextoApp.h2.copyWith(color: colorTexto)),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context, 
                backgroundColor: Colors.transparent, 
                builder: (ctx) => BottomSheetSelectorImagen(
                  titulo: 'Selecciona tu foto',
                  onCameraTap: () { Navigator.pop(ctx); auth.tomarFotoRegistro(ImageSource.camera); },
                  onGalleryTap: () { Navigator.pop(ctx); auth.tomarFotoRegistro(ImageSource.gallery); },
                )
              );
            },
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(color: tema.inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(32), border: Border.all(color: ColoresApp.terciarioMorado, width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: auth.fotoPerfilPath.isNotEmpty
                    ? Image.file(File(auth.fotoPerfilPath), fit: BoxFit.cover)
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_a_photo_outlined, size: 40, color: ColoresApp.terciarioMorado), const SizedBox(height: 8), Text('Subir foto *', style: EstilosTextoApp.cuerpoPequeno.copyWith(color: ColoresApp.terciarioMorado))]),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Align(alignment: Alignment.centerLeft, child: Text('¿Cómo te llamamos? *', style: EstilosTextoApp.h2.copyWith(color: colorTexto))),
          const SizedBox(height: 16),
          ...auth.nombresPublicosDisponibles.map((nombre) => RadioListTile<String>(
                title: Text(nombre, style: EstilosTextoApp.cuerpoDestacado.copyWith(color: colorTexto)),
                value: nombre,
                groupValue: auth.nombrePublicoElegido,
                activeColor: ColoresApp.terciarioMorado,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) { if (val != null) auth.setNombreElegido(val); },
              )),
          const SizedBox(height: 30),
          Align(alignment: Alignment.centerLeft, child: Row(children: [const Icon(Icons.location_on_rounded, color: ColoresApp.errorRojo, size: 24), const SizedBox(width: 8), Text('Tu Ubicación Base', style: EstilosTextoApp.h2.copyWith(color: colorTexto))])),
          const SizedBox(height: 16),
          
          // 🛡️ LEGO: Inyección pura, pantalla limpia
          SelectorDesplegableCristal(
            hintText: 'Provincia *',
            valorSeleccionado: auth.provinciaSeleccionada,
            iconoPrefix: Icons.location_city_rounded,
            colorActivo: ColoresApp.terciarioMorado,
            onTap: () {
              BottomSheetProvincias.mostrar(
                context,
                provinciaActual: auth.provinciaSeleccionada,
                colorActivo: ColoresApp.terciarioMorado,
                onProvinciaSeleccionada: (prov) => auth.setProvincia(prov),
              );
            },
          ),

          const SizedBox(height: 12),
          CampoTextoCristal(controller: auth.localidadCtrl, hintText: 'Localidad / Ciudad (Ej: Capital) *', iconoPrefix: Icons.map_outlined),
          const SizedBox(height: 12),
          CampoTextoCristal(controller: auth.barrioCtrl, hintText: 'Barrio (Opcional)', iconoPrefix: Icons.home_outlined),
          const SizedBox(height: 40),
          BotonAccionPrincipal(
            texto: 'Continuar', 
            colorFondo: ColoresApp.terciarioMorado, 
            onPressed: () {
              try {
                auth.validarAvance();
                auth.avanzarPagina();
              } catch (e) {
                _mostrarAlertaError(e.toString());
              }
            }
          ),
        ],
      ),
    );
  }

  Widget _construirFase4CurriculumPro(ControladorAuth auth, BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Arma tu Perfil Pro', style: EstilosTextoApp.h2.copyWith(color: colorTexto)),
          const SizedBox(height: 20),
          FormularioCurriculumProBase(
            oficioPrincipal: auth.oficioPrincipal,
            oficiosSecundarios: auth.oficiosSecundarios,
            onOficioPrincipalChanged: auth.setOficioPrincipal,
            onOficiosSecundariosChanged: auth.setOficiosSecundarios,
            
            habilidadesEspecialesCtrl: auth.habEspecialesCtrl,
            certificacionesCtrl: auth.certsCtrl,
            zonaCtrl: auth.zonaCtrl,
            bioCtrl: auth.bioCtrl,
            horariosCtrl: auth.horariosCtrl,
            tiempoRespCtrl: auth.tiempoRespCtrl,
            expCtrl: auth.expCtrl,
            garantiaCtrl: auth.garantiaCtrl,
            portfolioImages: auth.portfolioImagesPaths,
            onAddPortfolio: () async {
              try {
                await auth.tomarFotoPortfolio();
              } catch (e) {
                _mostrarAlertaError(e.toString());
              }
            },
            onRemovePortfolio: (path) => auth.removerFotoPortfolio(path),
          ),
          BotonAccionPrincipal(
            texto: 'Siguiente', 
            colorFondo: ColoresApp.terciarioMorado, 
            onPressed: () {
              try {
                auth.validarAvance();
                auth.avanzarPagina();
              } catch (e) {
                _mostrarAlertaError(e.toString());
              }
            }
          ),
        ],
      ),
    );
  }

  Widget _construirFase5Seguridad(ControladorAuth auth, BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text('Último Paso', style: EstilosTextoApp.h1.copyWith(color: colorTexto)), const SizedBox(width: 8), const Text('🔐', style: TextStyle(fontSize: 28))]),
          const SizedBox(height: 30),
          CampoTextoCristal(controller: auth.regEmailCtrl, hintText: 'Correo electrónico', iconoPrefix: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              CampoTextoCristal(controller: auth.regPassCtrl, hintText: 'Contraseña (mínimo 6 caracteres)', iconoPrefix: Icons.lock_outline, obscureText: auth.ocultarClave),
              Positioned(right: 8, child: IconButton(icon: Icon(auth.ocultarClave ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => auth.toggleOcultarClave())),
            ],
          ),
          const SizedBox(height: 50),
          BotonAccionPrincipal(
            texto: 'Finalizar registro',
            colorFondo: ColoresApp.terciarioMorado,
            isLoading: auth.isLoading,
            onPressed: () async {
              try {
                final String codigoGen = await auth.ejecutarRegistroFinal();
                if (!mounted) return;

                final gestor = context.read<GestorSesionGlobal>();
                await gestor.sincronizarPerfilConBaseDeDatos();
                if (auth.esRegistroProfesional) gestor.intentarCambiarModo(ModoUsuario.profesional);

                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => DialogoBienvenidaPremium(
                    esProfesional: auth.esRegistroProfesional,
                    codigoGenerado: codigoGen,
                    onComenzar: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PantallaHomeHub()), (r) => false);
                    },
                  )
                );
              } catch (e) {
                _mostrarAlertaError(e.toString());
              }
            },
          ),
        ],
      ),
    );
  }
}