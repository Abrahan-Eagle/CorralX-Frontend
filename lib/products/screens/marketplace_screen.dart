import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/advertisement_card.dart';
import '../widgets/filters_modal.dart';
import '../models/advertisement.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar productos y anuncios al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.fetchProducts();
      provider.fetchAdvertisements();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final currentFilters = context.read<ProductProvider>().currentFilters;
    currentFilters['search'] =
        _searchController.text.isEmpty ? null : _searchController.text;
    context.read<ProductProvider>().applyFilters(currentFilters);
  }

  void _showFiltersModal() {
    showDialog(
      context: context,
      builder: (context) => FiltersModal(
        currentFilters: context.read<ProductProvider>().currentFilters,
        onApplyFilters: (filters) {
          context.read<ProductProvider>().applyFilters(filters);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Content
          Positioned.fill(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if ((productProvider.isLoading || productProvider.isLoadingAdvertisements) &&
                    productProvider.marketplaceItems.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (productProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar productos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => productProvider.refreshProducts(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (productProvider.marketplaceItems.isEmpty &&
                    !productProvider.isLoading &&
                    !productProvider.isLoadingAdvertisements) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta ajustar los filtros o busca algo diferente',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => productProvider.refreshProducts(),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo de búsqueda con botón
                        Container(
                          margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Buscar por raza, tipo...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Consumer<ProductProvider>(
                                      builder:
                                          (context, productProvider, child) {
                                        final activeFiltersCount =
                                            productProvider.activeFiltersCount;
                                        return GestureDetector(
                                          onTap: _showFiltersModal,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.tune_rounded,
                                                  color: Colors.grey[600],
                                                  size: 20,
                                                ),
                                                if (activeFiltersCount > 0)
                                                  Positioned(
                                                    right: -2,
                                                    top: -2,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 14,
                                                        minHeight: 14,
                                                      ),
                                                      child: Text(
                                                        '$activeFiltersCount',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 20 : 16,
                                      vertical: isTablet ? 16 : 12,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // Solo actualizar el estado local, no aplicar filtros inmediatamente
                                    setState(() {
                                      // El campo se actualiza automáticamente
                                    });
                                  },
                                  onSubmitted: (value) {
                                    _performSearch();
                                  },
                                ),
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              SizedBox(
                                height: isTablet ? 56 : 48, // Altura fija para coincidir con TextField
                                child: ElevatedButton(
                                onPressed: _performSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 20 : 16,
                                      vertical: 0, // Padding vertical 0 porque usamos altura fija
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Icon(
                                  Icons.search,
                                  size: isTablet ? 24 : 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lista de productos y anuncios mezclados
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: productProvider.marketplaceItems.length,
                          itemBuilder: (context, index) {
                            final item = productProvider.marketplaceItems[index];

                            // Si es un anuncio
                            if (item.isAdvertisement) {
                              final ad = item.item as Advertisement;

                              // Si es producto patrocinado
                              if (ad.isSponsoredProduct) {
                                // Intentar obtener el producto asociado
                                final product = productProvider.getProductForSponsoredAd(ad);
                                
                                return SponsoredProductCard(
                                  advertisement: ad,
                                  product: product,
                                  isFavorite: product != null
                                      ? productProvider.favoriteProducts
                                          .any((fav) => fav.id == product.id)
                                      : false,
                                  onTap: () {
                                    if (product != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            productId: product.id,
                                            product: product,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onFavorite: () async {
                                    if (product != null) {
                                      await productProvider.toggleFavorite(product.id);
                                    }
                                  },
                                  onAdClick: () {
                                    productProvider.registerAdvertisementClick(ad);
                                  },
                                );
                              } else {
                                // Es publicidad externa
                                return ExternalAdCard(
                                  advertisement: ad,
                                  onAdClick: () {
                                    productProvider.registerAdvertisementClick(ad);
                                  },
                                );
                              }
                            }

                            // Si es un producto normal
                            final product = item.item as Product;
                            final isFavorite = productProvider.favoriteProducts
                                .any((fav) => fav.id == product.id);

                            return ProductCard(
                              product: product,
                              isFavorite: isFavorite,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      productId: product.id,
                                      product: product,
                                    ),
                                  ),
                                );
                              },
                              onFavorite: () async {
                                final wasInFavorites = isFavorite;
                                await productProvider.toggleFavorite(product.id);

                                // Mostrar mensaje de confirmación
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          wasInFavorites
                                              ? Icons.heart_broken
                                              : Icons.favorite,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            wasInFavorites
                                                ? 'Removido de favoritos'
                                                : 'Agregado a favoritos',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: wasInFavorites
                                        ? Colors.grey[700]
                                        : Colors.green[700],
                                    behavior: SnackBarBehavior
                                        .fixed, // ✅ Fixed para evitar overflow
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // Botón para cargar más productos
                        if (productProvider.hasMorePages &&
                            !productProvider.isLoading)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: () =>
                                  productProvider.loadMoreProducts(),
                              child: const Text('Cargar más productos'),
                            ),
                          ),

                        if (productProvider.isLoading &&
                            productProvider.products.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(
      String label, VoidCallback onRemove, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(right: isTablet ? 8 : 6),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 10,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        deleteIcon: Icon(
          Icons.close,
          size: isTablet ? 16 : 14,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        onDeleted: onRemove,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 8 : 6,
          vertical: isTablet ? 4 : 2,
        ),
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'Todos':
        return 'Todos';
      case 'lechero':
        return 'Lechero';
      case 'engorde':
        return 'Engorde';
      case 'padrote':
        return 'Padrote';
      case 'reproductor':
        return 'Reproductor';
      case 'mixto':
        return 'Mixto';
      default:
        return type;
    }
  }

  String _getLocationDisplayName(String location) {
    switch (location) {
      case 'Todos':
        return 'Todos';
      case 'Toda Venezuela':
        return 'Toda Venezuela';
      case 'carabobo':
        return 'Carabobo';
      case 'aragua':
        return 'Aragua';
      case 'miranda':
        return 'Miranda';
      case 'zulia':
        return 'Zulia';
      case 'merida':
        return 'Mérida';
      case 'tachira':
        return 'Táchira';
      case 'lara':
        return 'Lara';
      case 'falcon':
        return 'Falcón';
      case 'barinas':
        return 'Barinas';
      case 'portuguesa':
        return 'Portuguesa';
      case 'guarico':
        return 'Guárico';
      case 'cojedes':
        return 'Cojedes';
      case 'apure':
        return 'Apure';
      case 'anzoategui':
        return 'Anzoátegui';
      case 'monagas':
        return 'Monagas';
      case 'sucre':
        return 'Sucre';
      case 'delta_amacuro':
        return 'Delta Amacuro';
      case 'amazonas':
        return 'Amazonas';
      case 'bolivar':
        return 'Bolívar';
      case 'nueva_esparta':
        return 'Nueva Esparta';
      case 'vargas':
        return 'Vargas';
      case 'distrito_capital':
        return 'Distrito Capital';
      default:
        return location;
    }
  }

  Widget _buildCattleCard(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4ED),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isTablet ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isTablet ? 20 : 16),
                ),
                color: Colors.grey,
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: isTablet ? 64 : 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 2 : 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brahman Rojo',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 1 : 0),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isTablet ? 14 : 12,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          size: isTablet ? 18 : 16,
                        ),
                      ),
                      SizedBox(width: isTablet ? 10 : 8),
                      Expanded(
                        child: Text(
                          'Agropecuaria El Futuro',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.verified,
                        size: isTablet ? 18 : 16,
                        color: const Color(0xFF386A20),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Ver Detalles',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF386A20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
