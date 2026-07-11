// lib/5_modulos/modulo_publicaciones/componentes/seccion_direccion_maps.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/formularios/selector_desplegable_cristal.dart'; // 🛡️ Lego Selector
import '../../../4_componentes_globales/modales_y_alertas/bottom_sheet_provincias.dart'; // 🛡️ Lego Modal

class SeccionDireccionMaps extends StatelessWidget {
  final TextEditingController calleCtrl;
  final TextEditingController numeroCtrl;
  final String? provinciaSeleccionada; // 🛡️ REGLA DATA INTEGRITY (Estado en lugar de Controller)
  final Function(String) onProvinciaChanged; // 🛡️ Callback hacia el controlador
  final TextEditingController localidadCtrl;
  final TextEditingController barrioCtrl;
  final TextEditingController paisCtrl;
  final Color colorTema;

  const SeccionDireccionMaps({
    Key? key,
    required this.calleCtrl,
    required this.numeroCtrl,
    required this.provinciaSeleccionada,
    required this.onProvinciaChanged,
    required this.localidadCtrl,
    required this.barrioCtrl,
    required this.paisCtrl,
    this.colorTema = ColoresApp.primarioVerde,
  }) : super(key: key);

  Widget _buildAddressField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        filled: true,
        fillColor: Colors.black.withOpacity(0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorTema.withOpacity(0.05), 
            borderRadius: DimensionesApp.radioTarjetas, 
            border: Border.all(color: colorTema.withOpacity(0.5))
          ),
          child: Column(
            children:[
              Row(
                children:[
                  Expanded(flex: 2, child: _buildAddressField(calleCtrl, 'Calle (Ej. San Martín)', Icons.location_on)),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildAddressField(numeroCtrl, 'Número', Icons.tag)),
                ],
              ),
              const SizedBox(height: 8),
              
              // 🚀 🛡️ REGLA DATA INTEGRITY: Inyección del Botón Estricto
              SelectorDesplegableCristal(
                hintText: 'Provincia (Ej. Córdoba) *',
                valorSeleccionado: provinciaSeleccionada,
                iconoPrefix: Icons.map,
                colorActivo: colorTema,
                onTap: () {
                  BottomSheetProvincias.mostrar(
                    context,
                    provinciaActual: provinciaSeleccionada,
                    colorActivo: colorTema,
                    onProvinciaSeleccionada: onProvinciaChanged,
                  );
                },
              ),

              const SizedBox(height: 8),
              Row(
                children:[
                  Expanded(child: _buildAddressField(localidadCtrl, 'Localidad / Ciudad', Icons.location_city)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAddressField(barrioCtrl, 'Barrio', Icons.holiday_village_rounded)),
                ],
              ),
              const SizedBox(height: 8),
              _buildAddressField(paisCtrl, 'País (Ej. Argentina)', Icons.public),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text('🔒 Tu calle y número se mantendrán ocultos automáticamente. Solo la Provincia y Localidad serán visibles públicamente en el muro.', style: TextStyle(color: colorTema, fontSize: 12, fontStyle: FontStyle.italic, height: 1.3)),
        ),
      ],
    );
  }
}