import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zonix/admin/services/advertisement_admin_service.dart';
import 'package:zonix/admin/screens/create_edit_advertisement_screen.dart';
import 'package:zonix/admin/screens/advertisement_detail_screen.dart';
import '../../products/models/advertisement.dart';
import 'package:zonix/shared/utils/image_utils.dart';

/// Pantalla de listado de anuncios para administradores
class AdvertisementsListScreen extends StatefulWidget {
  const AdvertisementsListScreen({super.key});

  @override
  State<AdvertisementsListScreen> createState() => _AdvertisementsListScreenState();
}

class _AdvertisementsListScreenState extends State<AdvertisementsListScreen> {
  List<Advertisement> _advertisements = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterType = 'all'; // 'all', 'sponsored_product', 'external_ad'
  bool _filterActive = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _minPriority;
  int? _maxPriority;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  final TextEditingController _minPriorityController = TextEditingController();
  final TextEditingController _maxPriorityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriorityController.dispose();
    _maxPriorityController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvertisements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ads = await AdvertisementAdminService.getAllAdvertisements();
      setState(() {
        _advertisements = ads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Advertisement> get _filteredAdvertisements {
    var filtered = _advertisements;

    // Búsqueda por título
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ad) => 
        ad.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filtrar por tipo
    if (_filterType != 'all') {
      filtered = filtered.where((ad) => ad.type == _filterType).toList();
    }

    // Filtrar por estado activo
    if (_filterActive) {
      filtered = filtered.where((ad) => ad.isActive && ad.isCurrentlyActive).toList();
    }

    // Filtrar por rango de prioridad
    if (_minPriority != null) {
      filtered = filtered.where((ad) => ad.priority >= _minPriority!).toList();
    }
    if (_maxPriority != null) {
      filtered = filtered.where((ad) => ad.priority <= _maxPriority!).toList();
    }

    // Filtrar por rango de fechas
    if (_filterStartDate != null) {
      filtered = filtered.where((ad) {
        if (ad.startDate == null) return false;
        return ad.startDate!.isAfter(_filterStartDate!) || ad.startDate!.isAtSameMomentAs(_filterStartDate!);
      }).toList();
    }
    if (_filterEndDate != null) {
      filtered = filtered.where((ad) {
        if (ad.endDate == null) return true; // Si no tiene fecha de fin, incluir
        return ad.endDate!.isBefore(_filterEndDate!) || ad.endDate!.isAtSameMomentAs(_filterEndDate!);
      }).toList();
    }

    // Ordenar por prioridad (descendente) y fecha de creación (más reciente primero)
    filtered.sort((a, b) {
      if (b.priority != a.priority) {
        return b.priority.compareTo(a.priority);
      }
      return 0;
    });

    return filtered;
  }

  bool _hasActiveFilters() {
    return _filterType != 'all' ||
           !_filterActive ||
           _minPriority != null ||
           _maxPriority != null ||
           _filterStartDate != null ||
           _filterEndDate != null ||
           _searchQuery.isNotEmpty;
  }

  Future<void> _toggleActiveStatus(Advertisement ad) async {
    try {
      await AdvertisementAdminService.updateAdvertisement(ad.id, {
        'is_active': !ad.isActive,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ad.isActive 
              ? 'Anuncio desactivado' 
              : 'Anuncio activado'),
          ),
        );
        _loadAdvertisements();
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

  Future<void> _deleteAdvertisement(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: const Text('¿Estás seguro de que deseas eliminar este anuncio?'),
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

    if (confirm == true) {
      try {
        await AdvertisementAdminService.deleteAdvertisement(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anuncio eliminado exitosamente')),
          );
          _loadAdvertisements();
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

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditAdvertisementScreen(),
      ),
    ).then((_) => _loadAdvertisements());
  }

  void _navigateToEdit(Advertisement advertisement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditAdvertisementScreen(advertisement: advertisement),
      ),
    ).then((_) => _loadAdvertisements());
  }

  void _navigateToDetail(Advertisement advertisement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvertisementDetailScreen(advertisementId: advertisement.id),
      ),
    ).then((_) => _loadAdvertisements());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Publicidad'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(),
                tooltip: 'Filtros',
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdvertisements,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por título...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
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
                        onPressed: _loadAdvertisements,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _filteredAdvertisements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No se encontraron anuncios con "$_searchQuery"'
                                : 'No hay anuncios${_filterType != 'all' || _filterActive ? ' con los filtros aplicados' : ''}',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty || _filterType != 'all' || _filterActive) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _filterType = 'all';
                                  _filterActive = true;
                                });
                              },
                              child: const Text('Limpiar filtros'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAdvertisements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAdvertisements.length,
                        itemBuilder: (context, index) {
                          final ad = _filteredAdvertisements[index];
                          return _AdvertisementCard(
                            advertisement: ad,
                            onTap: () => _navigateToDetail(ad),
                            onEdit: () => _navigateToEdit(ad),
                            onDelete: () => _deleteAdvertisement(ad.id),
                            onToggleActive: () => _toggleActiveStatus(ad),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Anuncio'),
      ),
    );
  }

  void _showFilterDialog() {
    // Inicializar los controllers con los valores actuales
    _minPriorityController.text = _minPriority?.toString() ?? '';
    _maxPriorityController.text = _maxPriority?.toString() ?? '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtros'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Todos'),
                  value: 'all',
                  groupValue: _filterType,
                  onChanged: (value) {
                    setDialogState(() => _filterType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Producto Patrocinado'),
                  value: 'sponsored_product',
                  groupValue: _filterType,
                  onChanged: (value) {
                    setDialogState(() => _filterType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Publicidad Externa'),
                  value: 'external_ad',
                  groupValue: _filterType,
                  onChanged: (value) {
                    setDialogState(() => _filterType = value!);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Solo activos'),
                  value: _filterActive,
                  onChanged: (value) {
                    setDialogState(() => _filterActive = value);
                  },
                ),
                const Divider(),
                const Text('Prioridad:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Mín',
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: _minPriorityController,
                        onChanged: (value) {
                          _minPriority = value.isEmpty ? null : int.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(' - '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Máx',
                          hintText: '100',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: _maxPriorityController,
                        onChanged: (value) {
                          _maxPriority = value.isEmpty ? null : int.tryParse(value);
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const Text('Fechas:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => _filterStartDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha inicio',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _filterStartDate != null
                          ? DateFormat('dd/MM/yyyy').format(_filterStartDate!)
                          : 'Seleccionar',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => _filterEndDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha fin',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _filterEndDate != null
                          ? DateFormat('dd/MM/yyyy').format(_filterEndDate!)
                          : 'Seleccionar',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterType = 'all';
                  _filterActive = true;
                  _minPriority = null;
                  _maxPriority = null;
                  _filterStartDate = null;
                  _filterEndDate = null;
                  _minPriorityController.clear();
                  _maxPriorityController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Aplicar los valores de los controllers
                  _minPriority = _minPriorityController.text.isEmpty 
                      ? null 
                      : int.tryParse(_minPriorityController.text);
                  _maxPriority = _maxPriorityController.text.isEmpty 
                      ? null 
                      : int.tryParse(_maxPriorityController.text);
                });
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvertisementCard extends StatelessWidget {
  final Advertisement advertisement;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _AdvertisementCard({
    required this.advertisement,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  String _getStatusText() {
    if (!advertisement.isActive) return 'Inactivo';
    if (!advertisement.isCurrentlyActive) {
      if (advertisement.endDate != null && advertisement.endDate!.isBefore(DateTime.now())) {
        return 'Expirado';
      }
      if (advertisement.startDate != null && advertisement.startDate!.isAfter(DateTime.now())) {
        return 'Programado';
      }
    }
    return 'Activo';
  }

  Color _getStatusColor() {
    if (!advertisement.isActive) return Colors.grey;
    if (!advertisement.isCurrentlyActive) {
      if (advertisement.endDate != null && advertisement.endDate!.isBefore(DateTime.now())) {
        return Colors.red;
      }
      if (advertisement.startDate != null && advertisement.startDate!.isAfter(DateTime.now())) {
        return Colors.orange;
      }
    }
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (!advertisement.isActive) return Icons.block;
    if (!advertisement.isCurrentlyActive) {
      if (advertisement.endDate != null && advertisement.endDate!.isBefore(DateTime.now())) {
        return Icons.event_busy;
      }
      if (advertisement.startDate != null && advertisement.startDate!.isAfter(DateTime.now())) {
        return Icons.schedule;
      }
    }
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = _getStatusText();
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final isActive = advertisement.isActive && advertisement.isCurrentlyActive;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive 
            ? theme.colorScheme.primary.withOpacity(0.3)
            : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isBlockedImageHost(advertisement.imageUrl)
                        ? SizedBox(
                            width: 80,
                            height: 80,
                            child: buildImageFallback(
                              icon: Icons.image_not_supported,
                              backgroundColor: Colors.grey[300],
                              iconColor: Colors.grey[600],
                              iconSize: 32,
                            ),
                          )
                        : Image.network(
                            advertisement.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                width: 80,
                                height: 80,
                                child: buildImageFallback(
                                  icon: Icons.image_not_supported,
                                  backgroundColor: Colors.grey[300],
                                  iconColor: Colors.grey[600],
                                  iconSize: 32,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                advertisement.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Chip(
                              label: Text(
                                advertisement.type == 'sponsored_product'
                                    ? 'Patrocinado'
                                    : 'Externo',
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: advertisement.type == 'sponsored_product'
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.secondaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Estado y prioridad
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_up, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Prioridad: ${advertisement.priority}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Métricas
                        Row(
                          children: [
                            _buildMetric(
                              icon: Icons.mouse,
                              value: '${advertisement.clicks}',
                              label: 'Clicks',
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildMetric(
                              icon: Icons.visibility,
                              value: '${advertisement.impressions}',
                              label: 'Impresiones',
                              color: Colors.green,
                            ),
                          ],
                        ),
                        // Fechas
                        if (advertisement.startDate != null || advertisement.endDate != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: [
                              if (advertisement.startDate != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow, size: 12, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Inicio: ${DateFormat('dd/MM/yyyy').format(advertisement.startDate!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              if (advertisement.endDate != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.stop, size: 12, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Fin: ${DateFormat('dd/MM/yyyy').format(advertisement.endDate!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onToggleActive,
                    icon: Icon(
                      advertisement.isActive ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    color: advertisement.isActive ? Colors.orange : Colors.green,
                    tooltip: advertisement.isActive ? 'Desactivar' : 'Activar',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 20),
                    color: theme.colorScheme.primary,
                    tooltip: 'Editar',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

