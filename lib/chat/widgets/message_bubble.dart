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
    final theme = Theme.of(context);
    
    // 🔍 Debug log
    print('💬 MessageBubble - ID: ${message.id}, senderID: ${message.senderId}, isOwn: $isOwnMessage, align: ${isOwnMessage ? "DERECHA" : "IZQUIERDA"}');

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isOwnMessage ? 64 : 0,
          right: isOwnMessage ? 0 : 64,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
            bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenido del mensaje
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: isOwnMessage
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
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
                    color: isOwnMessage
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.6)
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),

                const SizedBox(width: 4),

                // Indicador de estado (solo mensajes propios)
                if (isOwnMessage) _buildStatusIndicator(theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Indicador de estado del mensaje
  Widget _buildStatusIndicator(ThemeData theme) {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
          ),
        );

      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
        );

      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
        );

      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: theme.colorScheme.primary,
        );

      case MessageStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: theme.colorScheme.error,
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Reintentar',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.error,
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

