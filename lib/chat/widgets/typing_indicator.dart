import 'package:flutter/material.dart';

/// Widget de indicador de "está escribiendo..."
/// Muestra una animación de 3 puntos rebotando
class TypingIndicator extends StatefulWidget {
  final String? userName;

  const TypingIndicator({
    super.key,
    this.userName,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Texto
            Text(
              widget.userName != null
                  ? '${widget.userName} está escribiendo'
                  : 'Escribiendo',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(width: 8),

            // Animación de puntos
            SizedBox(
              width: 30,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDot(theme, 0),
                  _buildDot(theme, 1),
                  _buildDot(theme, 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Punto animado
  Widget _buildDot(ThemeData theme, int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = (_controller.value - delay) % 1.0;
        final scale = value < 0.5 ? 1.0 + (value * 2) * 0.5 : 1.5 - ((value - 0.5) * 2) * 0.5;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

