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
    final isTablet = MediaQuery.of(context).size.width > 600;

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
          ranch.name,
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRanchScreen(ranch: ranch),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: Icon(Icons.edit_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información principal
            Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y badges
                  _buildTitleAndBadges(context, isTablet),
                  const SizedBox(height: 16),

                  // Información básica
                  if (ranch.legalName != null && ranch.legalName!.isNotEmpty)
                    _buildInfoSection(
                      context: context,
                      icon: Icons.business_center,
                      title: 'Razón Social',
                      content: ranch.legalName!,
                      isTablet: isTablet,
                    ),

                  if (ranch.taxId != null && ranch.taxId!.isNotEmpty)
                    _buildInfoSection(
                      context: context,
                      icon: Icons.credit_card,
                      title: 'RIF',
                      content: ranch.taxId!,
                      isTablet: isTablet,
                    ),

                  if (ranch.businessDescription != null &&
                      ranch.businessDescription!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDescriptionSection(context, isTablet),
                  ],

                  // Ubicación
                  if (ranch.address != null) ...[
                    const SizedBox(height: 16),
                    _buildLocationSection(context, isTablet),
                  ],

                  // Certificaciones
                  if (ranch.certifications != null &&
                      ranch.certifications!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCertificationsSection(context, isTablet),
                  ],

                  // Horarios
                  if (ranch.contactHours != null &&
                      ranch.contactHours!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildContactHoursSection(context, isTablet),
                  ],

                  // Políticas
                  if ((ranch.deliveryPolicy != null &&
                          ranch.deliveryPolicy!.isNotEmpty) ||
                      (ranch.returnPolicy != null &&
                          ranch.returnPolicy!.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _buildPoliciesSection(context, isTablet),
                  ],

                  // Estadísticas
                  const SizedBox(height: 16),
                  _buildStatisticsSection(context, isTablet),

                  // Información adicional
                  const SizedBox(height: 16),
                  _buildAdditionalInfoSection(context, isTablet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndBadges(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ranch.name,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
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
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star,
                        size: 16, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Principal',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
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
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility,
                        size: 16,
                        color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Acepta Visitas',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
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

  Widget _buildInfoSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isTablet ? 22 : 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 15,
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                size: isTablet ? 22 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Descripción del Negocio',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLocationSection(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final address = ranch.address;
    if (address == null) return const SizedBox.shrink();

    // Construir la ubicación completa
    String fullLocation = '';
    if (address.city != null) {
      final city = address.city;
      if (city != null) {
        fullLocation = city['name'] ?? '';

        if (city['state'] != null) {
          final state = city['state'];
          fullLocation += ', ${state['name'] ?? ''}';

          if (state['country'] != null) {
            final country = state['country'];
            fullLocation += ', ${country['name'] ?? ''}';
          }
        }
      }
    }

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: isTablet ? 22 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fullLocation.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.public,
                  size: isTablet ? 18 : 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fullLocation,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (address.addresses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home,
                  size: isTablet ? 18 : 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.addresses,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified,
                size: isTablet ? 22 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Certificaciones',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cert,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (ranch.businessLicenseUrl != null &&
              ranch.businessLicenseUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: isTablet ? 20 : 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Documento de Licencia Adjunto',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.download,
                    size: isTablet ? 20 : 18,
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactHoursSection(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: isTablet ? 24 : 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horario de Atención',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ranch.contactHours!,
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 15,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesSection(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ranch.deliveryPolicy != null && ranch.deliveryPolicy!.isNotEmpty)
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: isTablet ? 22 : 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Política de Entrega',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ranch.deliveryPolicy!,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        if (ranch.deliveryPolicy != null &&
            ranch.deliveryPolicy!.isNotEmpty &&
            ranch.returnPolicy != null &&
            ranch.returnPolicy!.isNotEmpty)
          const SizedBox(height: 12),
        if (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty)
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.keyboard_return,
                      size: isTablet ? 22 : 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Política de Devolución',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ranch.returnPolicy!,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                size: isTablet ? 22 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.star,
                  value: ranch.avgRating.toStringAsFixed(1),
                  label: 'Rating',
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.shopping_bag,
                  value: ranch.totalSales.toString(),
                  label: 'Ventas',
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.inventory_2,
                  value: '0',
                  label: 'Productos',
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: isTablet ? 30 : 26,
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isTablet ? 13 : 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: isTablet ? 22 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Información Adicional',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context: context,
            icon: Icons.calendar_today,
            label: 'Creada',
            value: DateFormat('dd/MM/yyyy').format(ranch.createdAt),
            isTablet: isTablet,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context: context,
            icon: Icons.update,
            label: 'Actualizada',
            value: DateFormat('dd/MM/yyyy HH:mm').format(ranch.updatedAt),
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: isTablet ? 18 : 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: isTablet ? 15 : 13,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 15 : 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
