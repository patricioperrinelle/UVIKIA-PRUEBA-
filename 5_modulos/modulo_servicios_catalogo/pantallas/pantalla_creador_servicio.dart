// lib/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_creador_servicio.dart

import 'package:flutter/material.dart';
import '../../../2_tema/colores_app.dart';
import '../../../3_modelos/modelo_servicio_catalogo.dart'; 
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/boton_delineado_secundario.dart';
import '../controladores/controlador_creador_servicio.dart';
import '../componentes/creador/stepper_creacion_servicio.dart';
import '../componentes/creador/pasos/paso_1_informacion.dart';
import '../componentes/creador/pasos/paso_2_planes_extras.dart';
import '../componentes/creador/pasos/paso_3_vista_previa.dart';

class PantallaCreadorServicio extends StatefulWidget {
  final ModeloServicioCatalogo? servicioAEditar;
  final bool modoLectura; // 🚨 NUEVO PARÁMETRO

  const PantallaCreadorServicio({Key? key, this.servicioAEditar, this.modoLectura = false}) : super(key: key);

  @override
  State<PantallaCreadorServicio> createState() => _PantallaCreadorServicioState();
}

class _PantallaCreadorServicioState extends State<PantallaCreadorServicio> {
  final ControladorCreadorServicio _controlador = ControladorCreadorServicio();

  @override
  void initState() {
    super.initState();
    if (widget.servicioAEditar != null) {
      _controlador.inicializarParaEdicion(widget.servicioAEditar!, widget.modoLectura);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.servicioAEditar != null ? 'Detalle del servicio' : 'Crear servicio', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_controlador.pasoActual > 0) {
              _controlador.pasoAnterior();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        // 🚨 EL LÁPIZ APARECE EN EL APPBAR SOLO SI ESTÁ EN MODO LECTURA
        actions: [
          ListenableBuilder(
            listenable: _controlador,
            builder: (context, _) {
              if (_controlador.modoLectura) {
                return TextButton.icon(
                  icon: const Icon(Icons.edit, color: ColoresApp.terciarioMorado, size: 20),
                  label: const Text('Editar', style: TextStyle(color: ColoresApp.terciarioMorado, fontWeight: FontWeight.bold)),
                  onPressed: _controlador.habilitarEdicion,
                );
              }
              return const SizedBox.shrink();
            }
          )
        ],
      ),
      body: ListenableBuilder(
        listenable: _controlador,
        builder: (context, _) {
          return Column(
            children: [
              StepperCreacionServicio(pasoActual: _controlador.pasoActual),
              
              Expanded(
                child: PageView(
                  controller: _controlador.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Paso1Informacion(controlador: _controlador),
                    Paso2PlanesExtras(controlador: _controlador), 
                    Paso3VistaPrevia(controlador: _controlador),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _controlador,
        builder: (context, _) {
          if (widget.servicioAEditar != null && !_controlador.modoLectura) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: esOscuro ? Colors.grey.shade900 : Colors.white,
                  border: Border(top: BorderSide(color: esOscuro ? Colors.white12 : Colors.grey.shade200)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BotonAccionPrincipal(
                      texto: _controlador.isGuardando ? 'Guardando...' : 'Guardar Cambios',
                      isLoading: _controlador.isGuardando,
                      onPressed: _controlador.isGuardando ? null : () {
                        _controlador.ejecutarGuardado(
                          esBorrador: false,
                          onSuccess: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext ctx) {
                                return AlertDialog(
                                  title: const Text('¡Cambios guardados!'),
                                  content: const Text('El servicio se ha actualizado correctamente.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx); // Cierra modal
                                        Navigator.pop(context, true); // Cierra pantalla
                                      },
                                      child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
                                    ),
                                  ],
                                );
                              }
                            );
                          },
                          onError: (err) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: ColoresApp.errorRojo));
                          }
                        );
                      }
                    ),
                    const SizedBox(height: 12),
                    BotonDelineadoSecundario(
                      texto: 'Salir sin guardar',
                      colorPrimario: esOscuro ? Colors.white70 : Colors.black54,
                      onPressed: _controlador.isGuardando ? null : () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
      ),
    );
  }
}