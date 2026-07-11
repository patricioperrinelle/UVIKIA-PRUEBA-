// lib/5_modulos/modulo_negociacion_oficios/componentes/seccion_detalles_trabajo.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/tarjetas/tarjeta_minimalista_base.dart';
import '../../../4_componentes_globales/indicadores/columna_info_destacada.dart';
import '../../../4_componentes_globales/tarjetas/panel_contacto_liberado.dart'; 

class SeccionDetallesTrabajo extends StatefulWidget {
  final bool vistaMinimalista; 
  final List<String> imagenes;
  final String title;
  final String displayPrice;
  final String metodoPagoElegido;
  final String formattedDate;
  final String fechaSubLabel;
  final String horarioLimpio;
  final String horarioSubLabel;
  final String mainDesc;
  final String requisitos;
  final String ubicacionFinal;
  final String referenciaLugar;
  final bool mostrarContactoLiberado;
  final String ubicacionMaps;
  final String telefonoContacto;

  const SeccionDetallesTrabajo({
    Key? key,
    this.vistaMinimalista = true,
    required this.imagenes,
    required this.title,
    required this.displayPrice,
    required this.metodoPagoElegido,
    required this.formattedDate,
    required this.fechaSubLabel,
    required this.horarioLimpio,
    required this.horarioSubLabel,
    required this.mainDesc,
    required this.requisitos,
    required this.ubicacionFinal,
    this.referenciaLugar = '',
    this.mostrarContactoLiberado = false,
    this.ubicacionMaps = '',
    this.telefonoContacto = '',
  }) : super(key: key);

  @override
  State<SeccionDetallesTrabajo> createState() => _SeccionDetallesTrabajoState();
}

class _SeccionDetallesTrabajoState extends State<SeccionDetallesTrabajo> {
  bool _expandido = false;

  List<String> _parsearHerramientas() {
    if (widget.requisitos.trim().isEmpty || widget.requisitos.trim().toLowerCase() == 'ninguno') {
      return ['No se requieren herramientas específicas para este trabajo.']; 
    }
    return widget.requisitos.split(RegExp(r'\n|- |• ')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorTexto = esOscuro ? Colors.white : Colors.black;
    final String precioSubLabel = widget.metodoPagoElegido.isNotEmpty ? 'Total (${widget.metodoPagoElegido.toUpperCase()})' : 'Presupuesto';

    if (!widget.vistaMinimalista) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text(widget.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorTexto, height: 1.2, letterSpacing: -0.5)),
            const SizedBox(height: 20),
            TarjetaMinimalistaBase(
              child: Row(
                children:[
                  Expanded(flex: 10, child: ColumnaInfoDestacada(icono: Icons.calendar_today_outlined, label: 'Fecha', valor: widget.formattedDate, subLabel: widget.fechaSubLabel)),
                  Container(width: 1, height: 40, color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200),
                  Expanded(flex: 9, child: ColumnaInfoDestacada(icono: Icons.access_time_rounded, label: 'Horario', valor: widget.horarioLimpio, subLabel: widget.horarioSubLabel)),
                  Container(width: 1, height: 40, color: esOscuro ? ColoresApp.bordeCristal : Colors.grey.shade200),
                  Expanded(flex: 12, child: ColumnaInfoDestacada(icono: Icons.payments_outlined, label: 'Monto', prefijoValor: '\$ ', valor: widget.displayPrice.replaceAll('\$ ', ''), subLabel: precioSubLabel, colorValor: ColoresApp.primarioVerde)),
                ],
              ),
            ),
            TarjetaMinimalistaBase(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
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
                  Text(widget.mainDesc, style: TextStyle(fontSize: 15, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.5)),
                ],
              ),
            ),
            TarjetaMinimalistaBase(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(children:[Icon(Icons.build_circle_outlined, color: colorTexto, size: 20), const SizedBox(width: 8), Text('Herramientas y requisitos', style: TextStyle(fontSize: 14, color: colorTexto))]),
                  const SizedBox(height: 16),
                  ..._parsearHerramientas().map((req) => Padding(
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
        ),
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
                    ? CachedNetworkImage(
                        imageUrl: widget.imagenes.first,
                        width: 64, 
                        height: 64, 
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(width: 64, height: 64, color: Colors.grey.withOpacity(0.2)),
                        errorWidget: (context, url, error) => Container(width: 64, height: 64, color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.broken_image)),
                      )
                    : Container(width: 64, height: 64, color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.work_outline)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTexto, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children:[
                          Icon(Icons.calendar_today, size: 12, color: tema.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Expanded(child: Text('${widget.formattedDate}  •  ${widget.horarioLimpio}', style: TextStyle(fontSize: 12, color: tema.textTheme.bodySmall?.color), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                    // 🚨 AISLAMIENTO DE TIPOGRAFÍA ESTRUCTURAL
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                          TextSpan(text: widget.displayPrice.replaceAll('\$ ', '')),
                        ]
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde),
                    ),
                    Text(precioSubLabel, style: TextStyle(fontSize: 11, color: tema.textTheme.bodySmall?.color)),
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
                color: esOscuro ? Colors.white.withOpacity(0.02) : ColoresApp.primarioVerde.withOpacity(0.05),
                borderRadius: _expandido ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Text(_expandido ? 'Ocultar detalles' : 'Ver detalles del trabajo', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
                  const SizedBox(width: 4),
                  Icon(_expandido ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: ColoresApp.primarioVerde, size: 18),
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
                        Text(widget.mainDesc, style: TextStyle(fontSize: 14, color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.5)),
                      ],
                    ),
                  ),
                  TarjetaMinimalistaBase(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Row(children:[Icon(Icons.build_circle_outlined, color: colorTexto, size: 18), const SizedBox(width: 8), Text('Herramientas y requisitos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorTexto))]),
                        const SizedBox(height: 16),
                        ..._parsearHerramientas().map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  const Icon(Icons.check_circle, color: ColoresApp.primarioVerde, size: 18),
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