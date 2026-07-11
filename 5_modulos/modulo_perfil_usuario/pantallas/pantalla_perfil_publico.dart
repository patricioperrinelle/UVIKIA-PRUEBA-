// lib/5_modulos/modulo_perfil_usuario/pantallas/pantalla_perfil_publico.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../3_modelos/modelo_resena.dart'; 
import '../../../3_modelos/modelo_perfil.dart'; 
import '../../../4_componentes_globales/cabeceras/cabecera_hero_perfil.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../../../4_componentes_globales/tarjetas/visor_imagen_pantalla_completa.dart'; 

import '../componentes/seccion_desempeno_usuario.dart';
import '../componentes/grilla_actividad_estadisticas.dart';
import '../componentes/seccion_listas_habilidades.dart';
import '../componentes/seccion_lista_resenas.dart'; // 🚨 NUEVO COMPONENTE INYECTADO
import '../componentes/seccion_galeria_portfolio.dart';
import '../controladores/controlador_visualizacion_perfil.dart';

import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../modulo_publicaciones/pantallas/pantalla_solicitar_presupuesto_privado.dart'; 

class PantallaPerfilPublico extends StatefulWidget {
  const PantallaPerfilPublico({Key? key}) : super(key: key);

  @override
  State<PantallaPerfilPublico> createState() => _PantallaPerfilPublicoState();
}

class _PantallaPerfilPublicoState extends State<PantallaPerfilPublico> {
  final ControladorVisualizacionPerfil _controlador = ControladorVisualizacionPerfil();
  late String _proId;
  String _apodoPrecargado = 'Cargando...';
  String _fotoPrecargada = '';
  List<String> _tagsPrecargados = [];
  
  bool _viendoProfesional = true;
  bool _isInit = true; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final miModo = context.read<GestorSesionGlobal>().modoActual;
      _viendoProfesional = (miModo == ModoUsuario.cliente);

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && _controlador.perfilActual == null) {
        _proId = args['id']?.toString() ?? '';
        _apodoPrecargado = args['name']?.toString() ?? 'Profesional';
        _fotoPrecargada = args['image']?.toString() ?? '';
        
        if (args['tags'] is List) {
          _tagsPrecargados = List<String>.from(args['tags']);
        } else if (args['oficios'] != null) {
          _tagsPrecargados = args['oficios'].toString().split(',').map((t)=>t.trim()).toList();
        }
        
        if (_proId.isNotEmpty) {
          final miId = context.read<GestorSesionGlobal>().miIdUsuario;
          _controlador.cargarPerfilPublico(_proId, miId).then((_) {
            if (_controlador.perfilActual?.esProfesional == false && mounted) {
              setState(() => _viendoProfesional = false);
            }
          });
        }
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool esExito = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: esExito ? ColoresApp.primarioVerde : ColoresApp.errorRojo,
      ),
    );
  }

  void _mostrarGaleria(int initialIndex, List<String> imagenes) {
    if (imagenes.isEmpty) return;
    showDialog(context: context, useSafeArea: false, builder: (ctx) => VisorImagenPantallaCompleta(imagenes: imagenes, indiceInicial: initialIndex));
  }

  Widget _buildDelicateTabs(ThemeData tema, bool esOscuro) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 24),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children:[
            _buildTabOption('PERFIL TRABAJADOR', true, tema),
            _buildTabOption('PERFIL CLIENTE', false, tema),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption(String titulo, bool isProTab, ThemeData tema) {
    final bool isSelected = _viendoProfesional == isProTab;
    final Color colorAcento = isProTab ? ColoresApp.terciarioMorado : ColoresApp.primarioVerde;
    
    return GestureDetector(
      onTap: () => setState(() => _viendoProfesional = isProTab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? colorAcento.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children:[
            if (isSelected) ...[Icon(isProTab ? Icons.person_outline : Icons.business_center_outlined, color: colorAcento, size: 14), const SizedBox(width: 4)],
            Text(
              titulo, 
              style: EstilosTextoApp.cuerpoPequeno.copyWith(
                color: isSelected ? colorAcento : tema.textTheme.bodyMedium?.color, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context); 

    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, child) {
        final perfil = _controlador.perfilActual;
        final pro = perfil?.perfilProfesional;
        final bool isLoading = _controlador.isLoading;
        
        final String apodoFinal = perfil?.apodo ?? _apodoPrecargado;
        final String fotoFinal = perfil?.fotoUrl ?? _fotoPrecargada;
        final List<String> tagsFinal = pro?.tagsOficios ?? _tagsPrecargados;
        final String oficioPrincipal = tagsFinal.isNotEmpty ? tagsFinal.first : ''; 
        
        final String bio = pro?.bio ?? '';
        final List<String> fotosPortafolio = pro?.fotosPortafolio ?? [];

        final List<String> habYCert = _controlador.habilidadesYCertificados;
        final List<String> extras = _controlador.serviciosExtras;

        final miId = context.read<GestorSesionGlobal>().miIdUsuario;
        final bool esMiPropioPerfil = miId == _proId;
        final bool esProfesionalReal = perfil?.esProfesional == true;

        final double ratingMostrar = _viendoProfesional ? _controlador.getRating(true) : _controlador.getRating(false);
        final int reviewsMostrar = _viendoProfesional ? _controlador.getReviewsCount(true) : _controlador.getReviewsCount(false);
        final List<ModeloResena> resenasMostrar = _viendoProfesional ? _controlador.misResenasProfesional : _controlador.misResenasCliente;
        final double scoreMostrar = _viendoProfesional ? _controlador.getScore(true) : _controlador.getScore(false);

        return Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor, 
          appBar: AppBar(
            backgroundColor: tema.scaffoldBackgroundColor, 
            elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface, size: 22), onPressed: () { if (Navigator.canPop(context)) Navigator.pop(context); }),
            actions:[
              if (!esMiPropioPerfil) ...[
                IconButton(
                  icon: Icon(_controlador.isFavorito ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _controlador.isFavorito ? ColoresApp.infoAzul : tema.colorScheme.onSurface, size: 22), 
                  visualDensity: VisualDensity.compact, 
                  onPressed: () async {
                    if (context.read<GestorSesionGlobal>().esInvitado) {
                      GestorSesionGlobal.requerirAuth(() {});
                      return;
                    }
                    try {
                      final estadoActualizado = await _controlador.toggleFavoritoGlobal(_proId, miId);
                      _mostrarMensaje(estadoActualizado ? 'Perfil guardado' : 'Perfil eliminado', esExito: true);
                    } catch (e) {
                      _mostrarMensaje(e.toString());
                    }
                  }
                ),
                IconButton(icon: Icon(Icons.share_outlined, color: tema.colorScheme.onSurface, size: 22), visualDensity: VisualDensity.compact, onPressed: () => _mostrarMensaje('Enlace copiado', esExito: true)),
                IconButton(icon: Icon(Icons.more_vert_rounded, color: tema.colorScheme.onSurface, size: 22), visualDensity: VisualDensity.compact, onPressed: () => _mostrarDialogoDenuncia(context)),
                const SizedBox(width: 8), 
              ] 
            ],
          ),
          body: RefreshIndicator(
            color: ColoresApp.primarioVerde,
            backgroundColor: tema.colorScheme.surface,
            onRefresh: () => _controlador.cargarPerfilPublico(_proId, miId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:[
                  SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                  
                  if (esProfesionalReal && !isLoading) 
                    _buildDelicateTabs(tema, tema.brightness == Brightness.dark),

                  CabeceraHeroPerfil(
                    apodo: apodoFinal, 
                    fotoUrl: fotoFinal, 
                    oficioPrincipal: _viendoProfesional ? oficioPrincipal : '',
                    rating: ratingMostrar, 
                    reviews: reviewsMostrar, 
                    zonaTrabajo: _viendoProfesional ? (pro?.zonaTrabajo ?? '') : _controlador.formatearUbicacionCliente,
                    miembroDesde: _controlador.formatearMesAnio, 
                    edad: _viendoProfesional ? perfil?.edadCalculada : null,
                    onAvatarTap: () => _mostrarGaleria(0, [fotoFinal]),
                  ),

                  Padding(
                    padding: DimensionesApp.paddingPantalla,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        if (isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: ColoresApp.primarioVerde)))
                        else if (perfil != null) ...[
                          const SizedBox(height: 16),
                          Text(_viendoProfesional ? (bio.isNotEmpty ? bio : 'Profesional responsable, puntual y con excelente actitud.') : 'Contratante particular o empresa. Buscamos siempre brindar la mejor experiencia.', style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.colorScheme.onSurface)),
                          const SizedBox(height: 32),

                          if (_viendoProfesional) ...[
                            
                            if (habYCert.isNotEmpty || extras.isNotEmpty) ...[
                              SeccionListasHabilidades(habilidades: habYCert, servicios: extras),
                              const SizedBox(height: 32),
                            ],

                            // 🚨 AQUÍ INYECTAMOS LA NUEVA CAJA DE RESEÑAS EN EL MODO PROFESIONAL (PÚBLICO)
                            SeccionListaResenas(
                              resenas: resenasMostrar,
                              ratingGlobal: ratingMostrar,
                              totalResenas: reviewsMostrar,
                              esCliente: false,
                            ),

                            SeccionDesempenoUsuario(
                              tituloSeccion: 'Mi desempeño', subtituloSeccion: 'Últimos 90 días', colorScoreBox: ColoresApp.terciarioMorado,
                              scoreConfiabilidad: pro?.scoreConfiabilidadPro ?? 0.0, etiquetaScore: 'Basado en tu desempeño general', tipoScore: scoreMostrar > 0 ? 'Excelente' : 'Nuevo', 
                              metricas:[
                                MetricaDesempeno(icono: Icons.access_time, colorIcono: ColoresApp.primarioVerde, titulo: 'Puntualidad', subtitulo: 'Llegó a tiempo', valorText: '${(pro?.puntualidad ?? 0).toInt()}%'),
                                MetricaDesempeno(icono: Icons.calendar_today, colorIcono: ColoresApp.infoAzul, titulo: 'Asistencia', subtitulo: 'Asiste a las jornadas', valorText: '${(pro?.asistencia ?? 0).toInt()}%'),
                                MetricaDesempeno(icono: Icons.work_outline, colorIcono: ColoresApp.primarioVerde, titulo: 'Jornadas completadas', subtitulo: 'Completa las jornadas asignadas', valorText: '${(pro?.jornadasCompletadas ?? 0).toInt()}'),
                                MetricaDesempeno(icono: Icons.cancel_outlined, colorIcono: ColoresApp.errorRojo, titulo: 'Cancelaciones', subtitulo: 'Cancela jornadas aceptadas', valorText: '${(pro?.cancelacionesPro ?? 0).toInt()}'),
                              ],
                            ),
                            const SizedBox(height: 32),
                            GrillaActividadEstadisticas(
                              titulo: 'Actividad',
                              datos:[
                                DatoActividad(icono: Icons.work_history_outlined, colorIcono: ColoresApp.terciarioMorado, valor: '${pro?.jornadasRealizadas ?? 0}', titulo: 'Jornadas\nrealizadas'),
                                DatoActividad(icono: Icons.star_border_rounded, colorIcono: ColoresApp.terciarioMorado, valor: ratingMostrar > 0 ? ratingMostrar.toStringAsFixed(1) : 'Nuevo', titulo: 'Promedio\nde estrellas'),
                                DatoActividad(icono: Icons.thumb_up_outlined, colorIcono: ColoresApp.primarioVerde, valor: '${(pro?.recomendacionClientes ?? 0).toInt()}%', titulo: 'Recomendación\nde clientes'),
                                DatoActividad(icono: Icons.calendar_month_outlined, colorIcono: ColoresApp.terciarioMorado, valor: pro?.experienciaAnos ?? '0', titulo: 'En la\nplataforma'),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            if (fotosPortafolio.isNotEmpty) ...[
                              Text('Trabajos Anteriores', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
                              const SizedBox(height: 16),
                              SeccionGaleriaPortfolio(imagenes: fotosPortafolio, onImageTap: (idx) => _mostrarGaleria(idx, fotosPortafolio)),
                            ],
                            
                          ] else ...[
                            
                            // 🚨 AQUÍ INYECTAMOS LA NUEVA CAJA DE RESEÑAS EN EL MODO CLIENTE (PÚBLICO)
                            SeccionListaResenas(
                              resenas: resenasMostrar,
                              ratingGlobal: ratingMostrar,
                              totalResenas: reviewsMostrar,
                              esCliente: true,
                            ),

                            SeccionDesempenoUsuario(
                              tituloSeccion: 'Mi desempeño', subtituloSeccion: 'Últimos 90 días', colorScoreBox: ColoresApp.primarioVerde,
                              scoreConfiabilidad: perfil.scoreConfiabilidadCliente, etiquetaScore: 'Basado en tu comportamiento como contratante', tipoScore: scoreMostrar > 0 ? 'Excelente' : 'Nuevo', 
                              metricas:[
                                MetricaDesempeno(icono: Icons.handshake_outlined, colorIcono: ColoresApp.primarioVerde, titulo: 'Tasa de contratación', subtitulo: 'Sobre el total publicado', valorText: '${_controlador.getTasaContratacion()}%'),
                                MetricaDesempeno(icono: Icons.cancel_outlined, colorIcono: ColoresApp.errorRojo, titulo: 'Cancelaciones', subtitulo: 'Publicaciones dadas de baja', valorText: '${_controlador.getCancelacionesCliente().toInt()}%'),
                                MetricaDesempeno(icono: Icons.favorite_border, colorIcono: ColoresApp.terciarioMorado, titulo: 'Buen trato al personal', subtitulo: 'Calidad del trato en obra', valorText: _controlador.getBuenTratoPersonal().toStringAsFixed(1)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            GrillaActividadEstadisticas(
                              titulo: 'Actividad',
                              datos:[
                                DatoActividad(icono: Icons.list_alt, colorIcono: ColoresApp.infoAzul, valor: '${_controlador.getTrabajosPublicados()}', titulo: 'Trabajos\npublicados'),
                                DatoActividad(icono: Icons.groups_outlined, colorIcono: ColoresApp.terciarioMorado, valor: '${perfil.trabajadoresContratados}', titulo: 'Trabajadores\ncontratados'),
                                DatoActividad(icono: Icons.thumb_up_outlined, colorIcono: ColoresApp.primarioVerde, valor: '${perfil.recomendacionTrabajadores.toInt()}%', titulo: 'Recomendación\ndel pro'),
                                DatoActividad(icono: Icons.warning_amber_rounded, colorIcono: ColoresApp.advertenciaAmarillo, valor: '${perfil.disputasAbiertas.toInt()}', titulo: 'Disputas\n(abiertas)'),
                              ],
                            ),
                          ]
                        ],
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: (esMiPropioPerfil) ? const SizedBox.shrink() : _buildStickyHireButton(apodoFinal),
        );
      }
    );
  }

  Widget _buildStickyHireButton(String apodoFijo) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: BotonAccionPrincipal(
          texto: 'PEDIR PRESUPUESTO', 
          onPressed: _controlador.isLoading ? null : () { 
            if (context.read<GestorSesionGlobal>().esInvitado) {
              GestorSesionGlobal.requerirAuth(() {});
              return;
            }
            if (_proId.isEmpty) return; 
            Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaSolicitarPresupuestoPrivado(idProfesional: _proId, nombreProfesional: apodoFijo))); 
          }
        ),
      ),
    );
  }

  void _mostrarDialogoDenuncia(BuildContext context) {
    // UI ciega, solo atrapa el string y pásaselo a _controlador.enviarDenuncia(...)
  }
}