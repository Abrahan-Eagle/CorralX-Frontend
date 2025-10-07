import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/theme_provider.dart';
import 'package:zonix/profiles/providers/profile_provider.dart';
import 'package:zonix/profiles/screens/edit_profile_screen.dart';
import 'package:zonix/products/screens/product_detail_screen.dart';
import 'package:zonix/products/widgets/product_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'profile';

  @override
  void initState() {
    super.initState();
    // Cargar datos del perfil al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      profileProvider.fetchMyProfile();
      if (_activeTab == 'myListings') {
        profileProvider.fetchMyProducts();
      } else if (_activeTab == 'farms') {
        profileProvider.fetchMyRanches();
      }
    });
  }

  Future<void> _handleRefresh() async {
    final profileProvider = context.read<ProfileProvider>();
    if (_activeTab == 'profile') {
      await profileProvider.fetchMyProfile(forceRefresh: true);
    } else if (_activeTab == 'myListings') {
      await profileProvider.fetchMyProducts(refresh: true);
    } else if (_activeTab == 'farms') {
      await profileProvider.fetchMyRanches(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : double.infinity,
        ),
        child: Column(
          children: [
            // Tabs
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: isTablet ? 120 : 100,
                      child:
                          _buildTabButton('profile', 'Perfil', isTablet, theme),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    SizedBox(
                      width: isTablet ? 160 : 140,
                      child: _buildTabButton(
                          'myListings', 'Mis Publicaciones', isTablet, theme),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    SizedBox(
                      width: isTablet ? 120 : 100,
                      child: _buildTabButton(
                          'farms', 'Mis Fincas', isTablet, theme),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: theme.colorScheme.primary,
                child: _buildTabContent(isTablet, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
      String tab, String label, bool isTablet, ThemeData theme) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
        // Cargar datos del tab seleccionado si aún no están cargados
        final profileProvider = context.read<ProfileProvider>();
        if (tab == 'myListings' && profileProvider.myProducts.isEmpty) {
          profileProvider.fetchMyProducts();
        } else if (tab == 'farms' && profileProvider.myRanches.isEmpty) {
          profileProvider.fetchMyRanches();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 12 : 8,
          horizontal: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isTablet, ThemeData theme) {
    switch (_activeTab) {
      case 'myListings':
        return _buildMyListingsContent(isTablet, theme);
      case 'farms':
        return _buildFarmsContent(isTablet, theme);
      case 'profile':
      default:
        return _buildProfileContent(isTablet, theme);
    }
  }

  Widget _buildProfileContent(bool isTablet, ThemeData theme) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Estado de carga
        if (profileProvider.isLoadingMyProfile) {
          return Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          );
        }

        // Estado de error
        if (profileProvider.myProfileError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isTablet ? 64 : 48,
                  color: theme.colorScheme.error,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  profileProvider.myProfileError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                ElevatedButton(
                  onPressed: () {
                    profileProvider.fetchMyProfile(forceRefresh: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final profile = profileProvider.myProfile;

        // Estado sin perfil
        if (profile == null) {
          return Center(
            child: Text(
              'No se pudo cargar el perfil',
              style: TextStyle(
                color: theme.colorScheme.onBackground,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          );
        }

        // Renderizar perfil
        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            children: [
              // Profile info card
              Container(
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                ),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: isTablet ? 80 : 64,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      backgroundImage: profile.photoUsers != null
                          ? CachedNetworkImageProvider(profile.photoUsers!)
                          : null,
                      child: profile.photoUsers == null
                          ? Icon(
                              Icons.person,
                              size: isTablet ? 80 : 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    SizedBox(height: isTablet ? 20 : 16),

                    // Nombre
                    Text(
                      profile.fullName,
                      style: TextStyle(
                        fontSize: isTablet ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 10 : 8),

                    // Rating y verificado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (profile.isVerified) ...[
                          Icon(
                            Icons.verified,
                            color: theme.colorScheme.primary,
                            size: isTablet ? 24 : 20,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                        ],
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: isTablet ? 24 : 20,
                        ),
                        SizedBox(width: isTablet ? 6 : 4),
                        Text(
                          profile.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: isTablet ? 10 : 8),
                        Text(
                          '(${profile.ratingsCount} ${profile.ratingsCount == 1 ? "opinión" : "opiniones"})',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ],
                    ),

                    // Premium badge
                    if (profile.isPremiumSeller) ...[
                      SizedBox(height: isTablet ? 12 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.amber.shade700
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: isTablet ? 20 : 16,
                            ),
                            SizedBox(width: isTablet ? 6 : 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Ubicación
                    if (profile.primaryAddress != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: isTablet ? 20 : 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: isTablet ? 6 : 4),
                          Text(
                            profile.primaryAddress!.formattedLocation,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                    ],

                    // Miembro desde
                    Text(
                      'Miembro desde: ${DateFormat('MMMM yyyy', 'es').format(profile.createdAt)}',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    SizedBox(height: isTablet ? 32 : 24),

                    // Botón Editar Perfil
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        // Refrescar perfil después de editar
                        if (mounted) {
                          profileProvider.fetchMyProfile(forceRefresh: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 32 : 24,
                          vertical: isTablet ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isTablet ? 30 : 25),
                        ),
                      ),
                      child: Text(
                        'Editar Perfil',
                        style: TextStyle(fontSize: isTablet ? 16 : 14),
                      ),
                    ),

                    SizedBox(height: isTablet ? 16 : 12),

                    // Botón para cambiar tema
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            themeProvider.toggleTheme();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 24,
                              vertical: isTablet ? 16 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(isTablet ? 30 : 25),
                            ),
                          ),
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            size: isTablet ? 20 : 18,
                          ),
                          label: Text(
                            themeProvider.isDarkMode
                                ? 'Modo Claro'
                                : 'Modo Oscuro',
                            style: TextStyle(fontSize: isTablet ? 16 : 14),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 32 : 24),

              // Métricas del vendedor
              Consumer<ProfileProvider>(
                builder: (context, metricsProvider, child) {
                  // Cargar métricas si no están cargadas
                  if (metricsProvider.metrics == null && 
                      !metricsProvider.isLoadingMetrics &&
                      metricsProvider.metricsError == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      metricsProvider.fetchMetrics();
                    });
                  }

                  // Mostrar loading
                  if (metricsProvider.isLoadingMetrics) {
                    return Container(
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  }

                  // Mostrar error
                  if (metricsProvider.metricsError != null) {
                    return SizedBox.shrink();
                  }

                  final metrics = metricsProvider.metrics;
                  if (metrics == null) return SizedBox.shrink();

                  return Container(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          'Estadísticas',
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: isTablet ? 20 : 16),

                        // Grid de métricas
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: isTablet ? 16 : 12,
                          crossAxisSpacing: isTablet ? 16 : 12,
                          childAspectRatio: isTablet ? 1.5 : 1.3,
                          children: [
                            _buildMetricCard(
                              icon: Icons.inventory_2,
                              iconColor: theme.colorScheme.primary,
                              label: 'Publicaciones',
                              value: metrics['total_products']?.toString() ?? '0',
                              theme: theme,
                              isTablet: isTablet,
                            ),
                            _buildMetricCard(
                              icon: Icons.check_circle,
                              iconColor: Colors.green,
                              label: 'Activas',
                              value: metrics['active_products']?.toString() ?? '0',
                              theme: theme,
                              isTablet: isTablet,
                            ),
                            _buildMetricCard(
                              icon: Icons.visibility,
                              iconColor: Colors.blue,
                              label: 'Vistas',
                              value: _formatNumber(metrics['total_views'] ?? 0),
                              theme: theme,
                              isTablet: isTablet,
                            ),
                            _buildMetricCard(
                              icon: Icons.favorite,
                              iconColor: Colors.red,
                              label: 'Favoritos',
                              value: metrics['total_favorites']?.toString() ?? '0',
                              theme: theme,
                              isTablet: isTablet,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: isTablet ? 32 : 28,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isTablet ? 4 : 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildMyListingsContent(bool isTablet, ThemeData theme) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Estado de carga
        if (profileProvider.isLoadingMyProducts) {
          return Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          );
        }

        // Estado de error
        if (profileProvider.myProductsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isTablet ? 64 : 48,
                  color: theme.colorScheme.error,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  profileProvider.myProductsError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                ElevatedButton(
                  onPressed: () {
                    profileProvider.fetchMyProducts(refresh: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Estado vacío
        if (profileProvider.myProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: isTablet ? 80 : 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  'No tienes publicaciones aún',
                  style: TextStyle(
                    color: theme.colorScheme.onBackground,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  'Crea tu primera publicación para empezar',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          );
        }

        // Lista de productos
        return GridView.builder(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 2 : 1,
            mainAxisSpacing: isTablet ? 20 : 16,
            crossAxisSpacing: isTablet ? 20 : 16,
            childAspectRatio: isTablet ? 1.2 : 1.5,
          ),
          itemCount: profileProvider.myProducts.length,
          itemBuilder: (context, index) {
            final product = profileProvider.myProducts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailScreen(productId: product.id),
                  ),
                );
              },
              child: ProductCard(product: product),
            );
          },
        );
      },
    );
  }

  Widget _buildFarmsContent(bool isTablet, ThemeData theme) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Estado de carga
        if (profileProvider.isLoadingMyRanches) {
          return Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          );
        }

        // Estado de error
        if (profileProvider.myRanchesError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isTablet ? 64 : 48,
                  color: theme.colorScheme.error,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  profileProvider.myRanchesError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                ElevatedButton(
                  onPressed: () {
                    profileProvider.fetchMyRanches(forceRefresh: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Contenido
        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            children: [
              // Botón agregar nueva finca
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Agregar Finca - Próximamente'),
                    ),
                  );
                },
                icon: Icon(Icons.add, size: isTablet ? 24 : 20),
                label: Text(
                  'Agregar Nueva Finca',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 32 : 24),

              // Estado vacío
              if (profileProvider.myRanches.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: isTablet ? 80 : 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        'No tienes fincas registradas',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Text(
                        'Agrega tu primera finca para comenzar',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // Lista de fincas
              ...profileProvider.myRanches.map((ranch) {
                return Container(
                  margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: isTablet ? 6 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icono
                      Container(
                        width: isTablet ? 80 : 64,
                        height: isTablet ? 80 : 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(isTablet ? 12 : 8),
                        ),
                        child: Icon(
                          Icons.home,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: isTablet ? 40 : 32,
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ranch.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: isTablet ? 18 : 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (ranch.isPrimary)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 10 : 8,
                                      vertical: isTablet ? 4 : 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Principal',
                                      style: TextStyle(
                                        fontSize: isTablet ? 12 : 10,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 6 : 4),
                            Text(
                              'RIF: ${ranch.taxId}',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (ranch.description != null) ...[
                              SizedBox(height: isTablet ? 6 : 4),
                              Text(
                                ranch.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Botones
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Editar Finca - Próximamente'),
                                ),
                              );
                            },
                            icon: Icon(Icons.edit, size: isTablet ? 24 : 20),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.5),
                              padding: EdgeInsets.all(isTablet ? 12 : 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
