import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/chat/providers/chat_provider.dart';

/// Widget de input para escribir mensajes
/// Incluye TextField, botón enviar y detección de typing
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final int conversationId;
  final Function(String) onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.conversationId,
    required this.onSend,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _hasText = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _typingTimer?.cancel();
    super.dispose();
  }

  /// Detectar cambios en el texto
  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // Manejar typing indicator
    if (hasText) {
      _handleTyping();
    } else {
      _stopTyping();
    }
  }

  /// Notificar que el usuario está escribiendo
  void _handleTyping() {
    // Cancelar timer anterior
    _typingTimer?.cancel();

    // Si no estaba escribiendo, notificar al backend
    if (!_isTyping) {
      _isTyping = true;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.notifyTyping(widget.conversationId, true);
      print('⌨️ Typing started notificado');
    }

    // Programar "stop typing" después de 3 segundos de inactividad
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  /// Notificar que el usuario dejó de escribir
  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.notifyTyping(widget.conversationId, false);
      print('⌨️ Typing stopped notificado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isSending = chatProvider.isSending;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF2A2F32)
                : const Color(0xFFECE5DD), // Color de fondo WhatsApp
          ),
          child: SafeArea(
            child: Row(
              children: [
                // TextField
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF2A2F32) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      enabled: !isSending,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Mensaje',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Botón enviar (solo cuando hay texto)
                if (_hasText || isSending)
                  Container(
                    decoration: BoxDecoration(
                      color: _hasText && !isSending
                          ? const Color(
                              0xFF075E54) // Verde WhatsApp (igual en ambos modos)
                          : (isDarkMode
                              ? Colors.grey[600]
                              : Colors.grey.shade300),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _hasText && !isSending
                          ? () {
                              final text = widget.controller.text;
                              widget.onSend(text);
                              _stopTyping(); // Detener typing al enviar
                            }
                          : null,
                      icon: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
