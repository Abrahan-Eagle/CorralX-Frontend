import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:corralx/chat/providers/chat_provider.dart';
import 'package:corralx/chat/screens/chat_screen.dart';
import 'package:corralx/chat/widgets/conversation_card.dart';

/// Pantalla de lista de conversaciones estilo WhatsApp
/// Muestra todas las conversaciones del usuario con diseño exacto de WhatsApp
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0B141A) : Colors.white,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color(0xFF2A2F32) : const Color(0xFF075E54),
        elevation: 0,
        title: Text(
          'Mensajes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Iconos removidos para interfaz minimalista
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
                    color: const Color(0xFF075E54),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando conversaciones...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar conversaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chatProvider.errorMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF075E54),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
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
                      color: isDarkMode ? Colors.white38 : Colors.black26,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No tienes conversaciones aún',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¡Empieza a contactar vendedores desde una publicación!',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white54 : Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // LISTA DE CONVERSACIONES - Estilo WhatsApp
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: const Color(0xFF075E54),
            backgroundColor:
                isDarkMode ? const Color(0xFF2A2F32) : Colors.white,
            child: ListView.builder(
              padding: EdgeInsets.zero,
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
                        backgroundColor:
                            isDarkMode ? const Color(0xFF2A2F32) : Colors.white,
                        title: Text(
                          'Eliminar conversación',
                          style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white : Colors.black87),
                        ),
                        content: Text(
                          '¿Estás seguro de que deseas eliminar esta conversación? '
                          'No podrás recuperar los mensajes.',
                          style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    final chatProvider = context.read<ChatProvider>();
                    chatProvider.deleteConversation(conversation.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Conversación eliminada'),
                        backgroundColor: isDarkMode
                            ? const Color(0xFF2A2F32)
                            : Colors.black87,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  child: ConversationCard(
                    conversation: conversation,
                    isDarkMode: isDarkMode,
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
