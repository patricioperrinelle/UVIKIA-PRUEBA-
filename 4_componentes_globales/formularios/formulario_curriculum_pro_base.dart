// lib/4_componentes_globales/formularios/formulario_curriculum_pro_base.dart
import 'package:flutter/material.dart';
import '../../1_nucleo/utilidades/constantes_categorias.dart'; 
import '../../2_tema/estilos_texto.dart';
import 'campo_texto_cristal.dart';
import '../../5_modulos/modulo_perfil_usuario/componentes/seccion_edicion_portfolio.dart';

class FormularioCurriculumProBase extends StatelessWidget {
  // 🛡️ REGLA 1: Variables algorítmicas ciegas y por Callback
  final String? oficioPrincipal;
  final List<String> oficiosSecundarios;
  final Function(String) onOficioPrincipalChanged;
  final Function(List<String>) onOficiosSecundariosChanged;

  // Variables de texto estándar
  final TextEditingController habilidadesEspecialesCtrl;
  final TextEditingController certificacionesCtrl;
  final TextEditingController zonaCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController horariosCtrl;
  final TextEditingController tiempoRespCtrl;
  final TextEditingController expCtrl;
  final TextEditingController garantiaCtrl;
  final List<String> portfolioImages;
  final VoidCallback onAddPortfolio;
  final Function(String) onRemovePortfolio;

  const FormularioCurriculumProBase({
    super.key,
    required this.oficioPrincipal,
    required this.oficiosSecundarios,
    required this.onOficioPrincipalChanged,
    required this.onOficiosSecundariosChanged,
    required this.habilidadesEspecialesCtrl,
    required this.certificacionesCtrl,
    required this.zonaCtrl,
    required this.bioCtrl,
    required this.horariosCtrl,
    required this.tiempoRespCtrl,
    required this.expCtrl,
    required this.garantiaCtrl,
    required this.portfolioImages,
    required this.onAddPortfolio,
    required this.onRemovePortfolio,
  });

  // =========================================================================
  // 🛠️ MOTORES VISUALES DE SELECCIÓN ESTRICTA (Cero Texto Libre)
  // =========================================================================

  void _mostrarSelectorPrincipal(BuildContext context) {
    final categorias = ConstantesCategorias.categoriasGlobales;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Text('Oficio Principal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final cat = categorias[index];
                    final isSelected = cat == oficioPrincipal;
                    return ListTile(
                      title: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
                      leading: Icon(Icons.star_rounded, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                      tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                      onTap: () {
                        onOficioPrincipalChanged(cat);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  void _mostrarSelectorSecundarios(BuildContext context) {
    List<String> seleccionTemp = List.from(oficiosSecundarios);
    final disponibles = ConstantesCategorias.categoriasGlobales.where((c) => c != oficioPrincipal && c != 'Otros').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateModal) {
              return Column(
                children: [
                  const Text('Habilidades (Plan B)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Selecciona otras áreas en las que trabajes', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: disponibles.length,
                      itemBuilder: (context, index) {
                        final cat = disponibles[index];
                        final isSelected = seleccionTemp.contains(cat);
                        return CheckboxListTile(
                          title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                          value: isSelected,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (bool? value) {
                            setStateModal(() {
                              if (value == true) {
                                seleccionTemp.add(cat);
                              } else {
                                seleccionTemp.remove(cat);
                              }
                            });
                            onOficiosSecundariosChanged(seleccionTemp);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  )
                ],
              );
            }
          ),
        ),
      )
    );
  }

  // 🧱 LEGO: Botón Selector
  Widget _buildBotonSelector({
    required BuildContext context,
    required String labelText,
    required String valueText,
    required String hintText,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    final tema = Theme.of(context);
    final hasValue = valueText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(labelText, style: EstilosTextoApp.cuerpoPequeno.copyWith(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: tema.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tema.dividerColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(icono, color: hasValue ? tema.colorScheme.primary : Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? valueText : hintText,
                    style: TextStyle(color: hasValue ? tema.colorScheme.onSurface : Colors.grey, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Motor de Búsqueda (Algoritmo)', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Esta información determina qué trabajos te llegarán y garantiza que los clientes te encuentren.', style: EstilosTextoApp.cuerpoPequeno.copyWith(color: Colors.grey)),
        const SizedBox(height: 16),
        
        // 🚀 SELECTOR OFICIO PRINCIPAL
        _buildBotonSelector(
          context: context,
          labelText: 'Oficio Principal (Tu especialidad Fuerte) *',
          valueText: oficioPrincipal ?? '',
          hintText: 'Toca para elegir tu especialidad',
          icono: Icons.star_rounded,
          onTap: () => _mostrarSelectorPrincipal(context),
        ),
        const SizedBox(height: 16),
        
        // 🚀 SELECTOR OFICIOS SECUNDARIOS
        _buildBotonSelector(
          context: context,
          labelText: 'Habilidades (Plan B)',
          valueText: oficiosSecundarios.isNotEmpty ? '${oficiosSecundarios.length} seleccionadas' : '',
          hintText: 'Toca para agregar habilidades secundarias',
          icono: Icons.add_task_rounded,
          onTap: () {
            if (oficioPrincipal == null || oficioPrincipal!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero debes elegir tu Oficio Principal')));
              return;
            }
            _mostrarSelectorSecundarios(context);
          },
        ),
        
        // 🚀 UX PREMIUM: Wrap con Chips eliminables
        if (oficiosSecundarios.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: oficiosSecundarios.map((cat) {
              return Chip(
                label: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: tema.colorScheme.primary.withOpacity(0.1),
                deleteIconColor: tema.colorScheme.primary,
                side: BorderSide(color: tema.colorScheme.primary.withOpacity(0.3)),
                onDeleted: () {
                  // Eliminación inmutable disparada al controlador padre
                  final List<String> nuevaLista = List.from(oficiosSecundarios);
                  nuevaLista.remove(cat);
                  onOficiosSecundariosChanged(nuevaLista);
                },
              );
            }).toList(),
          ),
        ],
        
        const SizedBox(height: 16),
        CampoTextoCristal(labelText: 'Certificados', hintText: 'Ej: Matrícula ERSEP, Cursos...', controller: certificacionesCtrl),
        const SizedBox(height: 16),
        CampoTextoCristal(labelText: 'Servicios Extras', hintText: 'Ej: Armado de tableros, Instalación de cámaras...', minLines: 2, maxLines: 3, controller: habilidadesEspecialesCtrl),
        
        const SizedBox(height: 32),
        Text('Tu Carta de Presentación', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
        const SizedBox(height: 12),
        CampoTextoCristal(labelText: 'Zona de Trabajo *', hintText: 'Ej: Córdoba Capital', iconoPrefix: Icons.location_on_outlined, controller: zonaCtrl),
        const SizedBox(height: 16),
        CampoTextoCristal(labelText: 'Sobre mí (Biografía)', hintText: 'Describe brevemente quién eres...', minLines: 3, maxLines: 4, controller: bioCtrl),
        
        const SizedBox(height: 32),
        Text('Disponibilidad', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
        const SizedBox(height: 12),
        CampoTextoCristal(labelText: 'Horario Habitual', hintText: 'Ej: Lunes a Sábados de 08:00 a 18:00 hs', maxLines: 2, iconoPrefix: Icons.schedule_rounded, controller: horariosCtrl),
        const SizedBox(height: 16),
        CampoTextoCristal(labelText: 'Tiempo de Respuesta', hintText: 'Ej: Contesto en el día', iconoPrefix: Icons.bolt_rounded, controller: tiempoRespCtrl),
        
        const SizedBox(height: 32),
        Text('Indicadores de Confianza', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: CampoTextoCristal(labelText: 'Experiencia (Años)', hintText: 'Ej: 5', keyboardType: TextInputType.number, iconoPrefix: Icons.star_border_rounded, controller: expCtrl)),
            const SizedBox(width: 16),
            Expanded(child: CampoTextoCristal(labelText: 'Garantía (Días)', hintText: 'Ej: 30', keyboardType: TextInputType.number, iconoPrefix: Icons.shield_outlined, controller: garantiaCtrl)),
          ],
        ),
        
        const SizedBox(height: 32),
        Text('Imágenes del Portfolio', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
        const SizedBox(height: 16),
        SeccionEdicionPortfolio(
          imagenes: portfolioImages,
          onAddTap: onAddPortfolio,
          onRemoveTap: onRemovePortfolio,
        ),
        const SizedBox(height: 40), 
      ],
    );
  }
}