// lib/5_modulos/modulo_autenticacion/pantallas/pantalla_login.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controladores/controlador_auth.dart';
import 'pantalla_registro.dart';
import 'pantalla_recuperar_password.dart';
import '../../modulo_explorar_feed/pantallas/pantalla_home_hub.dart';

import '../../../1_nucleo/estado_global/gestor_sesion_global.dart'; 
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/boton_delineado_secundario.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _ocultarClave = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
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

  Future<void> _ejecutarLoginSeguro() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    
    if (email.isEmpty || pass.isEmpty) {
      _mostrarMensaje('Por favor, completa todos los campos.');
      return;
    }

    try {
      final gestor = context.read<GestorSesionGlobal>();
      await gestor.destruirSesionCompletamente();
      await ControladorAuth.instancia.iniciarSesion(email, pass);

      if (!mounted) return; 
      await gestor.sincronizarPerfilConBaseDeDatos();
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PantallaHomeHub()), (route) => false);
    } catch (e) {
      if (mounted) _mostrarMensaje(e.toString());
    }
  }

  Future<void> _ejecutarLoginRapido(int index, String email) async {
    try {
      final gestor = context.read<GestorSesionGlobal>();
      await gestor.destruirSesionCompletamente();
      await ControladorAuth.instancia.loginRapido(index, email);

      if (!mounted) return; 
      await gestor.sincronizarPerfilConBaseDeDatos();
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PantallaHomeHub()), (route) => false);
    } catch (e) {
      if (mounted) _mostrarMensaje(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ControladorAuth.instancia;
    final tema = Theme.of(context);
    final isDarkMode = tema.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: tema.colorScheme.surface,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: DimensionesApp.paddingPantalla,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.home_work_rounded, size: 60, color: ColoresApp.terciarioMorado),
                        const SizedBox(height: 8),
                        Text('OfiHome', style: EstilosTextoApp.h1.copyWith(fontSize: 32, color: tema.colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Text(
                          'Conectamos hogares con\nprofesionales de confianza',
                          textAlign: TextAlign.center,
                          style: EstilosTextoApp.cuerpoRegular.copyWith(color: isDarkMode ? Colors.grey[400] : ColoresApp.terciarioMorado, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  CampoTextoCristal(controller: _emailCtrl, hintText: 'Correo electrónico', keyboardType: TextInputType.emailAddress, iconoPrefix: Icons.email_outlined),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      CampoTextoCristal(controller: _passCtrl, hintText: 'Contraseña', obscureText: _ocultarClave, iconoPrefix: Icons.lock_outline),
                      Positioned(right: 8, child: IconButton(icon: Icon(_ocultarClave ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _ocultarClave = !_ocultarClave))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRecuperarPassword())),
                      child: Text('¿Olvidaste tu contraseña?', style: EstilosTextoApp.cuerpoPequeno.copyWith(color: ColoresApp.terciarioMorado, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BotonAccionPrincipal(texto: 'Iniciar sesión', colorFondo: ColoresApp.terciarioMorado, isLoading: auth.isLoading, onPressed: _ejecutarLoginSeguro),
                  const SizedBox(height: 16),
                  BotonDelineadoSecundario(texto: 'Crear cuenta', colorPrimario: ColoresApp.terciarioMorado, icono: Icons.person_add_alt_1_outlined, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRegistro()))),
                  const SizedBox(height: 16),
                  BotonDelineadoSecundario(texto: 'Explorar sin registro', colorPrimario: ColoresApp.terciarioMorado, icono: Icons.explore_outlined, onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PantallaHomeHub()), (route) => false)),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),
                  Text('⚡ Testing Rápido', textAlign: TextAlign.center, style: EstilosTextoApp.cuerpoPequeno.copyWith(color: ColoresApp.advertenciaAmarillo)),
                  const SizedBox(height: 10),
                  BotonDelineadoSecundario(texto: 'Entrar como Cliente', colorPrimario: ColoresApp.infoAzul, icono: Icons.person_rounded, isLoading: auth.fastLoginLoading == 0, onPressed: () => _ejecutarLoginRapido(0, 'patricioperrinelle@gmail.com')),
                  const SizedBox(height: 10),
                  BotonDelineadoSecundario(texto: 'Entrar como Pro 1', colorPrimario: ColoresApp.primarioVerde, icono: Icons.build_rounded, isLoading: auth.fastLoginLoading == 1, onPressed: () => _ejecutarLoginRapido(1, 'usuario2@app.com')),
                  const SizedBox(height: 10),
                  BotonDelineadoSecundario(texto: 'Entrar como Pro 2', colorPrimario: ColoresApp.terciarioMorado, icono: Icons.engineering_rounded, isLoading: auth.fastLoginLoading == 2, onPressed: () => _ejecutarLoginRapido(2, 'usuario3@app.com')),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}