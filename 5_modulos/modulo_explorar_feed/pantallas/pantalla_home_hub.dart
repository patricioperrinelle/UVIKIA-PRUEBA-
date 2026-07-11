// lib/5_modulos/modulo_explorar_feed/pantallas/pantalla_home_hub.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- NÚCLEO Y TEMA ---
import '../../../1_nucleo/estado_global/gestor_sesion_global.dart';
import '../../../2_tema/colores_app.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../2_tema/estilos_texto.dart';

// --- COMPONENTES GLOBALES ---
import '../../../4_componentes_globales/cabeceras/titulo_seccion_con_icono.dart';
import '../../../4_componentes_globales/modales_y_alertas/modal_requiere_registro.dart'; 
import '../../../4_componentes_globales/modales_y_alertas/dialogo_confirmacion_estandar.dart'; 

// --- COMPONENTES DEL MÓDULO ---
import '../componentes/tarjeta_seccion_premium.dart'; 
import '../componentes/modal_selector_modo.dart';
import '../componentes/banner_rango_profesional.dart';

// --- RUTEO E HISTORIAL ---
import '../../modulo_autenticacion/controladores/controlador_auth.dart';
import '../../modulo_actividad_alertas/pantallas/pantalla_actividad_tabs.dart';
import '../../modulo_actividad_alertas/pantallas/pantalla_notificaciones_bandeja.dart';
import '../../modulo_actividad_alertas/controladores/controlador_bandeja_notificaciones.dart';
import '../../modulo_perfil_usuario/pantallas/pantalla_mi_perfil.dart';
import '../../modulo_perfil_usuario/pantallas/pantalla_onboarding_profesional.dart'; 
import '../../modulo_publicaciones/pantallas/pantalla_publicar_trabajo.dart';
import '../../modulo_publicaciones/pantallas/pantalla_publicar_jornada.dart';
import 'pantalla_feed_profesionales.dart';
import 'pantalla_feed_trabajos.dart';
import 'pantalla_feed_jornadas.dart';

import '../../modulo_servicios_catalogo/pantallas/pantalla_explorar_catalogo.dart';
import '../../modulo_servicios_catalogo/pantallas/pantalla_mis_servicios_pro.dart';

// 🚨 IMPORTACIÓN DE LA NUEVA BILLETERA
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modulo_billetera/pantallas/pantalla_mi_billetera.dart';

class PantallaHomeHub extends StatefulWidget {
  const PantallaHomeHub({Key? key}) : super(key: key);

  @override
  State<PantallaHomeHub> createState() => _PantallaHomeHubState();
}

class _PantallaHomeHubState extends State<PantallaHomeHub> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarPagosRecientes();
      ControladorBandejaNotificaciones().cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarPagosRecientes();
    }
  }

  Future<void> _verificarPagosRecientes() async {
    try {
      final userId = GestorSesionGlobal().miIdUsuario;
      if (userId.isEmpty) return;

      final respuesta = await Supabase.instance.client
          .from('wallet_transactions')
          .select('id')
          .eq('usuario_id', userId)
          .eq('tipo', 'pago_servicio')
          .eq('estado', 'completado')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (respuesta != null && mounted) {
        final String lastTxId = respuesta['id'].toString();
        final prefs = await SharedPreferences.getInstance();
        final String? notifiedId = prefs.getString('last_notified_payment');

        if (notifiedId != lastTxId) {
          await prefs.setString('last_notified_payment', lastTxId);
          if (mounted) {
            _mostrarNotificacionPagoExitoso(context);
          }
        }
      }
    } catch (e) {
      debugPrint('Error al verificar pagos recientes: $e');
    }
  }

  void _mostrarNotificacionPagoExitoso(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: ColoresApp.primarioVerde, size: 56),
            SizedBox(height: 16),
            Text('¡Pago Confirmado!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'El pago de tu servicio impactó exitosamente. Puedes revisarlo y gestionarlo en tu Agenda.', 
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresApp.primarioVerde,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).popUntil((route) => route.isFirst);
                _onTabTapped(1); // 1 es la tab de Actividad/Agenda
              },
              child: const Text('Ir a mi Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  // 🛡️ DELEGACIÓN VISUAL DE CIERRE DE SESIÓN
  void _mostrarDialogoCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DialogoConfirmacionEstandar(
        titulo: 'Cerrar Sesión',
        mensaje: '¿Seguro que deseas salir de tu cuenta?',
        textoBotonConfirmar: 'Salir',
        colorConfirmar: ColoresApp.errorRojo,
        onCancelar: () => Navigator.pop(ctx),
        onConfirmar: () async {
          Navigator.pop(ctx);
          try {
            await ControladorAuth.instancia.cerrarSesion();
            if (context.mounted) {
              await context.read<GestorSesionGlobal>().destruirSesionCompletamente();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          } catch (e) {
            // Error silencioso ya que estamos destruyendo sesión
          }
        },
      ),
    );
  }

  void _abrirOnboarding() {
    final tema = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tema.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: DimensionesApp.radioTarjetas),
        title: const Row(
          children:[
            Icon(Icons.workspace_premium_rounded, color: ColoresApp.primarioVerde, size: 28),
            SizedBox(width: 12),
            Text('¡Únete como Pro!', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text('Para acceder al modo profesional necesitas completar tu perfil.', style: TextStyle(color: tema.textTheme.bodyMedium?.color)),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Más tarde', style: TextStyle(color: tema.textTheme.bodyMedium?.color))
          ),
          ElevatedButton(
            onPressed: () { 
              Navigator.pop(ctx); 
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const PantallaOnboardingProfesional())
              ); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColoresApp.primarioVerde),
            child: const Text('Completar Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorSesionGlobal>();
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // 🚨 INYECCIÓN EN ÍNDICE 2 (Billetera insertada para usuarios registrados)
    final List<Widget> screens = gestor.esInvitado 
      ? <Widget>[_ContenidoMenuHub(onAbrirOnboarding: _abrirOnboarding)]
      : <Widget>[
          _ContenidoMenuHub(onAbrirOnboarding: _abrirOnboarding),
          PantallaActividadTabs(isActive: _currentIndex == 1), 
          const PantallaMiBilletera(), // <-- Billetera Inyectada (Índice 2)
          const PantallaNotificacionesBandeja(), 
          PantallaMiPerfil(onBack: () => _onTabTapped(0)), 
        ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _currentIndex = 0);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          appBar: _currentIndex == 0
              ? AppBar(
                  backgroundColor: tema.scaffoldBackgroundColor,
                  elevation: 0,
                  title: Text('In-Drive Services', style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
                  actions: <Widget>[
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Material(
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: tema.colorScheme.onSurface.withOpacity(0.15), width: 1),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => context.read<GestorSesionGlobal>().toggleTemaOscuro(),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                esOscuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                color: tema.colorScheme.onSurface,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    if (gestor.esInvitado)
                       TextButton(
                         onPressed: () => Navigator.pushNamed(context, '/login'),
                         child: const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde)),
                       )
                    else
                       IconButton(
                         icon: const Icon(Icons.exit_to_app_rounded, color: ColoresApp.errorRojo),
                         onPressed: () => _mostrarDialogoCerrarSesion(context), 
                       ),
                  ],
                )
              : null,

          body: IndexedStack(index: _currentIndex, children: screens),
          
          bottomNavigationBar: gestor.esInvitado 
            ? null
            : BottomNavigationBar(
                backgroundColor: tema.scaffoldBackgroundColor,
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                selectedItemColor: tema.colorScheme.onSurface,
                unselectedItemColor: esOscuro ? Colors.white38 : Colors.black38,
                type: BottomNavigationBarType.fixed, // Permite 5 ítems sin animaciones raras
                items: <BottomNavigationBarItem>[
                  const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
                  BottomNavigationBarItem(icon: const Icon(Icons.assignment_rounded), label: gestor.modoActual == ModoUsuario.cliente ? 'Contratos' : 'Mi Agenda'),
                  
                  // 🚨 INYECCIÓN EN ÍNDICE 2
                  const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Billetera'),
                  
                  BottomNavigationBarItem(
                    icon: ListenableBuilder(
                      listenable: ControladorBandejaNotificaciones(),
                      builder: (context, child) {
                        final count = ControladorBandejaNotificaciones().totalNoLeidas;
                        if (count > 0) {
                          return Badge(
                            label: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.redAccent,
                            child: const Icon(Icons.notifications_rounded),
                          );
                        }
                        return const Icon(Icons.notifications_rounded);
                      },
                    ),
                    label: 'Alertas',
                  ),
                  const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Mi Perfil'),
                ],
              ),
        ),
      ),
    );
  }
}

class _ContenidoMenuHub extends StatelessWidget {
  final VoidCallback onAbrirOnboarding;

  const _ContenidoMenuHub({Key? key, required this.onAbrirOnboarding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorSesionGlobal>();
    final modoActual = gestor.modoActual;
    final esCliente = modoActual == ModoUsuario.cliente;
    final esInvitado = gestor.esInvitado; 
    
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final nombreUsuario = esInvitado ? 'Invitado' : (gestor.perfilUsuario?.apodo ?? 'Usuario');

    final Color colorBordePastilla = esInvitado ? Colors.grey.shade400 : (esCliente ? ColoresApp.primarioVerde.withOpacity(0.3) : ColoresApp.terciarioMorado.withOpacity(0.3));
    final Color colorFondoPastilla = esInvitado ? Colors.grey.withOpacity(0.05) : (esCliente ? ColoresApp.primarioVerde.withOpacity(0.05) : ColoresApp.terciarioMorado.withOpacity(0.05));
    final IconData iconoPastilla = esInvitado ? Icons.explore_rounded : (esCliente ? Icons.person_search_rounded : Icons.work_rounded);
    final Color colorIconoPastilla = esInvitado ? Colors.grey.shade600 : (esCliente ? ColoresApp.primarioVerde : ColoresApp.terciarioMorado);
    final String textoPastilla = esInvitado ? 'Modo de Exploración' : (esCliente ? 'Soy Cliente' : 'Soy Profesional');

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: GestureDetector(
              onTap: () {
                if (esInvitado) {
                  ModalRequiereRegistro.mostrar(context);
                } else {
                  ModalSelectorModo.mostrar(context, gestor, onAbrirOnboarding);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorFondoPastilla,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorBordePastilla),
                ),
                child: Row(
                  children:[
                    Icon(iconoPastilla, color: colorIconoPastilla, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Text('Modo Actual', style: TextStyle(color: tema.textTheme.bodySmall?.color, fontSize: 11)),
                          Text(textoPastilla, style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: esOscuro ? Colors.white12 : Colors.black12, shape: BoxShape.circle),
                      child: Icon(Icons.swap_horiz_rounded, size: 18, color: tema.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('¡Hola, $nombreUsuario!', style: EstilosTextoApp.h1.copyWith(color: tema.colorScheme.onSurface, height: 1.1, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(esInvitado ? 'Descubre todo lo que puedes hacer' : (esCliente ? '¿Qué necesitás hacer hoy?' : '¿Listo para trabajar?'), style: EstilosTextoApp.cuerpoRegular.copyWith(color: tema.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: esInvitado
                  ? _buildVistaInvitado(context, tema)
                  : (esCliente ? _buildVistaCliente(context, tema) : _buildVistaProfesional(context, tema)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVistaInvitado(BuildContext context, ThemeData tema) {
    return [
      const TituloSeccionConIcono(titulo: 'CONTRATAR SERVICIOS', icono: Icons.shopping_bag_outlined, colorTema: ColoresApp.primarioVerde),
      TarjetaSeccionPremium(
        titulo: 'Catálogo Directo',
        subtitulo: 'Explora servicios con precios cerrados y agenda inmediata.',
        rutaImagen: 'assets/images/home_banners/catalogo_banner.jpg',
        iconoPlaceholder: Icons.shopping_bag_outlined,
        colorAcento: ColoresApp.primarioVerde, 
        vinetas: const ['Precios fijos', 'Elige nivel de servicio', 'Agenda automática'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaExplorarCatalogo())),
      ),
      TarjetaSeccionPremium(
        titulo: 'Directorio de Profesionales',
        subtitulo: 'Encontrá profesionales verificados en tu zona.',
        rutaImagen: 'assets/images/home_banners/profesionales_banner.jpg',
        iconoPlaceholder: Icons.people_alt_outlined,
        colorAcento: ColoresApp.primarioVerde,
        vinetas: const['Buscá y filtrá perfiles', 'Revisa calificaciones'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedProfesionales())),
      ),
      const SizedBox(height: 16),
      const TituloSeccionConIcono(titulo: 'CONSEGUIR TRABAJO', icono: Icons.work_outline_rounded, colorTema: ColoresApp.terciarioMorado),
      TarjetaSeccionPremium(
        titulo: 'Muro de Presupuestos',
        subtitulo: 'Mira los trabajos solicitados por los clientes en tu área.',
        rutaImagen: 'assets/images/home_banners/pro_presupuesto_banner.jpg',
        iconoPlaceholder: Icons.calculate_outlined,
        colorAcento: ColoresApp.terciarioMorado,
        vinetas: const['Explora solicitudes', 'Ver oficios demandados'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedTrabajos())),
      ),
      TarjetaSeccionPremium(
        titulo: 'Turnos y Jornadas',
        subtitulo: 'Mira las ofertas de empleos eventuales y turnos fijos.',
        rutaImagen: 'assets/images/home_banners/pro_jornada_banner.jpg',
        iconoPlaceholder: Icons.monetization_on_outlined,
        colorAcento: ColoresApp.terciarioMorado,
        vinetas: const['Turnos por hora', 'Analizar sueldos'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedJornadas())),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColoresApp.infoAzul.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColoresApp.infoAzul.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, color: ColoresApp.infoAzul, size: 40),
            const SizedBox(height: 12),
            const Text('¿Listo para empezar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Regístrate gratis para publicar ofertas, enviar presupuestos o contratar servicios.', textAlign: TextAlign.center, style: TextStyle(color: tema.textTheme.bodyMedium?.color, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresApp.infoAzul,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 45)
              ),
              child: const Text('Crear mi cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      const SizedBox(height: 40),
    ];
  }

  List<Widget> _buildVistaCliente(BuildContext context, ThemeData tema) {
    return[
      TarjetaSeccionPremium(
        titulo: 'Servicios Directos',
        subtitulo: 'Contrata servicios con precios cerrados, sin presupuesto y con agenda inmediata.',
        rutaImagen: 'assets/images/home_banners/catalogo_banner.jpg',
        iconoPlaceholder: Icons.shopping_bag_outlined,
        colorAcento: ColoresApp.primarioVerde, 
        vinetas: const ['Precios fijos', 'Elige nivel de servicio', 'Agenda automática'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaExplorarCatalogo())),
      ),
      TarjetaSeccionPremium(
        titulo: 'Pedir un presupuesto',
        subtitulo: 'Contá qué necesitás y recibí presupuestos de profesionales.',
        rutaImagen: 'assets/images/home_banners/presupuesto_banner.jpg',
        iconoPlaceholder: Icons.campaign_rounded,
        colorAcento: ColoresApp.primarioVerde,
        vinetas: const['Publicá tu solicitud', 'Recibí ofertas', 'Elegí la mejor opción'],
        onTap: () {
          GestorSesionGlobal.requerirAuth(() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaPublicarTrabajo())));
        },
      ),
      TarjetaSeccionPremium(
        titulo: 'Publicar una jornada',
        subtitulo: 'Publicá tu jornada y elegí a las personas ideales.',
        rutaImagen: 'assets/images/home_banners/jornada_banner.jpg',
        iconoPlaceholder: Icons.event_available_rounded,
        colorAcento: ColoresApp.secundarioCyan,
        vinetas: const['Definí detalles de jornada', 'Recibí postulaciones', 'Elegí a los que necesitás'],
        onTap: () {
          GestorSesionGlobal.requerirAuth(() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaPublicarJornada())));
        },
      ),
      TarjetaSeccionPremium(
        titulo: 'Buscar profesionales',
        subtitulo: 'Encontrá profesionales verificados y pedí presupuestos directos.',
        rutaImagen: 'assets/images/home_banners/profesionales_banner.jpg',
        iconoPlaceholder: Icons.people_alt_outlined,
        colorAcento: ColoresApp.terciarioMorado,
        vinetas: const['Buscá y filtrá perfiles', 'Pedí un presupuesto', 'Elegí y coordiná'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedProfesionales())),
      ),
      const SizedBox(height: 16),
      const TituloSeccionConIcono(titulo: 'VISTAS PREVIAS DEL MERCADO', icono: Icons.travel_explore_rounded, colorTema: ColoresApp.infoAzul),
      TarjetaSeccionPremium(
        titulo: 'Muro de Presupuestos',
        subtitulo: 'Mira cómo piden otros clientes, inspírate y encuentra tu propia publicación.',
        rutaImagen: 'assets/images/home_banners/muro_presupuesto_banner.jpg',
        iconoPlaceholder: Icons.dynamic_feed_rounded,
        colorAcento: ColoresApp.infoAzul,
        vinetas: const ['Explora solicitudes activas', 'Compara precios'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedTrabajos())),
      ),
      TarjetaSeccionPremium(
        titulo: 'Muro de Jornadas',
        subtitulo: 'Mira las ofertas de turnos que otros están publicando en tu zona.',
        rutaImagen: 'assets/images/home_banners/muro_jornada_banner.jpg',
        iconoPlaceholder: Icons.list_alt_rounded,
        colorAcento: ColoresApp.infoAzul,
        vinetas: const ['Ver turnos disponibles', 'Analizar sueldos'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedJornadas())),
      ),
    ];
  }

  List<Widget> _buildVistaProfesional(BuildContext context, ThemeData tema) {
    return[
      TarjetaSeccionPremium(
        titulo: 'Ofrecer Paquetes',
        subtitulo: 'Crea paquetes de servicio con niveles (Básico, Premium) y agenda fija.',
        rutaImagen: 'assets/images/home_banners/pro_catalogo_banner.jpg',
        iconoPlaceholder: Icons.storefront_rounded,
        colorAcento: ColoresApp.terciarioMorado,
        vinetas: const ['Define tu propio precio', 'Vende directo sin negociar', 'Controla tu agenda'],
        onTap: () {
          GestorSesionGlobal.requerirAuth(() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaMisServiciosPro())));
        },
      ),
      TarjetaSeccionPremium(
        titulo: 'Trabajos a Presupuestar',
        subtitulo: 'Envía tu mejor cotización a clientes.',
        rutaImagen: 'assets/images/home_banners/pro_presupuesto_banner.jpg',
        iconoPlaceholder: Icons.calculate_outlined,
        colorAcento: ColoresApp.terciarioMorado,
        vinetas: const['Explora trabajos locales', 'Envía tu oferta', 'Gana el contrato'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedTrabajos())),
      ),
      TarjetaSeccionPremium(
        titulo: 'Turnos y Empleos Fijos',
        subtitulo: 'Postúlate a jornadas con sueldo fijo.',
        rutaImagen: 'assets/images/home_banners/pro_jornada_banner.jpg',
        iconoPlaceholder: Icons.monetization_on_outlined,
        colorAcento: ColoresApp.terciarioMorado,
        vinetas: const['Turnos por hora', 'Sueldos garantizados', 'Aceptación rápida'],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFeedJornadas())),
      ),
      const SizedBox(height: 16),
      const BannerRangoProfesional(),
    ];
  }
}