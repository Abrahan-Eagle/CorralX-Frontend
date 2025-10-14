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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Hacienda'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRanchScreen(ranch: ranch),
                ),
              );
              // Si se editó, volver a la pantalla anterior para refrescar
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Información Principal
            _buildSectionCard(
              context: context,
              title: 'Información General',
              icon: Icons.business,
              children: [
                _buildDetailRow(
                  context: context,
                  icon: Icons.store,
                  label: 'Nombre',
                  value: ranch.name,
                  isBold: true,
                ),
                if (ranch.legalName != null && ranch.legalName!.isNotEmpty)
                  _buildDetailRow(
                    context: context,
                    icon: Icons.business_center,
                    label: 'Razón Social',
                    value: ranch.legalName!,
                  ),
                if (ranch.taxId != null && ranch.taxId!.isNotEmpty)
                  _buildDetailRow(
                    context: context,
                    icon: Icons.credit_card,
                    label: 'RIF',
                    value: ranch.taxId!,
                  ),
                if (ranch.businessDescription != null &&
                    ranch.businessDescription!.isNotEmpty)
                  _buildDetailRow(
                    context: context,
                    icon: Icons.description,
                    label: 'Descripción',
                    value: ranch.businessDescription!,
                    isMultiline: true,
                  ),
                // Badges
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (ranch.isPrimary)
                        Chip(
                          avatar: const Icon(Icons.star, size: 16, color: Colors.white),
                          label: const Text('Principal'),
                          backgroundColor: theme.colorScheme.primary,
                          labelStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      if (ranch.acceptsVisits)
                        Chip(
                          avatar: const Icon(Icons.visibility, size: 16),
                          label: const Text('Acepta Visitas'),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. Ubicación
            if (ranch.address != null) _buildLocationSection(context),

            const SizedBox(height: 16),

            // 3. Certificaciones
            if (ranch.certifications != null && ranch.certifications!.isNotEmpty)
              _buildCertificationsSection(context),

            if (ranch.certifications != null && ranch.certifications!.isNotEmpty)
              const SizedBox(height: 16),

            // 4. Horarios de Atención
            if (ranch.contactHours != null && ranch.contactHours!.isNotEmpty)
              _buildSectionCard(
                context: context,
                title: 'Horario de Atención',
                icon: Icons.access_time,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ranch.contactHours!,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            if (ranch.contactHours != null && ranch.contactHours!.isNotEmpty)
              const SizedBox(height: 16),

            // 5. Políticas de Entrega y Devolución
            if ((ranch.deliveryPolicy != null &&
                    ranch.deliveryPolicy!.isNotEmpty) ||
                (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty))
              _buildPoliciesSection(context),

            if ((ranch.deliveryPolicy != null &&
                    ranch.deliveryPolicy!.isNotEmpty) ||
                (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty))
              const SizedBox(height: 16),

            // 6. Estadísticas
            _buildStatisticsSection(context),

            const SizedBox(height: 16),

            // 7. Información Adicional
            _buildSectionCard(
              context: context,
              title: 'Información Adicional',
              icon: Icons.info_outline,
              children: [
                _buildDetailRow(
                  context: context,
                  icon: Icons.calendar_today,
                  label: 'Fecha de Creación',
                  value: DateFormat('dd/MM/yyyy').format(ranch.createdAt),
                ),
                _buildDetailRow(
                  context: context,
                  icon: Icons.update,
                  label: 'Última Actualización',
                  value: DateFormat('dd/MM/yyyy HH:mm').format(ranch.updatedAt),
                ),
                _buildDetailRow(
                  context: context,
                  icon: Icons.star,
                  label: 'Rating Promedio',
                  value: ranch.avgRating.toStringAsFixed(1),
                ),
                _buildDetailRow(
                  context: context,
                  icon: Icons.shopping_bag,
                  label: 'Total Ventas',
                  value: ranch.totalSales.toString(),
                ),
              ],
            ),

            const SizedBox(height: 80), // Espacio para el FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de contacto próximamente'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.message_outlined),
        label: const Text(
          'Contactar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
    bool isMultiline = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    height: isMultiline ? 1.4 : 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
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

    return _buildSectionCard(
      context: context,
      title: 'Ubicación',
      icon: Icons.location_on,
      children: [
        if (fullLocation.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.public,
            label: 'País, Estado, Ciudad',
            value: fullLocation,
          ),
        if (address.addresses.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.home,
            label: 'Dirección Detallada',
            value: address.addresses,
            isMultiline: true,
          ),
        if (address.latitude != null && address.longitude != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.gps_fixed,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS: ${address.latitude!.toStringAsFixed(6)}, ${address.longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCertificationsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSectionCard(
      context: context,
      title: 'Certificaciones',
      icon: Icons.verified,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ranch.certifications!.map((cert) {
            return Chip(
              avatar: Icon(
                Icons.check_circle,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(cert),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        if (ranch.businessLicenseUrl != null &&
            ranch.businessLicenseUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Documento de Licencia Adjunto',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.download,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPoliciesSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Políticas Comerciales',
      icon: Icons.policy,
      children: [
        if (ranch.deliveryPolicy != null && ranch.deliveryPolicy!.isNotEmpty)
          _buildPolicyCard(
            context: context,
            icon: Icons.local_shipping,
            title: 'Política de Entrega',
            content: ranch.deliveryPolicy!,
          ),
        if (ranch.deliveryPolicy != null &&
            ranch.deliveryPolicy!.isNotEmpty &&
            ranch.returnPolicy != null &&
            ranch.returnPolicy!.isNotEmpty)
          const SizedBox(height: 12),
        if (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty)
          _buildPolicyCard(
            context: context,
            icon: Icons.keyboard_return,
            title: 'Política de Devolución',
            content: ranch.returnPolicy!,
          ),
      ],
    );
  }

  Widget _buildPolicyCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Estadísticas',
      icon: Icons.bar_chart,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.star,
                value: ranch.avgRating.toStringAsFixed(1),
                label: 'Rating',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.shopping_bag,
                value: ranch.totalSales.toString(),
                label: 'Ventas',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.inventory_2,
                value: '0',
                label: 'Productos',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
