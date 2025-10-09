/// Estados de conexión para chat
///
/// Usado por compatibilidad con UI existente.
/// En MVP con HTTP Polling, el estado siempre es:
/// - connected: cuando polling está activo
/// - disconnected: cuando polling está detenido
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}
