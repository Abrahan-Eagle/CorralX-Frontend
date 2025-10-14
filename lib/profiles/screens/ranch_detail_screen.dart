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
            fontSize: isTablet ? 22 : 18,
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
                color: theme.colorScheme.primary),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con gradiente
            _buildHeader(context, isTablet),
            
            // Información principal
            Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica
                  if (ranch.legalName != null && ranch.legalName!.isNotEmpty)
                    _buildInfoRow(
                      context: context,
                      icon: Icons.business_center,
                      label: 'Razón Social',
                      content: ranch.legalName!,
                      isTablet: isTablet,
                    ),

                  if (ranch.taxId != null && ranch.taxId!.isNotEmpty)
                    _buildInfoRow(
                      context: context,
                      icon: Icons.credit_card,
                      label: 'RIF',
                      content: ranch.taxId!,
                      isTablet: isTablet,
                    ),

                  // Descripción
                  if (ranch.businessDescription != null &&
                      ranch.businessDescription!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDescriptionCard(context, isTablet),
                  ],

                  // Ubicación
                  if (ranch.address != null) ...[
                    const SizedBox(height: 16),
                    _buildLocationCard(context, isTablet),
                  ],

                  // Certificaciones
                  if (ranch.certifications != null &&
                      ranch.certifications!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCertificationsCard(context, isTablet),
                  ],

                  // Horarios
                  if (ranch.contactHours != null &&
                      ranch.contactHours!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildContactHoursCard(context, isTablet),
                  ],

                  // Políticas
                  if ((ranch.deliveryPolicy != null &&
                          ranch.deliveryPolicy!.isNotEmpty) ||
                      (ranch.returnPolicy != null &&
                          ranch.returnPolicy!.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _buildPoliciesCards(context, isTablet),
                  ],

                  // Estadísticas
                  const SizedBox(height: 16),
                  _buildStatisticsCard(context, isTablet),

                  // Información adicional
                  const SizedBox(height: 16),
                  _buildAdditionalInfoCard(context, isTablet),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primaryContainer.withOpacity(0.2),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.store,
                  size: isTablet ? 36 : 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ranch.name,
                      style: TextStyle(
                        fontSize: isTablet ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hacienda ${ranch.isPrimary ? 'Principal' : ''}',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (ranch.isPrimary)
                _buildBadge(
                  context: context,
                  icon: Icons.star,
                  label: 'Principal',
                  color: theme.colorScheme.primary,
                  isTablet: isTablet,
                ),
              if (ranch.acceptsVisits)
                _buildBadge(
                  context: context,
                  icon: Icons.visibility,
                  label: 'Acepta Visitas',
                  color: theme.colorScheme.secondary,
                  isTablet: isTablet,
                ),
              _buildBadge(
                context: context,
                icon: Icons.star_half,
                label: '${ranch.avgRating.toStringAsFixed(1)} rating',
                color: Colors.amber.shade700,
                isTablet: isTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 18 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String content,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: isTablet ? 20 : 18,
              color: theme.colorScheme.primary,
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
                    fontSize: isTablet ? 13 : 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 15,
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
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
                Icons.description_rounded,
                size: isTablet ? 24 : 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Descripción del Negocio',
                style: TextStyle(
                  fontSize: isTablet ? 19 : 17,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ranch.businessDescription!,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final address = ranch.address;
    if (address == null) return const SizedBox.shrink();

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
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.2),
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
                Icons.location_on_rounded,
                size: isTablet ? 24 : 22,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: isTablet ? 19 : 17,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          if (fullLocation.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLocationRow(
              context: context,
              icon: Icons.public,
              text: fullLocation,
              isTablet: isTablet,
            ),
          ],
          if (address.addresses.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLocationRow(
              context: context,
              icon: Icons.home_rounded,
              text: address.addresses,
              isTablet: isTablet,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required BuildContext context,
    required IconData icon,
    required String text,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isTablet ? 18 : 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationsCard(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50.withOpacity(0.3),
            Colors.green.shade50.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade200.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
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
                Icons.verified_rounded,
                size: isTablet ? 24 : 22,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 10),
              Text(
                'Certificaciones',
                style: TextStyle(
                  fontSize: isTablet ? 19 : 17,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ranch.certifications!.map((cert) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 14,
                  vertical: isTablet ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: isTablet ? 18 : 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cert,
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (ranch.businessLicenseUrl != null &&
              ranch.businessLicenseUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    size: isTablet ? 22 : 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Documento de Licencia Adjunto',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.download_rounded,
                    size: isTablet ? 22 : 20,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactHoursCard(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 14 : 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: isTablet ? 28 : 24,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horario de Atención',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ranch.contactHours!,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesCards(BuildContext context, bool isTablet) {
    return Column(
      children: [
        if (ranch.deliveryPolicy != null && ranch.deliveryPolicy!.isNotEmpty)
          _buildPolicyCard(
            context: context,
            icon: Icons.local_shipping_rounded,
            title: 'Política de Entrega',
            content: ranch.deliveryPolicy!,
            color: Colors.blue,
            isTablet: isTablet,
          ),
        if (ranch.deliveryPolicy != null &&
            ranch.deliveryPolicy!.isNotEmpty &&
            ranch.returnPolicy != null &&
            ranch.returnPolicy!.isNotEmpty)
          const SizedBox(height: 16),
        if (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty)
          _buildPolicyCard(
            context: context,
            icon: Icons.keyboard_return_rounded,
            title: 'Política de Devolución',
            content: ranch.returnPolicy!,
            color: Colors.orange,
            isTablet: isTablet,
          ),
      ],
    );
  }

  Widget _buildPolicyCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required MaterialColor color,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.shade50.withOpacity(0.4),
            color.shade50.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.shade200.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
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
                icon,
                size: isTablet ? 24 : 22,
                color: color.shade700,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 19 : 17,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.4),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
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
                Icons.bar_chart_rounded,
                size: isTablet ? 24 : 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: isTablet ? 19 : 17,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.star_rounded,
                  value: ranch.avgRating.toStringAsFixed(1),
                  label: 'Rating',
                  color: Colors.amber.shade600,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.shopping_bag_rounded,
                  value: ranch.totalSales.toString(),
                  label: 'Ventas',
                  color: Colors.green.shade600,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  value: '0',
                  label: 'Productos',
                  color: Colors.blue.shade600,
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
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: isTablet ? 26 : 22,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: isTablet ? 12 : 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: isTablet ? 22 : 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                'Información Adicional',
                style: TextStyle(
                  fontSize: isTablet ? 17 : 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoLine(
            context: context,
            icon: Icons.calendar_today_rounded,
            label: 'Creada',
            value: DateFormat('dd/MM/yyyy').format(ranch.createdAt),
            isTablet: isTablet,
          ),
          const SizedBox(height: 10),
          _buildInfoLine(
            context: context,
            icon: Icons.update_rounded,
            label: 'Actualizada',
            value: DateFormat('dd/MM/yyyy HH:mm').format(ranch.updatedAt),
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine({
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
          size: isTablet ? 16 : 14,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
