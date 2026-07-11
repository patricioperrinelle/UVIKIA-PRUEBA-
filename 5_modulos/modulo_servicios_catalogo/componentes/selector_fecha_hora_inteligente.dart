// lib/5_modulos/modulo_servicios_catalogo/componentes/selector_fecha_hora_inteligente.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';

class SelectorFechaHoraInteligente extends StatefulWidget {
  final List<DateTime> diasDisponibles; 
  final List<int> diasLaborales; 
  final DateTime fechaSeleccionada;
  final Function(DateTime) onFechaSeleccionada;
  final List<DateTime> horasHabilitadas;
  final List<DateTime> todasLasHoras;
  final DateTime? horaSeleccionada;
  final Function(DateTime) onHoraSeleccionada;
  final bool isLoadingHoras; 
  final String Function(DateTime) formateadorFecha; 

  const SelectorFechaHoraInteligente({
    Key? key,
    required this.diasDisponibles,
    required this.diasLaborales,
    required this.fechaSeleccionada,
    required this.onFechaSeleccionada,
    required this.horasHabilitadas,
    required this.todasLasHoras,
    this.horaSeleccionada,
    required this.onHoraSeleccionada,
    this.isLoadingHoras = false,
    required this.formateadorFecha,
  }) : super(key: key);

  @override
  _SelectorFechaHoraInteligenteState createState() => _SelectorFechaHoraInteligenteState();
}

class _SelectorFechaHoraInteligenteState extends State<SelectorFechaHoraInteligente> {
  late DateTime _mesActual;

  @override
  void initState() {
    super.initState();
    _mesActual = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month, 1);
  }

  @override
  void didUpdateWidget(SelectorFechaHoraInteligente oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la fecha seleccionada cambia de mes, actualizamos el mes en vista
    if (widget.fechaSeleccionada.month != oldWidget.fechaSeleccionada.month ||
        widget.fechaSeleccionada.year != oldWidget.fechaSeleccionada.year) {
      _mesActual = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month, 1);
    }
  }

  bool _esPasado(DateTime dia) {
    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final diaSoloFecha = DateTime(dia.year, dia.month, dia.day);
    return diaSoloFecha.isBefore(hoySoloFecha);
  }

  bool _esSeleccionable(DateTime dia) {
    if (_esPasado(dia)) return false;
    return widget.diasLaborales.contains(dia.weekday);
  }

  int _diasEnMes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month + 1, 0).day;
  }

  void _irMesAnterior() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month - 1, 1);
    });
  }

  void _irMesSiguiente() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    // El color de acento semántico del cliente es el verde
    const colorAcento = ColoresApp.primarioVerde;

    const meses = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    const diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    final primerDiaSemana = DateTime(_mesActual.year, _mesActual.month, 1).weekday; // 1 = Lun, 7 = Dom
    final diasVacios = primerDiaSemana - 1;
    final totalDias = _diasEnMes(_mesActual);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CALENDARIO MENSUAL PREMIUM
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: esOscuro ? ColoresApp.fondoTarjetas : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: esOscuro ? ColoresApp.bordeOscuro : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Cabecera: Mes, Año y Chevrons de navegación
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${meses[_mesActual.month]} ${_mesActual.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: esOscuro ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 24),
                        color: esOscuro ? Colors.white70 : Colors.black54,
                        onPressed: _irMesAnterior,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 24),
                        color: esOscuro ? Colors.white70 : Colors.black54,
                        onPressed: _irMesSiguiente,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Cabecera Días de la Semana
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: diasSemana.map((dia) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        dia,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: esOscuro ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              
              // Grilla de días
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: diasVacios + totalDias,
                itemBuilder: (context, index) {
                  if (index < diasVacios) {
                    return const SizedBox();
                  }

                  final diaNum = index - diasVacios + 1;
                  final diaDate = DateTime(_mesActual.year, _mesActual.month, diaNum);
                  
                  final isSelected = diaDate.year == widget.fechaSeleccionada.year &&
                      diaDate.month == widget.fechaSeleccionada.month &&
                      diaDate.day == widget.fechaSeleccionada.day;
                  
                  final hoy = DateTime.now();
                  final esHoy = diaDate.year == hoy.year &&
                      diaDate.month == hoy.month &&
                      diaDate.day == hoy.day;

                  final esSeleccionable = _esSeleccionable(diaDate);

                  return GestureDetector(
                    onTap: esSeleccionable ? () => widget.onFechaSeleccionada(diaDate) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorAcento
                            : (esHoy ? colorAcento.withOpacity(0.08) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : (esHoy
                                ? Border.all(color: colorAcento.withOpacity(0.3), width: 1.5)
                                : null),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            diaNum.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (esSeleccionable
                                      ? (esOscuro ? Colors.white : Colors.black87)
                                      : (esOscuro ? Colors.white24 : Colors.grey.shade300)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Pequeño punto verde debajo de los números de los días disponibles
                          if (esSeleccionable)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white70 : colorAcento,
                              ),
                            )
                          else
                            const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 2. SELECTOR DE HORAS (Grilla Wrap)
        if (widget.isLoadingHoras)
          const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: colorAcento)))
        else if (widget.todasLasHoras.isEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: esOscuro ? Colors.white10 : Colors.grey.shade100, 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: esOscuro ? Colors.white12 : Colors.grey.shade200),
            ),
            child: const Text(
              'No hay horarios configurados para este día.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Turnos disponibles', 
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: esOscuro ? Colors.white70 : Colors.black87)
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: widget.todasLasHoras.map((hora) {
                  final isSelected = widget.horaSeleccionada == hora;
                  final isAvailable = widget.horasHabilitadas.any((h) => h.isAtSameMomentAs(hora));
                  final horaString = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                  
                  Color bgColor;
                  Color textColor;
                  Color borderColor;

                  if (isSelected) {
                    bgColor = colorAcento;
                    textColor = Colors.white;
                    borderColor = colorAcento;
                  } else if (isAvailable) {
                    bgColor = esOscuro ? Colors.white10 : Colors.white;
                    textColor = esOscuro ? Colors.white : Colors.black87;
                    borderColor = esOscuro ? Colors.white54 : Colors.black87;
                  } else {
                    bgColor = esOscuro ? Colors.white10 : Colors.grey.shade200;
                    textColor = esOscuro ? Colors.white38 : Colors.grey.shade400;
                    borderColor = esOscuro ? Colors.white12 : Colors.grey.shade300;
                  }
                  
                  return GestureDetector(
                    onTap: isAvailable ? () => widget.onHoraSeleccionada(hora) : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
                          ),
                          child: Text(
                            horaString, textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected || isAvailable ? FontWeight.bold : FontWeight.w500, 
                              color: textColor,
                            ),
                          ),
                        ),
                        if (!isAvailable)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: esOscuro ? Colors.white38 : Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }
}