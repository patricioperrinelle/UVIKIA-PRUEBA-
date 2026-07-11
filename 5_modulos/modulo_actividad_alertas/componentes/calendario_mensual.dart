// lib/5_modulos/modulo_actividad_alertas/componentes/calendario_mensual.dart
import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';

class CalendarioMensual extends StatefulWidget {
  final DateTime fechaSeleccionada;
  final Function(DateTime) onFechaSeleccionada;
  final Map<DateTime, int> fechasConEventos;
  final Color colorAcento;

  const CalendarioMensual({
    Key? key,
    required this.fechaSeleccionada,
    required this.onFechaSeleccionada,
    this.fechasConEventos = const {},
    this.colorAcento = ColoresApp.primarioVerde,
  }) : super(key: key);

  @override
  State<CalendarioMensual> createState() => _CalendarioMensualState();
}

class _CalendarioMensualState extends State<CalendarioMensual> {
  late DateTime _mesActual;

  final List<String> _diasSemana = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  final List<String> _diasSemanaCompletos = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final List<String> _nombresMeses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _mesActual = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month);
  }

  @override
  void didUpdateWidget(CalendarioMensual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fechaSeleccionada != oldWidget.fechaSeleccionada) {
      // If the parent forced a new date (e.g. resetting to today), update our month view to match
      if (_mesActual.year != widget.fechaSeleccionada.year || _mesActual.month != widget.fechaSeleccionada.month) {
        _mesActual = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month);
      }
    }
  }

  void _mesAnterior() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month - 1);
    });
  }

  void _mesSiguiente() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + 1);
    });
  }
  
  void _volverAHoy() {
    final hoy = DateTime.now();
    setState(() {
      _mesActual = DateTime(hoy.year, hoy.month);
    });
    widget.onFechaSeleccionada(hoy);
  }

  List<DateTime> _diasDelMes(DateTime mes) {
    final primerDiaDelMes = DateTime(mes.year, mes.month, 1);
    final diasAntes = primerDiaDelMes.weekday - 1;
    final primerDiaAMostrar = primerDiaDelMes.subtract(Duration(days: diasAntes));

    List<DateTime> dias = [];
    for (int i = 0; i < 42; i++) {
      dias.add(primerDiaAMostrar.add(Duration(days: i)));
    }
    return dias;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final dias = _diasDelMes(_mesActual);

    // Si la última fila es de otro mes completamente, podríamos ocultarla para ahorrar espacio,
    // pero para mantener un grid constante de 6 filas (42 días), lo dejamos.
    // Aunque en la imagen se ve que si la última fila sobra (ej: empieza en 30, 1,2,3,4,5,6), 
    // a veces se muestran 6 semanas.

    return Container(
      color: tema.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
            child: Text(
              'Agenda programada para los días...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '${_diasSemanaCompletos[DateTime.now().weekday - 1]} ${DateTime.now().day}',
                  style: TextStyle(
                    color: esOscuro ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _mesAnterior,
                    splashRadius: 24,
                  ),
                  Text(
                    '${_nombresMeses[_mesActual.month - 1]} ${_mesActual.year}',
                    style: EstilosTextoApp.h3.copyWith(
                      color: tema.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _mesSiguiente,
                    splashRadius: 24,
                  ),
                ],
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, size: 20),
                    onPressed: _volverAHoy,
                    splashRadius: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _diasSemana.asMap().entries.map((entry) {
              int idx = entry.key;
              String dia = entry.value;
              bool esDiaDeHoy = (idx + 1) == DateTime.now().weekday;

              return Container(
                width: 32,
                padding: esDiaDeHoy ? const EdgeInsets.symmetric(vertical: 4) : null,
                decoration: esDiaDeHoy ? BoxDecoration(
                  color: esOscuro ? Colors.white24 : Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ) : null,
                child: Text(
                  dia,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: esDiaDeHoy ? Colors.white : Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Grid de días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dia = dias[index];
              return _buildDia(dia, tema, esOscuro);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDia(DateTime dia, ThemeData tema, bool esOscuro) {
    final hoy = DateTime.now();
    final diaNormalizado = DateTime(dia.year, dia.month, dia.day);
    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
    
    bool esHoy = diaNormalizado == hoyNormalizado;
    bool esPasado = diaNormalizado.isBefore(hoyNormalizado);
    bool esFuturo = diaNormalizado.isAfter(hoyNormalizado);
    
    bool esMesActual = dia.month == _mesActual.month;
    bool esSeleccionado = diaNormalizado == DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month, widget.fechaSeleccionada.day);

    int eventosDelDia = widget.fechasConEventos[diaNormalizado] ?? 0;
    bool tieneEvento = eventosDelDia > 0;

    Color bgColor = Colors.transparent;
    Border? border;
    Widget? indicador;

    // 1. Hoy con evento (se pinta todo, numero blanco)
    if (esHoy && tieneEvento) {
      bgColor = widget.colorAcento;
    } 
    // 2. Futuro con evento (circulo sin pintar, o sea borde)
    else if (esFuturo && tieneEvento) {
      border = Border.all(color: widget.colorAcento, width: 1.5);
    }
    // 3. Pasado con evento (punto abajo)
    else if (esPasado && tieneEvento) {
      indicador = Positioned(
        bottom: 5,
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: widget.colorAcento,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    // 4. Hoy sin evento (raya gruesa abajo)
    else if (esHoy && !tieneEvento) {
      indicador = Positioned(
        bottom: 5,
        child: Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: widget.colorAcento,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      );
    }

    // Color del texto
    Color colorTexto;
    if (esHoy && tieneEvento) {
      colorTexto = Colors.white;
    } else if (esHoy && !tieneEvento) {
      colorTexto = widget.colorAcento;
    } else if (!esMesActual) {
      colorTexto = Colors.grey.shade400;
    } else if (esSeleccionado) {
      colorTexto = widget.colorAcento;
    } else {
      colorTexto = tema.colorScheme.onSurface;
    }

    // Indicador de selección sutil para no pisar las reglas visuales
    if (esSeleccionado && !(esHoy && tieneEvento)) {
      bgColor = widget.colorAcento.withOpacity(0.15);
      if (border == null) {
        border = Border.all(color: widget.colorAcento.withOpacity(0.4), width: 1);
      }
    }

    return GestureDetector(
      onTap: () => widget.onFechaSeleccionada(dia),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: border,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${dia.day}',
                      style: TextStyle(
                        color: colorTexto,
                        fontWeight: (esSeleccionado || tieneEvento || esHoy) ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    if (indicador != null) indicador,
                  ],
                ),
              ),
              if (tieneEvento)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.colorAcento,
                      shape: BoxShape.circle,
                      border: Border.all(color: tema.colorScheme.surface, width: 2),
                    ),
                    child: Text(
                      '$eventosDelDia',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
