// lib/5_modulos/modulo_explorar_feed/componentes/tarjeta_seccion_premium.dart

import 'package:flutter/material.dart';
import '../../../2_tema/dimensiones_app.dart';

class TarjetaSeccionPremium extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String rutaImagen;
  final IconData iconoPlaceholder;
  final Color colorAcento;
  final List<String> vinetas;
  final VoidCallback onTap;

  const TarjetaSeccionPremium({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.rutaImagen,
    required this.iconoPlaceholder,
    required this.colorAcento,
    required this.vinetas,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final colorFondo = tema.colorScheme.surface;
    final colorBorde = esOscuro ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final colorSombra = esOscuro ? Colors.transparent : Colors.black.withOpacity(0.03);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: DimensionesApp.radioTarjetas,
          border: Border.all(color: colorBorde, width: 1.2),
          boxShadow:[
            BoxShadow(
              color: colorSombra,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: DimensionesApp.radioTarjetas,
            splashColor: colorAcento.withOpacity(0.1),
            highlightColor: Colors.transparent,
            // 🚨 SOLUCIÓN AL CRASHEO: IntrinsicHeight envuelve toda la fila
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:[
                  // MITAD IZQUIERDA: IMAGEN O FALLBACK NEGRO
                  SizedBox(
                    width: 130, // Ancho fijo
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(23),
                        bottomLeft: Radius.circular(23),
                      ),
                      child: Image.asset(
                        rutaImagen,
                        fit: BoxFit.cover,
                        // 🚨 FALLBACK: Si no existe la imagen, caja oscura indestructible
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1A1A1A), // Fondo casi negro
                          child: Center(
                            child: Icon(iconoPlaceholder, color: Colors.white54, size: 42),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // MITAD DERECHA: TEXTOS
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 🚨 SOLUCIÓN: Evita el infinito vertical
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:[
                          Text(
                            titulo,
                            style: TextStyle(
                              color: tema.colorScheme.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitulo,
                            style: TextStyle(
                              color: tema.textTheme.bodySmall?.color,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          ...vinetas.map((vineta) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle_rounded, size: 14, color: colorAcento),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vineta,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tema.textTheme.bodyMedium?.color?.withOpacity(0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),

                          const SizedBox(height: 8),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorAcento.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: colorAcento,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}