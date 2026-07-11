// lib/5_modulos/modulo_explorar_feed/componentes/modal_selector_modo.dart

import 'package:flutter/material.dart';
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../2_tema/estilos_texto.dart';

class ModalSelectorModo {
  static void mostrar(BuildContext context, GestorSesionGlobal gestor, VoidCallback onIrAOnboarding) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tema.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: esOscuro ? Colors.white12 : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text('Cambiar Modo de Uso', style: EstilosTextoApp.h2.copyWith(color: tema.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('Elige cómo quieres usar la plataforma en este momento.', style: TextStyle(color: tema.textTheme.bodyMedium?.color)),
            const SizedBox(height: 24),
            
            _ItemModo(
              titulo: 'Soy Cliente',
              descripcion: 'Busco profesionales y quiero contratar.',
              icono: Icons.person_search_rounded,
              estaSeleccionado: gestor.modoActual == ModoUsuario.cliente,
              onTap: () {
                gestor.intentarCambiarModo(ModoUsuario.cliente);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            
            _ItemModo(
              titulo: 'Soy Profesional',
              descripcion: 'Busco trabajos y quiero ofrecer servicios.',
              icono: Icons.work_rounded,
              estaSeleccionado: gestor.modoActual == ModoUsuario.profesional,
              onTap: () {
                final exito = gestor.intentarCambiarModo(ModoUsuario.profesional);
                Navigator.pop(ctx);
                if (!exito) onIrAOnboarding();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ItemModo extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final bool estaSeleccionado;
  final VoidCallback onTap;

  const _ItemModo({required this.titulo, required this.descripcion, required this.icono, required this.estaSeleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: DimensionesApp.radioTarjetas,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // 🚨 ERROR SOLUCIONADO: Se cambió cristalFondo por el estándar nativo
          color: estaSeleccionado ? ColoresApp.primarioVerde.withOpacity(0.1) : (esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
          borderRadius: DimensionesApp.radioTarjetas,
          border: Border.all(color: estaSeleccionado ? ColoresApp.primarioVerde : (esOscuro ? Colors.white12 : Colors.black12), width: estaSeleccionado ? 2 : 1),
        ),
        child: Row(
          children:[
            Icon(icono, color: estaSeleccionado ? ColoresApp.primarioVerde : tema.iconTheme.color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(titulo, style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(descripcion, style: TextStyle(color: tema.textTheme.bodyMedium?.color, fontSize: 13)),
                ],
              ),
            ),
            if (estaSeleccionado)
              const Icon(Icons.check_circle_rounded, color: ColoresApp.primarioVerde),
          ],
        ),
      ),
    );
  }
}