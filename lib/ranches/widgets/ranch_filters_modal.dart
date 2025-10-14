import 'package:flutter/material.dart';
import '../../shared/services/location_service.dart';

class RanchFiltersModal extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const RanchFiltersModal({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<RanchFiltersModal> createState() => _RanchFiltersModalState();
}

class _RanchFiltersModalState extends State<RanchFiltersModal> {
  late Map<String, dynamic> _filters;
  
  // Ubicación
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  int? _selectedCountryId;
  int? _selectedStateId;
  int? _selectedCityId;
  
  // Certificaciones
  List<String> _selectedCertifications = [];
  final List<String> _availableCertifications = [
    'SENASICA',
    'Libre de Brucelosis',
    'Libre de Tuberculosis',
    'Certificación Orgánica',
    'Buenas Prácticas Ganaderas (BPG)',
    'Trazabilidad Ganadera',
    'Libre de Aftosa',
    'Certificación HACCP',
  ];
  
  // Acepta visitas
  bool? _acceptsVisits;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
    
    // Inicializar valores desde filtros actuales
    _selectedStateId = _filters['state_id'];
    _selectedCityId = _filters['city_id'];
    _selectedCertifications = _filters['certifications'] != null 
        ? List<String>.from(_filters['certifications']) 
        : [];
    _acceptsVisits = _filters['accepts_visits'];
    
    // Cargar estados de Venezuela (ID: 1)
    _selectedCountryId = 1; // Venezuela por defecto
    _loadStates();
  }

  Future<void> _loadStates() async {
    if (_selectedCountryId == null) return;
    
    try {
      _states = await LocationService.getStates(_selectedCountryId!);
      
      // Si hay un estado seleccionado, cargar ciudades
      if (_selectedStateId != null) {
        await _loadCities();
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error loading states: $e');
    }
  }

  Future<void> _loadCities() async {
    if (_selectedStateId == null) return;
    
    try {
      _cities = await LocationService.getCities(_selectedStateId!);
      setState(() {});
    } catch (e) {
      debugPrint('Error loading cities: $e');
    }
  }

  void _applyFilters() {
    final Map<String, dynamic> filters = {};
    
    if (_selectedStateId != null) {
      filters['state_id'] = _selectedStateId;
    }
    
    if (_selectedCityId != null) {
      filters['city_id'] = _selectedCityId;
    }
    
    if (_selectedCertifications.isNotEmpty) {
      filters['certifications'] = _selectedCertifications;
    }
    
    if (_acceptsVisits != null) {
      filters['accepts_visits'] = _acceptsVisits;
    }
    
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedStateId = null;
      _selectedCityId = null;
      _selectedCertifications.clear();
      _acceptsVisits = null;
      _cities.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isTablet ? 500 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrar Haciendas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 24 : 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ubicación
                    Text(
                      'Ubicación',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Estado
                    DropdownButtonFormField<int>(
                      value: _selectedStateId,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      isExpanded: true,
                      items: _states.map((state) {
                        return DropdownMenuItem<int>(
                          value: state['id'],
                          child: Text(
                            state['name'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStateId = value;
                          _selectedCityId = null;
                          _cities.clear();
                        });
                        if (value != null) {
                          _loadCities();
                        }
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Ciudad
                    DropdownButtonFormField<int>(
                      value: _selectedCityId,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      isExpanded: true,
                      items: _cities.map((city) {
                        return DropdownMenuItem<int>(
                          value: city['id'],
                          child: Text(
                            city['name'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedStateId == null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCityId = value;
                              });
                            },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Acepta Visitas
                    Text(
                      'Opciones',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    CheckboxListTile(
                      value: _acceptsVisits ?? false,
                      onChanged: (value) {
                        setState(() {
                          _acceptsVisits = value == true ? true : null;
                        });
                      },
                      title: const Text('Solo haciendas que aceptan visitas'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Certificaciones
                    Text(
                      'Certificaciones',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCertifications.map((cert) {
                        final isSelected = _selectedCertifications.contains(cert);
                        return FilterChip(
                          label: Text(cert),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCertifications.add(cert);
                              } else {
                                _selectedCertifications.remove(cert);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

