import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profiles/models/ranch.dart';
import '../providers/ranch_provider.dart';

class PublicRanchDetailScreen extends StatelessWidget {
  final Ranch ranch;

  const PublicRanchDetailScreen({
    super.key,
    required this.ranch,
  });

  String _getLocationText() {
    final address = ranch.address;
    if (address == null) return 'Ubicación no especificada';

    // Intentar obtener de los campos directos primero
    String cityName = address.cityName ?? address.city?['name'] ?? '';
    String stateName = address.stateName ?? address.city?['state']?['name'] ?? '';
    String countryName = address.countryName ?? address.city?['state']?['country']?['name'] ?? '';

    List<String> parts = [];
    if (cityName.isNotEmpty) parts.add(cityName);
    if (stateName.isNotEmpty) parts.add(stateName);
    if (countryName.isNotEmpty) parts.add(countryName);

    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación no especificada';
  }

  @override
  Widget build(BuildContext context) {
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
              final isFavorite = ranchProvider.isFavorite(ranch.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  ranchProvider.toggleFavorite(ranch);
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
                  if (ranch.legalName != null && ranch.legalName!.isNotEmpty) ...[
                    _buildDetailCard(
                      context,
                      theme,
                      isTablet,
                      icon: Icons.business,
                      label: 'Razón Social',
                      value: ranch.legalName!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Ubicación completa
                  if (ranch.address != null) ...[
                    _buildLocationCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Estadísticas
                  _buildStatsSection(context, theme, isTablet),
                  const SizedBox(height: 16),

                  // Descripción
                  if (ranch.businessDescription != null &&
                      ranch.businessDescription!.isNotEmpty) ...[
                    _buildDescriptionCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Certificaciones
                  if (ranch.certifications != null &&
                      ranch.certifications!.isNotEmpty) ...[
                    _buildCertificationsCard(context, theme, isTablet),
                    const SizedBox(height: 16),
                  ],

                  // Horarios de contacto
                  if (ranch.contactHours != null &&
                      ranch.contactHours!.isNotEmpty) ...[
                    _buildDetailCard(
                      context,
                      theme,
                      isTablet,
                      icon: Icons.access_time,
                      label: 'Horarios de Contacto',
                      value: ranch.contactHours!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Políticas
                  if ((ranch.deliveryPolicy != null &&
                          ranch.deliveryPolicy!.isNotEmpty) ||
                      (ranch.returnPolicy != null &&
                          ranch.returnPolicy!.isNotEmpty)) ...[
                    _buildPoliciesCard(context, theme, isTablet),
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
    final profilePhoto = ranch.profile?['photo_users'];
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
                    ranch.name,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (ranch.address != null) ...[
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

  Widget _buildTitleSection(BuildContext context, ThemeData theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre de la hacienda
        Text(
          ranch.name,
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
            if (ranch.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            if (ranch.acceptsVisits)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildLocationCard(BuildContext context, ThemeData theme, bool isTablet) {
    final address = ranch.address!;
    
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

  Widget _buildStatsSection(BuildContext context, ThemeData theme, bool isTablet) {
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
                ranch.avgRating.toStringAsFixed(1),
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
                ranch.totalSales.toString(),
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
                '0', // TODO: Implementar contador de productos
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

  Widget _buildDescriptionCard(BuildContext context, ThemeData theme, bool isTablet) {
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
              ranch.businessDescription!,
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

  Widget _buildCertificationsCard(BuildContext context, ThemeData theme, bool isTablet) {
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
              children: ranch.certifications!.map((cert) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildPoliciesCard(BuildContext context, ThemeData theme, bool isTablet) {
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
            if (ranch.deliveryPolicy != null && ranch.deliveryPolicy!.isNotEmpty) ...[
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
                          ranch.deliveryPolicy!,
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
            if (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty) ...[
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
                          ranch.returnPolicy!,
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

  Widget _buildContactButton(BuildContext context, ThemeData theme, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 56 : 48,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Implementar función de contacto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Función de contacto próximamente...'),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        },
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
}
