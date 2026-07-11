// lib/5_modulos/modulo_perfil_usuario/componentes/seccion_perfiles_guardados.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';

class SeccionPerfilesGuardados extends StatelessWidget {
  final List<dynamic> favoritos;

  const SeccionPerfilesGuardados({super.key, required this.favoritos});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: tema.colorScheme.surface, // 🚨 Fondo dinámico
          borderRadius: DimensionesApp.radioTarjetas,
          border: Border.all(color: ColoresApp.infoAzul.withOpacity(0.3), width: 1.0),
        ),
        child: Theme(
          data: tema.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            iconColor: ColoresApp.infoAzul,
            collapsedIconColor: tema.textTheme.bodySmall?.color,
            title: Text(
              'Mis Profesionales Favoritos', 
              style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)
            ),
            children:[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: favoritos.isEmpty
                    ? Text(
                        'Aún no has guardado ningún perfil.', 
                        style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 13, fontStyle: FontStyle.italic)
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: favoritos.length,
                        itemBuilder: (context, index) {
                          final fav = favoritos[index];
                          final perf = fav['perfiles'] is Map ? fav['perfiles'] as Map : {};
                          
                          final String proId = fav['profesional_id']?.toString() ?? '';
                          final String name = perf['apodo']?.toString() ?? 'Profesional';
                          final String image = perf['foto_url']?.toString() ?? '';
                          final double rating = perf['rating'] != null ? (perf['rating'] as num).toDouble() : 3.0;
                          final int reviews = perf['cantidad_resenas'] != null ? (perf['cantidad_resenas'] as num).toInt() : 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/perfil_publico', arguments: {'id': proId});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: esOscuro ? Colors.black.withOpacity(0.4) : Colors.grey[100],
                                  borderRadius: DimensionesApp.radioTarjetas,
                                  border: Border.all(color: esOscuro ? ColoresApp.bordeCristal : Colors.black12),
                                ),
                                child: Row(
                                  children:[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 50, height: 50,
                                        child: image.startsWith('http') 
                                            ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.person, color: esOscuro ? Colors.white24 : Colors.black26))
                                            : Container(color: tema.inputDecorationTheme.fillColor, child: Icon(Icons.person, color: esOscuro ? Colors.white24 : Colors.black26)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:[
                                          Text(name, style: TextStyle(color: tema.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Row(
                                            children:[
                                              const Icon(Icons.star_rounded, color: ColoresApp.advertenciaAmarillo, size: 14),
                                              const SizedBox(width: 4),
                                              Text('$rating ($reviews)', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: tema.textTheme.bodySmall?.color),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}