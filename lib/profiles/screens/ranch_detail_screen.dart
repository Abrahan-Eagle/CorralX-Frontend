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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalle de Hacienda',
          style: TextStyle(
            color: Colors.white,
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
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(context),
            const SizedBox(height: 16),

            // Descripción
            if (ranch.businessDescription != null &&
                ranch.businessDescription!.isNotEmpty) ...[
              _buildDescriptionCard(context),
              const SizedBox(height: 16),
            ],

            // Ubicación
            if (ranch.address != null) ...[
              _buildLocationCard(context),
              const SizedBox(height: 16),
            ],

            // Certificaciones
            if (ranch.certifications != null &&
                ranch.certifications!.isNotEmpty) ...[
              _buildCertificationsCard(context),
              const SizedBox(height: 16),
            ],

            // Horarios
            if (ranch.contactHours != null && ranch.contactHours!.isNotEmpty) ...[
              _buildHoursCard(context),
              const SizedBox(height: 16),
            ],

            // Políticas
            if ((ranch.deliveryPolicy != null &&
                    ranch.deliveryPolicy!.isNotEmpty) ||
                (ranch.returnPolicy != null &&
                    ranch.returnPolicy!.isNotEmpty)) ...[
              _buildPoliciesSection(context),
              const SizedBox(height: 16),
            ],

            // Estadísticas
            _buildStatisticsCard(context),
            const SizedBox(height: 16),

            // Productos del Rancho
            _buildProductsSection(context),
            const SizedBox(height: 80), // Espacio para el FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de contacto próximamente'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        },
        backgroundColor: const Color(0xFF81C784),
        icon: const Icon(Icons.message, color: Colors.white),
        label: const Text(
          'Contactar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  ranch.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (ranch.isPrimary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Razón Social
          if (ranch.legalName != null && ranch.legalName!.isNotEmpty)
            _buildInfoRow(Icons.store, ranch.legalName!),

          // RIF
          if (ranch.taxId != null && ranch.taxId!.isNotEmpty)
            _buildInfoRow(Icons.badge, 'RIF: ${ranch.taxId}'),

          // Fecha de creación
          _buildInfoRow(
            Icons.calendar_today,
            'Creada: ${DateFormat('dd/MM/yyyy').format(ranch.createdAt)}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.description, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 12),
              Text(
                'Descripción del Negocio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ranch.businessDescription!,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 12),
              Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fullLocation.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.public, color: Color(0xFFB0B0B0), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fullLocation,
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14,
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
                const Icon(Icons.home, color: Color(0xFFB0B0B0), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.addresses,
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14,
                      height: 1.5,
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

  Widget _buildCertificationsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 12),
              Text(
                'Certificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    Text(
                      cert,
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 13,
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
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2196F3),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.attach_file, size: 18, color: Color(0xFF2196F3)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Documento de Licencia Adjunto',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.download, size: 18, color: Color(0xFF2196F3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHoursCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 12),
              Text(
                'Horarios de Atención',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ranch.contactHours!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.policy, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 12),
              Text(
                'Políticas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Política de Entrega
          if (ranch.deliveryPolicy != null && ranch.deliveryPolicy!.isNotEmpty)
            _buildPolicyItem(
              Icons.local_shipping,
              'Política de Entrega',
              ranch.deliveryPolicy!,
            ),

          if (ranch.deliveryPolicy != null &&
              ranch.deliveryPolicy!.isNotEmpty &&
              ranch.returnPolicy != null &&
              ranch.returnPolicy!.isNotEmpty)
            const SizedBox(height: 12),

          // Política de Devolución
          if (ranch.returnPolicy != null && ranch.returnPolicy!.isNotEmpty)
            _buildPolicyItem(
              Icons.keyboard_return,
              'Política de Devolución',
              ranch.returnPolicy!,
            ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(IconData icon, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4CAF50), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 12),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.star,
                  ranch.avgRating.toStringAsFixed(1),
                  'Rating',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  Icons.shopping_bag,
                  ranch.totalSales.toString(),
                  'Ventas',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  Icons.inventory_2,
                  '0',
                  'Productos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 12),
              Text(
                'Productos del Rancho',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: const [
                  Icon(
                    Icons.inventory_outlined,
                    size: 64,
                    color: Color(0xFF808080),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sin productos',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Esta finca aún no tiene productos publicados',
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


