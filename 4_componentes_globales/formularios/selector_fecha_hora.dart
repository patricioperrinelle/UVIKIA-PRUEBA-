// lib/4_componentes_globales/formularios/selector_fecha_hora.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/dimensiones_app.dart';

class SelectorFechaHora extends StatelessWidget {
  final DateTime? fechaSeleccionada;
  final TimeOfDay? horaSeleccionada;
  // 🚨 NUEVO: Parámetros opcionales para la hora de fin (Rango Horario)
  final TimeOfDay? horaFinSeleccionada;
  final ValueChanged<DateTime?> onFechaChanged;
  final ValueChanged<TimeOfDay?> onHoraChanged;
  final ValueChanged<TimeOfDay?>? onHoraFinChanged;
  final Color colorTema;

  const SelectorFechaHora({
    Key? key,
    required this.fechaSeleccionada,
    required this.horaSeleccionada,
    this.horaFinSeleccionada,
    required this.onFechaChanged,
    required this.onHoraChanged,
    this.onHoraFinChanged,
    this.colorTema = ColoresApp.primarioVerde,
  }) : super(key: key);

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colorTema,
              onPrimary: Colors.black,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onFechaChanged(picked);
  }

  Future<void> _seleccionarHora(BuildContext context, bool esHoraFin) async {
    final initial = esHoraFin 
        ? (horaFinSeleccionada ?? TimeOfDay.now()) 
        : (horaSeleccionada ?? TimeOfDay.now());

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      if (esHoraFin && onHoraFinChanged != null) {
        onHoraFinChanged!(picked);
      } else {
        onHoraChanged(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si pasaron la función onHoraFinChanged, significa que quieren el diseño de rango (3 cajas).
    final bool esRango = onHoraFinChanged != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: esRango ? 3 : 1,
            child: _buildCajaSelector(
              context: context,
              valor: fechaSeleccionada == null 
                  ? 'Fecha' 
                  : '${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}',
              icono: Icons.calendar_today_rounded,
              estaSeleccionado: fechaSeleccionada != null,
              onTap: () => _seleccionarFecha(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: esRango ? 2 : 1,
            child: _buildCajaSelector(
              context: context,
              valor: horaSeleccionada == null 
                  ? (esRango ? 'Inicio' : 'Hora') 
                  : '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}',
              icono: Icons.access_time_rounded,
              estaSeleccionado: horaSeleccionada != null,
              onTap: () => _seleccionarHora(context, false),
            ),
          ),
          if (esRango) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildCajaSelector(
                context: context,
                valor: horaFinSeleccionada == null 
                    ? 'Fin' 
                    : '${horaFinSeleccionada!.hour.toString().padLeft(2, '0')}:${horaFinSeleccionada!.minute.toString().padLeft(2, '0')}',
                icono: Icons.timelapse_rounded,
                estaSeleccionado: horaFinSeleccionada != null,
                onTap: () => _seleccionarHora(context, true),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCajaSelector({
    required BuildContext context,
    required String valor,
    required IconData icono,
    required bool estaSeleccionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), 
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), 
          borderRadius: DimensionesApp.radioTarjetas,
          border: Border.all(
            color: estaSeleccionado ? colorTema : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icono, color: estaSeleccionado ? colorTema : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                valor,
                style: TextStyle(color: estaSeleccionado ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}