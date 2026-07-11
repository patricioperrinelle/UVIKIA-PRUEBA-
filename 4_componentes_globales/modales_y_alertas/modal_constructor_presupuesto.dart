// lib/4_componentes_globales/modales_y_alertas/modal_constructor_presupuesto.dart
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';

class ModalConstructorPresupuesto extends StatefulWidget {
  final String tituloTrabajo;
  final double precioBase;
  final List<Map<String, dynamic>> itemsDb;
  final bool bloqueado;
  final Function(List<Map<String, dynamic>>) onEnviar;

  const ModalConstructorPresupuesto({
    Key? key,
    required this.tituloTrabajo,
    required this.precioBase,
    required this.itemsDb,
    required this.bloqueado,
    required this.onEnviar,
  }) : super(key: key);

  @override
  State<ModalConstructorPresupuesto> createState() => _ModalConstructorPresupuestoState();
}

class _ModalConstructorPresupuestoState extends State<ModalConstructorPresupuesto> {
  final List<Map<String, dynamic>> _itemsBorrador = [];
  
  final TextEditingController _txtConcepto = TextEditingController();
  final TextEditingController _txtMonto = TextEditingController();
  final FocusNode _focusConcepto = FocusNode();

  @override
  void initState() {
    super.initState();
    _cargarDesdeDb();
  }

  @override
  void didUpdateWidget(ModalConstructorPresupuesto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hashItems(oldWidget.itemsDb) != _hashItems(widget.itemsDb) || oldWidget.bloqueado != widget.bloqueado) {
      _cargarDesdeDb();
    }
  }

  String _hashItems(List<Map<String, dynamic>> items) {
    return items.map((e) => "${e['concepto']}_${e['monto']}_${e['estado']}").join('|');
  }

  void _cargarDesdeDb() {
    _itemsBorrador.clear();
    for (var adic in widget.itemsDb) {
      _itemsBorrador.add({'id': adic['id'], 'concepto': adic['concepto'], 'monto': adic['monto']});
    }
  }

  @override
  void dispose() {
    _txtConcepto.dispose();
    _txtMonto.dispose();
    _focusConcepto.dispose();
    super.dispose();
  }

  void _agregarItemAlBorrador() {
    final concepto = _txtConcepto.text.trim();
    final montoLimpio = _txtMonto.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final monto = double.tryParse(montoLimpio) ?? 0.0;

    if (concepto.isNotEmpty && monto > 0) {
      setState(() {
        _itemsBorrador.add({'concepto': concepto, 'monto': monto});
      });
      _txtConcepto.clear();
      _txtMonto.clear();
      _focusConcepto.requestFocus(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un concepto y un precio válido.')));
    }
  }

  void _eliminarBorrador(int index) {
    setState(() { _itemsBorrador.removeAt(index); });
  }

  double get _totalActualizado {
    double total = widget.precioBase;
    for (var borrador in _itemsBorrador) {
      total += double.tryParse(borrador['monto'].toString()) ?? 0.0;
    }
    return total;
  }

  bool get _huboCambios {
    final dbItems = widget.itemsDb;
    if (dbItems.length != _itemsBorrador.length) return true;
    for (int i = 0; i < _itemsBorrador.length; i++) {
      if (_itemsBorrador[i]['concepto'] != dbItems[i]['concepto']) return true;
      if (_itemsBorrador[i]['monto'] != dbItems[i]['monto']) return true;
    }
    if (dbItems.any((e) => e['estado'] == 'rechazado')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    const colorAcento = ColoresApp.terciarioMorado;

    return Container(
      margin: EdgeInsets.only(top: kToolbarHeight, bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(color: tema.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: colorAcento, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ticket de Presupuesto', style: EstilosTextoApp.h2.copyWith(color: tema.colorScheme.onSurface, fontSize: 18)),
                        Text(widget.tituloTrabajo, style: EstilosTextoApp.cuerpoPequeno.copyWith(color: tema.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context))
                ],
              ),
            ),
            
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Precio Base Fijo', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                      // 🚨 AISLAMIENTO DE TIPOGRAFÍA (Agnóstico)
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                            TextSpan(text: widget.precioBase.toStringAsFixed(0)),
                          ]
                        ),
                        style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_itemsBorrador.isNotEmpty) ...[
                    Text('Ítems en el ticket:', style: EstilosTextoApp.cuerpoPequeno.copyWith(color: tema.hintColor)),
                    const SizedBox(height: 8),
                    ..._itemsBorrador.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, dynamic> item = entry.value;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.surface, 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tema.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(item['concepto'], style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface))),
                            // 🚨 AISLAMIENTO DE TIPOGRAFÍA
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                                  TextSpan(text: item['monto'].toString()),
                                ]
                              ),
                              style: EstilosTextoApp.cuerpoDestacado.copyWith(color: colorAcento),
                            ),
                            const SizedBox(width: 8),
                            if (!widget.bloqueado)
                              GestureDetector(
                                onTap: () => _eliminarBorrador(idx),
                                child: const Icon(Icons.delete_outline_rounded, color: ColoresApp.errorRojo, size: 22),
                              )
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  Text('Agregar nuevo ítem', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _txtConcepto, focusNode: _focusConcepto, enabled: !widget.bloqueado,
                          style: TextStyle(color: tema.colorScheme.onSurface),
                          decoration: InputDecoration(labelText: 'Ej: Materiales', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _txtMonto, enabled: !widget.bloqueado, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: tema.colorScheme.onSurface),
                          decoration: InputDecoration(labelText: '\$ Precio', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: widget.bloqueado ? tema.disabledColor : colorAcento, borderRadius: BorderRadius.circular(12)),
                        child: IconButton(icon: const Icon(Icons.add_rounded, color: Colors.white), onPressed: widget.bloqueado ? null : _agregarItemAlBorrador),
                      )
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: tema.colorScheme.surface, border: Border(top: BorderSide(color: tema.dividerColor))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NUEVO TOTAL', style: EstilosTextoApp.h2.copyWith(color: tema.colorScheme.onSurface, fontSize: 18)),
                      // 🚨 AISLAMIENTO DE TIPOGRAFÍA
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                            TextSpan(text: _totalActualizado.toStringAsFixed(0)),
                          ]
                        ),
                        style: EstilosTextoApp.h2.copyWith(color: colorAcento, fontSize: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.bloqueado || !_huboCambios ? null : () {
                        widget.onEnviar(_itemsBorrador);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorAcento,
                        disabledBackgroundColor: tema.disabledColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.bloqueado 
                          ? 'ESPERANDO RESPUESTA DEL CLIENTE...' 
                          : (_huboCambios ? 'ENVIAR TICKET ACTUALIZADO' : 'AGREGA O QUITA ÍTEMS PARA ENVIAR'), 
                        style: TextStyle(
                          color: widget.bloqueado || !_huboCambios ? tema.hintColor : Colors.white, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}