import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductDetailWidget extends StatelessWidget {
  final Product product;
  final bool isTablet;

  const ProductDetailWidget({
    Key? key,
    required this.product,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Galería de imágenes
          _buildImageGallery(),

          // Información principal
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y precio
                _buildTitleAndPrice(),
                const SizedBox(height: 16),

                // Información del rancho
                if (product.ranch != null) ...[
                  _buildRanchInfo(),
                  const SizedBox(height: 16),
                ],

                // Detalles del animal
                _buildAnimalDetails(),
                const SizedBox(height: 16),

                // Información de salud
                _buildHealthInfo(),
                const SizedBox(height: 16),

                // Descripción
                _buildDescription(),
                const SizedBox(height: 24),

                // Botones de acción
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (product.images.isEmpty) {
      return Container(
        height: isTablet ? 400 : 300,
        width: double.infinity,
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                size: isTablet ? 80 : 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Sin imágenes disponibles',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: isTablet ? 400 : 300,
      child: PageView.builder(
        itemCount: product.images.length,
        itemBuilder: (context, index) {
          final image = product.images[index];
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(image.fileUrl),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleAndPrice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTypeDisplayName(),
                      style: TextStyle(
                        color: _getTypeColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.breed,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF386A20),
              ),
            ),
            Text(
              product.currency,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRanchInfo() {
    final ranch = product.ranch!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isTablet ? 30 : 25,
            backgroundColor: const Color(0xFF386A20),
            child: Text(
              ranch.name.isNotEmpty ? ranch.name[0].toUpperCase() : 'R',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
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
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (ranch.legalName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ranch.legalName!,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (ranch.avgRating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < (ranch.avgRating! / 2).round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${ranch.avgRating!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles del Animal',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Edad', '${product.age} meses'),
          _buildDetailRow('Cantidad disponible',
              '${product.quantity} ${product.quantity == 1 ? 'cabeza' : 'cabezas'}'),
          if (product.sex != null)
            _buildDetailRow('Sexo', _getSexDisplayName()),
          if (product.purpose != null)
            _buildDetailRow('Propósito', _getPurposeDisplayName()),
          if (product.weightAvg != null)
            _buildDetailRow(
                'Peso promedio', '${product.weightAvg!.toStringAsFixed(1)} kg'),
          if (product.weightMin != null && product.weightMax != null)
            _buildDetailRow('Rango de peso',
                '${product.weightMin!.toStringAsFixed(1)} - ${product.weightMax!.toStringAsFixed(1)} kg'),
        ],
      ),
    );
  }

  Widget _buildHealthInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de Salud',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthRow('Vacunado', product.isVaccinated ?? false),
          _buildHealthRow(
              'Documentación incluida', product.documentationIncluded ?? false),
          if (product.vaccinesApplied != null &&
              product.vaccinesApplied!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Vacunas aplicadas:',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.vaccinesApplied!,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[600],
                      ),
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

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: isTablet ? 56 : 48,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implementar contacto con vendedor
              _showContactDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF386A20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Contactar Vendedor',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: isTablet ? 48 : 44,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implementar compartir
                    _showShareDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF386A20),
                    side: const BorderSide(color: Color(0xFF386A20)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Compartir',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: isTablet ? 48 : 44,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implementar reportar
                    _showReportDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    side: BorderSide(color: Colors.red[600]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reportar',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 140 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: value ? Colors.green[600] : Colors.red[600],
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value ? 'Sí' : 'No',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: value ? Colors.green[600] : Colors.red[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contactar Vendedor'),
        content: const Text(
            '¿Deseas contactar al vendedor para más información sobre este ganado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar navegación a chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Funcionalidad de chat en desarrollo')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF386A20),
            ),
            child: const Text('Contactar'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir'),
        content: const Text('¿Deseas compartir este ganado con otros?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar compartir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Funcionalidad de compartir en desarrollo')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF386A20),
            ),
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar'),
        content: const Text('¿Deseas reportar este anuncio por algún motivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar reportar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Funcionalidad de reportar en desarrollo')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (product.type.toLowerCase()) {
      case 'lechero':
        return Colors.blue;
      case 'engorde':
        return Colors.orange;
      case 'padrote':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  String _getTypeDisplayName() {
    switch (product.type.toLowerCase()) {
      case 'lechero':
        return 'Lechero';
      case 'engorde':
        return 'Engorde';
      case 'padrote':
        return 'Padrote';
      default:
        return product.type;
    }
  }

  String _getSexDisplayName() {
    switch (product.sex?.toLowerCase()) {
      case 'male':
        return 'Macho';
      case 'female':
        return 'Hembra';
      default:
        return product.sex ?? '';
    }
  }

  String _getPurposeDisplayName() {
    switch (product.purpose?.toLowerCase()) {
      case 'meat':
        return 'Carne';
      case 'milk':
        return 'Leche';
      case 'breeding':
        return 'Reproducción';
      case 'mixed':
        return 'Mixto';
      default:
        return product.purpose ?? '';
    }
  }
}
