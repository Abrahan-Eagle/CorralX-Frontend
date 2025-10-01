import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/filters_modal.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar productos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
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
      backgroundColor: const Color(0xFFFCFDF7),
      body: Stack(
        children: [
          // Content
          Positioned.fill(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading &&
                    productProvider.products.isEmpty) {
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

                if (productProvider.products.isEmpty) {
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
                        // Lista de productos
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: productProvider.products.length,
                          itemBuilder: (context, index) {
                            final product = productProvider.products[index];
                            return ProductCard(
                              product: product,
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
                              onFavorite: () {
                                // TODO: Implementar favoritos
                                productProvider.toggleFavorite(product.id);
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

          // Botón de filtros minimalista
          Positioned(
            top: isTablet ? 24 : 20,
            right: isTablet ? 24 : 20,
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                final activeFiltersCount = productProvider.activeFiltersCount;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showFiltersModal,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 12 : 10),
                        child: Stack(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: isTablet ? 24 : 22,
                              color: Colors.grey[700],
                            ),
                            if (activeFiltersCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF386A20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '$activeFiltersCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
            color: const Color(0xFF082100),
          ),
        ),
        backgroundColor: const Color(0xFFB7F399),
        deleteIcon: Icon(
          Icons.close,
          size: isTablet ? 16 : 14,
          color: const Color(0xFF082100),
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
