import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/chat/providers/chat_provider.dart';
import 'package:corralx/chat/widgets/message_bubble.dart';
import 'package:corralx/chat/widgets/chat_input.dart';
import 'package:corralx/chat/widgets/typing_indicator.dart';
import 'package:corralx/config/app_config.dart';
import 'package:corralx/profiles/providers/profile_provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/orders/widgets/confirm_purchase_dialog.dart';
import 'package:corralx/products/providers/product_provider.dart';
import 'package:corralx/products/models/product.dart';
import 'package:corralx/chat/models/conversation.dart';

/// Pantalla de chat 1:1 con un usuario
/// Muestra mensajes con HTTP Polling (4 segundos)
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

  // Datos del contacto
  String? _contactFullName;
  String? _contactAvatar;
  bool _contactIsVerified = false;
  bool _isLoadingContact = true;

  // Datos de la conversación
  Conversation? _conversation;
  bool _hasOpenOrder = false;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>(); // ✅ Inicializar en initState

    print('🔄 ChatScreen: Inicializado - ConvID: ${widget.conversationId}');

    // Cargar datos del contacto y mensajes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      final profileProvider = context.read<ProfileProvider>();

      // ✅ Asegurar que el perfil esté cargado
      if (profileProvider.myProfile == null) {
        profileProvider.fetchMyProfile();
      }

      // Establecer como conversación activa
      chatProvider.setActiveConversation(widget.conversationId);

      // ✅ SUSCRIBIRSE AL WEBSOCKET DEL CANAL
      chatProvider.subscribeToConversation(widget.conversationId);

      // Cargar mensajes si no están cargados
      if (chatProvider.getMessages(widget.conversationId).isEmpty) {
        chatProvider.loadMessages(widget.conversationId);
      }

      // Cargar datos del contacto
      _loadContactData();

      // Cargar conversación y verificar pedidos
      _loadConversationAndCheckOrders();
    });
  }

  @override
  void dispose() {
    // Limpiar conversación activa usando la referencia guardada
    _chatProvider.setActiveConversation(null);

    // ✅ DESUSCRIBIRSE DEL WEBSOCKET
    _chatProvider.unsubscribeFromConversation(widget.conversationId);

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

  /// Cargar datos del contacto desde la conversación
  Future<void> _loadContactData() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final profileProvider = context.read<ProfileProvider>();

      // Obtener la conversación
      final conversations = chatProvider.conversations;
      final conversation = conversations.firstWhere(
        (conv) => conv.id == widget.conversationId,
        orElse: () => throw Exception('Conversación no encontrada'),
      );

      // Obtener el ID del otro participante
      final myProfileId = profileProvider.myProfile?.id;
      final otherProfileId = conversation.profile1Id == myProfileId
          ? conversation.profile2Id
          : conversation.profile1Id;

      // Obtener el perfil del contacto
      final contactProfile =
          await chatProvider.getContactProfile(otherProfileId);

      if (mounted) {
        setState(() {
          // Construir nombre completo: commercial_name o firstName + lastName
          // El backend devuelve Map<String, dynamic> en snake_case
          final commercialName = contactProfile['commercial_name'] as String?;
          if (commercialName != null && commercialName.isNotEmpty) {
            _contactFullName = commercialName;
          } else {
            final firstName = contactProfile['firstName'] as String? ?? '';
            final lastName = contactProfile['lastName'] as String? ?? '';
            _contactFullName = '$firstName $lastName'.trim();
          }

          _contactAvatar = contactProfile['photo_users'] as String?;
          _contactIsVerified = contactProfile['is_verified'] as bool? ?? false;
          _isLoadingContact = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos del contacto: $e');

      // Fallback: usar datos del widget
      if (mounted) {
        setState(() {
          _contactFullName = widget.contactName ?? 'Usuario';
          _contactAvatar = widget.contactAvatar;
          _contactIsVerified = widget.contactIsVerified ?? false;
          _isLoadingContact = false;
        });
      }
    }
  }

  /// Cargar conversación y verificar si hay pedidos abiertos
  Future<void> _loadConversationAndCheckOrders() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final conversations = chatProvider.conversations;
      final conversation = conversations.firstWhere(
        (conv) => conv.id == widget.conversationId,
        orElse: () => Conversation(
          id: widget.conversationId,
          profile1Id: 0,
          profile2Id: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _conversation = conversation;
        });
      }

      // Verificar si hay pedidos abiertos para esta conversación
      if (conversation.productId != null) {
        await _checkOpenOrders();
      }
    } catch (e) {
      print('❌ Error cargando conversación: $e');
    }
  }

  /// Verificar si hay pedidos abiertos para esta conversación
  Future<void> _checkOpenOrders() async {
    try {
      final orderProvider = context.read<OrderProvider>();
      final profileProvider = context.read<ProfileProvider>();
      final myProfileId = profileProvider.myProfile?.id;

      if (myProfileId == null) return;

      // Cargar pedidos como comprador
      await orderProvider.loadBuyerOrders(refresh: true);

      // Verificar si hay algún pedido abierto (pending, accepted, delivered) para esta conversación
      final openOrders = orderProvider.buyerOrders.where((order) {
        return order.conversationId == widget.conversationId &&
            (order.isPending || order.isAccepted || order.isDelivered);
      });

      if (mounted) {
        setState(() {
          _hasOpenOrder = openOrders.isNotEmpty;
        });
      }
    } catch (e) {
      print('❌ Error verificando pedidos: $e');
    }
  }

  /// Mostrar diálogo de confirmación de compra
  void _showConfirmPurchaseDialog() {
    if (_conversation?.productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se puede identificar el producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cargar el producto
    final productProvider = context.read<ProductProvider>();
    Product? product;

    // Buscar el producto en la lista de productos cargados
    product = productProvider.products
        .firstWhere(
          (p) => p.id == _conversation!.productId,
          orElse: () => Product(
            id: _conversation!.productId!,
            title: '',
            description: '',
            type: '',
            breed: '',
            age: 0,
            quantity: 0,
            price: 0,
            currency: 'USD',
            deliveryMethod: 'pickup',
            negotiable: false,
            status: 'active',
            viewsCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            ranchId: 0,
          ),
        );

    // Si no está en la lista, intentar cargarlo
    if (product.id == _conversation!.productId && product.title.isEmpty) {
      productProvider.fetchProductDetail(_conversation!.productId!);
      product = productProvider.selectedProduct;
    }

    showDialog(
      context: context,
      builder: (context) => ConfirmPurchaseDialog(
        productId: _conversation!.productId!,
        conversationId: widget.conversationId,
        product: product,
      ),
    ).then((_) {
      // Refrescar verificación de pedidos después de crear uno
      _checkOpenOrders();
    });
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF1E2428)
          : const Color(0xFF075E54), // Verde WhatsApp
      appBar: _buildWhatsAppAppBar(theme, isDarkMode),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF0B141A)
              : const Color(0xFFECE5DD), // Color de fondo WhatsApp
        ),
        child: Consumer2<ChatProvider, ProfileProvider>(
          builder: (context, chatProvider, profileProvider, child) {
            final messages = chatProvider.getMessages(widget.conversationId);
            final isTyping =
                chatProvider.isTypingInConversation(widget.conversationId);

            // ✅ Obtener el profile ID del usuario actual
            final currentProfileId = profileProvider.myProfile?.id ?? 0;

            return Column(
              children: [
                // Indicador de estado de conexión (HTTP Polling)
                _buildConnectionBanner(theme, chatProvider.isConnected),

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
                            final message =
                                messages[messages.length - 1 - index];
                            final isOwnMessage = message.isOwnMessage(
                                currentProfileId); // ✅ Usar el ID real del perfil

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

                // Typing indicator (solo con Pusher activo)
                if (chatProvider.isUsingPusher && isTyping)
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
      ),
      floatingActionButton: Consumer2<ChatProvider, ProfileProvider>(
        builder: (context, chatProvider, profileProvider, child) {
          // Mostrar FAB solo si:
          // 1. La conversación tiene productId
          // 2. No hay pedido abierto
          // 3. El usuario actual es comprador (no vendedor)
          if (_conversation?.productId == null || _hasOpenOrder) {
            return const SizedBox.shrink();
          }

          // Verificar que el usuario es comprador (no el vendedor del producto)
          final myProfileId = profileProvider.myProfile?.id;
          if (myProfileId == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: _showConfirmPurchaseDialog,
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Confirmar Compra'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          );
        },
      ),
    );
  }

  /// AppBar estilo WhatsApp
  PreferredSizeWidget _buildWhatsAppAppBar(ThemeData theme, bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode
          ? const Color(0xFF2A2F32)
          : const Color(0xFF075E54), // Verde WhatsApp
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar del contacto
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: _contactAvatar != null
                ? NetworkImage(_contactAvatar!.startsWith('http')
                    ? _contactAvatar!
                    : '${AppConfig.apiUrl}/storage/${_contactAvatar}')
                : null,
            child: _contactAvatar == null
                ? Text(
                    _contactFullName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
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
                        _isLoadingContact
                            ? 'Cargando...'
                            : (_contactFullName ?? 'Usuario'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    // Icono verificado
                    if (_contactIsVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),

                // Estado de conexión
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final statusText = chatProvider.isUsingPusher
                        ? 'En línea ⚡'
                        : chatProvider.isConnected
                            ? 'En línea'
                            : 'Sin conexión';

                    return Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
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
          icon: const Icon(Icons.more_vert, color: Colors.white),
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

  /// Banner de estado de conexión (HTTP Polling)
  Widget _buildConnectionBanner(
    ThemeData theme,
    bool isConnected,
  ) {
    if (isConnected) {
      return const SizedBox.shrink(); // No mostrar si está conectado
    }

    // Polling desconectado
    Color bgColor = Colors.red;
    String text = '🔴 Sin conexión';
    IconData icon = Icons.cloud_off;

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
}
