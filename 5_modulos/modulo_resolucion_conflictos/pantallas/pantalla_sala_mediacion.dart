// lib/5_modulos/modulo_resolucion_conflictos/pantallas/pantalla_sala_mediacion.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🛡️ Regla R2
import '../../../2_tema/colores_app.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/botones/boton_delineado_secundario.dart';
import '../../../4_componentes_globales/estados/pantalla_cargando_bloqueante.dart';
import '../../modulo_chat_mensajes/controladores/controlador_chat.dart';
import '../../modulo_chat_mensajes/componentes/seccion_chat_colapsable.dart';
import '../controladores/controlador_mediacion.dart';

class PantallaSalaMediacion extends StatefulWidget {
  final String trabajoId;
  final String contraparteId;

  const PantallaSalaMediacion({Key? key, required this.trabajoId, required this.contraparteId}) : super(key: key);

  @override
  State<PantallaSalaMediacion> createState() => _PantallaSalaMediacionState();
}

class _PantallaSalaMediacionState extends State<PantallaSalaMediacion> {
  late ControladorMediacion _controlador;
  final ControladorChat _controladorChat = ControladorChat();

  @override
  void initState() {
    super.initState();
    _controlador = ControladorMediacion(widget.trabajoId);
    _controlador.onRequerirAccionUI = _manejarEventosUI;
    
    // Inicializamos el chat inyectándolo directamente
    _controladorChat.inicializar(
      pTrabajoId: widget.trabajoId, 
      pMiId: _controlador.miId, 
      pContraparteId: widget.contraparteId
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    _controladorChat.dispose();
    super.dispose();
  }

  void _manejarEventosUI(String evento, [dynamic payload]) {
    if (evento == 'MOSTRAR_ERROR') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(payload), backgroundColor: ColoresApp.errorRojo));
    } else if (evento == 'MOSTRAR_EXITO') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(payload), backgroundColor: ColoresApp.primarioVerde));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sala de Resolución', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: _controlador,
        builder: (context, _) {
          if (_controlador.isLoading) return const Center(child: CircularProgressIndicator());

          return Stack(
            children: [
              Column(
                children: [
                  // 1. TICKET ORIGINAL
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: esOscuro ? Colors.black12 : Colors.grey.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_controlador.tituloTrabajo, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Text(_controlador.precioTrabajo, style: const TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.terciarioMorado, fontSize: 16)),
                      ],
                    ),
                  ),

                  // 2. TIMELINE DEL CONFLICTO Y ACCIONES
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCajaReclamo(tema, esOscuro),
                          const SizedBox(height: 24),
                          
                          // PANEL DE ACCIONES (Solo si no soy el que reportó y está esperando respuesta)
                          if (!_controlador.soyElReportador && _controlador.estadoMediacion == 'esperando_respuesta')
                            _buildCajaAcciones(),
                            
                          if (_controlador.estadoMediacion == 'acuerdo_logrado')
                            _buildCajaEstado('Acuerdo Logrado', 'El trabajo vuelve a estar en curso para su corrección o finalización.', ColoresApp.primarioVerde),
                            
                          if (_controlador.estadoMediacion == 'escalado_soporte')
                            _buildCajaEstado('Escalado a Soporte', 'Un moderador intervendrá en breve.', Colors.orange),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text('Chat de la disputa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          
                          // 3. EL CHAT INTEGRADO ABAJO
                          SeccionChatColapsable(
                            controlador: _controladorChat,
                            isCongelado: false, // El chat sigue vivo para que negocien
                            colorAcento: Colors.blueGrey, 
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_controlador.isProcessing) const PantallaCargandoBloqueante(mensaje: 'Procesando...'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCajaReclamo(ThemeData tema, bool esOscuro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
        boxShadow: esOscuro ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_problem_rounded, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(_controlador.categoriaProblema, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Descripción del problema:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(_controlador.descripcionProblema, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          
          if (_controlador.fotosEvidencia.isNotEmpty) ...[
            const Text('Evidencia adjunta:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _controlador.fotosEvidencia.length,
                itemBuilder: (ctx, i) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 80,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(imageUrl: _controlador.fotosEvidencia[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.handshake_rounded, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(child: Text('Solución solicitada: ${_controlador.solucionEsperada}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaAcciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tu respuesta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Puedes aceptar la solución para restaurar la jornada inmediatamente o escalar el caso si consideras que es injusto.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: BotonDelineadoSecundario(texto: 'RECHAZAR', colorPrimario: ColoresApp.errorRojo, onPressed: _controlador.rechazarYElevarSoporte)),
            const SizedBox(width: 12),
            Expanded(child: BotonAccionPrincipal(texto: 'ACEPTAR', colorFondo: ColoresApp.primarioVerde, onPressed: _controlador.aceptarSolucion)),
          ],
        ),
      ],
    );
  }

  Widget _buildCajaEstado(String titulo, String subtitulo, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 32),
          const SizedBox(height: 8),
          Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitulo, textAlign: TextAlign.center, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}