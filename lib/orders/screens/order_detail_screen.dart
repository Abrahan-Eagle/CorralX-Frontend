import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/profiles/providers/profile_provider.dart';
import 'package:corralx/orders/models/order.dart';
import 'package:corralx/orders/screens/receipt_screen.dart';
import 'package:corralx/orders/screens/mutual_review_screen.dart';
import 'package:corralx/orders/widgets/edit_order_dialog.dart';
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
  /// Flag local para saber si el usuario actual ya calificó en esta sesión
  /// (para ocultar el botón "Calificar" después de enviar la calificación).
  bool _hasCurrentUserReviewed = false;

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

  Future<void> _handleEdit() async {
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.selectedOrder;
    
    if (order == null) return;

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => EditOrderDialog(order: order),
    );

    if (updated == true && mounted) {
      // Recargar el detalle del pedido para mostrar los cambios
      await orderProvider.loadOrderDetail(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
                // Información del comprador (solo para vendedor)
                if (isSeller && order.buyer != null) ...[
                  _BuyerSection(order: order),
                  const SizedBox(height: 24),
                ],
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
                  hasCurrentUserReviewed: _hasCurrentUserReviewed,
                  onEdit: _handleEdit,
                  onAccept: _handleAccept,
                  onReject: _handleReject,
                  onDeliver: _handleDeliver,
                  onCancel: _handleCancel,
                  onReview: () async {
                    // Navegar a la pantalla de calificación y esperar el resultado
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MutualReviewScreen(orderId: order.id),
                      ),
                    );

                    // Si la calificación se envió correctamente, marcamos que ya calificó
                    // y opcionalmente recargamos el detalle del pedido.
                    if (result == true && mounted) {
                      setState(() {
                        _hasCurrentUserReviewed = true;
                      });
                      await context.read<OrderProvider>().loadOrderDetail(order.id);
                    }
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

class _BuyerSection extends StatelessWidget {
  final Order order;

  const _BuyerSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buyer = order.buyer;
    if (buyer == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Datos del Comprador',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              buyer.displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (buyer.displayName != buyer.fullName) ...[
              const SizedBox(height: 4),
              Text(
                buyer.fullName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (buyer.primaryAddress != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      buyer.primaryAddress!.fullLocation,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (buyer.isVerified) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Usuario Verificado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
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
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Información de Entrega',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Método de entrega
            _buildInfoRow(
              theme,
              'Método de entrega:',
              order.deliveryMethodDisplayName,
              Icons.delivery_dining,
            ),
            const SizedBox(height: 12),
            
            // Información específica según el método de delivery
            if (order.deliveryMethod == 'buyer_transport') ...[
              // Transporte del comprador
              if (order.pickupLocation != null)
                _buildInfoRow(
                  theme,
                  'Lugar de recogida:',
                  order.pickupLocation == 'ranch' ? 'En la finca' : 'Otro lugar',
                  Icons.location_on,
                ),
              if (order.pickupLocation == 'other' && order.pickupAddress != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Dirección de recogida:',
                  order.pickupAddress!,
                  Icons.place,
                ),
              ],
              if (order.pickupNotes != null && order.pickupNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Notas de recogida:',
                  order.pickupNotes!,
                  Icons.note,
                ),
              ],
            ] else if (order.deliveryMethod == 'seller_transport') ...[
              // Transporte del vendedor
              if (order.deliveryAddress != null)
                _buildInfoRow(
                  theme,
                  'Dirección de entrega:',
                  order.deliveryAddress!,
                  Icons.place,
                ),
              if (order.deliveryCost != null && order.deliveryCost! > 0) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Costo de entrega:',
                  '${order.deliveryCostCurrency ?? (order.currency == 'USD' ? '\$' : 'Bs')} ${order.deliveryCost!.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ],
            ] else if (order.deliveryMethod == 'external_delivery') ...[
              // Delivery externo
              if (order.deliveryAddress != null)
                _buildInfoRow(
                  theme,
                  'Dirección de entrega:',
                  order.deliveryAddress!,
                  Icons.place,
                ),
              if (order.deliveryProvider != null && order.deliveryProvider!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Proveedor de delivery:',
                  order.deliveryProvider!,
                  Icons.business,
                ),
              ],
              if (order.deliveryTrackingNumber != null && order.deliveryTrackingNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Número de tracking:',
                  order.deliveryTrackingNumber!,
                  Icons.qr_code,
                ),
              ],
              if (order.deliveryCost != null && order.deliveryCost! > 0) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Costo de delivery:',
                  '${order.deliveryCostCurrency ?? (order.currency == 'USD' ? '\$' : 'Bs')} ${order.deliveryCost!.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ],
            ] else if (order.deliveryMethod == 'corralx_delivery') ...[
              // Delivery CorralX
              if (order.deliveryAddress != null)
                _buildInfoRow(
                  theme,
                  'Dirección de entrega:',
                  order.deliveryAddress!,
                  Icons.place,
                ),
              if (order.deliveryTrackingNumber != null && order.deliveryTrackingNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Número de tracking CorralX:',
                  order.deliveryTrackingNumber!,
                  Icons.qr_code,
                ),
              ],
              if (order.deliveryCost != null && order.deliveryCost! > 0) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  'Costo de delivery:',
                  '${order.deliveryCostCurrency ?? (order.currency == 'USD' ? '\$' : 'Bs')} ${order.deliveryCost!.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ],
            ],
            
            // Fecha esperada (común para todos)
            if (order.expectedPickupDate != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                theme,
                'Fecha esperada:',
                DateFormat('dd/MM/yyyy').format(order.expectedPickupDate!),
                Icons.calendar_today,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
  final bool hasCurrentUserReviewed;
  final VoidCallback? onEdit;
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
    required this.hasCurrentUserReviewed,
    this.onEdit,
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
            // Botón Editar Pedido (vendedor, pedido pendiente)
            if (isSeller && order.canBeAccepted && onEdit != null)
              OutlinedButton.icon(
                onPressed: orderProvider.isUpdating ? null : onEdit,
                icon: orderProvider.isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit),
                label: const Text('Editar Pedido'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            if (isSeller && order.canBeAccepted && onEdit != null) const SizedBox(height: 8),
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
            if (order.canBeReviewed && !hasCurrentUserReviewed) ...[
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

