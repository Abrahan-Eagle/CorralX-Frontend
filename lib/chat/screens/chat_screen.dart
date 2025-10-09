import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/chat/providers/chat_provider.dart';
import 'package:zonix/chat/models/message.dart';
import 'package:zonix/chat/widgets/message_bubble.dart';
import 'package:zonix/chat/widgets/chat_input.dart';
import 'package:zonix/chat/widgets/typing_indicator.dart';
import 'package:zonix/chat/services/websocket_service.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/profiles/providers/profile_provider.dart'; // ✅ Para obtener el profileId

/// Pantalla de chat 1:1 con un usuario
/// Muestra mensajes en tiempo real con WebSocket
class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String? contactName;
  final String? contactAvatar;
  final bool? contactIsVerified;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.contactName,
    this.contactAvatar,
    this.contactIsVerified,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late final ChatProvider _chatProvider; // ✅ Guardar referencia

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>(); // ✅ Inicializar en initState

    print('🔄 ChatScreen: Inicializado - ConvID: ${widget.conversationId}');

    // Cargar mensajes y marcar como leído
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();

      // Establecer como conversación activa
      chatProvider.setActiveConversation(widget.conversationId);

      // Cargar mensajes si no están cargados
      if (chatProvider.getMessages(widget.conversationId).isEmpty) {
        chatProvider.loadMessages(widget.conversationId);
      }
    });
  }

  @override
  void dispose() {
    // Limpiar conversación activa usando la referencia guardada
    _chatProvider.setActiveConversation(null);

    _scrollController.dispose();
    _textController.dispose();

    print('🧹 ChatScreen: Disposed');
    super.dispose();
  }

  /// Auto-scroll al último mensaje
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Enviar mensaje
  Future<void> _handleSendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final chatProvider = context.read<ChatProvider>();

    try {
      await chatProvider.sendMessage(widget.conversationId, content.trim());

      // Limpiar input
      _textController.clear();

      // Scroll al final
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: _buildAppBar(theme),
      body: Consumer2<ChatProvider, ProfileProvider>(
        builder: (context, chatProvider, profileProvider, child) {
          final messages = chatProvider.getMessages(widget.conversationId);
          final isTyping =
              chatProvider.isTypingInConversation(widget.conversationId);
          
          // ✅ Obtener el profile ID del usuario actual
          final currentProfileId = profileProvider.myProfile?.id ?? 0;

          return Column(
            children: [
              // Indicador de estado de conexión WebSocket
              _buildConnectionBanner(theme, chatProvider.connectionState),

              // Lista de mensajes
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Mensajes más recientes abajo
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          // Invertir orden para reverse: true
                          final message = messages[messages.length - 1 - index];
                          final isOwnMessage = message
                              .isOwnMessage(currentProfileId); // ✅ Usar el ID real del perfil

                          // Separador de fecha si cambia el día
                          Widget? dateSeparator;
                          if (index < messages.length - 1) {
                            final nextMessage =
                                messages[messages.length - 2 - index];
                            if (!_isSameDay(
                                message.sentAt, nextMessage.sentAt)) {
                              dateSeparator =
                                  _buildDateSeparator(theme, message.sentAt);
                            }
                          } else if (index == messages.length - 1) {
                            // Primer mensaje siempre tiene separador
                            dateSeparator =
                                _buildDateSeparator(theme, message.sentAt);
                          }

                          return Column(
                            children: [
                              if (dateSeparator != null) dateSeparator,
                              MessageBubble(
                                message: message,
                                isOwnMessage: isOwnMessage,
                                onRetry: () async {
                                  await chatProvider.retryFailedMessage(
                                    widget.conversationId,
                                    message,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Indicador de "está escribiendo..."
              if (isTyping)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: TypingIndicator(),
                ),

              // Input de mensaje
              ChatInput(
                controller: _textController,
                conversationId: widget.conversationId,
                onSend: _handleSendMessage,
              ),
            ],
          );
        },
      ),
    );
  }

  /// AppBar con info del contacto
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar pequeño
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: widget.contactAvatar != null
                ? NetworkImage(
                    '${AppConfig.apiUrl}/storage/${widget.contactAvatar}')
                : null,
            child: widget.contactAvatar == null
                ? Text(
                    widget.contactName?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Nombre + Estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.contactName ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    // Icono verificado
                    if (widget.contactIsVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),

                // Estado de conexión WebSocket
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return Text(
                      _getConnectionText(chatProvider.connectionState),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getConnectionColor(
                          theme,
                          chatProvider.connectionState,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Menú de opciones
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _confirmDeleteConversation();
                break;
              case 'block':
                // TODO: Implementar bloqueo
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20),
                  SizedBox(width: 12),
                  Text('Eliminar conversación'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20),
                  SizedBox(width: 12),
                  Text('Bloquear usuario'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Banner de estado de conexión
  Widget _buildConnectionBanner(
    ThemeData theme,
    WebSocketConnectionState state,
  ) {
    if (state == WebSocketConnectionState.connected) {
      return const SizedBox.shrink(); // No mostrar si está conectado
    }

    Color bgColor;
    String text;
    IconData icon;

    switch (state) {
      case WebSocketConnectionState.connecting:
        bgColor = Colors.orange;
        text = '🟡 Conectando...';
        icon = Icons.sync;
        break;
      case WebSocketConnectionState.reconnecting:
        bgColor = Colors.orange;
        text = '🟡 Reconectando...';
        icon = Icons.sync;
        break;
      case WebSocketConnectionState.error:
      case WebSocketConnectionState.disconnected:
        bgColor = Colors.red;
        text = '🔴 Sin conexión - Los mensajes se enviarán cuando reconectes';
        icon = Icons.cloud_off;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bgColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(icon, size: 16, color: bgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: bgColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin mensajes aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Envía el primer mensaje!',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Separador de fecha
  Widget _buildDateSeparator(ThemeData theme, DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      dateText = 'Hoy';
    } else if (messageDate == yesterday) {
      dateText = 'Ayer';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Verificar si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Confirmar eliminación de conversación
  Future<void> _confirmDeleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta conversación? '
          'No podrás recuperar los mensajes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteConversation(widget.conversationId);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Texto de estado de conexión
  String _getConnectionText(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return 'En línea';
      case WebSocketConnectionState.connecting:
        return 'Conectando...';
      case WebSocketConnectionState.reconnecting:
        return 'Reconectando...';
      case WebSocketConnectionState.disconnected:
      case WebSocketConnectionState.error:
        return 'Sin conexión';
    }
  }

  /// Color de estado de conexión
  Color _getConnectionColor(ThemeData theme, WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return Colors.orange;
      case WebSocketConnectionState.disconnected:
      case WebSocketConnectionState.error:
        return Colors.red;
    }
  }
}
