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

    String cityName = address.city?['name'] ?? '';
    String stateName = address.city?['state']?['name'] ?? '';
    String countryName = address.city?['state']?['country']?['name'] ?? '';

    List<String> parts = [];
    if (cityName.isNotEmpty) parts.add(cityName);
    if (stateName.isNotEmpty) parts.add(stateName);
    if (countryName.isNotEmpty) parts.add(countryName);

    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación no especificada';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen de fondo (placeholder por ahora)
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Botón de favoritos
              Consumer<RanchProvider>(
                builder: (context, ranchProvider, child) {
                  final isFavorite = ranchProvider.isFavorite(ranch.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : theme.colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      ranchProvider.toggleFavorite(ranch);
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                ranch.name,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.agriculture,
                    size: 80,
                    color: theme.colorScheme.onPrimary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre legal y badges
                  _buildHeaderSection(theme),
                  const SizedBox(height: 16),

                  // Rating y estadísticas
                  _buildStatsRow(theme),
                  const SizedBox(height: 24),

                  // Descripción
                  if (ranch.businessDescription != null &&
                      ranch.businessDescription!.isNotEmpty) ...[
                    _buildSectionTitle(theme, 'Descripción'),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      theme,
                      isDark,
                      child: Text(
                        ranch.businessDescription!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Ubicación
                  _buildSectionTitle(theme, 'Ubicación'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    theme,
                    isDark,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getLocationText(),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Certificaciones
                  if (ranch.certifications != null &&
                      ranch.certifications!.isNotEmpty) ...[
                    _buildSectionTitle(theme, 'Certificaciones'),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      theme,
                      isDark,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ranch.certifications!.map((cert) {
                          return Chip(
                            avatar: Icon(
                              Icons.verified,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            label: Text(cert),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Horarios de contacto
                  if (ranch.contactHours != null &&
                      ranch.contactHours!.isNotEmpty) ...[
                    _buildSectionTitle(theme, 'Horarios de Contacto'),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      theme,
                      isDark,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ranch.contactHours!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Políticas
                  if ((ranch.deliveryPolicy != null &&
                          ranch.deliveryPolicy!.isNotEmpty) ||
                      (ranch.returnPolicy != null &&
                          ranch.returnPolicy!.isNotEmpty)) ...[
                    _buildSectionTitle(theme, 'Políticas'),
                    const SizedBox(height: 8),
                    if (ranch.deliveryPolicy != null &&
                        ranch.deliveryPolicy!.isNotEmpty)
                      _buildPolicyCard(
                        theme,
                        isDark,
                        'Política de Entrega',
                        ranch.deliveryPolicy!,
                        Icons.local_shipping,
                      ),
                    if (ranch.returnPolicy != null &&
                        ranch.returnPolicy!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPolicyCard(
                        theme,
                        isDark,
                        'Política de Devolución',
                        ranch.returnPolicy!,
                        Icons.assignment_return,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Productos del Rancho (placeholder)
                  _buildSectionTitle(theme, 'Productos Disponibles'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    theme,
                    isDark,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Próximamente: Lista de productos',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        label: const Text('Contactar'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ranch.legalName != null && ranch.legalName!.isNotEmpty)
          Text(
            ranch.legalName!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (ranch.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: theme.colorScheme.onPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'Principal',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (ranch.acceptsVisits)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Acepta Visitas',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.star,
            ranch.avgRating.toStringAsFixed(1),
            'Rating',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.shopping_bag,
            ranch.totalSales.toString(),
            'Ventas',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.inventory_2,
            '0', // TODO: Implementar contador de productos
            'Productos',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: child,
    );
  }

  Widget _buildPolicyCard(
    ThemeData theme,
    bool isDark,
    String title,
    String content,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

