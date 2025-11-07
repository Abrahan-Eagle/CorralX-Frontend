import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zonix/admin/services/advertisement_admin_service.dart';
import 'package:zonix/admin/screens/create_edit_advertisement_screen.dart';
import '../../products/models/advertisement.dart';
import 'package:zonix/shared/utils/image_utils.dart';

/// Pantalla de detalles del anuncio con estadísticas completas
class AdvertisementDetailScreen extends StatefulWidget {
  final int advertisementId;

  const AdvertisementDetailScreen({
    super.key,
    required this.advertisementId,
  });

  @override
  State<AdvertisementDetailScreen> createState() => _AdvertisementDetailScreenState();
}

class _AdvertisementDetailScreenState extends State<AdvertisementDetailScreen> {
  Advertisement? _advertisement;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdvertisement();
  }

  Future<void> _loadAdvertisement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ad = await AdvertisementAdminService.getAdvertisementById(widget.advertisementId);
      setState(() {
        _advertisement = ad;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActiveStatus() async {
    if (_advertisement == null) return;

    try {
      await AdvertisementAdminService.updateAdvertisement(_advertisement!.id, {
        'is_active': !_advertisement!.isActive,
      });
      _loadAdvertisement();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_advertisement!.isActive 
              ? 'Anuncio desactivado' 
              : 'Anuncio activado'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAdvertisement() async {
    if (_advertisement == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: const Text('¿Estás seguro de que deseas eliminar este anuncio? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await AdvertisementAdminService.deleteAdvertisement(_advertisement!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anuncio eliminado exitosamente')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getStatusText() {
    if (_advertisement == null) return '';
    if (!_advertisement!.isActive) return 'Inactivo';
    if (!_advertisement!.isCurrentlyActive) {
      if (_advertisement!.endDate != null && _advertisement!.endDate!.isBefore(DateTime.now())) {
        return 'Expirado';
      }
      if (_advertisement!.startDate != null && _advertisement!.startDate!.isAfter(DateTime.now())) {
        return 'Programado';
      }
    }
    return 'Activo';
  }

  Color _getStatusColor() {
    if (_advertisement == null) return Colors.grey;
    if (!_advertisement!.isActive) return Colors.grey;
    if (!_advertisement!.isCurrentlyActive) {
      if (_advertisement!.endDate != null && _advertisement!.endDate!.isBefore(DateTime.now())) {
        return Colors.red;
      }
      if (_advertisement!.startDate != null && _advertisement!.startDate!.isAfter(DateTime.now())) {
        return Colors.orange;
      }
    }
    return Colors.green;
  }

  double _getCTR() {
    if (_advertisement == null || _advertisement!.impressions == 0) return 0.0;
    return (_advertisement!.clicks / _advertisement!.impressions) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Anuncio'),
        actions: [
          if (_advertisement != null) ...[
            IconButton(
              icon: Icon(_advertisement!.isActive ? Icons.pause : Icons.play_arrow),
              onPressed: _toggleActiveStatus,
              tooltip: _advertisement!.isActive ? 'Desactivar' : 'Activar',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditAdvertisementScreen(
                      advertisement: _advertisement,
                    ),
                  ),
                ).then((_) => _loadAdvertisement());
              },
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAdvertisement,
              tooltip: 'Eliminar',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAdvertisement,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _advertisement == null
                  ? const Center(child: Text('Anuncio no encontrado'))
                  : RefreshIndicator(
                      onRefresh: _loadAdvertisement,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen principal
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: isBlockedImageHost(_advertisement!.imageUrl)
                                  ? SizedBox(
                                      width: double.infinity,
                                      height: 250,
                                      child: buildImageFallback(
                                        icon: Icons.image_not_supported,
                                        backgroundColor: Colors.grey[300],
                                        iconColor: Colors.grey[600],
                                        iconSize: 64,
                                      ),
                                    )
                                  : Image.network(
                                      _advertisement!.imageUrl,
                                      width: double.infinity,
                                      height: 250,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => SizedBox(
                                        width: double.infinity,
                                        height: 250,
                                        child: buildImageFallback(
                                          icon: Icons.image_not_supported,
                                          backgroundColor: Colors.grey[300],
                                          iconColor: Colors.grey[600],
                                          iconSize: 64,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),

                            // Estado y tipo
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getStatusColor()),
                                  ),
                                  child: Text(
                                    _getStatusText(),
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _advertisement!.type == 'sponsored_product'
                                        ? 'Producto Patrocinado'
                                        : 'Publicidad Externa',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Título
                            Text(
                              _advertisement!.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Descripción
                            if (_advertisement!.description != null && _advertisement!.description!.isNotEmpty) ...[
                              Text(
                                'Descripción',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _advertisement!.description!,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Estadísticas
                            Text(
                              'Estadísticas',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.mouse,
                                    label: 'Clicks',
                                    value: '${_advertisement!.clicks}',
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.visibility,
                                    label: 'Impresiones',
                                    value: '${_advertisement!.impressions}',
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              icon: Icons.trending_up,
                              label: 'CTR (Click Through Rate)',
                              value: '${_getCTR().toStringAsFixed(2)}%',
                              color: Colors.orange,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 24),

                            // Información del anuncio
                            Text(
                              'Información del Anuncio',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Prioridad', '${_advertisement!.priority}/100', Icons.trending_up),
                            if (_advertisement!.startDate != null)
                              _buildInfoRow(
                                'Fecha de Inicio',
                                DateFormat('dd/MM/yyyy').format(_advertisement!.startDate!),
                                Icons.play_arrow,
                              ),
                            if (_advertisement!.endDate != null)
                              _buildInfoRow(
                                'Fecha de Fin',
                                DateFormat('dd/MM/yyyy').format(_advertisement!.endDate!),
                                Icons.stop,
                              ),
                            if (_advertisement!.targetUrl != null && _advertisement!.targetUrl!.isNotEmpty)
                              _buildInfoRow('URL de Destino', _advertisement!.targetUrl!, Icons.link),

                            // Información específica por tipo
                            if (_advertisement!.type == 'sponsored_product' && _advertisement!.productId != null) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Producto Patrocinado',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('ID del Producto', '${_advertisement!.productId}', Icons.shopping_bag),
                              if (_advertisement!.product != null) ...[
                                _buildInfoRow('Título', _advertisement!.product!['title'] ?? 'N/A', Icons.title),
                                _buildInfoRow('Tipo', _advertisement!.product!['type'] ?? 'N/A', Icons.category),
                              ],
                            ],

                            if (_advertisement!.type == 'external_ad' && _advertisement!.advertiserName != null) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Anunciante',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('Nombre', _advertisement!.advertiserName!, Icons.business),
                            ],

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

