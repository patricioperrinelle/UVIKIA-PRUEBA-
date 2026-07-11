// lib/5_modulos/modulo_perfil_usuario/pantallas/pantalla_onboarding_profesional.dart

import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import 'pantalla_editar_perfil.dart';

class PantallaOnboardingProfesional extends StatelessWidget {
  const PantallaOnboardingProfesional({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: DimensionesApp.paddingPantalla,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:[
              const Icon(Icons.workspace_premium_rounded, size: 80, color: ColoresApp.primarioVerde),
              const SizedBox(height: 24),
              Text('Activa tu perfil Profesional', textAlign: TextAlign.center, style: EstilosTextoApp.h1.copyWith(color: tema.colorScheme.onSurface)),
              const SizedBox(height: 16),
              Text('Consigue clientes, ofrece presupuestos y aplica a jornadas con sueldo fijo. Necesitarás agregar al menos un oficio y llenar tus datos básicos para aparecer en el directorio.', textAlign: TextAlign.center, style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.textTheme.bodyMedium?.color)),
              const Spacer(),
              BotonAccionPrincipal(
                texto: 'CONTINUAR Y EDITAR',
                onPressed: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => const PantallaEditarPerfil(esPrimerOnboarding: true)
                    )
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}