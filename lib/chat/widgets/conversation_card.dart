import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:zonix/chat/models/conversation.dart';
import 'package:zonix/config/app_config.dart';

/// Widget Card para una conversación estilo WhatsApp
/// Diseño exacto de WhatsApp con avatares circulares, estados online y badges
class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final bool isDarkMode;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipant = conversation.otherParticipant;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2F32) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF3B3B3B)
                  : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // AVATAR CIRCULAR - Estilo WhatsApp
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDarkMode
                        ? const Color(0xFF3B3B3B)
                        : const Color(0xFFE0E0E0),
                    backgroundImage: _getAvatarImage(otherParticipant),
                    child: _getAvatarPlaceholder(otherParticipant),
                  ),

                  // Indicador online - Punto verde pequeño
                  if (otherParticipant?.isOnline == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF2A2F32)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // CONTENIDO PRINCIPAL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + Verificado + Timestamp
                    Row(
                      children: [
                        // Nombre del contacto
                        Expanded(
                          child: Text(
                            _getContactName(otherParticipant),
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.bold : FontWeight.w500,
                              fontSize: 17,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Icono verificado
                        if (otherParticipant?.isVerified == true) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Timestamp
                        Text(
                          _formatTimestamp(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? (isDarkMode ? Colors.white70 : Colors.black54)
                                : (isDarkMode
                                    ? Colors.white54
                                    : Colors.black38),
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Último mensaje + Badge de no leídos
                    Row(
                      children: [
                        // Último mensaje
                        Expanded(
                          child: Text(
                            _getLastMessage(conversation),
                            style: TextStyle(
                              color: hasUnread
                                  ? (isDarkMode
                                      ? Colors.white70
                                      : Colors.black54)
                                  : (isDarkMode
                                      ? Colors.white54
                                      : Colors.black38),
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Badge de no leídos - Estilo WhatsApp
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366), // Verde WhatsApp
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Obtener imagen del avatar
  ImageProvider? _getAvatarImage(ChatParticipant? participant) {
    if (participant?.avatar != null && participant!.avatar!.isNotEmpty) {
      // Evitar URLs de placeholder
      if (participant.avatar!.contains('via.placeholder.com') ||
          participant.avatar!.contains('placeholder.com') ||
          participant.avatar!.contains('placehold.it')) {
        return null;
      }

      final avatarUrl = participant.avatar!.startsWith('http')
          ? participant.avatar!
          : '${AppConfig.apiUrl}/storage/${participant.avatar}';
      return NetworkImage(avatarUrl);
    }
    return null;
  }

  /// Obtener placeholder del avatar
  Widget? _getAvatarPlaceholder(ChatParticipant? participant) {
    if (participant?.avatar == null || participant!.avatar!.isEmpty) {
      return Text(
        _getInitials(participant?.name ?? 'U'),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      );
    }
    return null;
  }

  /// Obtener iniciales del nombre
  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  /// Obtener nombre del contacto
  String _getContactName(ChatParticipant? participant) {
    if (participant?.name != null && participant!.name.isNotEmpty) {
      return participant.name;
    }
    return 'Usuario';
  }

  /// Obtener último mensaje
  String _getLastMessage(Conversation conversation) {
    if (conversation.lastMessage != null &&
        conversation.lastMessage!.isNotEmpty) {
      return conversation.lastMessage!;
    }
    return 'Sin mensajes';
  }

  /// Formatear timestamp relativo
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    try {
      return timeago.format(timestamp, locale: 'es');
    } catch (e) {
      return '';
    }
  }
}
