import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:zonix/chat/providers/chat_provider.dart';
import 'package:zonix/chat/screens/chat_screen.dart';
import 'package:zonix/chat/widgets/conversation_card.dart';

/// Pantalla de lista de conversaciones
/// Muestra todas las conversaciones del usuario con badges de no leídos
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    
    // Configurar timeago en español
    timeago.setLocaleMessages('es', timeago.EsMessages());
    
    // Cargar conversaciones al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.loadConversations();
    });
    
    print('🔄 MessagesScreen: Inicializado');
  }

  Future<void> _handleRefresh() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: Text(
          'Mensajes',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: true,
        actions: [
          // Badge de no leídos total
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.unreadCount > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${chatProvider.unreadCount}',
                      style: TextStyle(
                        color: theme.colorScheme.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          // LOADING STATE
          if (chatProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando conversaciones...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // ERROR STATE
          if (chatProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chatProvider.errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          // EMPTY STATE
          if (chatProvider.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No tienes conversaciones aún',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¡Empieza a contactar vendedores desde una publicación!',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // LISTA DE CONVERSACIONES
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 0,
                vertical: isTablet ? 16 : 8,
              ),
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];

                return Dismissible(
                  key: Key('conv-${conversation.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Confirmar antes de eliminar
                    return await showDialog<bool>(
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
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    chatProvider.deleteConversation(conversation.id);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conversación eliminada'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  background: Container(
                    color: theme.colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                  child: ConversationCard(
                    conversation: conversation,
                    onTap: () {
                      // Navegar a ChatScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: conversation.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
