// lib/4_componentes_globales/modales_y_alertas/modal_recibo_transaccion.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../2_tema/colores_app.dart';
import '../../2_tema/estilos_texto.dart';
import '../../4_componentes_globales/motor_cancelaciones_visuales/modelos/cancelacion_contexto.dart';
import 'dto_recibo.dart';

class ModalReciboTransaccion extends StatelessWidget {
  final dynamic trabajo;
  final bool esCliente;
  final String miNombre; 
  final String miAvatar;

  const ModalReciboTransaccion({
    Key? key,
    required this.trabajo,
    required this.esCliente,
    required this.miNombre,
    required this.miAvatar,
  }) : super(key: key);

  static void mostrar(BuildContext context, dynamic trabajo, bool esCliente, String miNombre, String miAvatar) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => ModalReciboTransaccion(
          trabajo: trabajo, 
          esCliente: esCliente,
          miNombre: miNombre,
          miAvatar: miAvatar,
        ),
      ),
    );
  }

  DatosReciboDTO _obtenerDatosRecibo(dynamic t) {
    if (t.dominio == DominioApp.catalogo) {
      return DatosReciboDTO(
        iconoServicio: Icons.shopping_bag_outlined,
        subtituloServicio: 'Compra Directa en Catálogo',
        mostrarRangoHorario: true,
        mostrarModalidad: true,
        detalleOperativoEsLista: true,
      );
    } else if (t.dominio == DominioApp.jornadas) {
      return DatosReciboDTO(
        iconoServicio: Icons.calendar_today_rounded,
        subtituloServicio: 'Turno o Jornada',
        mostrarRangoHorario: true,
        mostrarModalidad: false,
        detalleOperativoEsLista: false,
      );
    } else {
      return DatosReciboDTO(
        iconoServicio: Icons.handyman_rounded,
        subtituloServicio: 'Contratación por Oficio',
        mostrarRangoHorario: false,
        mostrarModalidad: false,
        detalleOperativoEsLista: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    // Motor Dual de Colores
    final colorAcento = esCliente ? ColoresApp.primarioVerde : ColoresApp.terciarioMorado;
    
    // Identificadores de Módulo
    final datosRecibo = _obtenerDatosRecibo(trabajo);

    // EXTRACCIÓN SEGURA (Try-Catch Defensivo para evitar Red Screen of Death)
    String proNombreReal = miNombre;
    String proAvatarReal = miAvatar;
    String clienteNombre = miNombre;
    String clienteAvatar = miAvatar;
    
    try {
      proNombreReal = esCliente ? (trabajo.contraparteNombre ?? miNombre) : miNombre;
      proAvatarReal = esCliente ? (trabajo.contraparteAvatar ?? miAvatar) : miAvatar;
      if (esCliente && trabajo.ganadorPuja != null) {
        proNombreReal = trabajo.ganadorPuja!.apodoProfesional ?? proNombreReal;
        proAvatarReal = trabajo.ganadorPuja!.avatarUrl ?? proAvatarReal;
      }
      clienteNombre = esCliente ? miNombre : (trabajo.contraparteNombre ?? miNombre);
      clienteAvatar = esCliente ? miAvatar : (trabajo.contraparteAvatar ?? miAvatar);
    } catch (_) {}

    String idFactura = '0001';
    try {
      idFactura = trabajo.id != null && trabajo.id.toString().length >= 8 
          ? trabajo.id.toString().substring(0, 8).toUpperCase() 
          : '0001';
    } catch (_) {}

    final String fechaHoy = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    
    String precioBaseLimpio = '0';
    try { precioBaseLimpio = (trabajo.precioBaseCalculado ?? 0.0).toStringAsFixed(0); } catch (_) {}
    
    String granTotalLimpio = '0';
    try { granTotalLimpio = (trabajo.precioTotalFinal ?? 0.0).toStringAsFixed(0); } catch (_) {}
    
    List<Map<String, dynamic>> extras = [];
    try { extras = trabajo.extrasAceptados != null ? List<Map<String, dynamic>>.from(trabajo.extrasAceptados) : []; } catch (_) {}

    String valTitulo = '';
    try { valTitulo = trabajo.titulo ?? ''; } catch (_) {}

    String valFechaLimpia = '';
    try { valFechaLimpia = trabajo.fechaLimpia ?? ''; } catch (_) {}

    String valHoraLimpia = '';
    try { valHoraLimpia = trabajo.horaLimpia ?? ''; } catch (_) {}

    String valHoraFin = '';
    try { valHoraFin = trabajo.horaFin ?? ''; } catch (_) {}

    String valUbicacion = '';
    try { valUbicacion = (trabajo.ubicacionExacta ?? '').replaceAll('||', ', '); } catch (_) {}

    String valDescripcion = '';
    try { valDescripcion = trabajo.descripcion ?? ''; } catch (_) {}

    String valRequisitos = '';
    try { valRequisitos = trabajo.requisitos ?? ''; } catch (_) {}

    bool esDomicilio = valDescripcion.toLowerCase().contains('domicilio');

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: tema.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: tema.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tema.dividerColor.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. CABECERA
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorAcento.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.home_work_rounded, color: colorAcento, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Text('Tu App', style: EstilosTextoApp.h2.copyWith(color: colorAcento)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('FACTURA DE SERVICIO', style: EstilosTextoApp.cuerpoPequeno.copyWith(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface)),
                      Text('Nº $idFactura', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: colorAcento)),
                      const SizedBox(height: 4),
                      Text(fechaHoy, style: EstilosTextoApp.cuerpoPequeno),
                    ],
                  )
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 2. SERVICIO REALIZADO
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: colorAcento.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      datosRecibo.iconoServicio, 
                      color: colorAcento, size: 28
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SERVICIO REALIZADO', style: EstilosTextoApp.etiquetaEstado.copyWith(color: tema.hintColor)),
                        const SizedBox(height: 4),
                        Text(valTitulo, style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text(
                          datosRecibo.subtituloServicio,
                          style: EstilosTextoApp.cuerpoRegular.copyWith(color: colorAcento),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // 3. BLOQUE DE IDENTIDADES
              Row(
                children: [
                  _ConstruirIdentidad(
                    titulo: 'CLIENTE',
                    nombre: clienteNombre,
                    avatarUrl: clienteAvatar,
                    colorBorde: esCliente ? ColoresApp.primarioVerde : Colors.transparent,
                    tema: tema,
                  ),
                  const SizedBox(width: 16),
                  _ConstruirIdentidad(
                    titulo: 'PROFESIONAL',
                    nombre: proNombreReal, 
                    avatarUrl: proAvatarReal, 
                    colorBorde: !esCliente ? ColoresApp.terciarioMorado : Colors.transparent,
                    tema: tema,
                    esPro: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // 4. CUADRÍCULA DE LOGÍSTICA
              _FilaLogistica(icono: Icons.calendar_today_rounded, etiqueta: 'FECHA', valor: valFechaLimpia, tema: tema),
              
              if (datosRecibo.mostrarRangoHorario && valHoraFin.isNotEmpty)
                _FilaLogistica(icono: Icons.schedule_rounded, etiqueta: 'RANGO HORARIO', valor: 'De $valHoraLimpia a $valHoraFin', tema: tema)
              else
                _FilaLogistica(icono: Icons.access_time_rounded, etiqueta: 'HORARIO', valor: valHoraLimpia, tema: tema),
              
              if (datosRecibo.mostrarModalidad)
                _FilaLogistica(
                  icono: Icons.storefront_rounded, 
                  etiqueta: 'MODALIDAD', 
                  valor: esDomicilio ? 'A domicilio' : 'En local', 
                  tema: tema
                ),

              _FilaLogistica(icono: Icons.location_on_rounded, etiqueta: 'DIRECCIÓN', valor: valUbicacion, tema: tema),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // 5. DETALLE OPERATIVO
              Text('DETALLE DEL SERVICIO', style: EstilosTextoApp.etiquetaEstado.copyWith(color: colorAcento, fontSize: 12)),
              const SizedBox(height: 16),
              
              if (datosRecibo.detalleOperativoEsLista) ...[
                ...valDescripcion.split('\n').where((linea) => linea.trim().isNotEmpty).map((linea) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: colorAcento),
                        const SizedBox(width: 8),
                        Expanded(child: Text(linea, style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.colorScheme.onSurface))),
                      ],
                    ),
                  );
                }).toList(),
              ] else ...[
                Text(valDescripcion, style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.colorScheme.onSurface)),
                if (valRequisitos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Requisitos:', style: EstilosTextoApp.cuerpoPequeno.copyWith(fontWeight: FontWeight.bold, color: tema.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(valRequisitos, style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.colorScheme.onSurface)),
                ]
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // 6. DESGLOSE FINANCIERO
              Text('DESGLOSE DE PAGOS', style: EstilosTextoApp.etiquetaEstado.copyWith(color: colorAcento, fontSize: 12)),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Monto acordado', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface)),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                        TextSpan(text: precioBaseLimpio),
                      ]
                    ),
                    style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface),
                  ),
                ],
              ),
              
              if (extras.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Extras adicionales', style: EstilosTextoApp.cuerpoPequeno.copyWith(fontWeight: FontWeight.bold, color: tema.hintColor)),
                const SizedBox(height: 8),
                ...extras.map((ad) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(ad['concepto']?.toString() ?? 'Adicional', style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                              TextSpan(text: ad['monto']?.toString() ?? '0'),
                            ]
                          ),
                          style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 24),
              
              // TOTAL FINAL HIGHLIGHT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: colorAcento.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorAcento.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL FINAL', style: EstilosTextoApp.h3.copyWith(color: colorAcento)),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: '\$ ', style: TextStyle(fontWeight: FontWeight.normal)),
                          TextSpan(text: granTotalLimpio),
                        ]
                      ),
                      style: EstilosTextoApp.h2.copyWith(color: colorAcento, fontSize: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 7. PIE DE PÁGINA Y TRUST BADGE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: tema.dividerColor, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: colorAcento, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Servicio asegurado y verificado', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Transacción cerrada mediante PIN presencial.', style: EstilosTextoApp.cuerpoPequeno),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('¡Gracias por confiar en nosotros!', style: EstilosTextoApp.cuerpoDestacado.copyWith(color: colorAcento)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstruirIdentidad extends StatelessWidget {
  final String titulo;
  final String nombre;
  final String avatarUrl;
  final Color colorBorde;
  final ThemeData tema;
  final bool esPro;

  const _ConstruirIdentidad({
    required this.titulo, required this.nombre, required this.avatarUrl,
    required this.colorBorde, required this.tema, this.esPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colorBorde == Colors.transparent ? tema.dividerColor.withOpacity(0.3) : colorBorde, width: colorBorde == Colors.transparent ? 1 : 1.5),
          borderRadius: BorderRadius.circular(12),
          color: colorBorde == Colors.transparent ? Colors.transparent : colorBorde.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: EstilosTextoApp.etiquetaEstado.copyWith(color: tema.hintColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl, width: 36, height: 36, fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: tema.dividerColor, width: 36, height: 36),
                          errorWidget: (context, url, error) => Icon(Icons.person, color: tema.hintColor),
                        )
                      : Container(width: 36, height: 36, color: tema.dividerColor, child: Icon(Icons.person, color: tema.hintColor, size: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(nombre.isEmpty ? 'Usuario' : nombre, style: EstilosTextoApp.cuerpoDestacado.copyWith(color: tema.colorScheme.onSurface, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (esPro) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, color: ColoresApp.terciarioMorado, size: 14),
                          ]
                        ],
                      ),
                      Text(esPro ? 'Profesional' : 'Contratante', style: EstilosTextoApp.cuerpoPequeno.copyWith(fontSize: 11)),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _FilaLogistica extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final ThemeData tema;

  const _FilaLogistica({required this.icono, required this.etiqueta, required this.valor, required this.tema});

  @override
  Widget build(BuildContext context) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: tema.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(etiqueta, style: EstilosTextoApp.cuerpoPequeno.copyWith(fontWeight: FontWeight.bold, color: tema.hintColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(valor, style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
