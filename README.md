📌 Corral X — Resumen Ejecutivo & Modelo de Negocio
Visión

Conectar a ganaderos de Venezuela en un marketplace confiable y simple, reduciendo fricción en la compra/venta de ganado. Digitalizamos procesos para generar confianza, ampliar el alcance y acelerar las negociaciones.

Público y roles

User (único rol en el MVP): puede vender y comprar.

Admin (post-MVP): moderación y verificación manual (no prioritario ahora).

Propuesta de valor

Confianza: perfiles con reputación (ratings/comentarios) y bandera “verificado” (si aplica).

Alcance: publicar y encontrar ganado fuera de la zona geográfica habitual.

Eficiencia: fichas estandarizadas (tipo, raza, edad, cantidad, ubicación, fotos, certificado opcional) y chat 1:1 para cerrar tratos.

Flujo de negocio (MVP)

Usuario se registra/inicia sesión.

Crea publicación (listado) con datos y fotos.

Otros usuarios buscan/filtran y abren el detalle.

Interesan → contactan por chat (WebSocket en tiempo real).

El vendedor gestiona sus publicaciones y ve métricas (vistas, favoritos).

KPIs de éxito (MVP)

Usuarios registrados activos/mes.

Publicaciones activas.

Contactos iniciados (chats) y tasa de respuesta.

% publicaciones con al menos 1 conversación.

Retención a 30 días.

Monetización (post-MVP)

Comisión por transacción (cuando se integre pago/escrow).

Suscripción Premium (listados destacados, insights).

Publicidad sectorial (limitada, sin invadir la UX).

📱 README — Frontend (Flutter)

Stack: Flutter (stable), Provider para estado, HTTP/dio, flutter_secure_storage para token, web_socket_channel para chat en tiempo real. UI mobile-first.

1) Funcionalidad (MVP)

Auth: registro/login, persistir token.

Marketplace: lista + filtros + detalle, favoritos, reviews.

Publicar: crear/editar/eliminar publicaciones (con imágenes).

Perfiles: propio (editar) y público (de vendedores).

Chat: conversaciones + mensajes (WebSocket en tiempo real).

Dashboard: mis publicaciones + métricas.

2) Estructura de carpetas (Arquitectura Modular)
lib/
  main.dart
  config/                    # Configuración central
    app_config.dart         # Configuración de la app
    auth_utils.dart         # Utilidades de autenticación
    corral_x_theme.dart     # Tema de la aplicación
    user_provider.dart      # Provider de usuario global
  shared/                   # Servicios y widgets compartidos
    models/                 # Modelos compartidos
    services/               # Servicios compartidos
    widgets/                # Widgets compartidos
      amazon_widgets.dart   # Widgets estilo Amazon/Alibaba
  auth/                     # Módulo de autenticación
    models/                 # Modelos de auth
    screens/                # Pantallas de auth
      sign_in_screen.dart   # Pantalla de inicio de sesión
    services/               # Servicios de auth
      api_service.dart      # Servicio de API
      google_sign_in_service.dart # Google Sign-In
    widgets/                # Widgets de auth
  onboarding/               # Módulo de onboarding
    models/                 # Modelos de onboarding
    screens/                # Pantallas de onboarding
      onboarding_screen.dart # Pantalla principal
      onboarding_page1.dart # Datos personales
      onboarding_page2.dart # Datos comerciales
      onboarding_page3.dart # Selección de ubicación
      onboarding_page4.dart # Configuración adicional
      onboarding_page5.dart # Confirmación
      onboarding_page6.dart # Finalización
      welcome_page.dart     # Página de bienvenida
    services/               # Servicios de onboarding
      onboarding_api_service.dart # API de onboarding
    widgets/                # Widgets de onboarding
  products/                 # Módulo de productos
    models/                 # Modelos de productos
    screens/                # Pantallas de productos
      marketplace_screen.dart # Marketplace principal
      create_screen.dart     # Crear publicación
    services/               # Servicios de productos
    widgets/                # Widgets de productos
  chat/                     # Módulo de chat
    models/                 # Modelos de chat
    screens/                # Pantallas de chat
      messages_screen.dart  # Pantalla de mensajes
    services/               # Servicios de chat
    widgets/                # Widgets de chat
  favorites/                # Módulo de favoritos
    models/                 # Modelos de favoritos
    screens/                # Pantallas de favoritos
      favorites_screen.dart # Pantalla de favoritos
    services/               # Servicios de favoritos
    widgets/                # Widgets de favoritos
  profiles/                 # Módulo de perfiles
    models/                 # Modelos de perfiles
    screens/                # Pantallas de perfiles
      profile_screen.dart   # Pantalla de perfil
    services/               # Servicios de perfiles
    widgets/                # Widgets de perfiles

3) Dependencias (pubspec.yaml sugeridas)
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0        # o dio si prefieres
  provider: ^6.0.0
  flutter_secure_storage: ^9.0.0
  image_picker: ^1.0.7
  path: ^1.8.3
  intl: ^0.19.0

4) Configuración

lib/config/app_config.dart

class AppConfig {
  static const baseUrl = "https://backend.tudominio.com/api";
  static const websocketUrl = "wss://backend.tudominio.com/ws";
  static const reconnectDelaySeconds = 5; // Delay para reconexión automática
}

5) Servicios (patrón)

ApiService: adjunta Authorization: Bearer <token>, maneja JSON/errores (401→logout; 422→errores de campo).

AuthService: register, login, me, guarda token en flutter_secure_storage.

ListingService: index(filters), show(id), create(data), update(id,data), delete, uploadImages(id, files), favorite(id, on/off), reviews(id) GET/POST.

ChatService: createConversation(recipientId, listingId?), conversations(), messages(convId, sinceId), sendMessage(convId, content).

ProfileService: me(), updateMe(data), publicProfile(userId).

6) Providers (estado)

AuthProvider: isAuthenticated, currentUser, login, register, logout.

ListingProvider: listings, isLoading, filters, CRUD, favorite, loadReviews/addReview.

ChatProvider: conversations, messagesByConv, openConversation, loadMessages, sendMessage, startPolling/stopPolling.

ProfileProvider: me, updateMe, publicProfile.

7) Pantallas y UX

Marketplace: búsqueda + chips de filtros; ListingCard con foto, tipo/raza, ubicación, favorito. Pull-to-refresh.

Detalle: carrusel de imágenes, descripción, datos del vendedor (nombre, rating, verificado), botón Contactar → abre/crea conversación y navega a Chat. Si es del dueño → botones Editar/Eliminar. Reviews listadas al final.

Formulario de publicación: validaciones locales (campos obligatorios), grid de imágenes (máx 5), submit deshabilitado al enviar. Manejo de 422 con mensajes bajo cada campo.

Perfiles:

Mi perfil: editar nombre, teléfono, bio, ubicación; ver Mis publicaciones y métricas.

Público: ver perfil del vendedor y sus listados; botón Contactar.

Chats:

Lista de conversaciones (badge no leídos).

ChatScreen: ListView de burbujas; al abrir, conectar WebSocket para la conversación específica. Manejar estados de conexión (conectado/desconectado/reconectando) con indicadores visuales. Reconexión automática en caso de pérdida de conexión.

8) Manejo de errores

401: redirigir a login y limpiar token.

422: mostrar mensajes por campo (form).

500/otros: SnackBar “Ocurrió un error, inténtalo más tarde”.

Estados loading/empty/error en todas las vistas críticas.

9) Seguridad

Token en flutter_secure_storage.

No loggear token/PII.

Cerrar sesión borra token/estado.

10) Arquitectura Modular

La aplicación utiliza una arquitectura modular por features que facilita:
- Escalabilidad: cada módulo es independiente
- Mantenibilidad: código organizado por funcionalidad
- Colaboración: múltiples desarrolladores pueden trabajar en paralelo
- Testing: estructura clara para pruebas unitarias y de integración

Cada módulo contiene:
- models/: Modelos de datos específicos del módulo
- screens/: Pantallas de la UI del módulo
- services/: Lógica de negocio y comunicación con API
- widgets/: Componentes reutilizables del módulo

Configuración centralizada en config/:
- app_config.dart: URLs de API, configuración WebSocket
- auth_utils.dart: Utilidades de autenticación
- corral_x_theme.dart: Tema y estilos de la aplicación
- user_provider.dart: Estado global del usuario

11) Build y ejecución
flutter pub get
flutter run -d 192.168.27.5:5555   # Dispositivo Android específico
# Producción
flutter build apk --release         # Android
flutter build ios --release         # iOS (requiere Xcode)
flutter build web --release         # Web (si aplica)

12) Pruebas (sugeridas)

Unit: parsing de modelos (fromJson/toJson), servicios con mocks de HTTP.

Widget: formularios (validaciones), lista de marketplace (estados loading/empty/error), chat (append de mensajes).

Integración manual con Postman: validar flujos end-to-end (login → crear listing → ver → chatear).

13) Parámetros y convenciones clave

Fechas: ISO 8601 desde backend; formatear con intl.

Imágenes: comprimir/redimensionar client-side si es posible; limitar a 5.

Paginación: usar page en /listings; infinito o botones.

Polling: 10–15s en Chat; pausar fuera de ChatScreen.

14) Roadmap UI (post-MVP)

Estados “Destacado”, banners de promoción.

Notificaciones push.

Modo sin conexión (borradores).

Analítica de búsquedas y conversión.

🔚 Notas finales

Alineación back/front: nombres de campos y rutas ya coinciden; cualquier cambio de contrato debe reflejarse en ambos README.

Hosting compartido: implementa WebSockets para chat en tiempo real. Optimiza imágenes y cachea config/rutas/vistas.

Criterios de “Hecho” (DoD): endpoints funcionales, validaciones y policies aplicadas, pruebas básicas verdes, deploy en hosting compartido, flujos principales verificados (crear listing, buscar, ver, chatear).

14) Especificación de UI del Demo (HTML)

Navegación inferior (Bottom Nav):
- Mercado (`store`), Favoritos (`favorite`), Publicar (`add_circle`), Mensajes (`chat` con badge de no leídos), Perfil (`account_circle`).

Vistas principales (IDs de vista):
- `marketplace`: búsqueda, filtros por tipo (`all|lechero|engorde|padrote`), filtro por ubicación, sección Destacadas y lista de recientes.
- `detail`: detalle de publicación con carrusel/miniaturas, favorito, reporte, registro del animal (con/sin certificado), info de vendedor verificado, acciones de editar/eliminar si es dueño, comentarios y calificaciones (1–5).
- `create`: formulario de publicación con hasta 5 fotos (primera = portada), registro (obliga certificado si aplica), tipo/raza/edad/cantidad/ubicación/descr., toggle Destacado.
- `profile`/`editProfile`: perfil propio o público con avatar, nombre comercial, datos de contacto, ubicación, bio, rating, verificado, fecha de alta; edición con cambio de foto y datos.
- `favorites`: rejilla con publicaciones marcadas por el usuario.
- `dashboard` y `myListings`: panel del vendedor con métricas (total publicaciones, vistas, favoritos) y gestión de publicaciones.
- `messages` y `chat`: lista de conversaciones (último mensaje), vista de chat 1:1 con input y envío; al abrir `messages` se limpian no leídos.
- `marketPulse`: analítica resumida del mercado (mock) a partir de publicaciones.
- Admin (`adminDashboard`, `adminListings`, `adminUsers`, `adminActivity`, `adminUserSupport`, `adminReports`): vistas para métricas, usuarios, actividad y reportes (mock en demo).

Componentes y comportamientos:
- Card de publicación: imagen principal, favorito con animación, vendedor con insignia verificado, CTA “Ver Detalles”.
- Favoritos: botón con estado persistente en usuario; animación “pop”.
- Comentarios: selección de estrellas con hover/filled; recalcula rating promedio del vendedor según comentarios acumulados.
- Reportes: modal con motivos predefinidos, registra evento de actividad.
- Certificado: modal de imagen con bloqueo de scroll y cierre por overlay o botón.
- Carga de imágenes: límite 5, previews con eliminar; oculta caja de subida al alcanzar límite.
- Filtros: búsqueda por raza/tipo/ubicación, chips de tipo con estado activo, select de ubicación.
- Mensajes: badge de no leídos en nav; al entrar en `messages` se marcan como leídos.

Estilos y diseño:
- Tokens Material Design (variables CSS) para colores; TailwindCSS para layout/responsivo.
- Contenedores surface para tarjetas y secciones.

Notas de integración Frontend Flutter:
- Mapear estas vistas a pantallas Flutter equivalentes (Marketplace, Detalle, Formulario, Perfil, Favoritos, Chats, Dashboard, Admin opcional).
- Reutilizar los nombres de acciones/estados (favoritos, verificado, reportes) y comportamientos (límite de imágenes, validación de certificado, limpieza de no leídos) en Providers/Services.
- Para MVP, los módulos Admin pueden quedar detrás de flag/rol.

## 🎨 Paleta de Colores - Sistema de Diseño

### Modo Claro (Light Theme)
```css
:root {
    --md-sys-color-primary: #386A20;                    /* Verde principal */
    --md-sys-color-on-primary: #FFFFFF;                 /* Blanco sobre verde */
    --md-sys-color-primary-container: #B7F399;          /* Verde claro contenedor */
    --md-sys-color-on-primary-container: #082100;       /* Verde oscuro sobre contenedor */
    --md-sys-color-secondary: #55624C;                  /* Verde secundario */
    --md-sys-color-on-secondary: #FFFFFF;               /* Blanco sobre secundario */
    --md-sys-color-secondary-container: #D9E7CA;        /* Verde claro secundario */
    --md-sys-color-on-secondary-container: #131F0D;     /* Verde oscuro sobre secundario */
    --md-sys-color-error: #BA1A1A;                      /* Rojo de error */
    --md-sys-color-on-error: #FFFFFF;                   /* Blanco sobre error */
    --md-sys-color-background: #FCFDF7;                 /* Fondo principal (crema) */
    --md-sys-color-on-background: #1A1C18;              /* Texto sobre fondo */
    --md-sys-color-surface: #FCFDF7;                    /* Superficie principal */
    --md-sys-color-on-surface: #1A1C18;                 /* Texto sobre superficie */
    --md-sys-color-surface-variant: #E0E4D7;            /* Variante de superficie */
    --md-sys-color-on-surface-variant: #43483E;         /* Texto sobre variante */
    --md-sys-color-outline: #74796D;                    /* Color de borde/outline */
    --md-sys-color-surface-container-high: #E9E9E2;     /* Contenedor alto */
    --md-sys-color-surface-container-low: #F4F4ED;      /* Contenedor bajo */
}
```

### Modo Oscuro (Dark Theme)
```css
.dark-theme {
    --md-sys-color-primary: #9CDA7F;                    /* Verde claro principal */
    --md-sys-color-on-primary: #082100;                 /* Verde oscuro sobre principal */
    --md-sys-color-primary-container: #1F3314;          /* Verde oscuro contenedor */
    --md-sys-color-on-primary-container: #B7F399;       /* Verde claro sobre contenedor */
    --md-sys-color-secondary: #BCCAB0;                  /* Verde claro secundario */
    --md-sys-color-on-secondary: #263420;               /* Verde oscuro sobre secundario */
    --md-sys-color-secondary-container: #3A4A2F;        /* Verde medio contenedor */
    --md-sys-color-on-secondary-container: #D9E7CA;     /* Verde claro sobre contenedor */
    --md-sys-color-error: #FFB4AB;                      /* Rojo claro de error */
    --md-sys-color-on-error: #690005;                   /* Rojo oscuro sobre error */
    --md-sys-color-background: #1A1C18;                 /* Fondo principal (negro verdoso) */
    --md-sys-color-on-background: #E0E4D7;              /* Texto claro sobre fondo */
    --md-sys-color-surface: #2B2D28;                    /* Superficie principal */
    --md-sys-color-on-surface: #E0E4D7;                 /* Texto claro sobre superficie */
    --md-sys-color-surface-variant: #43483E;            /* Variante de superficie */
    --md-sys-color-on-surface-variant: #C4C8BB;         /* Texto sobre variante */
    --md-sys-color-outline: #8E9388;                    /* Color de borde/outline */
    --md-sys-color-surface-container-high: #2F312C;     /* Contenedor alto */
    --md-sys-color-surface-container-low: #1F211C;      /* Contenedor bajo */
}
```

### Uso en CSS
```css
/* Ejemplo de uso */
.my-component {
    background-color: var(--md-sys-color-surface);
    color: var(--md-sys-color-on-surface);
    border: 1px solid var(--md-sys-color-outline);
}

.my-button {
    background-color: var(--md-sys-color-primary);
    color: var(--md-sys-color-on-primary);
}

.my-button:hover {
    background-color: var(--md-sys-color-primary-container);
    color: var(--md-sys-color-on-primary-container);
}
```

### Implementación JavaScript
```javascript
// Aplicar tema oscuro
document.documentElement.classList.add('dark-theme');

// Aplicar tema claro
document.documentElement.classList.remove('dark-theme');

// Persistencia en localStorage
localStorage.setItem('theme', 'dark'); // o 'light'
const savedTheme = localStorage.getItem('theme') || 'light';
```