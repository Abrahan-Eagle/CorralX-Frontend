import 'package:flutter/material.dart';
import '../../config/corral_x_theme.dart';

/// Widgets estilo Amazon/Alibaba - DENSOS y FUNCIONALES
/// Mucha información visible, layout denso, sin minimalismo

/// Botón estilo Amazon - funcional y denso
class AmazonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final double? width;
  final IconData? icon;

  const AmazonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.width,
    this.icon,
  });

  @override
  State<AmazonButton> createState() => _AmazonButtonState();
}

class _AmazonButtonState extends State<AmazonButton> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: widget.width,
      height: 36,
      decoration: BoxDecoration(
        color: widget.isSecondary 
            ? colorScheme.surface 
            : CorralXTheme.primarySolid, // Verde principal #386A20
        border: widget.isSecondary
            ? Border.all(color: CorralXTheme.primarySolid, width: 1)
            : null,
        borderRadius: BorderRadius.circular(9999), // Botón totalmente redondeado (HTML style)
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999), // Coincidir con el container
          onTap: widget.onPressed,
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isSecondary
                            ? CorralXTheme.primarySolid
                            : Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 16,
                          color: widget.isSecondary
                              ? CorralXTheme.primarySolid
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.isSecondary
                              ? CorralXTheme.primarySolid
                              : Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta estilo Amazon - densa con mucha información
class AmazonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final String? title;
  final String? subtitle;

  const AmazonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.onTap,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: width,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || subtitle != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Container(
            padding: padding ?? const EdgeInsets.all(12),
            child: onTap != null
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(2),
                      onTap: onTap,
                      child: child,
                    ),
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

/// Característica estilo Amazon - densa con múltiples elementos
class AmazonFeature extends StatelessWidget {
  final String title;
  final String description;
  final String? price;
  final String? rating;
  final String? reviews;
  final Color accentColor;
  final IconData? icon;

  const AmazonFeature({
    super.key,
    required this.title,
    required this.description,
    this.price,
    this.rating,
    this.reviews,
    required this.accentColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: accentColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y título
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Descripción
          Text(
            description,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 10,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Información adicional (precio, rating, reviews)
          if (price != null || rating != null || reviews != null)
            Row(
              children: [
                if (price != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      price!,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (rating != null) ...[
                  Text(
                    '★ $rating',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (reviews != null)
                  Expanded(
                    child: Text(
                      '($reviews)',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 8,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Lista densa estilo Amazon
class AmazonList extends StatelessWidget {
  final List<Widget> items;
  final String? title;
  final bool showMore;

  const AmazonList({
    super.key,
    required this.items,
    this.title,
    this.showMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    title!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (showMore)
                    Text(
                      'Ver más',
                      style: TextStyle(
                        color: CorralXTheme.accentSolid,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                item,
                if (index < items.length - 1)
                  Container(
                    height: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Elemento de lista estilo Amazon
class AmazonListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final IconData? icon;
  final VoidCallback? onTap;

  const AmazonListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: CorralXTheme.accentSolid,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 12,
                    color: CorralXTheme.accentSolid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animación simple sin efectos excesivos
class AmazonFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AmazonFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AmazonFadeIn> createState() => _AmazonFadeInState();
}

class _AmazonFadeInState extends State<AmazonFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

/// Indicador de progreso estilo Amazon
class AmazonProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const AmazonProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 3,
          width: index == currentPage ? 16 : 3,
          decoration: BoxDecoration(
            color: index == currentPage
                ? CorralXTheme.primarySolid // Verde principal #386A20
                : CorralXTheme.lightGray, // Gris claro #E0E4D7
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
