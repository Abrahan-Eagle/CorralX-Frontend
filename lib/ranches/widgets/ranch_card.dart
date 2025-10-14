import 'package:flutter/material.dart';
import '../../profiles/models/ranch.dart';

class RanchCard extends StatelessWidget {
  final Ranch ranch;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  const RanchCard({
    super.key,
    required this.ranch,
    required this.isFavorite,
    required this.onTap,
    this.onFavorite,
  });

  String _getLocationText() {
    // Construir texto de ubicación desde address.city
    if (ranch.address?.city != null) {
      final city = ranch.address!.city!;
      final cityName = city['name'] ?? '';
      final state = city['state'];
      final stateName = state != null ? state['name'] ?? '' : '';
      
      if (cityName.isNotEmpty && stateName.isNotEmpty) {
        return '$cityName, $stateName';
      } else if (cityName.isNotEmpty) {
        return cityName;
      } else if (stateName.isNotEmpty) {
        return stateName;
      }
    }
    
    return 'Ubicación no especificada';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 8,
      ),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nombre + Favorito
              Row(
                children: [
                  // Icono de hacienda
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.home_work_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Nombre del rancho
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranch.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 18 : 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ranch.legalName != null && ranch.legalName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ranch.legalName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isTablet ? 14 : 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Botón de favorito
                  if (onFavorite != null)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onFavorite,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Badges: Principal + Acepta Visitas
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (ranch.isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Principal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (ranch.acceptsVisits)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Acepta Visitas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Información de ubicación
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: isTablet ? 18 : 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getLocationText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: isTablet ? 15 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Certificaciones
              if (ranch.certifications != null && ranch.certifications!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: isTablet ? 18 : 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${ranch.certifications!.length} ${ranch.certifications!.length == 1 ? 'Certificación' : 'Certificaciones'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Rating y ventas
              if (ranch.avgRating > 0 || ranch.totalSales > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (ranch.avgRating > 0) ...[
                      Icon(
                        Icons.star,
                        size: isTablet ? 18 : 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ranch.avgRating.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 15 : 14,
                        ),
                      ),
                    ],
                    
                    if (ranch.avgRating > 0 && ranch.totalSales > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    
                    if (ranch.totalSales > 0) ...[
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: isTablet ? 18 : 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ranch.totalSales} ${ranch.totalSales == 1 ? 'venta' : 'ventas'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: isTablet ? 15 : 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

