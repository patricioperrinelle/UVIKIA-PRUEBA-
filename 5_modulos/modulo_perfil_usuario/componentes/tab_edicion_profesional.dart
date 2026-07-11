// lib/5_modulos/modulo_perfil_usuario/componentes/tab_edicion_profesional.dart
import 'package:flutter/material.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/formularios/formulario_curriculum_pro_base.dart';
import '../controladores/controlador_edicion_perfil.dart';

class TabEdicionProfesional extends StatelessWidget {
  final ControladorEdicionPerfil controlador;
  final VoidCallback onAddPortfolio;

  const TabEdicionProfesional({
    super.key,
    required this.controlador,
    required this.onAddPortfolio,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: DimensionesApp.paddingPantalla,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          FormularioCurriculumProBase(
            // 🛡️ REGLA 1: Variables de estado inmutables y Callbacks
            oficioPrincipal: controlador.oficioPrincipal,
            oficiosSecundarios: controlador.oficiosSecundarios,
            onOficioPrincipalChanged: controlador.setOficioPrincipal,
            onOficiosSecundariosChanged: controlador.setOficiosSecundarios,
            
            habilidadesEspecialesCtrl: controlador.habilidadesEspecialesCtrl,
            certificacionesCtrl: controlador.certificacionesCtrl,
            zonaCtrl: controlador.zonaCtrl,
            bioCtrl: controlador.bioCtrl,
            horariosCtrl: controlador.horariosCtrl,
            tiempoRespCtrl: controlador.tiempoRespCtrl,
            expCtrl: controlador.expCtrl,
            garantiaCtrl: controlador.garantiaCtrl,
            portfolioImages: controlador.portfolioImages,
            onAddPortfolio: onAddPortfolio,
            onRemovePortfolio: (url) => controlador.eliminarFotoPortfolio(url),
          ),
          const SizedBox(height: 60), 
        ],
      ),
    );
  }
}