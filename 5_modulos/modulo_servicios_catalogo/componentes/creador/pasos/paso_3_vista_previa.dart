// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/pasos/paso_3_vista_previa.dart
import 'package:flutter/material.dart';
import '../../../../../2_tema/colores_app.dart'; 
import '../../../../../1_nucleo/estado_global/gestor_sesion_global.dart'; 
import '../../../../../3_modelos/modelo_servicio_catalogo.dart'; 
import '../../../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../controladores/controlador_creador_servicio.dart';
import '../../tarjeta_servicio_catalogo.dart'; 
import '../../selector_nivel_servicio.dart'; 

class Paso3VistaPrevia extends StatelessWidget {
  final ControladorCreadorServicio controlador;

  const Paso3VistaPrevia({Key? key, required this.controlador}) : super(key: key);

  void _mostrarDialogoFaq(BuildContext context, {int? indexAEditar}) {
    controlador.prepararEditorFaq(index: indexAEditar); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(indexAEditar != null ? 'Editar Pregunta' : 'Nueva Pregunta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CampoTextoCristal(controller: controlador.faqPreguntaModalController, hintText: 'Pregunta (Ej: ¿Llevan sus propios productos?)'),
            const SizedBox(height: 12),
            CampoTextoCristal(controller: controlador.faqRespuestaModalController, hintText: 'Respuesta (Ej: Sí, llevamos todo lo necesario)', maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: BotonAccionPrincipal(
                texto: indexAEditar != null ? 'Guardar Cambios' : 'Agregar FAQ',
                onPressed: () {
                  controlador.guardarEditorFaq(index: indexAEditar);
                  Navigator.pop(ctx);
                },
              ),
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorAcento = tema.colorScheme.primary;

    final ratingReal = controlador.ratingProfesionalVistaPrevia;
    final planesActivos = controlador.nivelesAgregados.where((n) => controlador.nivelesSeleccionados.contains(n.idNivel)).toList();

    final servicioMock = ModeloServicioCatalogo(
      id: controlador.idServicioEditando ?? 'preview',
      profesionalId: GestorSesionGlobal().miIdUsuario,
      categoria: controlador.categoriaSeleccionada,
      titulo: controlador.tituloController.text.isEmpty ? 'Título de tu servicio' : controlador.tituloController.text.trim(),
      descripcion: controlador.descripcionController.text.trim(),
      modalidad: controlador.modalidadSeleccionada,
      
      // 🛡️ REGLA APLICADA: Instanciación sin las 4 columnas eliminadas, 
      // usando los getters de concatenación para la previsualización
      zonasCoberturaDescripcion: controlador.modalidadSeleccionada == 'a_domicilio' ? controlador.zonaConcatenada : '',
      direccionLocal: controlador.modalidadSeleccionada == 'en_local' ? controlador.direccionConcatenada : '',
      
      duracionEstimada: controlador.duracionEstimada,
      capacidadSimultanea: controlador.modalidadSeleccionada == 'en_local' ? (int.tryParse(controlador.capacidadController.text) ?? 1) : 1,
      tiempoMinimoAnticipacionHoras: int.tryParse(controlador.anticipacionController.text) ?? 2,
      tiposContratoSoportados: controlador.contratosSoportados,
      usaProductosPremium: controlador.usaProductosPremium,
      profesionalVerificado: true,
      etiquetasConfianza: controlador.etiquetasConfianzaSeleccionadas,
      niveles: planesActivos,
      reglasDisponibilidad: ModeloReglasDisponibilidad(
        diasLaborales: controlador.diasLaboralesSeleccionados.isEmpty ? [1,2,3,4,5] : controlador.diasLaboralesSeleccionados,
        horarioInicio: '${controlador.horarioApertura.hour.toString().padLeft(2, '0')}:${controlador.horarioApertura.minute.toString().padLeft(2, '0')}',
        horarioFin: '${controlador.horarioCierre.hour.toString().padLeft(2, '0')}:${controlador.horarioCierre.minute.toString().padLeft(2, '0')}',
        bloqueosManuales: []
      ),
      extrasOpcionales: [],
      preguntasFrecuentes: [],
      profesionalNombre: GestorSesionGlobal().perfilUsuario?.apodo ?? 'Tú',
      profesionalRating: ratingReal,
      profesionalReviews: controlador.reviewsProfesionalVistaPrevia,
      imagenes: [...controlador.fotosExistentesUrls, ...controlador.fotosSeleccionadas.map((f) => f.path)],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Así se verá en el catálogo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Revisa cómo verán los clientes tu servicio.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              if (!controlador.modoLectura)
                GestureDetector(
                  onTap: () => controlador.irAlPaso(0),
                  child: Text('Editar', style: TextStyle(color: colorAcento, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          TarjetaServicioCatalogo(
            servicio: servicioMock,
            onTapVerServicio: () {}, 
            onTapFavorito: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta es una vista previa del botón favoritos'), duration: Duration(seconds: 1)));
            },
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 24),

          if (planesActivos.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Planes y precios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (!controlador.modoLectura)
                  GestureDetector(
                    onTap: () => controlador.irAlPaso(1),
                    child: Text('Editar', style: TextStyle(color: colorAcento, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Transform.translate(
              offset: const Offset(-16, 0), 
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SelectorNivelServicio(
                  niveles: planesActivos,
                  idSeleccionado: planesActivos.first.idNivel, 
                  onNivelSeleccionado: (id) {}, 
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (!controlador.modoLectura)
                GestureDetector(
                  onTap: () => controlador.irAlPaso(0),
                  child: Text('Editar', style: TextStyle(color: colorAcento, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            controlador.descripcionController.text.isEmpty ? 'Sin descripción provista.' : controlador.descripcionController.text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preguntas Frecuentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (!controlador.modoLectura)
                TextButton.icon(
                  onPressed: () => _mostrarDialogoFaq(context),
                  icon: Icon(Icons.add, color: colorAcento, size: 16),
                  label: Text('Agregar', style: TextStyle(color: colorAcento, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                )
            ],
          ),
          const SizedBox(height: 12),
          
          if (controlador.faqMock.isEmpty)
            const Text('Añadir preguntas frecuentes ayuda a los clientes a decidir más rápido (Opcional).', style: TextStyle(fontSize: 13, color: Colors.grey)),

          IgnorePointer(
            ignoring: controlador.modoLectura,
            child: Column(
              children: controlador.faqMock.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, String> faq = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(border: Border.all(color: tema.brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Theme(
                    data: tema.copyWith(dividerColor: Colors.transparent), 
                    child: ExpansionTile(
                      title: Text(faq['pregunta']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      iconColor: colorAcento,
                      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(faq['respuesta']!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                            Row(
                              children: [
                                IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _mostrarDialogoFaq(context, indexAEditar: idx)),
                                const SizedBox(width: 12),
                                IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => controlador.eliminarFaq(idx)),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 40),

          if (controlador.modoLectura)
            Center(
              child: Text(
                'Toca el ícono del lápiz en la parte superior ✏️ para habilitar la edición de este servicio.', 
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13), 
                textAlign: TextAlign.center
              )
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: BotonAccionPrincipal(
                texto: controlador.isGuardando ? 'Publicando...' : (controlador.idServicioEditando != null ? 'Actualizar Cambios' : 'Publicar servicio'),
                isLoading: controlador.isGuardando,
                onPressed: () {
                  controlador.ejecutarGuardado(
                    esBorrador: false,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Servicio publicado con éxito!')));
                      Navigator.pop(context, true);
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: ColoresApp.errorRojo, duration: const Duration(seconds: 4)));
                    }
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: controlador.isGuardando ? null : () {
                  controlador.ejecutarGuardado(
                    esBorrador: true,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💾 Guardado en borradores.')));
                      Navigator.pop(context, true);
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: ColoresApp.advertenciaAmarillo, duration: const Duration(seconds: 4)));
                    }
                  );
                },
                child: Text(controlador.isGuardando ? 'Guardando...' : 'Guardar como borrador', style: TextStyle(color: controlador.isGuardando ? Colors.grey : colorAcento, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}