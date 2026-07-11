# Registro de Cambios Implementados

## [MEJORA] Rediseño de Billetera y Cálculos Seguros (Estilo Premium - Ejemplo 3)
- **Módulo**: Billetera (`pantalla_mi_billetera.dart`, `controlador_billetera.dart`)
- **Implementación**:
  - **Rediseño Visual Premium (Ejemplo 3)**: Se refactorizó la pantalla de la billetera aplicando el tercer concepto visual de la imagen, alineándola con un estilo minimalista, limpio, sin sombras pesadas y con un amplio uso de espacio en blanco.
  - **Eliminación de la Campana de Notificaciones**: Se quitó la campanita de notificaciones de la AppBar como solicitó explícitamente el usuario, centralizando las alertas únicamente en la pestaña del Home.
  - **Botón de Privacidad de Saldos (Eye Toggle)**: Se implementó un botón interactivo en la AppBar con el ícono de ojo (`Icons.visibility_outlined` / `Icons.visibility_off_outlined`) para ocultar o mostrar los montos confidenciales de la billetera con el formato discreto de `••••`.
  - **Tarjeta de Saldo Principal**: Rediseñada de un fondo morado plano con sombras a un contenedor plano adaptativo con el fondo de superficie (`Theme.of(context).colorScheme.surface`), borde fino, ícono de billetera encuadrado, y un chevron que indica interactividad.
  - **Fila de Métricas "En Proceso" y "Por Cobrar"**: Se añadió una sección horizontal con división central debajo del saldo principal, mostrando de forma elegante los totales que se encuentran en tránsito.
  - **Sección de Estado General**: Incorporación de un indicador visual lineal (barra de progreso) sutil con colores neutros de alto contraste para mostrar el ratio mensual de Ingresos vs. Egresos de forma dinámica y calculada a partir del Ledger real.
  - **Gestión de Cuentas Bancarias Vertical**: Se rediseñó el listado de cuentas bancarias para mostrarse en formato vertical a ancho completo con un ícono del banco en un fondo circular celeste claro, información de Alias/CBU estructurada, un tag visual estilizado de "Principal" para la primera cuenta de la lista, y un chevron intermitente.
  - **Eliminación Segura de Cuentas Bancarias**: Se integró soporte para pulsación larga (`onLongPress`) sobre cualquier cuenta bancaria que dispara de forma segura el componente `DialogoConfirmacionEstandar`, previniendo toques accidentales y permitiendo desvincular la cuenta con transiciones seguras.
  - **Cálculos Financieros Robustos y Dinámicos**:
    - Se agregaron getters matemáticos en `ControladorBilletera` que parsean el historial completo del Ledger para calcular en tiempo real los egresos e ingresos del mes en curso, montos pendientes y la proporción mensual exacta de forma 100% real y sin datos simulados.

---

## [MEJORA] Diseño y confirmación en botones de Pausa/Reanudación de Servicios
- **Módulo**: Servicios Catálogo (`tarjeta_servicio_catalogo.dart`, `pantalla_mis_servicios_pro.dart`)
- **Implementación**:
  - Se rediseñó el botón de "Pausar" y "Reanudar" (Activar) en la tarjeta de servicio, haciéndolo rectangular con esquinas levemente redondeadas, incluyendo el texto descriptivo junto al ícono.
  - Se reubicaron los botones de pausa/activación debajo del botón de eliminar (basurero) para mejorar la ergonomía.
  - Se agregó un diálogo de confirmación idéntico al de pausa cuando el profesional intenta "Activar" un servicio previamente pausado, previniendo toques accidentales y brindando mayor control.

---

## [NUEVO] Funcionalidad para Pausar/Reanudar Servicios
- **Módulo**: Servicios Catálogo (`controlador_mis_servicios_pro.dart`, `pantalla_mis_servicios_pro.dart`, `tarjeta_servicio_catalogo.dart`, `servicio_gestion_catalogo_supabase.dart`)
- **Implementación**:
  - Se agregó la opción para que los profesionales puedan **Pausar** un servicio publicado y luego **Reanudarlo** cuando lo deseen, sin necesidad de eliminarlo de la base de datos.
  - El estado del servicio se actualiza en la base de datos a `estado = 'pausado'` y `activo = false`. Las reservas y ventas ya realizadas sobre este servicio no se ven afectadas y continúan vigentes.
  - Se añadió una tercera pestaña "Pausados" en la vista de "Mis Servicios" del perfil profesional para que puedan ver los servicios que no están activos en el feed pero que mantienen sus datos.
  - La UI de la tarjeta muestra un botón naranja de "Pausar" cuando está publicado, un botón verde de "Reanudar" cuando está pausado, y un tag de estado "PAUSADO" visible.
  - **SQL**: Al utilizar las columnas existentes (`estado` y `activo`), no fue necesario crear tablas nuevas. La función `obtener_feed_servicios_v5` deberá omitir los registros donde `activo = false` o `estado = 'pausado'` (como ya lo hacía con los borrados/eliminados).

---

## [NUEVO] Calendario mensual visual en sección Contratos y Mi Agenda
- **Módulo**: Actividad Alertas (`pantalla_actividad_tabs.dart`, `calendario_mensual.dart`)
- **Implementación**: 
  - Se creó un nuevo componente reutilizable `CalendarioMensual` que replica el diseño pixel-perfect proporcionado.
  - El componente permite navegar entre meses, volver a la fecha actual y seleccionar fechas específicas.
  - Se ajustó el estilo según los requerimientos: el día de hoy se resalta con una delicada línea verde inferior, y los días con eventos muestran un círculo de color verde sólido rodeando el número de día.
  - Se modificó la extracción de fechas para usar `fechaHora` (la fecha en que se realizará el servicio/jornada) en lugar de `fechaCreacion`, asegurando que el calendario refleje con precisión la ocupación de la agenda del usuario.
  - Se agregó el título delicado "Agenda programada para los días..." en la parte superior izquierda del calendario.
  - **Identidad Visual del Profesional**: Se agregó la propiedad `colorAcento` al `CalendarioMensual`, permitiendo que la vista "Mi Agenda" del lado del profesional utilice su color característico (`ColoresApp.terciarioMorado`), manteniendo la coherencia de identidad en la UI de cada rol.
  - Se integró el calendario en la parte superior de la `ListView` de la `PantallaActividadTabs`, visible tanto para el cliente (Contratos) como para el profesional (Mi Agenda).
  - **Corrección de Estado de Reserva**: Se agregó el estado inicial `asignado` a los filtros de lectura de Base de Datos para el perfil Profesional, solucionando un bug crítico donde las nuevas reservas directas compradas por el cliente no aparecían en el panel de Mi Agenda del Pro.
- **Data Integrity**: La interfaz es "tonta" (UI sin lógica compleja). Las fechas se extraen pasivamente de los objetos ya cargados mediante la función `_obtenerFechasConEventos` y se pasan al componente visual a través de SWR y estados locales.

---

## [MEJORA] Reutilización del componente de dirección detallada en Checkout
- **Módulo**: Servicios Catálogo (`pantalla_detalle_servicio.dart`, `controlador_catalogo_cliente.dart`, `extension_catalogo_checkout.dart`)
- **Implementación**: 
  - Se reemplazó el campo de texto único para la dirección en la compra de servicios "A domicilio" por el componente estructurado `SeccionDireccionMaps`.
  - Ahora el cliente debe ingresar Calle, Número, Provincia, Localidad y demás campos de forma estructurada, unificando la experiencia con el creador de servicios del Profesional.
  - La dirección se valida y luego se concatena (Calle Número, Barrio, Localidad, Provincia) al preparar la reserva final, garantizando consistencia en el formato almacenado en la Base de Datos.

---

## [NUEVO] Botón persistente para edición rápida de servicios y mejora en botón Editar
- **Módulo**: Servicios Catálogo (`pantalla_creador_servicio.dart`)
- **Implementación**: 
  - Se cambió el ícono solitario del lápiz en el `AppBar` por un `TextButton.icon` que incluye la palabra "Editar" al lado del ícono para hacerlo más intuitivo y visible para los usuarios Pro.
  - Se agregó un `bottomNavigationBar` persistente en el Scaffold de edición que muestra un botón principal "Guardar Cambios" al activar la edición de un servicio existente.
  - Debajo del botón "Guardar Cambios", se integró un botón secundario `BotonDelineadoSecundario` con el texto "Salir sin guardar", dando a los usuarios una ruta de escape clara y reduciendo el miedo a editar.
  - Esto evita la fricción de tener que recorrer obligatoriamente los 3 pasos (Información, Planes, Vista Previa) solo para persistir o descartar un pequeño ajuste en la configuración.
  - **Corrección de Estado**: Se ajustó `Navigator.pop(context, true)` en la función de guardado exitoso para forzar la recarga del panel principal de servicios al regresar, corrigiendo el problema donde los cambios no se veían reflejados sin recargar.
- **Data Integrity**: Respeta los estados de carga y reglas de validación preexistentes en `ControladorCreadorServicio`.

---

A continuación se detallan los cambios realizados en el sistema de catálogo de servicios para habilitar el campo **"Lo que NO cubre"** y la opción de **"Sin duración"** en los planes del servicio, así como las mejoras en el procesamiento y visualización de listas en el modo de creación.

---

## 1. Cambios y Nuevas Funcionalidades

### 🚫 Campo "Lo que NO cubre" (Planes del Servicio)
*   **Modelo de Datos**: Se integró el campo `loQueNoCubre` (mapeado como `lo_que_no_cubre` en JSON) en la clase `ModeloNivelServicio`. Adicionalmente, se creó el getter `loQueNoCubreProcesado` para parsear múltiples ítems de forma dinámica.
*   **Creación y Edición del Servicio**: En el paso 2 del creador de servicios (planes y extras), se añadió una sección visual y un campo de texto cristalino (`CampoTextoCristal`) específico para configurar "Lo que NO cubre" opcionalmente, con instrucciones claras que guían al profesional.
*   **Visualización en la Tarjeta de Plan (Para el Cliente)**: Se integró en la tarjeta de selección del nivel de servicio (`SelectorNivelServicio`) la lista de ítems no cubiertos. Estos se muestran de manera destacada y clara con un icono de descarte rojo (`Icons.close_rounded`) y textos estilizados en tonos rojizos para evitar confusiones al cliente final.

### ⏱️ Planes sin Duración Estricta ("Sin duración")
*   **Selector de Duración**: Se añadió la opción **"Sin duración"** dentro de la lista de opciones disponibles en el panel modal de selección de duración del plan (Paso 2). Esto permite que aquellos servicios o planes que no requieran estimación temporal se configuren de forma adecuada.

### 📝 Soporte Inteligente de Listas (Separación por Comas o Signo "+")
*   **Procesamiento de Textos**: Se actualizaron las funciones `caracteristicasProcesadas` y `loQueNoCubreProcesado` en el modelo para normalizar la entrada del usuario. Ahora soporta indistintamente separar los elementos de la lista usando **comas (`,`)** o el signo **más (`+`)**. La aplicación remueve estos delimitadores automáticamente al presentarlos, garantizando que el usuario final visualice una lista limpia sin caracteres de puntuación residuales.
*   **Límites de Seguridad contra Abusos**: Se ha impuesto un **límite estricto de 300 caracteres** tanto para el campo de "Lo que cubre" como para "Lo que NO cubre". Esto previene que usuarios malintencionados o erróneos ingresen listas infinitas que puedan saturar la base de datos (Supabase) o colapsar la interfaz visual.
*   **Indicaciones en Pantalla**: Se modificaron las descripciones en los formularios del diálogo de edición de plan para indicarle explícitamente al profesional: *"Separa cada ítem con una coma (,) o un signo más (+) para que se enliste (máx. 300 caracteres)"*. Los hints de ejemplo también se adaptaron para usar comas (por ejemplo: *"Ej: No incluye pulido, No incluye lavado de chasis"*).

### 👁️ Vista Previa Detallada para el Creador (Enlistado Visual)
*   **Tarjeta del Plan Creado**: Se rediseñó la `TarjetaPlanCreado` en el Paso 2 de creación para mostrar de manera instantánea cómo quedarán estructurados los ítems. Ahora, al guardar los cambios, el profesional visualizará inmediatamente en forma de lista con viñetas:
    *   Los ítems que **SÍ cubre** el plan acompañados de un check de verificación.
    *   Los ítems que **NO cubre** el plan acompañados de una cruz de advertencia de color rojo.
    Esto permite al creador constatar el diseño visual exacto antes de continuar al siguiente paso.

### 🗂️ Unificación Estética del Catálogo (Tarjetas del Feed para el Pro)
*   **Diseño Unificado**: Se reemplazó la tarjeta de servicio genérica de la lista de servicios del profesional (`PantallaMisServiciosPro`) por la misma **`TarjetaServicioCatalogo`** exacta que se muestra en el feed de exploración de cara al cliente. Esto le da al profesional una vista previa 100% realista de cómo se muestra su servicio ante el público, incluyendo todas las ubicaciones, horarios, etiquetas de confianza y visualización de planes/precios.
*   **Botón de Eliminación Flotante e Integrado**: Para mantener la consistencia y limpieza absoluta, el botón de favoritos (corazón) sobre la foto se oculta en la vista del profesional. En su lugar, se añade un botón táctil flotante con un **tacho de basura de color rojo** (`Icons.delete_outline_rounded`) dentro de un círculo estilizado con sombra sutil (`Material` + `CircleBorder` + `elevation: 2`) ubicado de manera elegante, limpia y visible en el **borde derecho, centrado verticalmente** de la tarjeta (donde el espacio es claro y no hay texto), flotando perfectamente sobre el diseño para no achicar ni alterar la estructura responsive de la tarjeta.
*   **Confirmación de Eliminación**: Al presionar el tacho de basura, se añadió un cuadro de diálogo de confirmación (`AlertDialog`) con estilo minimalista para evitar eliminaciones accidentales y guiar de forma segura la eliminación en la base de datos.

---

## 2. Archivos Afectados

El desarrollo involucró modificaciones directas en la estructura de modelos, controladores de interfaz, componentes modulares y el stepper de creación en los siguientes archivos:

1.  **`/lib_editada/3_modelos/modelo_servicio_catalogo.dart`**
    *   *Modificación*: Extensión de `ModeloNivelServicio` agregando el atributo `loQueNoCubre` y los procesadores optimizados de cadenas múltiples para división dinámica por coma o signo más.
2.  **`/lib_editada/5_modulos/modulo_servicios_catalogo/controladores/controlador_creador_servicio.dart`**
    *   *Modificación*: Implementación de `planNoCubreModalController` para la recolección de la información en el formulario y actualización del método `guardarNivelDesdeUI` para persistir la propiedad de forma dinámica.
3.  **`/lib_editada/5_modulos/modulo_servicios_catalogo/componentes/creador/pasos/paso_2_planes_extras.dart`**
    *   *Modificación*: Adición de la interfaz del formulario para "Lo que NO cubre", textos de ayuda explícitos para separación por comas/signo más, la nueva opción `"Sin duración"`, e integración de los parámetros `loQueCubre` y `loQueNoCubre` en la tarjeta de plan.
4.  **`/lib_editada/5_modulos/modulo_servicios_catalogo/componentes/creador/tarjeta_plan_creado.dart`**
    *   *Modificación*: Rediseño estructural de la tarjeta para renderizar en forma de lista con viñetas estilizadas (checks verdes e iconos de descarte rojos) los beneficios y exclusiones ingresados para el plan.
5.  **`/lib_editada/5_modulos/modulo_servicios_catalogo/componentes/selector_nivel_servicio.dart`**
    *   *Modificación*: Actualización de la visualización para renderizar dinámicamente la lista roja de exclusiones asociadas al plan activo en la pantalla de cara al cliente.
6.  **`/lib_editada/5_modulos/modulo_servicios_catalogo/componentes/tarjeta_servicio_catalogo.dart`**
    *   *Modificación*: Adaptación para soportar vista profesional (`esVistaPro` y `onTapEliminar`), reemplazando interactivamente el botón favorito por el tacho de basura en la esquina superior derecha de la imagen de portada.
7.  **`/lib_editada/5_modulos/modulo_servicios_catalogo/pantallas/pantalla_mis_servicios_pro.dart`**
    *   *Modificación*: Reemplazo de las tarjetas de servicios genéricos por la `TarjetaServicioCatalogo` con acciones personalizadas y cuadro de diálogo emergente de confirmación de borrado.

---

## 3. Rediseño de Selección de Fecha: Calendario Mensual Premium (Lado Cliente)

*   **Calendario Mensual**: Se reemplazó la antigua lista horizontal desplazable de días por un calendario mensual premium en vista completa, limpio, minimalista, estilo Flat UI, sin sombras pesadas y con amplio espacio en blanco, respetando la estética y filosofía de diseño de la aplicación.
*   **Color de Acento**: Se utiliza el **Verde Semántico** (`ColoresApp.primarioVerde` / `Color(0xFF00C853)`) de forma estricta para el día seleccionado en la reserva del cliente, logrando consistencia visual con el rol del contratante.
*   **Puntos de Disponibilidad**: Se renderiza un pequeño punto verde debajo de los números de los días hábiles y laborales habilitados para el servicio (`diasLaborales.contains(dia.weekday)`), sirviendo como indicador discreto pero claro de disponibilidad en 0ms.
*   **Navegación e Interactividad**: Permite interactuar libremente mediante flechas de navegación para consultar meses pasados o futuros, garantizando el bloqueo de fechas previas al día de hoy para proteger la integridad lógica del sistema.
*   **Aislamiento Arquitectónico**: Este rediseño fue localizado exclusivamente dentro de la interfaz del cliente, manteniendo intacta la grilla de selección de slots de hora debajo del calendario y sin alterar de ninguna manera la configuración de disponibilidad del profesional.

### Archivos Afectados

1.  **`/lib_editada/5_modulos/modulo_servicios_catalogo/componentes/selector_fecha_hora_inteligente.dart`**
    *   *Modificación*: Refactorización completa del widget `SelectorFechaHoraInteligente` de un `StatelessWidget` plano a un `StatefulWidget` interactivo que mantiene el mes actual en visualización, calcula la matriz de la grilla de días alineados al día de la semana inicial, y delega la selección de regreso al controlador principal en un flujo puramente asíncrono y desacoplado.

---

## [MEJORA] Revisión Profunda y Fortalecimiento del Sistema de Notificaciones Push
- **Módulos**: Núcleo / Seguridad / Notificaciones (`arranque_app.dart`, `enviar_push/index.ts`, `config.toml`)
- **Implementación**:
  - **FCM v1 en Edge Function**: Se optimizó la función `enviar_push` en Supabase para soportar tanto payloads con la fila anidada (`payload.record` de Webhooks nativos) como cargas planas directas.
  - **Seguridad y Clave Privada**: Se añadió normalización automática de la clave de servicio (`FIREBASE_SERVICE_ACCOUNT`) reemplazando los caracteres literales `\n` por saltos de línea reales para evitar fallas en la firma del token de acceso de Google.
  - **Configuración de Prioridad y Sonido**: Se actualizó el payload para activar alta prioridad (`priority: "HIGH"` en Android y `"apns-priority": "10"` en iOS), se asoció al canal de alta importancia `"high_importance_channel"`, y se habilitaron los sonidos nativos en ambas plataformas.
  - **Exclusión de JWT para Webhooks**: Se configuró `verify_jwt = false` para la Edge Function en `config.toml`, permitiendo que los disparadores/webhooks desde la base de datos PostgreSQL realicen llamadas HTTP directas sin ser interceptados por el validador del router de Supabase.
  - **Listeners y Enrutamiento en Flutter**:
    - Se implementó `FirebaseMessaging.onMessage` para escuchar mensajes en primer plano (Foreground), que ahora recarga la bandeja de notificaciones en tiempo real y muestra un hermoso SnackBar flotante con diseño morado/neón con botón interactivo "VER".
    - Se agregaron los controladores de gestos `onMessageOpenedApp` y `getInitialMessage` para asegurar que el dispositivo reaccione adecuadamente abriendo la app y enrutando con transiciones fluidas hacia el detalle de la orden/trabajo cuando el usuario presiona la notificación en su bandeja.
  - **Guía de Configuración Android/iOS**: Se documentaron los pasos detallados para configurar el archivo de manifiesto Android (`AndroidManifest.xml`) y registrar el canal de alta importancia en la plataforma nativa.
  
---

## [CORRECCIÓN] Restauración del contrato FuenteDeActividad y nombre de método global
- **Módulos**: Núcleo, Alertas, Jornadas, Catálogo, Oficios
- **Implementación**:
  - **Reversión de renombrado**: Se restauró el nombre del método `recargarSilenciosoGlobal()` en la interfaz `FuenteDeActividad` y en todas sus implementaciones (`ControladorActividadJornadas`, `ControladorActividadCatalogo`, `ControladorActividadOficios`).
  - **Resolución de errores en cascada**: Al devolverle el nombre original al método, se solucionaron los errores de compilación masivos en los módulos dependientes y extensiones (`extension_jornadas_postulaciones`, `extension_negociacion_ejecucion`, etc.) que todavía intentaban llamar a `recargarSilenciosoGlobal()`.
  - **Arranque de App y Background**: Se actualizó el bucle en `arranque_app.dart` para iterar sobre `RegistroFuentesActividad.fuentes` e invocar el nombre correcto `fuente.recargarSilenciosoGlobal()`.
  
---

## [UI & UX] Refinamiento de Interfaz de Calendario y Acordeones Mutuamente Excluyentes
- **Módulo**: Actividad Alertas (`calendario_mensual.dart`, `pantalla_actividad_tabs.dart`, `acordeon_categoria_historial.dart`)
- **Implementación**:
  - **Limpieza Visual y Cabecera**: Se eliminó la flecha del mes. El mes activo volvió a estar centrado con sus controles de navegación (`<` y `>`).
  - **Fecha de Hoy Tipográfica**: Se movió el día actual (ej: "Lunes 1", sin coma) hacia el lado izquierdo de la cabecera del calendario. Se invirtieron las jerarquías de tamaño (ahora el mes es más grande y el día más pequeño, ambos en negrita).
  - **Destacado de Día Semanal**: Se agregó un rectángulo de color sutil detrás del día de la semana actual (ej: LUN, MAR) en la grilla de días.
  - **Forma de Selección de Fechas**: Se cambió la forma base del indicador de selección de fechas en el grid (de círculo a un cuadrado con bordes ligeramente redondeados).
  - **Acordeones Mutuamente Excluyentes**: Se implementó una lógica de estado global en la vista de Agenda (`_acordeonAbierto`) para garantizar que solo un contenedor o categoría pueda estar abierta al mismo tiempo. Al abrir uno, los demás se cierran automáticamente.
  - **Vinculación Calendario-Acordeones**: Al tocar un día resaltado en el calendario (que indica un turno o evento), la UI identifica automáticamente a qué categoría pertenece ese trabajo activo y despliega el acordeón correspondiente, cerrando cualquier otro que estuviera abierto.
  - **Ciclo de Contenedores por Día**: Se agregó una lógica inteligente de ciclado al calendario. Si un mismo día contiene turnos en múltiples módulos (ej. Servicios y Oficios), tocar el día por primera vez abrirá el primer contenedor. Volver a tocar el mismo día cerrará el actual y abrirá el siguiente contenedor que tenga turnos.
  - **Ordenamiento Cronológico Inteligente**: Los turnos listados dentro de cada acordeón ahora se muestran ordenados temporalmente. Para la agenda (trabajos activos) se aplica un orden cronológico ascendente (los eventos más próximos arriba) evaluando no solo el día sino también el horario (ej: turno 10:00 AM antes que turno 4:00 PM). Para el historial y cancelados se emplea orden descendente (lo más reciente primero).
  - **Reset Automático del Calendario**: Se implementó un ciclo de vida reactivo en el tab de Agenda para detectar cuando el usuario sale y vuelve a entrar a la pantalla (usando la propiedad `isActive`). Esto reinicia automáticamente el calendario al día actual de manera limpia.
  - **Grilla de Horarios Integral**: En el momento de contratar un servicio, la grilla de selección de horarios inferior al calendario ahora muestra todas las franjas horarias que abarcan el turno del profesional. 
  - **Estado y Legibilidad de Disponibilidad**: Los horarios no disponibles (por choques, capacidad máxima o margen de tiempo superado) ahora se muestran atenuados pero visibles, con una pequeña cruz en la esquina para comunicación visual nítida. Los horarios disponibles ahora utilizan un diseño limpio con fondo blanco y delineado oscuro de alto contraste, permitiendo una distinción visual inmediata.
  - **Limpieza de Código - Horario Libre**: Se eliminó completamente la modalidad "Horario Libre" tanto de la interfaz gráfica de configuración del profesional como de las validaciones de agenda del consumidor, limpiando código no utilizado.
  - **Frecuencia de Turnos Adaptable**: Se implementó la configuración "Frecuencia de turnos" (mínimo 30 minutos) en la creación de servicios. Esto permite a los profesionales generar y ofertar bloques de horarios de forma mucho más densa (ej: cada 30 min en lugar de cada 60 min), maximizando la ocupación del día y permitiendo encajar trabajos entre los tiempos muertos de otras citas.

