import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corralx/products/providers/product_provider.dart';
import 'package:corralx/products/screens/product_detail_screen.dart';
import 'package:corralx/products/models/product.dart';
import 'package:corralx/shared/utils/image_utils.dart';

/// FavoritesScreen - Pantalla de productos favoritos del usuario
///
/// Muestra una grid de productos que el usuario ha marcado como favoritos.
/// Características:
/// - Grid responsive (2/3/4 columnas según dispositivo)
/// - Pull-to-refresh para actualizar
/// - Loading state mientras carga
/// - Empty state si no hay favoritos
/// - Navegación a ProductDetail al hacer tap
/// - Botón de favorito para remover directamente
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar favoritos al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 FavoritesScreen: Iniciando carga de favoritos...');
      final provider = Provider.of<ProductProvider>(context, listen: false);
      // Forzar refresh si no hay favoritos cargados
      if (provider.favoriteProducts.isEmpty) {
        provider.fetchFavorites(refresh: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar favoritos si se navega desde otra pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (provider.favoriteProducts.isEmpty && !provider.isLoadingFavorites) {
        provider.fetchFavorites(refresh: true);
      }
    });
  }

  Future<void> _onRefresh() async {
    print('🔄 FavoritesScreen: Pull-to-refresh activado');
    await Provider.of<ProductProvider>(context, listen: false)
        .fetchFavorites(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: Text(
          'Mis Favoritos',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Loading state (primera carga)
          if (productProvider.isLoadingFavorites &&
              productProvider.favoriteProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando tus favoritos...',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (productProvider.favoriteProducts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No tienes favoritos guardados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Marca productos como favoritos\ndesde el marketplace para verlos aquí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.outline,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        print('📱 Usuario presionó Explorar Marketplace');
                        // Guardar el índice del marketplace (0) en SharedPreferences
                        // para que MainRouter se posicione en el marketplace al volver
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('bottomNavIndex', 0);
                        // Volver al MainRouter (que cargará el índice guardado)
                        if (mounted) {
                          Navigator.of(context)
                              .pop(0); // Pasar 0 como resultado
                        }
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Ir al Marketplace'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Lista de favoritos
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: theme.colorScheme.primary,
            child: GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: isTablet ? 20 : 16,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
                childAspectRatio: 0.75,
                crossAxisSpacing: isTablet ? 16 : 12,
                mainAxisSpacing: isTablet ? 16 : 12,
              ),
              itemCount: productProvider.favoriteProducts.length +
                  (productProvider.isLoadingFavorites ? 1 : 0),
              itemBuilder: (context, index) {
                // Loader al final si está cargando más
                if (index == productProvider.favoriteProducts.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }

                final product = productProvider.favoriteProducts[index];
                return _buildFavoriteCard(
                  context,
                  product,
                  productProvider,
                  isTablet,
                  theme,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    Product product,
    ProductProvider provider,
    bool isTablet,
    ThemeData theme,
  ) {
    final primaryImage =
        product.images.isNotEmpty ? product.images.first.fileUrl : null;

    return GestureDetector(
      onTap: () {
        print('📱 Navegando a detalle del producto: ${product.id}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con botón de favorito
            Expanded(
              child: Stack(
                children: [
                  // Imagen del producto
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: theme.colorScheme.surfaceVariant,
                    ),
                    child: primaryImage != null && !isBlockedImageHost(primaryImage)
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              primaryImage,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: theme.colorScheme.outline,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.pets,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                  ),
                  // Botón de favorito (para remover)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          print(
                              '❤️ Toggle favorito desde FavoritesScreen: ${product.id}');
                          try {
                            await provider.toggleFavorite(product.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Producto removido de favoritos'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: theme.colorScheme.secondary,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Información del producto
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título/Raza
                  Text(
                    product.breed,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tipo
                  Text(
                    product.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Hacienda y verificación
                  if (product.ranch != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.ranch!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // Precio
                  Text(
                    '${product.currency} \$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Cantidad
                  Text(
                    '${product.quantity} ${product.quantity == 1 ? "unidad" : "unidades"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
