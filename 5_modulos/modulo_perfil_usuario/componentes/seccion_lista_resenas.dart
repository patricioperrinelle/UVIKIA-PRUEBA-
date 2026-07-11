// lib/5_modulos/modulo_perfil_usuario/componentes/seccion_lista_resenas.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../3_modelos/modelo_resena.dart';
import '../../../4_componentes_globales/indicadores/estrellas_calificacion_fila.dart';

class SeccionListaResenas extends StatelessWidget {
  final List<ModeloResena> resenas;
  final double ratingGlobal;
  final int totalResenas;
  final bool esCliente;

  const SeccionListaResenas({
    Key? key,
    required this.resenas,
    required this.ratingGlobal,
    required this.totalResenas,
    this.esCliente = false,
  }) : super(key: key);

  void _abrirModalTodasLasResenas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalTodasLasResenas(
        resenas: resenas, 
        totalResenas: totalResenas
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (resenas.isEmpty) return const SizedBox.shrink();

    final tema = Theme.of(context);
    final resenaReciente = resenas.first; 
    final colorAcento = esCliente ? ColoresApp.primarioVerde : ColoresApp.terciarioMorado;
    String ratingStr = ratingGlobal > 0 ? ratingGlobal.toStringAsFixed(1) : '5.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          esCliente ? 'Opiniones de profesionales' : 'Opiniones de clientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: tema.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: ColoresApp.advertenciaAmarillo, size: 22),
                const SizedBox(width: 6),
                Text(
                  '$ratingStr Excelente',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (resenas.length > 1) 
              InkWell(
                onTap: () => _abrirModalTodasLasResenas(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: colorAcento.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      color: colorAcento,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ConstruirTarjetaResena(resena: resenaReciente, destacar: true),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ModalTodasLasResenas extends StatelessWidget {
  final List<ModeloResena> resenas;
  final int totalResenas;

  const _ModalTodasLasResenas({
    required this.resenas,
    required this.totalResenas,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: esOscuro ? ColoresApp.cristalFuerte : ColoresApp.cristalSuave,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Todas las opiniones ($totalResenas)',
              style: TextStyle(
                color: tema.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: resenas.length,
                separatorBuilder: (_, __) => Divider(
                  color: tema.dividerColor.withOpacity(0.1), 
                  height: 32
                ),
                itemBuilder: (ctx, index) {
                  return _ConstruirTarjetaResena(
                    resena: resenas[index], 
                    destacar: false
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstruirTarjetaResena extends StatelessWidget {
  final ModeloResena resena;
  final bool destacar;

  const _ConstruirTarjetaResena({
    required this.resena,
    required this.destacar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    
    final double rating = resena.rating;
    final String comentario = resena.comentario.trim().isNotEmpty 
        ? resena.comentario.trim() 
        : 'Excelente trabajo.';
    
    final String autorCrudo = resena.evaluadorNombre.trim().isNotEmpty 
        ? resena.evaluadorNombre.trim() 
        : 'Usuario';

    // 🛡️ AUTH-GUARDIAN: Extractor de Primer Nombre.
    // Corta en el primer espacio para ignorar "Electricista", "Plomero", etc.
    String autor = autorCrudo.split(' ').first;
    
    // Capitalización defensiva (Asegura que "carlos" se vea como "Carlos")
    if (autor.length > 1) {
      autor = autor[0].toUpperCase() + autor.substring(1).toLowerCase();
    }

    String fecha = '';
    if (resena.fechaCreacion.isNotEmpty) {
      fecha = resena.fechaCreacion.split('T').first;
    }

    Widget contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$autor • $fecha', 
          style: TextStyle(
            color: tema.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        EstrellasCalificacionFila(rating: rating, tamano: 16),
        const SizedBox(height: 12),
        Text(
          '“$comentario”',
          style: TextStyle(
            color: tema.colorScheme.onSurface.withOpacity(0.9),
            fontSize: 15,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );

    if (destacar) {
      return Container(
        width: double.infinity,
        padding: DimensionesApp.paddingTarjetas,
        decoration: BoxDecoration(
          color: tema.colorScheme.surface,
          borderRadius: DimensionesApp.radioTarjetas,
          border: Border.all(color: esOscuro ? ColoresApp.cristalFuerte : ColoresApp.cristalSuave),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: contenido,
      );
    }

    return contenido;
  }
}