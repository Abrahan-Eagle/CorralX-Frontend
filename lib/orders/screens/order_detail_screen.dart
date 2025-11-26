import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/profiles/providers/profile_provider.dart';
import 'package:corralx/orders/models/order.dart';
import 'package:corralx/orders/screens/receipt_screen.dart';
import 'package:corralx/orders/screens/mutual_review_screen.dart';
import 'package:intl/intl.dart';

/// Pantalla que muestra el detalle de un pedido con acciones contextuales
class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  bool _isCurrentUserBuyer(Order order) {
    final profileProvider = context.read<ProfileProvider>();
    final myProfile = profileProvider.myProfile;
    return myProfile?.id == order.buyerProfileId;
  }

  bool _isCurrentUserSeller(Order order) {
    final profileProvider = context.read<ProfileProvider>();
    final myProfile = profileProvider.myProfile;
    return myProfile?.id == order.sellerProfileId;
  }

  Future<void> _handleAccept() async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.acceptOrder(widget.orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido aceptado exitosamente')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Error al aceptar pedido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.rejectOrder(widget.orderId, reason: reason);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido rechazado')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Error al rechazar pedido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeliver() async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.markAsDelivered(widget.orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido marcado como entregado')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Error al marcar como entregado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await _showCancelConfirmation();
    if (!confirmed) return;

    final reason = await _showCancelDialog();
    if (reason == null) return;

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.cancelOrder(widget.orderId, reason: reason);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Error al cancelar pedido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Pedido'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            hintText: 'Explica por qué rechazas el pedido',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text.isEmpty ? null : reasonController.text),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCancelConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Estás seguro de que deseas cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<String?> _showCancelDialog() async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            hintText: 'Explica por qué cancelas el pedido',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text.isEmpty ? null : reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final order = orderProvider.selectedOrder;
              if (order == null || !order.hasReceipt) return const SizedBox();
              
              return IconButton(
                icon: const Icon(Icons.receipt),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptScreen(orderId: order.id),
                    ),
                  );
                },
                tooltip: 'Ver Comprobante',
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoadingOrderDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = orderProvider.selectedOrder;
          if (order == null) {
            return Center(
              child: Text(
                orderProvider.errorMessage ?? 'Pedido no encontrado',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final isBuyer = _isCurrentUserBuyer(order);
          final isSeller = _isCurrentUserSeller(order);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado del pedido
                _StatusSection(order: order),
                const SizedBox(height: 24),
                // Información del producto
                _ProductSection(order: order),
                const SizedBox(height: 24),
                // Información de delivery
                _DeliverySection(order: order),
                const SizedBox(height: 24),
                // Información de precios
                _PricingSection(order: order),
                const SizedBox(height: 24),
                // Notas
                if (order.buyerNotes != null || order.sellerNotes != null)
                  _NotesSection(order: order),
                const SizedBox(height: 24),
                // Botones de acción
                _ActionButtons(
                  order: order,
                  isBuyer: isBuyer,
                  isSeller: isSeller,
                  onAccept: _handleAccept,
                  onReject: _handleReject,
                  onDeliver: _handleDeliver,
                  onCancel: _handleCancel,
                  onReview: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MutualReviewScreen(orderId: order.id),
                      ),
                    );
                  },
                  onReceipt: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptScreen(orderId: order.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final Order order;

  const _StatusSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Columna de estado ocupa el espacio disponible
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.statusDisplayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (order.receiptNumber != null)
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.receiptNumber!,
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final Order order;

  const _ProductSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Producto',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              order.product?.title ?? 'Producto no disponible',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cantidad: ${order.quantity}',
              style: theme.textTheme.bodyMedium,
            ),
            if (order.product?.breed != null)
              Text(
                'Raza: ${order.product!.breed}',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliverySection extends StatelessWidget {
  final Order order;

  const _DeliverySection({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Método de Entrega',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              order.deliveryMethodDisplayName,
              style: theme.textTheme.bodyLarge,
            ),
            if (order.pickupAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dirección de recogida: ${order.pickupAddress}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (order.deliveryAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dirección de entrega: ${order.deliveryAddress}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (order.expectedPickupDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Fecha esperada: ${DateFormat('dd/MM/yyyy').format(order.expectedPickupDate!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  final Order order;

  const _PricingSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Precios',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Precio unitario:', style: theme.textTheme.bodyMedium),
                Text(
                  order.formattedUnitPrice,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cantidad:', style: theme.textTheme.bodyMedium),
                Text('${order.quantity}', style: theme.textTheme.bodyMedium),
              ],
            ),
            if (order.deliveryCost != null && order.deliveryCost! > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Costo de entrega:', style: theme.textTheme.bodyMedium),
                  Text(
                    '${order.deliveryCostCurrency ?? (order.currency == 'USD' ? '\$' : 'Bs')} ${order.deliveryCost!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.formattedTotalPrice,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final Order order;

  const _NotesSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (order.buyerNotes != null) ...[
              Text(
                'Notas del comprador:',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(
                order.buyerNotes!,
                style: theme.textTheme.bodyMedium,
              ),
              if (order.sellerNotes != null) const SizedBox(height: 12),
            ],
            if (order.sellerNotes != null) ...[
              Text(
                'Notas del vendedor:',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(
                order.sellerNotes!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Order order;
  final bool isBuyer;
  final bool isSeller;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDeliver;
  final VoidCallback onCancel;
  final VoidCallback onReview;
  final VoidCallback onReceipt;

  const _ActionButtons({
    required this.order,
    required this.isBuyer,
    required this.isSeller,
    required this.onAccept,
    required this.onReject,
    required this.onDeliver,
    required this.onCancel,
    required this.onReview,
    required this.onReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botones para vendedor
            if (isSeller && order.canBeAccepted)
              ElevatedButton.icon(
                onPressed: orderProvider.isAccepting ? null : onAccept,
                icon: orderProvider.isAccepting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Aceptar Pedido'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            if (isSeller && order.canBeAccepted) const SizedBox(height: 8),
            if (isSeller && order.canBeRejected)
              OutlinedButton.icon(
                onPressed: orderProvider.isRejecting ? null : onReject,
                icon: orderProvider.isRejecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close),
                label: const Text('Rechazar Pedido'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            // Botones para comprador
            if (isBuyer && order.canBeDelivered) ...[
              if (isSeller && order.canBeRejected) const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: orderProvider.isDelivering ? null : onDeliver,
                icon: orderProvider.isDelivering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text('Confirmar Recogida'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            // Botón de comprobante
            if (order.hasReceipt) ...[
              if ((isBuyer && order.canBeDelivered) ||
                  (isSeller && order.canBeRejected))
                const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onReceipt,
                icon: const Icon(Icons.receipt),
                label: const Text('Ver Comprobante'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            // Botón de calificación
            if (order.canBeReviewed) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.star),
                label: const Text('Calificar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            // Botón de cancelar
            if (order.canBeCancelled) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: orderProvider.isCancelling ? null : onCancel,
                icon: orderProvider.isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel),
                label: const Text('Cancelar Pedido'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

