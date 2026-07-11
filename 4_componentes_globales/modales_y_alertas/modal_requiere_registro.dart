// lib/4_componentes_globales/modales_y_alertas/modal_requiere_registro.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../botones/boton_accion_principal.dart';

class ModalRequiereRegistro extends StatelessWidget {
  const ModalRequiereRegistro({Key? key}) : super(key: key);

  /// 🚨 Invocador Ciego (Dumb Launcher)
  static void mostrar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ModalRequiereRegistro(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: esOscuro ? ColoresApp.fondoTarjetas : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Icono central
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tema.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: 40,
                color: tema.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Textos
            const Text(
              'Requiere iniciar sesión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Para interactuar con profesionales, pedir presupuestos o guardar favoritos, necesitas una cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            
            // Botones
            SizedBox(
              width: double.infinity,
              child: BotonAccionPrincipal(
                texto: 'Iniciar Sesión / Crear Cuenta',
                onPressed: () {
                  Navigator.pop(context); // Cierra el modal
                  // 🚨 Navegamos al Login
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Seguir explorando',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}