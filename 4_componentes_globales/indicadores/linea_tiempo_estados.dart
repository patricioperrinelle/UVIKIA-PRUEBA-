// lib/4_componentes_globales/indicadores/linea_tiempo_estados.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';

class LineaTiempoEstados extends StatelessWidget {
  final bool llegoAlLugar;
  final bool enCurso;
  final bool completada;

  const LineaTiempoEstados({
    Key? key,
    required this.llegoAlLugar,
    required this.enCurso,
    required this.completada,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children:[
        _PasoHorizontal(titulo: 'Contratado', completado: true, activo: true, esOscuro: esOscuro),
        _LineaConectora(completado: llegoAlLugar),
        _PasoHorizontal(titulo: 'En el lugar', completado: llegoAlLugar, activo: llegoAlLugar, esOscuro: esOscuro),
        _LineaConectora(completado: enCurso),
        _PasoHorizontal(titulo: 'En curso', completado: enCurso, activo: enCurso, esOscuro: esOscuro),
        _LineaConectora(completado: completada),
        _PasoHorizontal(titulo: 'Finalizado', completado: completada, activo: completada, esOscuro: esOscuro),
      ],
    );
  }
}

class _PasoHorizontal extends StatelessWidget {
  final String titulo; final bool completado; final bool activo; final bool esOscuro;
  const _PasoHorizontal({required this.titulo, required this.completado, required this.activo, required this.esOscuro});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children:[
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: completado ? ColoresApp.terciarioMorado : Colors.transparent,
              border: Border.all(color: completado ? ColoresApp.terciarioMorado : (esOscuro ? Colors.white24 : Colors.black26), width: 2),
            ),
            child: completado ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(height: 8),
          Text(titulo, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: activo ? FontWeight.bold : FontWeight.normal, color: activo ? (esOscuro ? Colors.white : Colors.black) : Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LineaConectora extends StatelessWidget {
  final bool completado; const _LineaConectora({required this.completado});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(margin: const EdgeInsets.only(bottom: 20), height: 2, color: completado ? ColoresApp.terciarioMorado : Colors.grey.withOpacity(0.3)),
    );
  }
}