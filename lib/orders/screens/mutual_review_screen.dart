import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/profiles/providers/profile_provider.dart';
import 'package:corralx/orders/models/order.dart';

/// Pantalla para calificaciones mutuas del pedido
class MutualReviewScreen extends StatefulWidget {
  final int orderId;

  const MutualReviewScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<MutualReviewScreen> createState() => _MutualReviewScreenState();
}

class _MutualReviewScreenState extends State<MutualReviewScreen> {
  // Ratings para compradores
  int _productRating = 0;
  int _sellerRating = 0;
  final _productCommentController = TextEditingController();
  final _sellerCommentController = TextEditingController();

  // Ratings para vendedores
  int _buyerRating = 0;
  final _buyerCommentController = TextEditingController();

  bool _isSubmitting = false;
  Order? _order;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Asegurarnos de tener el perfil cargado para saber si somos comprador o vendedor
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.myProfile == null) {
        await profileProvider.fetchMyProfile();
      }
      if (!mounted) return;
      await _loadOrder();
    });
  }

  Future<void> _loadOrder() async {
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.loadOrderDetail(widget.orderId);
    if (mounted) {
      setState(() {
        _order = orderProvider.selectedOrder;
      });
    }
  }

  bool _isCurrentUserBuyer() {
    if (_order == null) return false;
    final profileProvider = context.read<ProfileProvider>();
    final myProfile = profileProvider.myProfile;
    return myProfile?.id == _order!.buyerProfileId;
  }

  Future<void> _submitReview() async {
    if (_isCurrentUserBuyer()) {
      if (_productRating == 0 || _sellerRating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor califica el producto y al vendedor'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      if (_buyerRating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor califica al comprador'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.submitReview(
      orderId: widget.orderId,
      productRating: _isCurrentUserBuyer() ? _productRating : null,
      productComment: _isCurrentUserBuyer() ? _productCommentController.text.isEmpty ? null : _productCommentController.text : null,
      sellerRating: _isCurrentUserBuyer() ? _sellerRating : null,
      sellerComment: _isCurrentUserBuyer() ? _sellerCommentController.text.isEmpty ? null : _sellerCommentController.text : null,
      buyerRating: !_isCurrentUserBuyer() ? _buyerRating : null,
      buyerComment: !_isCurrentUserBuyer() ? _buyerCommentController.text.isEmpty ? null : _buyerCommentController.text : null,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calificación enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Error al enviar calificación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _productCommentController.dispose();
    _sellerCommentController.dispose();
    _buyerCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuyer = _isCurrentUserBuyer();

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calificar Pedido')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificar Pedido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBuyer
                  ? 'Califica el producto y al vendedor'
                  : 'Califica al comprador',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (isBuyer) ...[
              // Calificación del producto
              _RatingSection(
                title: 'Calificación del Producto',
                rating: _productRating,
                onRatingChanged: (rating) {
                  setState(() {
                    _productRating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _productCommentController,
                decoration: const InputDecoration(
                  labelText: 'Comentario sobre el producto (opcional)',
                  hintText: '¿Cómo fue el producto?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Calificación del vendedor
              _RatingSection(
                title: 'Calificación del Vendedor',
                rating: _sellerRating,
                onRatingChanged: (rating) {
                  setState(() {
                    _sellerRating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sellerCommentController,
                decoration: const InputDecoration(
                  labelText: 'Comentario sobre el vendedor (opcional)',
                  hintText: '¿Cómo fue la experiencia con el vendedor?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ] else ...[
              // Calificación del comprador
              _RatingSection(
                title: 'Calificación del Comprador',
                rating: _buyerRating,
                onRatingChanged: (rating) {
                  setState(() {
                    _buyerRating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _buyerCommentController,
                decoration: const InputDecoration(
                  labelText: 'Comentario sobre el comprador (opcional)',
                  hintText: '¿Cómo fue la experiencia con el comprador?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar Calificación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  final String title;
  final int rating;
  final Function(int) onRatingChanged;

  const _RatingSection({
    required this.title,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return IconButton(
              icon: Icon(
                starIndex <= rating ? Icons.star : Icons.star_border,
                size: 48,
                color: starIndex <= rating
                    ? Colors.amber
                    : theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => onRatingChanged(starIndex),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            rating > 0 ? '$rating de 5 estrellas' : 'Toca una estrella para calificar',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

