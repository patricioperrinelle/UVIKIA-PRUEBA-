// lib/5_modulos/modulo_servicios_catalogo/componentes/creador/pasos/paso_2_planes_extras.dart

import 'package:flutter/material.dart';
import '../../../../../2_tema/colores_app.dart'; 
import '../../../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../../../3_modelos/modelo_servicio_catalogo.dart';
import '../../../controladores/controlador_creador_servicio.dart';
import '../tarjeta_plan_creado.dart';
import '../item_extra_opcional.dart';

class Paso2PlanesExtras extends StatelessWidget {
  final ControladorCreadorServicio controlador;

  const Paso2PlanesExtras({Key? key, required this.controlador}) : super(key: key);

  final Map<int, String> _diasSemana = const {
    1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'
  };

  Future<void> _seleccionarHora(BuildContext context, bool esApertura) async {
    final horaActual = esApertura ? controlador.horarioApertura : controlador.horarioCierre;
    final TimeOfDay? horaElegida = await showTimePicker(
      context: context,
      initialTime: horaActual,
    );
    if (horaElegida != null) {
      if (esApertura) {
        controlador.actualizarHorarioApertura(horaElegida);
      } else {
        controlador.actualizarHorarioCierre(horaElegida);
      }
    }
  }

  Future<void> _seleccionarHora2(BuildContext context, bool esApertura) async {
    final horaActual = esApertura ? controlador.horarioApertura2 : controlador.horarioCierre2;
    final TimeOfDay? horaElegida = await showTimePicker(
      context: context,
      initialTime: horaActual,
    );
    if (horaElegida != null) {
      if (esApertura) {
        controlador.actualizarHorarioApertura2(horaElegida);
      } else {
        controlador.actualizarHorarioCierre2(horaElegida);
      }
    }
  }

  // 🚨 ARQUITECTURA LIMPIA: Erradicamos el StatefulBuilder de aquí y conectamos al ListenableBuilder
  void _mostrarDialogoPlan(BuildContext context, {required ModeloNivelServicio nivelAEditar}) {
    controlador.prepararEditorPlan(nivelAEditar); 
    final hintEjemplo = controlador.obtenerHintParaPlan(nivelAEditar.nombre); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 16, right: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Editando plan: ${nivelAEditar.nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              const Text('Lo que cubre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Arma tu plan con lo que cubre este servicio. Separa cada ítem con una coma (,) o un signo más (+) para que se enliste (máx. 300 caracteres).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              CampoTextoCristal(
                controller: controlador.planDescModalController, 
                hintText: hintEjemplo,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              const Text('Lo que NO cubre (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Escribe aquello que NO cubre el servicio para evitar confusiones. Separa cada ítem con una coma (,) o un signo más (+) para enlistarlo (máx. 300 caracteres).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              CampoTextoCristal(
                controller: controlador.planNoCubreModalController,
                hintText: 'Ej: No incluye pulido, No incluye lavado de chasis',
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              const Text('Precio final', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CampoTextoCristal(controller: controlador.planPrecioModalController, hintText: 'Precio final \$', tecladoNumerico: true),
              const SizedBox(height: 16),

              const Text('Tiempo estimado para este plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // 🚨 ListenableBuilder envolviendo solo la parte que cambia (Reactividad sin romper UI estricta)
              ListenableBuilder(
                listenable: controlador,
                builder: (context, _) {
                  return GestureDetector(
                    onTap: () async {
                      final opciones = ['30 min aprox.', '1 hora aprox.', '1 hora y media aprox.', '2 horas aprox.', '3 horas aprox.', 'A convenir', 'Sin duración'];
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Duración del plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ...opciones.map((op) => ListTile(
                                title: Text(op, style: const TextStyle(fontSize: 16)),
                                onTap: () => Navigator.pop(c, op),
                              )).toList(),
                            ],
                          ),
                        ),
                      );
                      
                      if (result != null) {
                        controlador.actualizarDuracionPlanModal(result);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.white,
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(controlador.planDuracionModalSeleccionada, style: const TextStyle(fontSize: 14)),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey)
                        ],
                      ),
                    ),
                  );
                }
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: BotonAccionPrincipal(
                  texto: 'Guardar Cambios',
                  onPressed: () {
                    controlador.guardarEditorPlan(nivelAEditar.idNivel);
                    Navigator.pop(ctx);
                  },
                ),
              )
            ],
          ),
          ),
        );
      }
    );
  }

  void _mostrarDialogoExtra(BuildContext context, {int? indexAEditar}) {
    controlador.prepararEditorExtra(index: indexAEditar);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(indexAEditar != null ? 'Editar Extra' : 'Nuevo Extra Opcional', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CampoTextoCristal(controller: controlador.extraNombreModalController, hintText: 'Ej: Limpieza de motor, Barnizado, etc.'),
              const SizedBox(height: 12),
              CampoTextoCristal(controller: controlador.extraPrecioModalController, hintText: 'Precio Adicional \$', tecladoNumerico: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: BotonAccionPrincipal(
                  texto: indexAEditar != null ? 'Guardar Cambios' : 'Agregar Extra',
                  onPressed: () {
                    controlador.guardarEditorExtra(index: indexAEditar);
                    Navigator.pop(ctx);
                  },
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorAcento = tema.colorScheme.primary;
    final esOscuro = tema.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IgnorePointer(
            ignoring: controlador.modoLectura,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Disponibilidad y calendario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Días disponibles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _diasSemana.entries.map((entry) {
                      final isSel = controlador.diasLaboralesSeleccionados.contains(entry.key);
                      return GestureDetector(
                        onTap: () => controlador.toggleDiaLaboral(entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? colorAcento.withOpacity(0.05) : Colors.transparent,
                            border: Border.all(color: isSel ? colorAcento : (esOscuro ? Colors.white24 : Colors.grey.shade300)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              if (isSel) ...[Icon(Icons.check_circle, size: 14, color: colorAcento), const SizedBox(width: 4)],
                              Text(entry.value, style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? colorAcento : Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Horarios disponibles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: controlador,
                  builder: (context, _) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Desde', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _seleccionarHora(context, true),
                                  child: _SelectorDropdown(texto: '${controlador.horarioApertura.hour.toString().padLeft(2, '0')}:${controlador.horarioApertura.minute.toString().padLeft(2, '0')}'),
                                ),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Hasta', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _seleccionarHora(context, false),
                                  child: _SelectorDropdown(texto: '${controlador.horarioCierre.hour.toString().padLeft(2, '0')}:${controlador.horarioCierre.minute.toString().padLeft(2, '0')}'),
                                ),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: esOscuro ? Colors.white10 : Colors.white,
                            border: Border.all(color: esOscuro ? Colors.white24 : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: const Text('Habilitar doble jornada (cortar al medio día)', style: TextStyle(fontSize: 14)),
                            value: controlador.dobleJornada,
                            activeColor: colorAcento,
                            onChanged: (v) => controlador.toggleDobleJornada(v),
                          ),
                        ),
                        if (controlador.dobleJornada) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Desde', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _seleccionarHora2(context, true),
                                    child: _SelectorDropdown(texto: '${controlador.horarioApertura2.hour.toString().padLeft(2, '0')}:${controlador.horarioApertura2.minute.toString().padLeft(2, '0')}'),
                                  ),
                                ]),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Hasta', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _seleccionarHora2(context, false),
                                    child: _SelectorDropdown(texto: '${controlador.horarioCierre2.hour.toString().padLeft(2, '0')}:${controlador.horarioCierre2.minute.toString().padLeft(2, '0')}'),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                const Text('Tiempos de traslado y preparación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Especifica cuánto tiempo necesitas bloquear para ir de un servicio a otro, o cuánto tiempo necesitas después de terminar para preparar todo. Esto bloquea el calendario automáticamente para que no se peguen las reservas.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: controlador,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SECCIÓN ANTES ---
                        const Text('Antes del servicio (Traslado/Preparación)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Horas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  CampoTextoCristal(
                                    controller: controlador.tiempoAntesHorasController,
                                    hintText: '0',
                                    tecladoNumerico: true,
                                    onChanged: (v) => controlador.actualizarTiempoMuertoAntes(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Minutos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  CampoTextoCristal(
                                    controller: controlador.tiempoAntesMinutosController,
                                    hintText: '40',
                                    tecladoNumerico: true,
                                    onChanged: (v) => controlador.actualizarTiempoMuertoAntes(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // --- SECCIÓN DESPUÉS ---
                        const Text('Después del servicio (Limpieza/Cierre)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Horas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  CampoTextoCristal(
                                    controller: controlador.tiempoDespuesHorasController,
                                    hintText: '0',
                                    tecladoNumerico: true,
                                    onChanged: (v) => controlador.actualizarTiempoMuertoDespues(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Minutos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  CampoTextoCristal(
                                    controller: controlador.tiempoDespuesMinutosController,
                                    hintText: '40',
                                    tecladoNumerico: true,
                                    onChanged: (v) => controlador.actualizarTiempoMuertoDespues(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Frecuencia de turnos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text(
                          'Genera opciones de turnos cada cierta cantidad de minutos (Ej: Cada 30 o 60 min). Reducir este tiempo genera más opciones para el cliente y ayuda a encajar turnos entre tiempos muertos, pero mantén un mínimo de 30 minutos.', 
                          style: TextStyle(fontSize: 12, color: Colors.grey)
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Minutos (Mínimo 30)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  CampoTextoCristal(
                                    controller: controlador.frecuenciaSlotsController,
                                    hintText: '60',
                                    tecladoNumerico: true,
                                    onChanged: (v) => controlador.actualizarFrecuenciaSlots(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                ),
                
                const SizedBox(height: 32),
                
                const Text('Planes y precios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Habilita los planes que ofreces. (Mínimo 1)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                
                ...controlador.nivelesAgregados.map((nivel) {
                  return TarjetaPlanCreado(
                    titulo: nivel.nombre,
                    subtitulo: nivel.descripcionCorta.isEmpty ? 'Toca el lápiz para añadir los beneficios' : nivel.descripcionCorta,
                    precio: nivel.precioFijo,
                    duracionEstimada: nivel.duracionEstimada, 
                    seleccionada: controlador.nivelesSeleccionados.contains(nivel.idNivel),
                    loQueCubre: nivel.caracteristicasProcesadas,
                    loQueNoCubre: nivel.loQueNoCubreProcesado,
                    onToggle: () => controlador.toggleSeleccionNivel(nivel.idNivel),
                    onEditar: () => _mostrarDialogoPlan(context, nivelAEditar: nivel),
                  );
                }).toList(),

                const SizedBox(height: 32),

                const Text('Extras opcionales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                if (controlador.extrasOpcionalesMock.isEmpty)
                  const Text('Puedes agregar acciones o detalles adicionales para que el cliente los sume al plan que eligio.', style: TextStyle(fontSize: 13, color: Colors.grey)),

                ...controlador.extrasOpcionalesMock.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> extra = entry.value;
                  return ItemExtraOpcional(
                    nombre: extra['nombre'],
                    precio: extra['precio'].toDouble(),
                    seleccionado: extra['seleccionado'],
                    onEditar: () => _mostrarDialogoExtra(context, indexAEditar: idx),
                    onChanged: (val) => controlador.toggleExtra(idx, val ?? false),
                  );
                }).toList(),

                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _mostrarDialogoExtra(context),
                  icon: Icon(Icons.add, color: colorAcento, size: 18),
                  label: Text('Agregar extra', style: TextStyle(color: colorAcento)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: esOscuro ? Colors.white12 : Colors.grey.shade200),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                ),
              ],
            ),
          ), 

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: BotonAccionPrincipal(
              texto: 'Continuar',
              onPressed: () {
                if (controlador.modoLectura) {
                  controlador.siguientePaso();
                } else {
                  controlador.validarPaso2((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: ColoresApp.errorRojo));
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SelectorDropdown extends StatelessWidget {
  final String texto;
  const _SelectorDropdown({required this.texto});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white10 : Colors.white,
        border: Border.all(color: esOscuro ? Colors.white24 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(texto, style: const TextStyle(fontSize: 14)),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
        ],
      ),
    );
  }
}