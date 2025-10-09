import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:zonix/chat/models/conversation.dart';
import 'package:zonix/config/app_config.dart';

/// Widget Card para una conversación en la lista de mensajes
class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final otherParticipant = conversation.otherParticipant;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 0 : 16,
          vertical: isTablet ? 6 : 4,
        ),
        decoration: BoxDecoration(
          color: hasUnread
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
          border: Border.all(
            color: hasUnread
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(
            children: [
              // AVATAR
              Stack(
                children: [
                  CircleAvatar(
                    radius: isTablet ? 28 : 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: otherParticipant?.avatar != null
                        ? NetworkImage(
                            '${AppConfig.apiUrl}/storage/${otherParticipant!.avatar}',
                          )
                        : null,
                    child: otherParticipant?.avatar == null
                        ? Text(
                            otherParticipant?.name.substring(0, 1).toUpperCase() ?? '?',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  
                  // Indicador online
                  if (otherParticipant?.isOnline == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // CONTENIDO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + Verificado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherParticipant?.name ?? 'Usuario',
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: isTablet ? 18 : 16,
                              color: theme.colorScheme.onSurface,
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
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Último mensaje
                    Text(
                      conversation.lastMessage ?? 'Sin mensajes',
                      style: TextStyle(
                        color: hasUnread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // TIMESTAMP + BADGE
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Timestamp relativo
                  Text(
                    conversation.lastMessageAt != null
                        ? timeago.format(
                            conversation.lastMessageAt!,
                            locale: 'es',
                          )
                        : '',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: hasUnread
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Badge de no leídos
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
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
      ),
    );
  }
}

