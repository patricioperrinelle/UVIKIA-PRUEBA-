// lib/5_modulos/modulo_perfil_usuario/componentes/tab_edicion_cliente.dart
import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';

// 🛡️ LEGOS INYECTADOS
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/formularios/selector_desplegable_cristal.dart';
import '../../../4_componentes_globales/modales_y_alertas/bottom_sheet_provincias.dart';

import '../controladores/controlador_edicion_perfil.dart';
import '../componentes/selector_imagen_perfil_editable.dart';

class TabEdicionCliente extends StatelessWidget {
  final ControladorEdicionPerfil controlador;
  final VoidCallback onCambiarFoto;
  final String nombreLegal;
  final String userId;

  const TabEdicionCliente({
    super.key,
    required this.controlador,
    required this.onCambiarFoto,
    required this.nombreLegal,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      padding: DimensionesApp.paddingPantalla,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(child: SelectorImagenPerfilEditable(imagenActual: controlador.profileImage, onTap: onCambiarFoto)),
          const SizedBox(height: 48),
          
          Text('Información Básica', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
          const SizedBox(height: 12),
          CampoTextoCristal(labelText: 'Apodo / Nombre Público', hintText: '', controller: controlador.apodoCtrl, iconoPrefix: Icons.lock_outline, readOnly: true),
          const SizedBox(height: 6),
          Text('Tu nombre fue validado por tu DNI y no puede ser modificado.', style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          
          Text('Ubicación Base', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
          const SizedBox(height: 12),
          
          // 🚀 🛡️ REGLA DATA INTEGRITY: Selector Estricto de Provincia (Reemplaza al TextField libre)
          SelectorDesplegableCristal(
            hintText: 'Provincia *',
            valorSeleccionado: controlador.provinciaSeleccionada,
            iconoPrefix: Icons.location_city_rounded,
            colorActivo: ColoresApp.terciarioMorado,
            onTap: () {
              BottomSheetProvincias.mostrar(
                context,
                provinciaActual: controlador.provinciaSeleccionada,
                colorActivo: ColoresApp.terciarioMorado,
                onProvinciaSeleccionada: (prov) => controlador.setProvincia(prov),
              );
            },
          ),
          
          const SizedBox(height: 16),
          CampoTextoCristal(labelText: 'Localidad / Ciudad (Ej: Capital) *', hintText: 'Ej: Capital', iconoPrefix: Icons.map_outlined, controller: controlador.localidadCtrl),
          const SizedBox(height: 16),
          CampoTextoCristal(labelText: 'Barrio (Opcional)', hintText: 'Ej: Nueva Córdoba', iconoPrefix: Icons.home_outlined, controller: controlador.barrioCtrl),
          const SizedBox(height: 32),
          
          Text('Datos de Seguridad', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
          const SizedBox(height: 12),
          CampoTextoCristal(labelText: 'Nombre Legal (Macheado con DNI)', hintText: '', controller: TextEditingController(text: nombreLegal), readOnly: true, iconoPrefix: Icons.lock_outline),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('ID de Usuario:', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 14)),
              const SizedBox(width: 8),
              Text(userId, style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }
}