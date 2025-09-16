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

Interesan → contactan por chat (polling HTTP).

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

Stack: Flutter (stable), Provider para estado, HTTP/dio, flutter_secure_storage para token. UI mobile-first. Chat por polling (Timer.periodic + since_id).

1) Funcionalidad (MVP)

Auth: registro/login, persistir token.

Marketplace: lista + filtros + detalle, favoritos, reviews.

Publicar: crear/editar/eliminar publicaciones (con imágenes).

Perfiles: propio (editar) y público (de vendedores).

Chat: conversaciones + mensajes (polling).

Dashboard: mis publicaciones + métricas.

2) Estructura de carpetas
lib/
  main.dart
  config/             (constantes: baseUrl, tiempo de polling)
  models/             (User, Listing, ListingImage, Review, Conversation, Message)
  services/           (api_service.dart, auth_service.dart, listing_service.dart, chat_service.dart, profile_service.dart)
  providers/          (auth_provider.dart, listing_provider.dart, chat_provider.dart, profile_provider.dart)
  screens/
    auth/             (login_screen.dart, register_screen.dart)
    marketplace/      (marketplace_screen.dart, listing_detail_screen.dart, listing_form_screen.dart)
    chat/             (conversations_screen.dart, chat_screen.dart)
    profile/          (my_profile_screen.dart, public_profile_screen.dart)
    dashboard/        (my_listings_screen.dart, metrics_screen.dart)
  widgets/            (listing_card.dart, filter_bar.dart, image_picker_grid.dart, chat_bubble.dart, metrics_tiles.dart)

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
  static const chatPollingSeconds = 10; // 10–15s recomendado
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

ChatScreen: ListView de burbujas; al abrir, startPolling(convId) usando Timer.periodic(Duration(seconds: AppConfig.chatPollingSeconds), ...). Cancelar en dispose(). since_id para mensajes nuevos.

8) Manejo de errores

401: redirigir a login y limpiar token.

422: mostrar mensajes por campo (form).

500/otros: SnackBar “Ocurrió un error, inténtalo más tarde”.

Estados loading/empty/error en todas las vistas críticas.

9) Seguridad

Token en flutter_secure_storage.

No loggear token/PII.

Cerrar sesión borra token/estado.

10) Build y ejecución
flutter pub get
flutter run -d chrome   # o dispositvo/emulador
# Producción
flutter build apk       # Android
flutter build ios       # iOS (requiere Xcode)
flutter build web       # Web (si aplica)

11) Pruebas (sugeridas)

Unit: parsing de modelos (fromJson/toJson), servicios con mocks de HTTP.

Widget: formularios (validaciones), lista de marketplace (estados loading/empty/error), chat (append de mensajes).

Integración manual con Postman: validar flujos end-to-end (login → crear listing → ver → chatear).

12) Parámetros y convenciones clave

Fechas: ISO 8601 desde backend; formatear con intl.

Imágenes: comprimir/redimensionar client-side si es posible; limitar a 5.

Paginación: usar page en /listings; infinito o botones.

Polling: 10–15s en Chat; pausar fuera de ChatScreen.

13) Roadmap UI (post-MVP)

Estados “Destacado”, banners de promoción.

Notificaciones push.

Modo sin conexión (borradores).

Analítica de búsquedas y conversión.

🔚 Notas finales

Alineación back/front: nombres de campos y rutas ya coinciden; cualquier cambio de contrato debe reflejarse en ambos README.

Hosting compartido: evita websockets, usa polling. Optimiza imágenes y cachea config/rutas/vistas.

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