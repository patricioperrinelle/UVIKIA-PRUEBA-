<!-- reglas_base.md -->
🚨 CONTEXTO MAESTRO: ARQUITECTURA GRANULAR Y SISTEMA DE DISEÑO SOBRE LA
APLICACIÓN Y SU DISEÑO: Estamos trabajando en una plataforma móvil premium de
contratación de oficios y servicios eventuales (Multi-Hire y 1-a-1). La app
posee un diseño Minimalista, Serio y Premium, con soporte absoluto para Modo
Claro y Oscuro. Estilo Visual: Interfaz limpia (Flat UI), estructurada en
tarjetas con bordes sutiles (sin sombras pesadas), amplio espacio en blanco
(padding generoso) y tipografía de alto contraste con jerarquía clara. Sistema
Dual de Colores: Usa un enrutamiento visual estricto. Morado es el color de
acento para el Profesional/Trabajador. Verde es el color de acento para el
Cliente/Contratante. Se usan fondos pastel suaves para etiquetas de estado (Ej:
verde agua para "Finalizada") y colores semánticos puros para métricas (Verde =
positivo, Rojo = negativo). Funcionalidad: Posee Sockets en tiempo real,
validaciones presenciales criptográficas (PINs), seguimiento GPS, persistencia
Offline-First (SWR) y un motor de almacenamiento en la nube de gasto cero
(Cloudflare R2) optimizado al extremo. LA ARQUITECTURA (ESTRICTAMENTE GRANULAR):
La aplicación está construida bajo una arquitectura modular estricta dividida
en 5 pilares. Está absolutamente prohibido crear "God Objects" (Archivos
gigantes) o mezclar UI con lógica de negocio. lib/1_nucleo/: El motor invisible.
Maneja la sesión, el enrutamiento global, el caché offline (SWR), los conectores
nativos de hardware (GPS) y el puente proxy de seguridad hacia Cloudflare R2
(motores de compresión y destrucción física de archivos). lib/2_tema/:
Constantes puras. Colores, dimensiones y tipografías (Cero lógica).
lib/3_modelos/: Clases de datos puras que parsean JSON y manejan la seguridad de
nulos (Cero UI). lib/4_componentes_globales/: El "Sistema de Diseño". Botones,
inputs, tarjetas minimalistas, chips de estado, modales universales (Ej: Flujo
de Calificación) y paneles de ejecución. Son componentes 100% "tontos" (Dumb
Components) que no llaman a bases de datos. lib/5_modulos/: Dominio de negocio
(Auth, Feed, Publicaciones, Negociación, Jornadas, Chat, Actividad, Perfil).
ESTRUCTURA INTERNA DE UN MÓDULO (lib/5_modulos/.../): Toda pantalla nueva o
refactorizada debe respetar esta división: pantallas/: Son Enrutadores Ciegos.
NO calculan matemáticas, NO llaman a Supabase y NO dibujan UI compleja. Solo
inicializan controladores y ensamblan componentes. componentes/: Vistas
inyectables (Legos) específicas de ese módulo. controladores/: Máquinas de
estado. Procesan datos, manejan SWR, variables de carga (isLoading), manejan la
recolección de basura temporal y deciden el flujo. No saben qué es un Widget.
servicios/: Únicos archivos autorizados a hablar con Supabase (SQL/Network).
──────────────────────────── ⚠️ REGLAS DE DESARROLLO OBLIGATORIAS
──────────────────────────── REUTILIZACIÓN EXTREMA: Antes de crear
un botón, tarjeta, o loader, DEBES buscar en lib/4_componentes_globales/ o
lib/2_tema/. COMPONENTE NUEVO: Si una UI no existe, no la incrustes en la
pantalla. Créala como un "ladrillo" en la carpeta componentes/ correspondiente.
CERO LÓGICA EN LA UI: Las pantallas solo reciben variables pre-calculadas (Ej:
controlador.fechaFormateada). Toda transformación va en el controlador. UX
INTACTA: Debes preservar estrictamente el SafeArea (iOS), bordes redondeados
suaves (Squircle), el diseño plano minimalista y el sistema dual de colores
Morado/Verde según el rol. PROTECCIÓN DE INVITADOS (AUTH GUARD): Todo método de
mutación (guardar, comprar, postularse, favoritos) debe estar estrictamente
envuelto en la primera línea por GestorSesionGlobal.requerirAuth() para repeler
invitados. POLÍTICA ESTRICTA OFFLINE-FIRST Y MANEJO DE CACHÉ (SWR GENUINO V3.2):
Toda pantalla o controlador nuevo que consuma datos de red DEBE ser
indestructible ante la falta de internet, evitando pantallas rojas, loaders
infinitos y borrados accidentales: MICRO-CACHÉ LOCAL OBLIGATORIO: Los
controladores deben implementar _cargarCacheSWR() (leyendo de SharedPreferences)
y ejecutarse en la inicialización para dibujar la UI en 0ms con el último estado
conocido. Luego se dispara el fetch en silencio. Si el fetch triunfa, se invoca
_guardarCacheSWR(). BLINDAJE ANTI-LOADER (Finally): Las variables de carga (Ej:
isLoading = false) DEBEN apagarse obligatoriamente dentro del bloque finally {
... } de las peticiones de red. Si el internet falla y cae en el catch, el
bloque finally garantiza que la UI se destrabe y sobreviva con los datos de
caché. BARRERA ANTI-DESTRUCCIÓN (Falsos Positivos): NUNCA se debe sobreescribir
la RAM o la caché en disco con arrays vacíos ([]) si la petición a Supabase
falló o retornó vacío por un micro-corte. Se debe validar matemáticamente el
estado para conservar la memoria previa. PREVENCIÓN DE RACE CONDITIONS
(Sincronía UI): Al inicializar datos SWR rápidos (0ms), no emitir eventos
asíncronos inmediatos que requieran que la UI esté lista (como abrir chats o
modales). Se debe usar un Future.delayed(150ms) para darle tiempo a Flutter de
conectar los Listeners de la pantalla. MEMORIA ESTÁTICA PARA VISTAS VOLÁTILES:
Módulos dinámicos de alto montaje/desmontaje (Ej: El Chat) deben usar
colecciones static final (Ej: _memoriaChats) para que la RAM sobreviva al flujo
natural de navegación (pop/push) sin destruirse o parpadear. POLÍTICA ESTRICTA
DE ALMACENAMIENTO Y RED (EL ECOSISTEMA R2): Para mantener los costos de servidor
controlados y evitar fugas de memoria o ancho de banda, la aplicación implementa
una arquitectura defensiva obligatoria para todo archivo multimedia: LECTURAS
(Caché Visual Absoluta): Está terminantemente prohibido usar Image.network en
cualquier parte de la app. Todo componente que dibuje una imagen proveniente de
internet DEBE usar CachedNetworkImage o CachedNetworkImageProvider para
almacenar la foto en el disco local y evitar agotar las operaciones de lectura
del CDN. SUBIDAS (Compresión Agresiva Local): Nunca se suben bytes crudos a la
red. Cualquier flujo que requiera subir fotos DEBE delegar la acción a
SupabaseService.uploadImage (ubicado en el núcleo), el cual actúa como proxy
para triturar la imagen convirtiéndola a .webp de baja resolución móvil.
BORRADOS Y REEMPLAZOS (Cero Basura / Hard Deletes): Si un controlador permite al
usuario borrar un registro completo, eliminar fotos, o reemplazar un avatar,
DEBE almacenar las URLs viejas en una bolsa temporal en RAM (ej:
urlsAEliminarDeR2). Estrictamente DESPUÉS de que el UPDATE o DELETE en
PostgreSQL sea confirmado como exitoso, el controlador debe iterar sobre la
bolsa y llamar a SupabaseService.deleteImage(url) para ejecutar la destrucción
física y atómica en el bucket de R2. POLÍTICA ESTRICTA DE TIEMPO REAL
(ARQUITECTURA V3.2): Se prohíbe el uso de "Timer.periodic" (Polling ciego) para
sincronización. Toda pantalla o controlador en tiempo real DEBE implementar el
patrón "Event-Driven + Failover Watchdog": Anti-Ghosting (1 Pantalla = 1 Canal):
El dispose() debe ejecutar estrictamente "await channel.unsubscribe();" seguido
de "await supabase.removeChannel(channel);". Watchdog Inteligente: Se usa un
Timer de 120s que se DESTRUYE y REINICIA A CERO con cada evento recibido del
Socket. Solo si el Socket falla y el Timer llega a 0, se hace un fetch SQL.
Deduplicación y RAM Patching: Todo evento de Socket debe pasar por un Timer de
Debounce (500ms) para evitar tormentas SQL, priorizando actualizar la memoria
RAM local. AppLifecycleState: El controlador DEBE observar el ciclo de vida. Si
la app pasa a background, el Watchdog y los canales pesados se destruyen
temporalmente para ahorrar batería, y se reconectan silenciosamente en resume.
Realtime SQL: El Realtime solo está habilitado para "pujas", "trabajos" y
"mensajes"; el resto depende estrictamente de SWR/Caché.
──────────────────────────── ⚙️

# REGLAS DE AISLAMIENTO ARQUITECTÓNICO (OBLIGATORIAS)

La arquitectura de esta aplicación está basada en módulos independientes.

Los tres módulos principales son:

* Jornadas
* Catálogo
* Oficios/Servicios

Estos módulos deben permanecer desacoplados de forma permanente.

## Principio fundamental

Toda modificación debe quedar contenida dentro del módulo sobre el que se está trabajando.

El objetivo es que cualquier cambio realizado hoy continúe estando aislado dentro de ese módulo incluso meses después, cuando se desarrollen nuevas funcionalidades.

Modificar un módulo nunca debe obligar a modificar otro módulo.

---

## Reglas obligatorias

### 1. Prohibido crear dependencias cruzadas

Nunca debes hacer que un módulo importe:

* controladores
* servicios
* providers
* repositorios
* modelos
* lógica de negocio
* utilidades específicas

pertenecientes a otro módulo.

Si detectas que una solución requiere hacerlo, debes detenerte y proponer una alternativa arquitectónica.

---

### 2. Toda funcionalidad nueva debe nacer aislada

Cada nueva funcionalidad deberá implementarse dentro del módulo correspondiente.

No debe reutilizar lógica perteneciente a otro módulo únicamente para evitar escribir código.

Prefiero duplicar una pequeña cantidad de código antes que crear una dependencia que pueda producir efectos secundarios en el futuro.

---

### 3. Los componentes compartidos deben ser realmente globales

Solo pueden compartirse elementos que sean completamente independientes del negocio.

Por ejemplo:

* componentes UI reutilizables
* tarjetas de perfil
* chat
* navegación
* sistema de temas
* utilidades puras
* helpers
* clientes de infraestructura
* autenticación
* GPS
* almacenamiento
* servicios base

Estos componentes nunca deben contener lógica específica de Jornadas, Catálogo u Oficios.

---

### 4. Nunca mezclar reglas de negocio

Si una funcionalidad pertenece a Jornadas, su lógica debe permanecer exclusivamente dentro de Jornadas.

Lo mismo aplica para Catálogo y Oficios.

No se deben introducir condiciones del tipo:

* if (esCatalogo)
* if (esJornada)
* if (tipoServicio)

dentro de componentes compartidos.

Si aparece esa necesidad, significa que la responsabilidad está ubicada en el lugar incorrecto.

---

### 5. Las nuevas integraciones deben ser ramificaciones

Toda integración nueva debe diseñarse como una extensión del módulo donde nace.

Nunca debe convertirse en un punto común del que dependan los otros módulos.

Es preferible crear un adaptador o una interfaz específica antes que modificar componentes compartidos.

---

### 6. Antes de modificar un archivo compartido

Si durante una tarea detectas que necesitas modificar un archivo utilizado por más de un módulo, debes detenerte y responder:

"Este archivo es compartido por varios módulos. Modificarlo puede afectar funcionalidades fuera del alcance de la tarea."

Luego deberás indicar:

* qué módulos lo utilizan;
* por qué sería necesario modificarlo;
* si existe una alternativa que mantenga el aislamiento.

No modifiques un archivo compartido sin justificarlo explícitamente.

---

### 7. Auditoría obligatoria antes de escribir código

Antes de implementar cualquier cambio debes verificar:

* que la solución permanezca dentro del módulo correspondiente;
* que no aparezcan nuevas dependencias entre módulos;
* que no aumente el acoplamiento de la arquitectura;
* que el cambio no convierta un componente global en un componente dependiente del negocio.

---

### 8. Criterio de decisión

Si existen dos soluciones técnicamente correctas:

* una reutiliza código pero crea dependencia entre módulos;
* otra mantiene el aislamiento aunque implique crear nuevos archivos o duplicar pequeñas porciones de código;

debes elegir siempre la segunda.

La prioridad absoluta es preservar la independencia arquitectónica de Jornadas, Catálogo y Oficios a largo plazo.



ESTADO DEL PROYECTO
La aplicación ya es funcional y se encuentra en fase final de estabilización previa a producción.
No estamos desarrollando una nueva arquitectura.
No estamos realizando reescrituras.
No estamos realizando migraciones.
Toda modificación debe ser:
Mínima.
Conservadora.
Compatible hacia atrás.
Localizada.
Fácilmente reversible.
Prioridades absolutas:
No romper funcionalidades existentes.
No aumentar costos.
No aumentar consumo de memoria.
No aumentar consumo de batería.
No aumentar complejidad.
Si existen varias soluciones posibles, siempre debe elegirse la menos invasiva.
────────────────────────────
ARQUITECTURA GENERAL
La aplicación es una plataforma móvil premium de contratación de oficios y servicios eventuales.
Características principales:
Multi-Hire y 1-a-1.
Supabase Free.
Cloudflare R2 Free.
Firebase Free.
Realtime mediante sockets.
Validaciones mediante PIN.
Seguimiento GPS.
Persistencia Offline First.
Caché SWR.
Optimización extrema de consumo de recursos.
────────────────────────────
DISEÑO VISUAL
Estilo:
Minimalista.
Profesional.
Premium.
Flat UI.
Reglas:
Sin sombras pesadas.
Bordes suaves tipo squircle.
Amplio espacio en blanco.
SafeArea obligatorio.
Compatible con modo claro y oscuro.
Sistema de colores:
Morado = Profesional.
Verde = Cliente.
Estados positivos = Verde.
Estados negativos = Rojo.
Etiquetas = Fondos pastel suaves.
────────────────────────────
ARQUITECTURA MODULAR OBLIGATORIA
lib/1_nucleo
Motor interno, sesión, caché, GPS, R2, seguridad.
lib/2_tema
Colores, tamaños, tipografías y constantes.
lib/3_modelos
Modelos de datos puros.
lib/4_componentes_globales
Sistema de diseño reutilizable.
lib/5_modulos
Lógica de negocio.
Estructura obligatoria de cada módulo:
pantallas/
componentes/
controladores/
servicios/
Prohibido mezclar responsabilidades.
────────────────────────────
REUTILIZACIÓN OBLIGATORIA
Antes de crear:
Botones.
Tarjetas.
Inputs.
Modales.
Chips.
Loaders.
Debe buscarse primero una implementación existente.
No duplicar componentes.
────────────────────────────
CERO LÓGICA EN UI
Las pantallas:
No realizan consultas SQL.
No contienen lógica compleja.
No procesan datos.
No realizan cálculos.
Las pantallas solamente ensamblan componentes y controladores.
Toda transformación debe realizarse en controladores.
────────────────────────────
PROTECCIÓN DE AUTENTICACIÓN
Todo flujo que modifique información debe ejecutar obligatoriamente:
GestorSesionGlobal.requerirAuth()
antes de cualquier operación.
Aplica para:
Guardados.
Favoritos.
Postulaciones.
Compras.
Actualizaciones.
Eliminaciones.
────────────────────────────
POLÍTICA OFFLINE FIRST (SWR)
Toda pantalla con datos remotos debe:
Cargar memoria local.
Dibujar inmediatamente.
Ejecutar actualización silenciosa.
Actualizar RAM.
Actualizar caché.
Nunca mostrar loaders infinitos.
Toda variable de carga debe apagarse en finally.
Nunca destruir caché válida por errores temporales de red.
Nunca reemplazar datos existentes por listas vacías debido a fallos de conexión.
────────────────────────────
EL SWR ES SAGRADO
Nunca sustituir:
RAM.
Caché local.
SWR.
por consultas SQL directas.
Nunca eliminar memoria local para simplificar código.
Nunca reemplazar caché por refetch permanente.
────────────────────────────
POLÍTICA DE COSTOS
La aplicación opera en planes gratuitos.
Toda modificación debe mantener o reducir:
Requests SQL.
Lecturas de Storage.
Escrituras de Storage.
Consumo de red.
Consumo de RAM.
Suscripciones Realtime.
Está prohibido solucionar errores aumentando consultas.
Debe priorizarse:
RAM.
SWR.
Caché local.
Eventos Realtime existentes.
────────────────────────────
PROHIBIDO REFETCH GLOBAL
No realizar recargas completas de pantallas.
No ejecutar fetch automáticos innecesarios.
Solo se permite consultar Supabase cuando:
No exista información en memoria.
El usuario fuerce actualización.
El watchdog detecte pérdida real de sincronización.
────────────────────────────
POLÍTICA REALTIME
Prohibido usar polling.
Prohibido usar Timer.periodic para sincronización.
Modelo obligatorio:
Realtime + Watchdog.
Cada pantalla debe poseer una sola suscripción activa.
Toda suscripción debe destruirse correctamente en dispose().
No se permiten canales duplicados.
Los eventos deben actualizar primero la RAM local.
────────────────────────────
POLÍTICA DE IMÁGENES
Image.network está completamente prohibido.
Solo se permite:
CachedNetworkImage
CachedNetworkImageProvider
Toda imagen remota debe quedar cacheada localmente.
────────────────────────────
POLÍTICA R2
Toda subida debe pasar por el sistema centralizado de compresión.
Nunca subir imágenes originales.
Toda sustitución de archivos debe:
Guardar URL anterior.
Confirmar UPDATE SQL.
Ejecutar deleteImage().
Verificar eliminación.
No deben existir archivos huérfanos.
────────────────────────────
POLÍTICA DE MEMORIA
No almacenar:
Imágenes en RAM.
Historiales infinitos.
Listas sin límite.
Toda memoria temporal debe poseer estrategia de limpieza.
────────────────────────────
AUDITORÍA OBLIGATORIA
Antes de modificar cualquier archivo:
Identificar:
Pantallas afectadas.
Controladores afectados.
Servicios afectados.
Tablas Supabase afectadas.
Cachés SWR afectadas.
Canales Realtime afectados.
Recursos R2 afectados.
Nunca modificar a ciegas.
────────────────────────────
VERIFICACIÓN FINAL OBLIGATORIA
Antes de considerar una tarea terminada verificar:
✓ No aumentó requests SQL.
✓ No aumentó uso de Realtime.
✓ No aumentó RAM.
✓ No aumentó Storage.
✓ No se rompió SWR.
✓ No se rompió modo offline.
✓ No se rompió autenticación.
✓ No se generaron archivos huérfanos en R2.
✓ No se agregaron dependencias innecesarias.
✓ No se modificó la arquitectura existente.
FIN DEL CONTEXTO MAESTRO.