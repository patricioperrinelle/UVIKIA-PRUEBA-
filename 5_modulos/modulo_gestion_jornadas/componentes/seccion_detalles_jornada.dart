// lib/5_modulos/modulo_gestion_jornadas/componentes/seccion_detalles_jornada.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_minimalista_base.dart';
import '../../../4_componentes_globales/indicadores/columna_info_destacada.dart';
import '../../../4_componentes_globales/tarjetas/panel_contacto_liberado.dart';

class SeccionDetallesJornada extends StatefulWidget {
  final bool vistaMinimalista; 
  final List<String> imagenes;
  final String titulo;
  final String precio;
  final String descripcionLimpia;
  final String requisitosLimpios;
  final String fechaFormateada;
  final String fechaSubLabel; 
  final String horarioLimpio;
  final String horarioSubLabel; 
  final String ubicacionFinal;
  final String referenciaLugar;
  
  final bool mostrarContactoLiberado;
  final String ubicacionMaps;
  final String telefonoContacto;

  const SeccionDetallesJornada({
    Key? key,
    this.vistaMinimalista = true,
    required this.imagenes,
    required this.titulo,
    required this.precio,
    required this.descripcionLimpia,
    required this.requisitosLimpios,
    required this.fechaFormateada,
    required this.fechaSubLabel,
    required this.horarioLimpio,
    required this.horarioSubLabel,
    required this.ubicacionFinal,
    this.referenciaLugar = '',
    this.mostrarContactoLiberado = false,
    this.ubicacionMaps = '',
    this.telefonoContacto = '',
  }) : super(key: key);

  @override
  State<SeccionDetallesJornada> createState() => _SeccionDetallesJornadaState();
}

class _SeccionDetallesJornadaState extends State<SeccionDetallesJornada> {
  bool _expandido = false;

  List<String> _parsearRequisitos() {
    if (widget.requisitosLimpios.trim().isEmpty || widget.requisitosLimpios.trim().toLowerCase() == 'ninguno') {
      return['Experiencia comprobable', 'Buena presencia y trato', 'Disponibilidad horaria']; 
    }
    return widget.requisitosLimpios.split(RegExp(r'\n|- |• ')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorTexto = esOscuro ? Colors.white : Colors.black;

    if (!widget.vistaMinimalista) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(widget.titulo, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorTexto, height: 1.2, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          TarjetaMinimalistaBase(
            child: IntrinsicHeight(
              child: Row(
                children:[
                  Expanded(flex: 10, child: ColumnaInfoDestacada(icono: Icons.calendar_today_outlined, label: 'Fecha', valor: widget.fechaFormateada, subLabel: widget.fechaSubLabel)),
                  VerticalDivider(color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200, width: 12, thickness: 1),
                  Expanded(flex: 9, child: ColumnaInfoDestacada(icono: Icons.access_time_rounded, label: 'Horario', valor: widget.horarioLimpio, subLabel: widget.horarioSubLabel)),
                  VerticalDivider(color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200, width: 12, thickness: 1),
                  // 🔥 SEPARACIÓN APLICADA AQUÍ: Se inyecta prefijoValor: '$ '
                  Expanded(flex: 12, child: ColumnaInfoDestacada(icono: Icons.payments_outlined, label: 'Pago por jornada', prefijoValor: '\$ ', valor: widget.precio, subLabel: 'Total jornada', colorValor: ColoresApp.primarioVerde)),
                ],
              ),
            ),
          ),
          TarjetaMinimalistaBase(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children:[Icon(Icons.location_on_outlined, color: colorTexto, size: 20), const SizedBox(width: 8), Text('Ubicación', style: TextStyle(fontSize: 14, color: colorTexto))]),
                const SizedBox(height: 12),
                Text(widget.ubicacionFinal, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTexto)),
                if (widget.referenciaLugar.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.referenciaLugar, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.3))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          TarjetaMinimalistaBase(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Row(children:[Icon(Icons.description_outlined, color: colorTexto, size: 20), const SizedBox(width: 8), Text('Descripción del trabajo', style: TextStyle(fontSize: 14, color: colorTexto))]),
                const SizedBox(height: 12),
                Text(widget.descripcionLimpia, style: TextStyle(fontSize: 15, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.5)),
              ],
            ),
          ),
          TarjetaMinimalistaBase(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children:[Icon(Icons.fact_check_outlined, color: colorTexto, size: 20), const SizedBox(width: 8), Text('Requisitos', style: TextStyle(fontSize: 14, color: colorTexto))]),
                const SizedBox(height: 16),
                ..._parsearRequisitos().map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          const Icon(Icons.check_circle_outline, color: ColoresApp.primarioVerde, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(req, style: TextStyle(fontSize: 15, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.4))),
                        ],
                      ),
                    )).toList(),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: DimensionesApp.radioTarjetas,
        border: Border.all(color: esOscuro ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.imagenes.isNotEmpty 
                    ? Image.network(widget.imagenes.first, width: 64, height: 64, fit: BoxFit.cover)
                    : Container(width: 64, height: 64, color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.work_outline)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(widget.titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTexto, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children:[
                          Icon(Icons.calendar_today, size: 12, color: tema.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Expanded(child: Text('${widget.fechaFormateada}  •  ${widget.horarioLimpio}', style: TextStyle(fontSize: 12, color: tema.textTheme.bodySmall?.color), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children:[
                          Icon(Icons.location_on_outlined, size: 12, color: tema.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Expanded(child: Text(widget.ubicacionFinal, style: TextStyle(fontSize: 12, color: tema.textTheme.bodySmall?.color), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children:[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children:[
                        const Text('\$ ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColoresApp.terciarioMorado)),
                        Text(widget.precio, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColoresApp.terciarioMorado)),
                      ],
                    ),
                    Text('por jornada', style: TextStyle(fontSize: 11, color: tema.textTheme.bodySmall?.color)),
                  ],
                ),
              ],
            ),
          ),
          
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: esOscuro ? Colors.white.withOpacity(0.02) : ColoresApp.terciarioMorado.withOpacity(0.05),
                borderRadius: _expandido ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Text(_expandido ? 'Ocultar detalles' : 'Ver detalles de la jornada', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ColoresApp.terciarioMorado)),
                  const SizedBox(width: 4),
                  Icon(_expandido ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: ColoresApp.terciarioMorado, size: 18),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  if (widget.mostrarContactoLiberado)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      // 🚨 FIX AQUÍ: Se cambió el nombre de PanelContactoLiberadoCliente a PanelContactoLiberado
                      child: PanelContactoLiberado(
                        ubicacionMaps: widget.ubicacionMaps, 
                        telefono: widget.telefonoContacto,
                      ),
                    ),

                  if (widget.referenciaLugar.isNotEmpty)
                    TarjetaMinimalistaBase(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children:[Icon(Icons.info_outline, color: colorTexto, size: 18), const SizedBox(width: 8), Text('Referencias del lugar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorTexto))]),
                          const SizedBox(height: 12),
                          Text(widget.referenciaLugar, style: TextStyle(fontSize: 14, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.5)),
                        ],
                      ),
                    ),

                  TarjetaMinimalistaBase(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children:[Icon(Icons.description_outlined, color: colorTexto, size: 18), const SizedBox(width: 8), Text('Descripción del trabajo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorTexto))]),
                        const SizedBox(height: 12),
                        Text(widget.descripcionLimpia, style: TextStyle(fontSize: 14, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.5)),
                      ],
                    ),
                  ),
                  TarjetaMinimalistaBase(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Row(children:[Icon(Icons.fact_check_outlined, color: colorTexto, size: 18), const SizedBox(width: 8), Text('Requisitos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorTexto))]),
                        const SizedBox(height: 16),
                        ..._parsearRequisitos().map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  const Icon(Icons.check_circle, color: ColoresApp.terciarioMorado, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(req, style: TextStyle(fontSize: 14, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.4))),
                                ],
                              ),
                            )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expandido ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          )
        ],
      ),
    );
  }
}