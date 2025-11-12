import 'package:flutter/material.dart';
import 'package:corralx/chat/models/message.dart';
import 'package:intl/intl.dart';

/// Burbuja de mensaje diferenciada para enviados/recibidos
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isOwnMessage ? 64 : 8,
          right: isOwnMessage ? 8 : 64,
          bottom: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? (isDarkMode
                  ? const Color(
                      0xFF056162) // Verde oscuro WhatsApp (modo oscuro)
                  : const Color(
                      0xFFDCF8C6)) // Verde claro WhatsApp (modo claro)
              : (isDarkMode
                  ? const Color(0xFF2A2F32) // Gris oscuro (modo oscuro)
                  : Colors.white), // Blanco (modo claro)
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isOwnMessage ? 8 : 0),
            bottomRight: Radius.circular(isOwnMessage ? 0 : 8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenido del mensaje
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white : Colors.black87,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 4),

            // Timestamp + Estado
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.sentAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[400] : Colors.black54,
                  ),
                ),

                const SizedBox(width: 4),

                // Indicador de estado (solo mensajes propios)
                if (isOwnMessage) _buildWhatsAppStatusIndicator(isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Indicador de estado estilo WhatsApp
  Widget _buildWhatsAppStatusIndicator(bool isDarkMode) {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: isDarkMode ? Colors.grey[400] : Colors.black54,
          ),
        );

      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: isDarkMode ? Colors.grey[400] : Colors.black54,
        );

      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: isDarkMode ? Colors.grey[400] : Colors.black54,
        );

      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF4FC3F7), // Azul de WhatsApp (igual en ambos modos)
        );

      case MessageStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 14,
              color: Colors.red,
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }

  /// Formatear hora
  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}
