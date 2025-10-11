import 'package:flutter/material.dart';
import 'package:zonix/chat/models/message.dart';
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
              ? const Color(
                  0xFFDCF8C6) // Verde claro WhatsApp (mensajes enviados)
              : Colors.white, // Blanco (mensajes recibidos)
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isOwnMessage ? 8 : 0),
            bottomRight: Radius.circular(isOwnMessage ? 0 : 8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(width: 4),

                // Indicador de estado (solo mensajes propios)
                if (isOwnMessage) _buildWhatsAppStatusIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Indicador de estado estilo WhatsApp
  Widget _buildWhatsAppStatusIndicator() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.black54,
          ),
        );

      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 14,
          color: Colors.black54,
        );

      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.black54,
        );

      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF4FC3F7), // Azul de WhatsApp
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
