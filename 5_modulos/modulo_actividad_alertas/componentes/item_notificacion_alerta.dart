// lib/5_modulos/modulo_actividad_alertas/componentes/item_notificacion_alerta.dart

import 'package:flutter/material.dart';
import '../../../3_modelos/modelo_notificacion.dart';

class ItemNotificacionAlerta extends StatelessWidget {
  final ModeloNotificacion notificacion;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool modoSeleccion;
  final bool esSeleccionado;
  final VoidCallback onToggleSeleccion;

  const ItemNotificacionAlerta({
    Key? key,
    required this.notificacion,
    required this.onTap,
    required this.onLongPress,
    this.modoSeleccion = false,
    this.esSeleccionado = false,
    required this.onToggleSeleccion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final bool isClickable = notificacion.trabajoId != null && notificacion.trabajoId!.isNotEmpty;

    // Colores basados en el estado de lectura (Diseño de la izquierda)
    // No leídas: fondo un poco más oscuro/grisáceo para llamar la atención.
    // Leídas: lo más blanco (o fondo base) posible.
    final Color backgroundColor = notificacion.leida
        ? (esOscuro ? const Color(0xFF121212) : Colors.white)
        : (esOscuro ? const Color(0xFF1E1E24) : const Color(0xFFF1F3F5));

    // Determinar estilo de ícono y colores basados en el tipo o contenido de la notificación
    final tipoLower = notificacion.tipo.toLowerCase();
    final tituloLower = notificacion.titulo.toLowerCase();
    final mensajeLower = notificacion.mensaje.toLowerCase();

    IconData iconData = Icons.notifications_active_rounded;
    Color iconColor = const Color(0xFF8B5CF6); // Morado por defecto
    Color iconBgColor = const Color(0xFFF3E8FF);

    if (tipoLower.contains('confirm') || tituloLower.contains('confirm') || mensajeLower.contains('confirm')) {
      iconData = Icons.calendar_today_rounded;
      iconColor = const Color(0xFF3B82F6); // Azul
      iconBgColor = const Color(0xFFEFF6FF);
    } else if (tipoLower.contains('pago') || tipoLower.contains('billetera') || tituloLower.contains('pago') || mensajeLower.contains('pago') || mensajeLower.contains('recibiste')) {
      iconData = Icons.attach_money_rounded;
      iconColor = const Color(0xFF10B981); // Verde
      iconBgColor = const Color(0xFFECFDF5);
    } else if (tipoLower.contains('recordatorio') || tipoLower.contains('alerta') || tituloLower.contains('recordatorio')) {
      iconData = Icons.notifications_none_rounded;
      iconColor = const Color(0xFFF59E0B); // Ámbar/Naranja
      iconBgColor = const Color(0xFFFEF3C7);
    } else if (tipoLower.contains('resena') || tipoLower.contains('reseña') || tipoLower.contains('calificacion') || tituloLower.contains('reseña') || tituloLower.contains('nueva reseña')) {
      iconData = Icons.star_rounded;
      iconColor = const Color(0xFFEAB308); // Amarillo
      iconBgColor = const Color(0xFFFEF08A);
    } else if (tipoLower.contains('verific') || tituloLower.contains('verific')) {
      iconData = Icons.verified_user_outlined;
      iconColor = const Color(0xFF06B6D4); // Celeste/Teal
      iconBgColor = const Color(0xFFECFEFF);
    } else if (tipoLower.contains('cancel') || tituloLower.contains('cancel')) {
      iconData = Icons.cancel_outlined;
      iconColor = const Color(0xFFEF4444); // Rojo
      iconBgColor = const Color(0xFFFEF2F2);
    }

    // Ajustar colores para modo oscuro
    if (esOscuro) {
      iconBgColor = iconBgColor.withOpacity(0.12);
    }

    // Extraer monto de pago para mostrarlo en verde a la derecha (Estilo de la izquierda)
    String? montoPago;
    if (iconData == Icons.attach_money_rounded) {
      final regExp = RegExp(r'\$\s*(\d+[\d.,]*)');
      final match = regExp.firstMatch(notificacion.mensaje);
      if (match != null) {
        montoPago = '+\$${match.group(1)}';
      }
    }

    final bool esResena = iconData == Icons.star_rounded;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: modoSeleccion ? onToggleSeleccion : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: esOscuro ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de selección si está activo
            if (modoSeleccion) ...[
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 12.0),
                  child: Icon(
                    esSeleccionado ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: esSeleccionado ? const Color(0xFF8B5CF6) : (esOscuro ? Colors.white30 : Colors.black38),
                    size: 22,
                  ),
                ),
              ),
            ],

            // Caja del Ícono (Estilo Bento)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Contenido de la notificación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacion.titulo,
                    style: TextStyle(
                      color: esOscuro ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notificacion.mensaje,
                    style: TextStyle(
                      color: esOscuro ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      height: 1.3,
                      fontFamily: 'Inter',
                    ),
                  ),
                  
                  // Mostrar Estrellas de Calificación si es una reseña (Diseño de la izquierda)
                  if (esResena) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),
                  Text(
                    _obtenerTiempoTranscurrido(notificacion.fecha),
                    style: TextStyle(
                      color: esOscuro ? Colors.white30 : Colors.black38,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // Badge de Monto de Pago o Punto de No Leído
            if (montoPago != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  montoPago,
                  style: const TextStyle(
                    color: Color(0xFF10B981), // Verde diseño
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ] else if (!notificacion.leida && !modoSeleccion) ...[
              // Punto negro minimalista de no leído (Diseño de la izquierda)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 18.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: esOscuro ? Colors.white : Colors.black, // Punto negro en diseño de la izquierda
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],

            if (isClickable && !modoSeleccion)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 14.0),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: esOscuro ? Colors.white24 : Colors.black26,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _obtenerTiempoTranscurrido(String fechaIso) {
    if (fechaIso.isEmpty) return '';
    try {
      final fechaN = DateTime.parse(fechaIso).toLocal();
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fechaN);

      if (diferencia.isNegative) {
        return 'Hace unos instantes';
      }

      if (diferencia.inSeconds < 60) {
        return 'Hace unos instantes';
      } else if (diferencia.inMinutes < 60) {
        return 'Hace ${diferencia.inMinutes} ${diferencia.inMinutes == 1 ? 'minuto' : 'minutos'}';
      } else if (diferencia.inHours < 24) {
        return 'Hace ${diferencia.inHours} ${diferencia.inHours == 1 ? 'hora' : 'horas'}';
      } else if (diferencia.inDays == 1) {
        return 'Ayer';
      } else if (diferencia.inDays < 7) {
        return 'Hace ${diferencia.inDays} días';
      } else {
        return '${fechaN.day.toString().padLeft(2, '0')}/${fechaN.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }
}
