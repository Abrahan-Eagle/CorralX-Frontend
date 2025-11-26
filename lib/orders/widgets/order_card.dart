import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/order.dart';

/// Widget Card para mostrar un pedido en la lista
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Producto y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.product?.title ?? 'Producto',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cantidad: ${order.quantity}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              // Precio y Moneda
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.formattedTotalPrice,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    timeago.format(order.createdAt, locale: 'es'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Método de delivery
              Row(
                children: [
                  Icon(
                    _getDeliveryIcon(order.deliveryMethod),
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.deliveryMethodDisplayName,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeliveryIcon(String method) {
    switch (method) {
      case 'buyer_transport':
        return Icons.directions_car;
      case 'seller_transport':
        return Icons.local_shipping;
      case 'external_delivery':
        return Icons.inventory_2;
      case 'corralx_delivery':
        return Icons.store;
      default:
        return Icons.shopping_cart;
    }
  }
}

/// Chip de estado del pedido
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, backgroundColor) = _getStatusColors(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'rejected':
        return 'Rechazado';
      case 'delivered':
        return 'Entregado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  (Color, Color) _getStatusColors(ThemeData theme) {
    switch (status) {
      case 'pending':
        return (Colors.orange, Colors.orange.withOpacity(0.1));
      case 'accepted':
        return (Colors.blue, Colors.blue.withOpacity(0.1));
      case 'rejected':
        return (Colors.red, Colors.red.withOpacity(0.1));
      case 'delivered':
        return (Colors.green, Colors.green.withOpacity(0.1));
      case 'completed':
        return (Colors.green.shade700, Colors.green.withOpacity(0.2));
      case 'cancelled':
        return (Colors.grey, Colors.grey.withOpacity(0.1));
      default:
        return (theme.colorScheme.onSurface, theme.colorScheme.surfaceVariant);
    }
  }
}

