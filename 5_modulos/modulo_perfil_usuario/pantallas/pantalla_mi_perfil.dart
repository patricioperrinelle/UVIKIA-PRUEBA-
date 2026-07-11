// lib/5_modulos/modulo_perfil_usuario/pantallas/pantalla_mi_perfil.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../3_modelos/modelo_perfil.dart'; 
import '../../../4_componentes_globales/cabeceras/cabecera_hero_perfil.dart';
import '../../../4_componentes_globales/tarjetas/visor_imagen_pantalla_completa.dart'; 

import '../componentes/seccion_desempeno_usuario.dart';
import '../componentes/grilla_actividad_estadisticas.dart';
import '../componentes/seccion_listas_habilidades.dart';
import '../componentes/seccion_lista_resenas.dart'; 
import '../componentes/seccion_galeria_portfolio.dart';
import '../componentes/seccion_perfiles_guardados.dart'; 

import '../controladores/controlador_visualizacion_perfil.dart';
import 'pantalla_editar_perfil.dart';

import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';

class PantallaMiPerfil extends StatefulWidget {
  final VoidCallback? onBack;

  const PantallaMiPerfil({Key? key, this.onBack}) : super(key: key);

  @override
  State<PantallaMiPerfil> createState() => _PantallaMiPerfilState();
}

class _PantallaMiPerfilState extends State<PantallaMiPerfil> {
  final ControladorVisualizacionPerfil _controlador = ControladorVisualizacionPerfil();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gestor = context.read<GestorSesionGlobal>();
      _controlador.cargarDatosPrivados(gestor.miIdUsuario);
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _abrirEditor() async {
    final huboCambios = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const PantallaEditarPerfil())
    );
    if (!mounted) return; // 🛡️ QA-Terminator: Prevención de Async Gaps
    if (huboCambios == true) {
      final miId = context.read<GestorSesionGlobal>().miIdUsuario;
      _controlador.cargarDatosPrivados(miId);
    }
  }

  void _mostrarGaleria(int initialIndex, List<String> imagenes) {
    if (imagenes.isEmpty || imagenes.first.isEmpty) return;
    showDialog(
      context: context, 
      useSafeArea: false, 
      builder: (ctx) => VisorImagenPantallaCompleta(imagenes: imagenes, indiceInicial: initialIndex)
    );
  }

  @override
  Widget build(BuildContext context) {
    final gestorSesion = context.watch<GestorSesionGlobal>();
    final perfil = gestorSesion.perfilUsuario;
    final tema = Theme.of(context); 
    final bool viendoPro = gestorSesion.modoActual == ModoUsuario.profesional;

    _controlador.perfilActual = perfil;

    final bool mostrarBotonVolver = widget.onBack != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor, 
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: mostrarBotonVolver ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface, size: 22), 
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!(); 
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context); 
            }
          },
        ) : null,
        actions:[
          IconButton(
            icon: Icon(Icons.edit_outlined, color: tema.colorScheme.onSurface, size: 22), 
            onPressed: _abrirEditor,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controlador,
        builder: (context, child) {
          return RefreshIndicator(
            color: ColoresApp.primarioVerde,
            onRefresh: () async {
              await gestorSesion.sincronizarPerfilConBaseDeDatos();
              await _controlador.cargarDatosPrivados(gestorSesion.miIdUsuario);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:[
                  SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                  
                  CabeceraHeroPerfil(
                    apodo: perfil?.apodo ?? 'Usuario',
                    fotoUrl: perfil?.fotoUrl ?? '',
                    oficioPrincipal: _controlador.getOficioPrincipal(viendoPro),
                    rating: _controlador.getRating(viendoPro),               
                    reviews: _controlador.getReviewsCount(viendoPro),
                    zonaTrabajo: viendoPro ? (perfil?.perfilProfesional?.zonaTrabajo ?? '') : _controlador.formatearUbicacionCliente,
                    miembroDesde: _controlador.formatearMesAnio,
                    edad: viendoPro ? perfil?.edadCalculada : null, 
                    onAvatarTap: () => _mostrarGaleria(0,[perfil?.fotoUrl ?? '']),
                  ),

                  Padding(
                    padding: DimensionesApp.paddingPantalla,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children:[
                        const SizedBox(height: 16),
                        _buildBioOTextoInformativo(viendoPro, perfil, tema),
                        const SizedBox(height: 32),

                        if (perfil != null) 
                          viendoPro 
                            ? _buildContenidoProfesional(perfil, tema) 
                            : _buildContenidoCliente(perfil, tema),
                        
                        const SizedBox(height: 40), 
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBioOTextoInformativo(bool viendoPro, ModeloPerfil? perfil, ThemeData tema) {
    String texto = viendoPro 
        ? (perfil?.perfilProfesional?.bio.isNotEmpty == true ? perfil!.perfilProfesional!.bio : 'Aún no has escrito tu biografía profesional.') 
        : 'Perfil de contratante. Aquí gestionas tus publicaciones y trabajadores guardados.';
    return Text(texto, style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.textTheme.bodyMedium?.color));
  }

  Widget _buildContenidoProfesional(ModeloPerfil perfil, ThemeData tema) {
    final pro = perfil.perfilProfesional;
    final fotosPortafolio = pro?.fotosPortafolio ??[];

    final List<String> habYCert = _controlador.habilidadesYCertificados;
    final List<String> extras = _controlador.serviciosExtras;

    return Column(
      children:[
        if (habYCert.isNotEmpty || extras.isNotEmpty) ...[
          SeccionListasHabilidades(habilidades: habYCert, servicios: extras),
          const SizedBox(height: 32),
        ],

        // 🚨 AQUÍ INYECTAMOS LA NUEVA CAJA DE RESEÑAS 
        SeccionListaResenas(
          resenas: _controlador.misResenasProfesional,
          ratingGlobal: _controlador.getRating(true),
          totalResenas: _controlador.getReviewsCount(true),
          esCliente: false,
        ),
        
        SeccionDesempenoUsuario(
          tituloSeccion: 'Mi desempeño', subtituloSeccion: 'Últimos 90 días', colorScoreBox: ColoresApp.terciarioMorado,
          scoreConfiabilidad: pro?.scoreConfiabilidadPro ?? 0.0, etiquetaScore: 'Basado en tu desempeño general', tipoScore: (pro?.scoreConfiabilidadPro ?? 0) > 0 ? 'Excelente' : 'Nuevo', 
          metricas:[
            MetricaDesempeno(icono: Icons.access_time, colorIcono: ColoresApp.primarioVerde, titulo: 'Puntualidad', subtitulo: 'Llegó a tiempo', valorText: '${(pro?.puntualidad ?? 0).toInt()}%'),
            MetricaDesempeno(icono: Icons.calendar_today, colorIcono: ColoresApp.infoAzul, titulo: 'Asistencia', subtitulo: 'Asiste a las jornadas', valorText: '${(pro?.asistencia ?? 0).toInt()}%'),
            MetricaDesempeno(icono: Icons.work_outline, colorIcono: ColoresApp.primarioVerde, titulo: 'Jornadas completadas', subtitulo: 'Total asignadas', valorText: '${(pro?.jornadasCompletadas ?? 0).toInt()}'),
            MetricaDesempeno(icono: Icons.cancel_outlined, colorIcono: ColoresApp.errorRojo, titulo: 'Cancelaciones', subtitulo: 'Post-aceptación', valorText: '${(pro?.cancelacionesPro ?? 0).toInt()}'),
          ],
        ),
        const SizedBox(height: 32),

        GrillaActividadEstadisticas(
          titulo: 'Actividad',
          datos:[
            DatoActividad(icono: Icons.work_history_outlined, colorIcono: ColoresApp.terciarioMorado, valor: '${pro?.jornadasRealizadas ?? 0}', titulo: 'Jornadas\nrealizadas'),
            DatoActividad(icono: Icons.star_border_rounded, colorIcono: ColoresApp.terciarioMorado, valor: _controlador.getRating(true) > 0 ? _controlador.getRating(true).toStringAsFixed(1) : 'Nuevo', titulo: 'Promedio\nde estrellas'),
            DatoActividad(icono: Icons.thumb_up_outlined, colorIcono: ColoresApp.primarioVerde, valor: '${(pro?.recomendacionClientes ?? 0).toInt()}%', titulo: 'Recomendación\nde clientes'),
            DatoActividad(icono: Icons.calendar_month_outlined, colorIcono: ColoresApp.terciarioMorado, valor: pro?.experienciaAnos ?? '0', titulo: 'Años de\nExperiencia'),
          ],
        ),
        const SizedBox(height: 32),
        
        if (fotosPortafolio.isNotEmpty) ...[
          Text('Trabajos Anteriores', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
          const SizedBox(height: 16),
          SeccionGaleriaPortfolio(imagenes: fotosPortafolio, onImageTap: (idx) => _mostrarGaleria(idx, fotosPortafolio)),
        ],
      ],
    );
  }

  Widget _buildContenidoCliente(ModeloPerfil perfil, ThemeData tema) {
    return Column(
      children:[
        // 🚨 AQUÍ INYECTAMOS LA NUEVA CAJA DE RESEÑAS PARA MODO CLIENTE
        SeccionListaResenas(
          resenas: _controlador.misResenasCliente,
          ratingGlobal: _controlador.getRating(false),
          totalResenas: _controlador.getReviewsCount(false),
          esCliente: true,
        ),
        
        const SizedBox(height: 32),
        
        SeccionDesempenoUsuario(
          tituloSeccion: 'Mi desempeño', subtituloSeccion: 'Últimos 90 días', colorScoreBox: ColoresApp.primarioVerde,
          scoreConfiabilidad: perfil.scoreConfiabilidadCliente, etiquetaScore: 'Comportamiento como contratante', tipoScore: perfil.scoreConfiabilidadCliente > 0 ? 'Excelente' : 'Nuevo', 
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
        const SizedBox(height: 32),

        Row(
          children:[
            const Icon(Icons.bookmark_rounded, color: ColoresApp.infoAzul, size: 20),
            const SizedBox(width: 8),
            Text('Perfiles Guardados', style: EstilosTextoApp.h3.copyWith(color: tema.colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 16),
        SeccionPerfilesGuardados(favoritos: _controlador.misFavoritos),
      ],
    );
  }
}