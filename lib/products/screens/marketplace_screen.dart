import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'Todos';
  String _selectedType = 'Todos';

  @override
  void initState() {
    super.initState();
    // Cargar productos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final productProvider = context.read<ProductProvider>();
    final filters = <String, String>{};

    if (_selectedLocation != 'Todos') {
      filters['location'] = _selectedLocation;
    }

    if (_selectedType != 'Todos') {
      filters['type'] = _selectedType;
    }

    if (_searchController.text.isNotEmpty) {
      filters['search'] = _searchController.text;
    }

    productProvider.applyFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFCFDF7),
              border: Border(
                bottom: BorderSide(color: Color(0xFF74796D), width: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por raza, tipo o ubicación...',
                    filled: true,
                    fillColor: const Color(0xFFF4F4ED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, size: isTablet ? 24 : 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 16 : 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _applyFilters();
                  },
                ),
                SizedBox(height: isTablet ? 16 : 12),
                // Location filter and market pulse button
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF4F4ED),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 12 : 8,
                          ),
                        ),
                        value: _selectedLocation,
                        items: const [
                          DropdownMenuItem(
                              value: 'Todos', child: Text('Toda Venezuela')),
                          DropdownMenuItem(
                              value: 'carabobo', child: Text('Carabobo')),
                          DropdownMenuItem(
                              value: 'aragua', child: Text('Aragua')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value ?? 'Todos';
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.insights, size: isTablet ? 20 : 16),
                      label: Text('Mercado',
                          style: TextStyle(fontSize: isTablet ? 16 : 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9E7CA),
                        foregroundColor: const Color(0xFF131F0D),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isTablet ? 12 : 8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 12 : 8,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 12),
                // Filter buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 2),
                    child: Row(
                      children: [
                        _buildFilterChip(
                            'Todos', _selectedType == 'Todos', isTablet, () {
                          setState(() {
                            _selectedType = 'Todos';
                          });
                          _applyFilters();
                        }),
                        SizedBox(width: isTablet ? 12 : 8),
                        _buildFilterChip(
                            'Lechero', _selectedType == 'lechero', isTablet,
                            () {
                          setState(() {
                            _selectedType = 'lechero';
                          });
                          _applyFilters();
                        }),
                        SizedBox(width: isTablet ? 12 : 8),
                        _buildFilterChip(
                            'Engorde', _selectedType == 'engorde', isTablet,
                            () {
                          setState(() {
                            _selectedType = 'engorde';
                          });
                          _applyFilters();
                        }),
                        SizedBox(width: isTablet ? 12 : 8),
                        _buildFilterChip(
                            'Padrote', _selectedType == 'padrote', isTablet,
                            () {
                          setState(() {
                            _selectedType = 'padrote';
                          });
                          _applyFilters();
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
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
                        // Featured section
                        Text(
                          'Productos Disponibles',
                          style: TextStyle(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

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
                                // TODO: Navegar a detalle del producto
                                productProvider.fetchProductDetail(product.id);
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isActive, bool isTablet, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontSize: isTablet ? 16 : 14),
      ),
      selected: isActive,
      onSelected: (selected) => onTap(),
      selectedColor: const Color(0xFFB7F399),
      checkmarkColor: const Color(0xFF082100),
      backgroundColor: const Color(0xFFF4F4ED),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 4,
      ),
    );
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
