import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/product_detail_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Product? product;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = true;
  Product? _product;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    // Si ya tenemos el producto, usarlo directamente
    if (widget.product != null) {
      setState(() {
        _product = widget.product;
        _isLoading = false;
      });
      return;
    }

    // Si no, buscar en la lista de productos
    final existingProduct = productProvider.products
        .where((p) => p.id == widget.productId)
        .firstOrNull;

    if (existingProduct != null) {
      setState(() {
        _product = existingProduct;
        _isLoading = false;
      });
      return;
    }

    // Si no está en la lista, cargarlo desde la API
    try {
      await productProvider.fetchProductDetail(widget.productId);
      final product = productProvider.selectedProduct;
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el producto: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Cargando...',
            style: TextStyle(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Error',
            style: TextStyle(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
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
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Producto no encontrado',
            style: TextStyle(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'El producto solicitado no existe.',
            style: TextStyle(color: theme.colorScheme.onBackground),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detalles del Ganado',
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        actions: [
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              final isFavorite =
                  productProvider.favorites.contains(_product!.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  productProvider.toggleFavorite(_product!.id);
                },
              );
            },
          ),
        ],
      ),
      body: ProductDetailWidget(
        product: _product!,
        isTablet: isTablet,
      ),
    );
  }
}
