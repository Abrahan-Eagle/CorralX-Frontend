import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../profiles/models/ranch.dart';
import '../providers/ranch_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/chat_screen.dart';
import '../../profiles/providers/profile_provider.dart';
import '../../shared/screens/pdf_viewer_screen.dart';
import '../../products/models/product.dart' hide Ranch;
import '../../products/screens/product_detail_screen.dart';
import '../../products/providers/product_provider.dart';
import '../../config/app_config.dart';
import 'package:corralx/shared/utils/image_utils.dart';

class PublicRanchDetailScreen extends StatefulWidget {
  final Ranch ranch;

  const PublicRanchDetailScreen({
    super.key,
    required this.ranch,
  });

  @override
  State<PublicRanchDetailScreen> createState() =>
      _PublicRanchDetailScreenState();
}

class _PublicRanchDetailScreenState extends State<PublicRanchDetailScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Product> _ranchProducts = [];
  bool _isLoadingProducts = false;
  bool _hasErrorProducts = false;

  @override
  void initState() {
    super.initState();
    _loadRanchProducts();
    // Cargar favoritos si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      if (productProvider.favoriteProducts.isEmpty &&
          !productProvider.isLoadingFavorites) {
        productProvider.fetchFavorites(refresh: true);
      }
    });
  }

  Future<void> _loadRanchProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProducts = true;
      _hasErrorProducts = false;
    });

    try {
      final token = await _storage.read(key: 'token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse(
          '${AppConfig.apiUrl}/api/ranches/${widget.ranch.id}/products');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (mounted) {
            setState(() {
              _ranchProducts = (data['data'] as List)
                  .map((json) => Product.fromJson(json))
                  .toList();
              _isLoadingProducts = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _hasErrorProducts = true;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print('Error cargando productos del ranch: $e');
      if (mounted) {
        setState(() {
          _hasErrorProducts = true;
          _isLoadingProducts = false;
        });
      }
    }
  }

  String _getLocationText() {
    final address = widget.ranch.address;
    if (address == null) return 'Ubicación no especificada';

    // Intentar obtener de los campos directos primero
    String cityName = address.cityName ?? address.city?['name'] ?? '';
    String stateName =
        address.stateName ?? address.city?['state']?['name'] ?? '';
    String countryName = address.countryName ??
        address.city?['state']?['country']?['name'] ??
        '';

    List<String> parts = [];
    if (cityName.isNotEmpty) parts.add(cityName);
    if (stateName.isNotEmpty) parts.add(stateName);
    if (countryName.isNotEmpty) parts.add(countryName);

    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación no especificada';
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🟢 PublicRanchDetailScreen: Construyendo pantalla para ranch: ${widget.ranch.name} (ID: ${widget.ranch.id})');
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: theme.colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detalles de la Hacienda',
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        actions: [
          Consumer<RanchProvider>(
            builder: (context, ranchProvider, child) {
              final isFavorite = ranchProvider.isFavorite(widget.ranch.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Colors.red
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  ranchProvider.toggleFavorite(widget.ranch);
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galería de imágenes (placeholder)
            _buildImageGallery(context, isTablet),

            // Contenido
            Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y badges
                  _buildTitleSection(context, theme, isTablet),
                  const SizedBox(height: 16),

                  // Información del rancho
                  if (widget.ranch.legalName != null &&
                      widget.ranch.legalName!.isNotEmpty) ...[
                    _buildDetailCard(
                      context,
                      theme,
                      isTablet,
                      icon: Icons.business,
                      label: 'Razón Social',
                      value: widget.ranch.legalName!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Ubicación completa
                  if (widget.ranch.address != null) ...[
                    _buildLocationCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Estadísticas
                  _buildStatsSection(context, theme, isTablet),
                  const SizedBox(height: 16),

                  // Descripción
                  if (widget.ranch.businessDescription != null &&
                      widget.ranch.businessDescription!.isNotEmpty) ...[
                    _buildDescriptionCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Certificaciones
                  if (widget.ranch.certifications != null &&
                      widget.ranch.certifications!.isNotEmpty) ...[
                    _buildCertificationsCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Documentos PDF
                  if (widget.ranch.documents != null &&
                      widget.ranch.documents!.isNotEmpty) ...[
                    _buildDocumentsCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Horarios de contacto
                  if (widget.ranch.contactHours != null &&
                      widget.ranch.contactHours!.isNotEmpty) ...[
                    _buildDetailCard(
                      context,
                      theme,
                      isTablet,
                      icon: Icons.access_time,
                      label: 'Horarios de Contacto',
                      value: widget.ranch.contactHours!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Políticas
                  if ((widget.ranch.deliveryPolicy != null &&
                          widget.ranch.deliveryPolicy!.isNotEmpty) ||
                      (widget.ranch.returnPolicy != null &&
                          widget.ranch.returnPolicy!.isNotEmpty)) ...[
                    _buildPoliciesCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Productos del ranch
                  if (_ranchProducts.isNotEmpty ||
                      _isLoadingProducts ||
                      _hasErrorProducts) ...[
                    _buildProductsSection(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Botón de contactar
                  _buildContactButton(context, theme, isTablet),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Obtener foto del perfil del dueño
    final profilePhoto = widget.ranch.profile?['photo_users'];
    final hasPhoto = profilePhoto != null && profilePhoto.toString().isNotEmpty;

    return Container(
      height: isTablet ? 400 : 300,
      width: double.infinity,
      decoration: BoxDecoration(
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(profilePhoto),
                fit: BoxFit.cover,
              )
            : null,
        gradient: !hasPhoto
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.surfaceVariant,
                      ]
                    : [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.primaryContainer.withOpacity(0.3),
                      ],
              )
            : null,
      ),
      child: Stack(
        children: [
          // Icono de fondo (solo si no hay foto)
          if (!hasPhoto)
            Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.agriculture,
                  size: isTablet ? 120 : 100,
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
            ),
          // Texto overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.ranch.name,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.ranch.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getLocationText(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(
      BuildContext context, ThemeData theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre de la hacienda
        Text(
          widget.ranch.name,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 12),

        // Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.ranch.isPrimary)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Principal',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.ranch.acceptsVisits)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Acepta Visitas',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationCard(
      BuildContext context, ThemeData theme, bool isTablet) {
    final address = widget.ranch.address!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ubicación',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dirección completa (campo addresses)
            if (address.addresses.isNotEmpty) ...[
              Text(
                address.addresses,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Ciudad, Estado, País
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getLocationText(),
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    ThemeData theme,
    bool isTablet, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: isTablet ? 24 : 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onBackground,
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

  Widget _buildStatsSection(
      BuildContext context, ThemeData theme, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                theme,
                isTablet,
                Icons.star,
                widget.ranch.avgRating.toStringAsFixed(1),
                'Rating',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _buildStatItem(
                theme,
                isTablet,
                Icons.shopping_bag,
                widget.ranch.totalSales.toString(),
                'Ventas',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _buildStatItem(
                theme,
                isTablet,
                Icons.inventory_2,
                (widget.ranch.productsCount ?? 0).toString(),
                'Productos',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    bool isTablet,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: isTablet ? 24 : 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(
      BuildContext context, ThemeData theme, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: theme.colorScheme.primary,
                  size: isTablet ? 24 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.ranch.businessDescription!,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsCard(
      BuildContext context, ThemeData theme, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: theme.colorScheme.primary,
                  size: isTablet ? 24 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Certificaciones',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.ranch.certifications!.map((cert) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cert,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesCard(
      BuildContext context, ThemeData theme, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.policy,
                  color: theme.colorScheme.primary,
                  size: isTablet ? 24 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Políticas',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
            if (widget.ranch.deliveryPolicy != null &&
                widget.ranch.deliveryPolicy!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entrega',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.ranch.deliveryPolicy!,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (widget.ranch.returnPolicy != null &&
                widget.ranch.returnPolicy!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.assignment_return,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Devolución',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.ranch.returnPolicy!,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: theme.colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildContactButton(
      BuildContext context, ThemeData theme, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 56 : 48,
      child: ElevatedButton.icon(
        onPressed: () => _showContactDialog(context),
        icon: const Icon(Icons.message),
        label: Text(
          'Contactar Vendedor',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildProductsSection(
      BuildContext context, ThemeData theme, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: theme.colorScheme.primary,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_ranchProducts.length}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingProducts)
              const Center(child: CircularProgressIndicator())
            else if (_hasErrorProducts)
              Center(
                child: Text(
                  'Error al cargar los productos del rancho.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else if (_ranchProducts.isEmpty)
              Center(
                child: Text(
                  'No hay productos disponibles para este rancho.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.73,
                    children: _ranchProducts.map((product) {
                      // Verificar si el producto está en favoritos (usar Set para mejor rendimiento)
                      final isFavorite =
                          productProvider.favorites.contains(product.id);

                      return _buildCompactProductCard(
                        context: context,
                        product: product,
                        isFavorite: isFavorite,
                        productProvider: productProvider,
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    final profileProvider = context.read<ProfileProvider>();

    // Obtener ID del perfil del dueño del rancho
    final sellerId = widget.ranch.profileId;
    final currentProfileId = profileProvider.myProfile?.id ?? 0;

    if (sellerId == currentProfileId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes contactarte a ti mismo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Abrir o crear conversación (contexto: hacienda)
      final conversation = await chatProvider.openConversation(
        sellerId,
        ranchId: widget.ranch.id, // Contexto de hacienda
      );

      if (!context.mounted) return;

      // Cerrar loading
      Navigator.pop(context);

      if (conversation != null) {
        // Enviar mensaje automático
        final initialMessage =
            'Hola, me interesa tu hacienda "${widget.ranch.name}"';
        await chatProvider.sendMessage(conversation.id, initialMessage);

        if (!context.mounted) return;

        // Navegar al chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversationId: conversation.id),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir la conversación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      // Cerrar loading si está abierto
      Navigator.of(context)
          .popUntil((route) => route.isFirst || !route.isActive);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDocumentsCard(
      BuildContext context, ThemeData theme, bool isTablet) {
    final documents = widget.ranch.documents ?? [];

    if (documents.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: theme.colorScheme.primary,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Documentos PDF',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${documents.length}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...documents.map((doc) {
              final documentUrl = doc['document_url']?.toString() ?? '';
              final certificationType = doc['certification_type']?.toString();
              final originalFilename =
                  doc['original_filename']?.toString() ?? 'Documento.pdf';
              final fileSize = doc['file_size'] as int?;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (certificationType != null &&
                              certificationType.isNotEmpty)
                            Text(
                              certificationType,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onBackground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (certificationType != null &&
                              certificationType.isNotEmpty)
                            const SizedBox(height: 4),
                          Text(
                            originalFilename,
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (fileSize != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatFileSize(fileSize),
                              style: TextStyle(
                                fontSize: isTablet ? 11 : 10,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openDocument(
                        context,
                        documentUrl,
                        title: certificationType ?? originalFilename,
                      ),
                      icon: Icon(
                        Icons.open_in_new,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Abrir documento',
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _openDocument(BuildContext context, String url,
      {String? title}) async {
    if (url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL del documento no disponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Navegar a la pantalla de visor de PDF embebido
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: url,
          title: title,
        ),
      ),
    );
  }

  Widget _buildCompactProductCard({
    required BuildContext context,
    required Product product,
    required bool isFavorite,
    required ProductProvider productProvider,
  }) {
    final theme = Theme.of(context);
    final imageUrl =
        product.images.isNotEmpty ? product.images.first.fileUrl : '';

    return GestureDetector(
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
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey[300],
                  child: imageUrl.isNotEmpty && !isBlockedImageHost(imageUrl)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(
                            child: buildImageFallback(
                              icon: Icons.image_not_supported,
                              backgroundColor: Colors.grey[300],
                              iconColor: Colors.grey[600],
                              iconSize: 40,
                            ),
                          ),
                        )
                      : Center(
                          child: buildImageFallback(
                            icon: Icons.image,
                            backgroundColor: Colors.grey[300],
                            iconColor: Colors.grey[500],
                            iconSize: 40,
                          ),
                        ),
                ),
                // Botón de favorito
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await productProvider.toggleFavorite(product.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Título y precio
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Precio
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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
