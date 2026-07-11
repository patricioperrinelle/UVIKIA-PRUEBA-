// lib/5_modulos/modulo_explorar_feed/pantallas/pantalla_vista_previa_marketing.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../componentes/tarjeta_trabajo_feed.dart';
import '../componentes/tarjeta_jornada_feed.dart';

class PantallaVistaPreviaMarketing extends StatelessWidget {
  final String titulo;
  final List<dynamic> trabajos;
  final bool esJornada;
  final VoidCallback onIrAContratos;

  const PantallaVistaPreviaMarketing({
    Key? key,
    required this.titulo,
    required this.trabajos,
    required this.esJornada,
    required this.onIrAContratos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: tema.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(titulo, style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColoresApp.infoAzul.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColoresApp.infoAzul.withOpacity(0.3)),
              ),
              child: Row(
                children:[
                  const Icon(Icons.remove_red_eye_rounded, color: ColoresApp.infoAzul, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Así ven los profesionales tus tarjetas en el directorio público. Toca tu tarjeta para ir a gestionarla.', 
                      style: TextStyle(color: tema.textTheme.bodyMedium?.color, fontSize: 13, height: 1.4)
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: esJornada ? 0.52 : 0.53, 
                crossAxisSpacing: 8, 
                mainAxisSpacing: 12, 
              ),
              itemCount: trabajos.length,
              itemBuilder: (context, index) {
                final t = trabajos[index];
                return esJornada 
                  ? TarjetaJornadaFeed(
                      jornada: t, 
                      yaOfertado: false, 
                      isDueno: true, 
                      esModoCliente: true,
                      esGuardado: false, // 🚀 V5.8: Falso negativo para compilar (Vista previa del creador)
                      onTapGuardar: () {}, // 🚀 V5.8: Acción ciega
                      onTap: () { Navigator.pop(context); onIrAContratos(); }
                    )
                  : TarjetaTrabajoFeed(
                      trabajo: t, 
                      yaOfertado: false, 
                      isDueno: true, 
                      esModoCliente: true,
                      esGuardado: false, // 🚀 V5.8: Falso negativo para compilar
                      onTapGuardar: () {}, // 🚀 V5.8: Acción ciega
                      onTap: () { Navigator.pop(context); onIrAContratos(); }
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}