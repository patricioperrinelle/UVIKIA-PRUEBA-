// lib/4_componentes_globales/modales_y_alertas/dialogo_bienvenida_premium.dart
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import '../../2_tema/dimensiones_app.dart';

class DialogoBienvenidaPremium extends StatelessWidget {
  final bool esProfesional;
  final String codigoGenerado;
  final VoidCallback onComenzar;

  const DialogoBienvenidaPremium({
    super.key,
    required this.esProfesional,
    required this.codigoGenerado,
    required this.onComenzar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: DimensionesApp.radioTarjetas),
      backgroundColor: Theme.of(context).colorScheme.surface,
      contentPadding: DimensionesApp.paddingTarjetas,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: DimensionesApp.paddingTarjetas,
            decoration: BoxDecoration(
              color: (esProfesional ? ColoresApp.terciarioMorado : ColoresApp.primarioVerde).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              esProfesional ? Icons.work_outline_rounded : Icons.handshake_outlined,
              color: esProfesional ? ColoresApp.terciarioMorado : ColoresApp.primarioVerde,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            esProfesional ? '¡Bienvenido al equipo!' : '¡Felicidades!',
            style: EstilosTextoApp.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            esProfesional
                ? 'Tu perfil profesional está activo y listo para recibir propuestas. Ya eres parte de la comunidad.'
                : 'Ya eres parte de nuestra comunidad como Contratante. Prepárate para encontrar a los mejores profesionales.',
            style: EstilosTextoApp.cuerpoRegular.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: esProfesional 
                    ? ColoresApp.terciarioMorado.withOpacity(0.5) 
                    : ColoresApp.primarioVerde.withOpacity(0.5)
              )
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined, 
                  size: 20, 
                  color: esProfesional ? ColoresApp.terciarioMorado : ColoresApp.primarioVerde
                ),
                const SizedBox(width: 8),
                Text(
                  'ID: $codigoGenerado', 
                  style: EstilosTextoApp.cuerpoDestacado
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: esProfesional ? ColoresApp.terciarioMorado : ColoresApp.primarioVerde,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: onComenzar,
              child: Text('Comenzar', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}