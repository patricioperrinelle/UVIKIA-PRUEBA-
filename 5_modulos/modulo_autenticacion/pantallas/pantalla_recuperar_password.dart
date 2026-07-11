// lib/5_modulos/modulo_autenticacion/pantallas/pantalla_recuperar_password.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controladores/controlador_auth.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';

class PantallaRecuperarPassword extends StatefulWidget {
  const PantallaRecuperarPassword({super.key});

  @override
  State<PantallaRecuperarPassword> createState() => _PantallaRecuperarPasswordState();
}

class _PantallaRecuperarPasswordState extends State<PantallaRecuperarPassword> {
  bool _usarEscaner = true;
  bool _escaneoExitoso = false;
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: esError ? ColoresApp.errorRojo : ColoresApp.primarioVerde,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _ejecutarRecuperacionPorCorreo(ControladorAuth auth) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _mostrarMensaje('Por favor, ingresa tu correo electrónico.');
      return;
    }
    try {
      await auth.recuperarPassword(email);
      if (!mounted) return; // 🛡️ QA-Terminator
      _mostrarMensaje('Te hemos enviado un correo con las instrucciones.', esError: false);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _mostrarMensaje(e.toString());
    }
  }

  Future<void> _ejecutarRecuperacionPorDni(ControladorAuth auth, String rawValue) async {
    try {
      await auth.recuperarPasswordConDni(rawValue);
      if (!mounted) return; // 🛡️ QA-Terminator
      _mostrarMensaje('¡Enviado! Revisa el correo electrónico asociado a este DNI.', esError: false);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _mostrarMensaje(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ControladorAuth.instancia;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, child) {
            return Column(
              children: [
                Padding(
                  padding: DimensionesApp.paddingPantalla,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recuperar Acceso', style: EstilosTextoApp.h1),
                      const SizedBox(height: 10),
                      Text(
                        _usarEscaner ? 'Escanea el código de barras de tu DNI para enviarte un enlace de recuperación.' : 'Ingresa tu correo electrónico registrado.',
                        style: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Con DNI', textAlign: TextAlign.center),
                              selected: _usarEscaner,
                              selectedColor: ColoresApp.primarioVerde.withOpacity(0.2),
                              onSelected: (val) => setState(() { _usarEscaner = true; _escaneoExitoso = false; }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Con Correo', textAlign: TextAlign.center),
                              selected: !_usarEscaner,
                              selectedColor: ColoresApp.primarioVerde.withOpacity(0.2),
                              onSelected: (val) => setState(() => _usarEscaner = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _usarEscaner ? _construirVistaEscaner(auth) : _construirVistaCorreo(auth)),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _construirVistaEscaner(ControladorAuth auth) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: auth.isLoading
          ? const Center(child: CircularProgressIndicator(color: ColoresApp.primarioVerde))
          : MobileScanner(
              onDetect: (capture) async {
                if (_escaneoExitoso || auth.isLoading) return;
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final rawValue = barcodes.first.rawValue ?? '';
                  if (rawValue.contains('@')) {
                    setState(() => _escaneoExitoso = true); 
                    await _ejecutarRecuperacionPorDni(auth, rawValue);
                    if (mounted) setState(() => _escaneoExitoso = false); 
                  }
                }
              },
            ),
    );
  }

  Widget _construirVistaCorreo(ControladorAuth auth) {
    return SingleChildScrollView(
      padding: DimensionesApp.paddingPantalla,
      child: Column(
        children: [
          CampoTextoCristal(controller: _emailCtrl, hintText: 'ejemplo@correo.com', keyboardType: TextInputType.emailAddress, iconoPrefix: Icons.email_outlined),
          const SizedBox(height: 30),
          BotonAccionPrincipal(texto: 'ENVIAR ENLACE', isLoading: auth.isLoading, onPressed: () => _ejecutarRecuperacionPorCorreo(auth)),
        ],
      ),
    );
  }
}