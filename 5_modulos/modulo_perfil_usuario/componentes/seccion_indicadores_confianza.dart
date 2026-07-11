// lib/5_modulos/modulo_perfil_usuario/componentes/seccion_indicadores_confianza.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class SeccionIndicadoresConfianza extends StatelessWidget {
  final int trabajosCompletados;
  final int horasTrabajadas;
  final int tasaCompletado;

  const SeccionIndicadoresConfianza({
    Key? key,
    this.trabajosCompletados = 7, // Dejamos 7 para que la barra se vea en progreso
    this.horasTrabajadas = 530,     
    this.tasaCompletado = 98,       
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        // 1. LA NUEVA BARRA DE PROGRESO LIBRE
        _buildBarraProgresoNivel(context),
        const SizedBox(height: 16),

        // 2. GRILLA DE 3 RECTÁNGULOS
        Row(
          children:[
            Expanded(child: _buildCajaGrid(context, Icons.work_outline_rounded, 'Trabajos', trabajosCompletados.toString(), '', ColoresApp.infoAzul)),
            const SizedBox(width: 12),
            Expanded(child: _buildCajaGrid(context, Icons.schedule_rounded, 'Horas', horasTrabajadas.toString(), '', ColoresApp.advertenciaAmarillo)),
            const SizedBox(width: 12),
            Expanded(child: _buildCajaGrid(context, Icons.check_circle_outline_rounded, 'Éxito', '$tasaCompletado', '%', ColoresApp.primarioVerde)),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // LÓGICA Y DIBUJO DE LA BARRA DE PROGRESO GAMIFICADA
  // =========================================================
  Widget _buildBarraProgresoNivel(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Lógica matemática (Módulos de 5)
    int trabajosNivel = trabajosCompletados % 5;
    if (trabajosCompletados >= 15) trabajosNivel = 5; 

    // Colores de las medallas
    const Color colorBronce = Color(0xFFCD7F32);
    const Color colorPlata = Color(0xFFC0C0C0);
    const Color colorOro = Color(0xFFFFD700);
    const Color colorMaestro = ColoresApp.terciarioMorado; 
    final Color colorGris = esOscuro ? Colors.white24 : Colors.black12;

    bool bronceOn = false, plataOn = false, oroOn = false, maestroOn = false;

    if (trabajosCompletados < 5) {
      bronceOn = true;
    } else if (trabajosCompletados < 10) {
      bronceOn = true; plataOn = true;
    } else if (trabajosCompletados < 15) {
      bronceOn = true; plataOn = true; oroOn = true;
    } else {
      bronceOn = true; plataOn = true; oroOn = true; maestroOn = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children:[
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(
                    'Progreso de experiencia en la app', 
                    style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  // 🚨 Texto cambiado y color Verde Lindo aplicado
                  const Text(
                    'Trabajos exitosos con buena calificación', 
                    style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Medallas
            Row(
              mainAxisSize: MainAxisSize.min,
              children:[
                Icon(Icons.military_tech_rounded, color: bronceOn ? colorBronce : colorGris, size: 28),
                Icon(Icons.workspace_premium_rounded, color: plataOn ? colorPlata : colorGris, size: 28),
                Icon(Icons.emoji_events_rounded, color: oroOn ? colorOro : colorGris, size: 28),
                Icon(Icons.diamond_rounded, color: maestroOn ? colorMaestro : colorGris, size: 26),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // 🚨 Barra de Progreso en color Verde Lindo
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: trabajosNivel / 5.0,
            minHeight: 8,
            backgroundColor: esOscuro ? Colors.white12 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(ColoresApp.primarioVerde),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CAJA DE GRILLA (Trabajos, Horas, Éxito)
  // =========================================================
  Widget _buildCajaGrid(BuildContext context, IconData icono, String titulo, String valor, String sufijo, Color colorIcono) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: DimensionesApp.radioTarjetas,
        border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12),
        boxShadow: esOscuro ? null :[BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Icon(icono, color: colorIcono, size: 24),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children:[
                TextSpan(text: valor, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
                if (sufijo.isNotEmpty)
                  TextSpan(text: sufijo, style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo, 
            style: TextStyle(color: tema.textTheme.bodySmall?.color, fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}