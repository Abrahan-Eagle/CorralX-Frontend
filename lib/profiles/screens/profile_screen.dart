import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/user_provider.dart';
import 'package:zonix/profiles/providers/profile_provider.dart';
import 'package:zonix/profiles/screens/edit_profile_screen.dart';
import 'package:zonix/profiles/screens/edit_ranch_screen.dart';
import 'package:zonix/profiles/screens/create_ranch_screen.dart';
import 'package:zonix/profiles/screens/ranch_detail_screen.dart';
import 'package:zonix/profiles/services/ranch_service.dart';
import 'package:zonix/products/providers/product_provider.dart';
import 'package:zonix/products/screens/product_detail_screen.dart';
import 'package:zonix/products/screens/edit_product_screen.dart';
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
        actions: [
          // Icono Perfil
          _buildHeaderIcon(
            icon: Icons.person_outline,
            isActive: _activeTab == 'profile',
            onTap: () => _switchTab('profile'),
            theme: theme,
            isTablet: isTablet,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          // Icono Mis Publicaciones
          _buildHeaderIcon(
            icon: Icons.inventory_2_outlined,
            isActive: _activeTab == 'myListings',
            onTap: () => _switchTab('myListings'),
            theme: theme,
            isTablet: isTablet,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          // Icono Mis Fincas
          _buildHeaderIcon(
            icon: Icons.home_outlined,
            isActive: _activeTab == 'farms',
            onTap: () => _switchTab('farms'),
            theme: theme,
            isTablet: isTablet,
          ),
          SizedBox(width: isTablet ? 16 : 12),
        ],
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : double.infinity,
        ),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: theme.colorScheme.primary,
          child: _buildTabContent(isTablet, theme),
        ),
      ),
    );
  }

  void _switchTab(String tab) {
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
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 12 : 10),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: isTablet ? 28 : 24,
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
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
              // Profile info card - Diseño Minimalista Moderno
              Container(
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar con borde sólido
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: isTablet ? 76 : 60,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        backgroundImage: profile.photoUsers != null
                            ? CachedNetworkImageProvider(profile.photoUsers!)
                            : null,
                        child: profile.photoUsers == null
                            ? Icon(
                                Icons.person,
                                size: isTablet ? 76 : 60,
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
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

                    // Bio
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        profile.bio!,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: isTablet ? 16 : 12),

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

                    // Premium badge - Sólido
                    if (profile.isPremiumSeller) ...[
                      SizedBox(height: isTablet ? 12 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
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

                    SizedBox(height: isTablet ? 24 : 20),

                    // Información de contacto (solo perfil propio) - Card limpia
                    Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Email
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              final email = userProvider.userEmail.isNotEmpty
                                  ? userProvider.userEmail
                                  : 'No disponible';
                              return Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: isTablet ? 20 : 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  SizedBox(width: isTablet ? 12 : 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: isTablet ? 12 : 11,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 14,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          if (profile.whatsappNumber != null &&
                              profile.whatsappNumber!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 16 : 12),
                            Divider(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2)),
                            SizedBox(height: isTablet ? 16 : 12),
                            // WhatsApp
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: isTablet ? 20 : 18,
                                  color: Colors.green,
                                ),
                                SizedBox(width: isTablet ? 12 : 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WhatsApp',
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 11,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        profile.whatsappNumber!,
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 14,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: isTablet ? 24 : 20),

                    // Notificación de cuenta no verificada
                    if (!profile.isVerified) ...[
                      Container(
                        padding: EdgeInsets.all(isTablet ? 16 : 14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(isTablet ? 16 : 12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: isTablet ? 28 : 24,
                            ),
                            SizedBox(width: isTablet ? 12 : 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cuenta no verificada',
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Verifica tu cuenta para aumentar tu credibilidad y acceder a más funciones.',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 20),
                    ],

                    SizedBox(height: isTablet ? 8 : 6),

                    // Botones de acción - Estilo minimalista
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                        icon: Icon(Icons.edit, size: isTablet ? 20 : 18),
                        label: Text(
                          'Editar Perfil',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Botón de cambiar tema eliminado - El tema ahora se ajusta automáticamente según el sistema
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
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                              value:
                                  metrics['total_products']?.toString() ?? '0',
                              theme: theme,
                              isTablet: isTablet,
                            ),
                            _buildMetricCard(
                              icon: Icons.check_circle,
                              iconColor: Colors.green,
                              label: 'Activas',
                              value:
                                  metrics['active_products']?.toString() ?? '0',
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
                              value:
                                  metrics['total_favorites']?.toString() ?? '0',
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
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono circular con fondo de color
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

  Widget _buildMinimalStat({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isTablet ? 20 : 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 11 : 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
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

        // Lista de productos con métricas y acciones
        return ListView.builder(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          itemCount: profileProvider.myProducts.length,
          itemBuilder: (context, index) {
            final product = profileProvider.myProducts[index];
            return Container(
              margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Imagen del producto
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(productId: product.id),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isTablet ? 16 : 12),
                        bottomLeft: Radius.circular(isTablet ? 16 : 12),
                      ),
                      child: product.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.images.first.fileUrl,
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              color: theme.colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.image,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),

                  // Información del producto
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            product.title,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isTablet ? 8 : 6),

                          // Raza y tipo
                          Text(
                            '${product.breed} · ${product.type}',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: isTablet ? 12 : 10),

                          // Métricas
                          Wrap(
                            spacing: isTablet ? 16 : 12,
                            runSpacing: isTablet ? 8 : 6,
                            children: [
                              // Vistas
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${product.viewsCount}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),

                              // Estado
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 10 : 8,
                                  vertical: isTablet ? 4 : 3,
                                ),
                                decoration: BoxDecoration(
                                  color: product.status == 'active'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: product.status == 'active'
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  product.status == 'active'
                                      ? 'Activo'
                                      : 'Vendido',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: product.status == 'active'
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Acciones (Editar/Eliminar)
                  Padding(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón Editar - Estilo minimalista
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              // Navegar a pantalla de edición
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProductScreen(product: product),
                                ),
                              );

                              // Si se editó exitosamente, refrescar lista
                              if (result == true && mounted) {
                                profileProvider.fetchMyProducts(refresh: true);
                              }
                            },
                            icon: Icon(
                              Icons.edit_outlined,
                              size: isTablet ? 22 : 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),

                        // Botón Eliminar - Estilo minimalista
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              // Mostrar confirmación
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminar Publicación'),
                                  content: const Text(
                                    '¿Estás seguro de que deseas eliminar esta publicación? Esta acción no se puede deshacer.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        'Eliminar',
                                        style: TextStyle(
                                            color: theme.colorScheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && mounted) {
                                // Eliminar producto
                                final productProvider =
                                    context.read<ProductProvider>();
                                final success = await productProvider
                                    .deleteProduct(product.id);

                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          '✅ Publicación eliminada exitosamente'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Refrescar lista
                                  profileProvider.fetchMyProducts(
                                      refresh: true);
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          productProvider.errorMessage ??
                                              'Error al eliminar publicación'),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              size: isTablet ? 22 : 20,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              // Botón agregar nueva finca - Mejorado
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRanchScreen(),
                        ),
                      );

                      if (result == true && mounted) {
                        // Ya se refrescó en CreateRanchScreen
                      }
                    },
                    icon: Icon(
                      Icons.add_business_outlined,
                      size: isTablet ? 24 : 20,
                    ),
                    label: Text(
                      'Agregar Nueva Finca',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 20 : 16,
                        horizontal: isTablet ? 32 : 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
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

              // Lista de fincas - Diseño minimalista profesional
              ...profileProvider.myRanches.map((ranch) {
                final isDark = theme.brightness == Brightness.dark;

                return Container(
                  margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RanchDetailScreen(ranch: ranch),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Nombre y Badge
                          Row(
                            children: [
                              // Icono minimalista
                              Container(
                                padding: EdgeInsets.all(isTablet ? 12 : 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.home_work_outlined,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: isTablet ? 24 : 20,
                                ),
                              ),
                              SizedBox(width: isTablet ? 14 : 12),

                              // Nombre y RIF
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ranch.name,
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'RIF: ${ranch.taxId}',
                                      style: TextStyle(
                                        fontSize: isTablet ? 13 : 12,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Badge Principal
                              if (ranch.isPrimary)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 10 : 8,
                                    vertical: isTablet ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Principal',
                                    style: TextStyle(
                                      fontSize: isTablet ? 11 : 10,
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Descripción
                          if (ranch.description != null &&
                              ranch.description!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 14 : 12),
                            Text(
                              ranch.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 13,
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],

                          SizedBox(height: isTablet ? 16 : 14),

                          // Divider
                          Divider(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            height: 1,
                          ),

                          SizedBox(height: isTablet ? 16 : 14),

                          // Estadísticas - Equitativamente distribuidas
                          Row(
                            children: [
                              Expanded(
                                child: _buildMinimalStat(
                                  icon: Icons.star_outline,
                                  value: ranch.avgRating.toStringAsFixed(1),
                                  label: 'Rating',
                                  theme: theme,
                                  isTablet: isTablet,
                                ),
                              ),
                              Expanded(
                                child: _buildMinimalStat(
                                  icon: Icons.shopping_bag_outlined,
                                  value: ranch.totalSales.toString(),
                                  label: 'Ventas',
                                  theme: theme,
                                  isTablet: isTablet,
                                ),
                              ),
                              Expanded(
                                child: _buildMinimalStat(
                                  icon: Icons.inventory_2_outlined,
                                  value: (ranch.productsCount ?? 0).toString(),
                                  label: 'Productos',
                                  theme: theme,
                                  isTablet: isTablet,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isTablet ? 16 : 14),

                          // Divider
                          Divider(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            height: 1,
                          ),

                          SizedBox(height: isTablet ? 16 : 14),

                          // Botones de acción - Minimalista
                          Row(
                            children: [
                              // Ver
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RanchDetailScreen(ranch: ranch),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.visibility_outlined,
                                    size: isTablet ? 18 : 16,
                                  ),
                                  label: Text(
                                    'Ver',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onSurfaceVariant,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 12 : 10,
                                    ),
                                  ),
                                ),
                              ),

                              // Divider vertical
                              Container(
                                width: 1,
                                height: isTablet ? 40 : 36,
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),

                              // Editar
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditRanchScreen(ranch: ranch),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      profileProvider.fetchMyRanches(
                                          forceRefresh: true);
                                    }
                                  },
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: isTablet ? 18 : 16,
                                  ),
                                  label: Text(
                                    'Editar',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 12 : 10,
                                    ),
                                  ),
                                ),
                              ),

                              // Divider vertical
                              Container(
                                width: 1,
                                height: isTablet ? 40 : 36,
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),

                              // Eliminar
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Eliminar Hacienda'),
                                        content: const Text(
                                          '¿Estás seguro de eliminar esta hacienda?\n\n'
                                          'No podrás eliminarla si tiene productos activos o es la única hacienda.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && mounted) {
                                      try {
                                        final result =
                                            await RanchService.deleteRanch(
                                                ranch.id);
                                        if (result['success'] == true &&
                                            mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  '✅ Hacienda eliminada exitosamente'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          profileProvider.fetchMyRanches(
                                              forceRefresh: true);
                                        } else if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(result['message'] ??
                                                  'Error al eliminar hacienda'),
                                              backgroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(e
                                                  .toString()
                                                  .replaceFirst(
                                                      'Exception: ', '')),
                                              backgroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: isTablet ? 18 : 16,
                                  ),
                                  label: Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 12 : 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
