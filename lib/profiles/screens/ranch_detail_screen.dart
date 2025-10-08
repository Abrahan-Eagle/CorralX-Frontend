import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ranch.dart';
import 'edit_ranch_screen.dart';

class RanchDetailScreen extends StatelessWidget {
  final Ranch ranch;

  const RanchDetailScreen({
    super.key,
    required this.ranch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Hacienda'),
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
        actions: [
          // Botón Editar en el AppBar
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRanchScreen(ranch: ranch),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal con información básica
            _buildMainInfoCard(theme, isTablet),

            SizedBox(height: isTablet ? 24 : 16),

            // Card de descripción si existe
            if (ranch.description != null && ranch.description!.isNotEmpty)
              _buildDescriptionCard(theme, isTablet),

            if (ranch.description != null && ranch.description!.isNotEmpty)
              SizedBox(height: isTablet ? 24 : 16),

            // Card de horarios si existen
            if (ranch.contactHours != null && ranch.contactHours!.isNotEmpty)
              _buildScheduleCard(theme, isTablet),

            if (ranch.contactHours != null && ranch.contactHours!.isNotEmpty)
              SizedBox(height: isTablet ? 24 : 16),

            // Card de políticas si existen
            if ((ranch.deliveryPolicy != null &&
                    ranch.deliveryPolicy!.isNotEmpty) ||
                (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty))
              _buildPoliciesCard(theme, isTablet),

            if ((ranch.deliveryPolicy != null &&
                    ranch.deliveryPolicy!.isNotEmpty) ||
                (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty))
              SizedBox(height: isTablet ? 24 : 16),

            // Card de estadísticas
            _buildStatsCard(theme, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre y badge principal
          Row(
            children: [
              Expanded(
                child: Text(
                  ranch.name,
                  style: TextStyle(
                    fontSize: isTablet ? 26 : 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (ranch.isPrimary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Principal',
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 10,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          if (ranch.legalName != null && ranch.legalName!.isNotEmpty) ...[
            SizedBox(height: isTablet ? 12 : 8),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: isTablet ? 20 : 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ranch.legalName!,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (ranch.taxId != null && ranch.taxId!.isNotEmpty) ...[
            SizedBox(height: isTablet ? 10 : 8),
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: isTablet ? 20 : 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'RIF: ${ranch.taxId}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: isTablet ? 16 : 12),
          const Divider(),
          SizedBox(height: isTablet ? 12 : 8),

          // Fecha de creación
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: isTablet ? 18 : 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Creada: ${DateFormat('dd/MM/yyyy').format(ranch.createdAt)}',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: theme.colorScheme.primary,
                size: isTablet ? 24 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Descripción del Negocio',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            ranch.description!,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ThemeData theme, bool isTablet) {
    final schedules = ranch.contactHours!.split(', ');

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: theme.colorScheme.primary,
                size: isTablet ? 24 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Horarios de Atención',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: schedules.map((schedule) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      schedule,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: theme.colorScheme.onPrimaryContainer,
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
    );
  }

  Widget _buildPoliciesCard(ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.policy_outlined,
                color: theme.colorScheme.primary,
                size: isTablet ? 24 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Políticas',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (ranch.deliveryPolicy != null &&
              ranch.deliveryPolicy!.isNotEmpty) ...[
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: isTablet ? 18 : 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Política de Entrega',
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    ranch.deliveryPolicy!,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty) ...[
            SizedBox(height: isTablet ? 12 : 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_return_outlined,
                        size: isTablet ? 18 : 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Política de Devolución',
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    ranch.returnPolicy!,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: isTablet ? 24 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),

          // Grid de métricas
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: isTablet ? 16 : 12,
            crossAxisSpacing: isTablet ? 16 : 12,
            childAspectRatio: 2.2,
            children: [
              _buildStatItem(
                icon: Icons.star_outline,
                label: 'Rating Promedio',
                value: ranch.avgRating.toStringAsFixed(2),
                iconColor: Colors.amber.shade700,
                theme: theme,
                isTablet: isTablet,
              ),
              _buildStatItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Ventas Totales',
                value: '${ranch.totalSales}',
                iconColor: Colors.green.shade600,
                theme: theme,
                isTablet: isTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 6 : 4),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: isTablet ? 18 : 16,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 10 : 9,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
