// lib/4_componentes_globales/modales_y_alertas/modal_centro_resolucion.dart

import 'package:flutter/material.dart';
import '../../2_tema/colores_app.dart';
import '../botones/boton_accion_principal.dart';
import '../formularios/campo_texto_cristal.dart';

class ModalCentroResolucion extends StatefulWidget {
  final bool esCliente;

  const ModalCentroResolucion({Key? key, required this.esCliente}) : super(key: key);

  @override
  State<ModalCentroResolucion> createState() => _ModalCentroResolucionState();
}

class _ModalCentroResolucionState extends State<ModalCentroResolucion> {
  final PageController _pageController = PageController();
  final TextEditingController _descController = TextEditingController();

  int _pasoActual = 0;
  String? _categoriaSeleccionada;
  String? _solucionSeleccionada;

  final List<Map<String, dynamic>> _categorias = [
    {'titulo': 'Problema con el trabajo', 'icono': Icons.build_circle_rounded, 'color': ColoresApp.secundarioCyan, 'desc': 'Algo quedó mal, está incompleto o hay diferencias.'},
    {'titulo': 'Molestia Leve', 'icono': Icons.access_time_filled_rounded, 'color': ColoresApp.advertenciaAmarillo, 'desc': 'Demoras, desorden o falta de comunicación.'},
    {'titulo': 'Conducta Inapropiada', 'icono': Icons.person_off_rounded, 'color': Colors.orange, 'desc': 'Faltas de respeto, insultos o extorsión.'},
    {'titulo': 'Seguridad / Emergencia', 'icono': Icons.warning_rounded, 'color': ColoresApp.errorRojo, 'desc': 'Peligro real, violencia o robo. (Requiere confirmación)'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _avanzarPaso() {
    if (_pasoActual == 0 && _categoriaSeleccionada == null) return;
    if (_pasoActual == 1 && _solucionSeleccionada == null) return;
    
    setState(() => _pasoActual++);
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _retrocederPaso() {
    setState(() => _pasoActual--);
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _finalizar() {
    if (_descController.text.trim().length < 10) return;
    
    Navigator.pop(context, {
      'categoria': _categoriaSeleccionada,
      'solucion_esperada': _solucionSeleccionada ?? 'No aplica',
      'descripcion': _descController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: tema.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    if (_pasoActual > 0) IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _retrocederPaso, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    if (_pasoActual > 0) const SizedBox(width: 12),
                    Expanded(child: Text(_pasoActual == 0 ? 'Centro de Resolución' : _categoriaSeleccionada!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPaso1Categorias(tema, esOscuro),
                    _buildPaso2Solucion(tema, esOscuro),
                    _buildPaso3Descripcion(tema),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaso1Categorias(ThemeData tema, bool esOscuro) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final cat = _categorias[index];
        final bool esNuclear = cat['titulo'] == 'Seguridad / Emergencia';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              setState(() => _categoriaSeleccionada = cat['titulo']);
              if (cat['titulo'] == 'Molestia Leve') {
                _solucionSeleccionada = 'Afectar reputación interna';
                setState(() => _pasoActual = 2);
                _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                _avanzarPaso();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: esNuclear ? ColoresApp.errorRojo.withOpacity(0.5) : (esOscuro ? ColoresApp.bordeCristal : Colors.black12)),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cat['color'].withOpacity(0.15), shape: BoxShape.circle), child: Icon(cat['icono'], color: cat['color'])),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat['titulo'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: esNuclear ? ColoresApp.errorRojo : tema.colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text(cat['desc'], style: TextStyle(fontSize: 13, color: tema.textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: tema.textTheme.bodyMedium?.color),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaso2Solucion(ThemeData tema, bool esOscuro) {
    if (_categoriaSeleccionada == 'Seguridad / Emergencia') {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_rounded, color: ColoresApp.errorRojo, size: 64),
            const SizedBox(height: 24),
            const Text('Acción Inmediata', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColoresApp.errorRojo)),
            const SizedBox(height: 12),
            const Text('Este reporte es auditable y congelará la transacción inmediatamente. Se notificará a nuestro equipo de seguridad para suspender cuentas preventivamente.\n\nEl mal uso de este botón afectará tu permanencia en la app.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
            const Spacer(),
            BotonAccionPrincipal(texto: 'ENTIENDO, CONTINUAR', colorFondo: ColoresApp.errorRojo, onPressed: () {
              _solucionSeleccionada = 'Intervención de Seguridad';
              _avanzarPaso();
            }),
          ],
        ),
      );
    }

    final List<String> opciones = widget.esCliente 
      ? ['Solicitar corrección al profesional', 'Solicitar descuento parcial', 'Cancelar el pago']
      : ['Ofrecer corrección del trabajo', 'Ofrecer descuento parcial', 'El cliente se niega a pagar'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Qué solución esperas?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Intentaremos una mediación automática antes de intervenir.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ...opciones.map((opc) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RadioListTile<String>(
              title: Text(opc, style: TextStyle(fontWeight: opc.contains('corrección') ? FontWeight.bold : FontWeight.normal)),
              subtitle: opc.contains('corrección') ? const Text('Preserva tu dinero y reputación.', style: TextStyle(color: ColoresApp.primarioVerde, fontSize: 12)) : null,
              value: opc,
              groupValue: _solucionSeleccionada,
              activeColor: ColoresApp.terciarioMorado,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), 
                // 🚨 CORRECCIÓN: Usar BorderSide en lugar de Border.all para la propiedad 'side'
                side: BorderSide(color: _solucionSeleccionada == opc ? ColoresApp.terciarioMorado : Colors.black12)
              ),
              tileColor: esOscuro ? Colors.black12 : Colors.white,
              onChanged: (val) => setState(() => _solucionSeleccionada = val),
            ),
          )),
          const Spacer(),
          BotonAccionPrincipal(texto: 'CONTINUAR', onPressed: _solucionSeleccionada != null ? _avanzarPaso : null),
        ],
      ),
    );
  }

  Widget _buildPaso3Descripcion(ThemeData tema) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Describe la situación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Sé objetivo. En el siguiente paso te pediremos adjuntar evidencia fotográfica si es necesario.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          CampoTextoCristal(
            controller: _descController,
            hintText: 'Ej: El trabajo se terminó pero quedó un problema en...',
            minLines: 5,
            maxLines: 8,
            maxLength: 500,
          ),
          const Spacer(),
          BotonAccionPrincipal(
            texto: 'ENVIAR REPORTE',
            colorFondo: _categoriaSeleccionada == 'Seguridad / Emergencia' ? ColoresApp.errorRojo : ColoresApp.terciarioMorado,
            onPressed: () {
              if (_descController.text.trim().length >= 10) { _finalizar(); }
            },
          )
        ],
      ),
    );
  }
}