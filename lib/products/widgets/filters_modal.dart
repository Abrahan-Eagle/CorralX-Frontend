import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FiltersModal extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FiltersModal({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Estado de los filtros
  String _selectedType = 'Todos';
  String _selectedLocation = 'Todos';
  RangeValues _priceRange = const RangeValues(0, 100000);
  int _quantity = 1;
  String _sortBy = 'newest'; // newest, price_asc, price_desc

  // Opciones para los dropdowns
  final List<String> _types = [
    'Todos',
    'lechero',
    'engorde',
    'padrote',
    'reproductor',
    'mixto'
  ];

  final List<String> _locations = [
    'Todos',
    'Toda Venezuela',
    'carabobo',
    'aragua',
    'miranda',
    'zulia',
    'merida',
    'tachira',
    'trujillo',
    'portuguesa',
    'barinas',
    'apure',
    'guarico',
    'cojedes',
    'yaracuy',
    'lara',
    'falcon',
    'sucre',
    'monagas',
    'anzoategui',
    'delta_amacuro',
    'amazonas',
    'bolivar',
    'nueva_esparta',
    'vargas',
    'distrito_capital'
  ];

  @override
  void initState() {
    super.initState();
    _loadFiltersFromCache();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadFiltersFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedFilters = prefs.getString('marketplace_filters');

      if (cachedFilters != null) {
        final filters = json.decode(cachedFilters) as Map<String, dynamic>;

        setState(() {
          _searchController.text = filters['search'] ?? '';
          _selectedType = filters['type'] ?? 'Todos';
          _selectedLocation = filters['location'] ?? 'Todos';
          _priceRange = RangeValues(
            (filters['min_price'] ?? 0).toDouble(),
            (filters['max_price'] ?? 100000).toDouble(),
          );
          _quantity = filters['quantity'] ?? 1;
          _sortBy = filters['sort_by'] ?? 'newest';

          _quantityController.text = _quantity.toString();
        });
      } else {
        // Cargar filtros actuales si no hay cache
        setState(() {
          _searchController.text = widget.currentFilters['search'] ?? '';
          _selectedType = widget.currentFilters['type'] ?? 'Todos';
          _selectedLocation = widget.currentFilters['location'] ?? 'Todos';
          _priceRange = RangeValues(
            (widget.currentFilters['min_price'] ?? 0).toDouble(),
            (widget.currentFilters['max_price'] ?? 100000).toDouble(),
          );
          _quantity = widget.currentFilters['quantity'] ?? 1;
          _sortBy = widget.currentFilters['sort_by'] ?? 'newest';

          _quantityController.text = _quantity.toString();
        });
      }
    } catch (e) {
      print('Error loading filters from cache: $e');
    }
  }

  Future<void> _saveFiltersToCache(Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('marketplace_filters', json.encode(filters));
    } catch (e) {
      print('Error saving filters to cache: $e');
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = 'Todos';
      _selectedLocation = 'Todos';
      _priceRange = const RangeValues(0, 100000);
      _quantity = 1;
      _sortBy = 'newest';

      _quantityController.text = _quantity.toString();
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_searchController.text.isNotEmpty) {
      filters['search'] = _searchController.text;
    }

    if (_selectedType != 'Todos') {
      filters['type'] = _selectedType;
    }

    if (_selectedLocation != 'Todos') {
      filters['location'] = _selectedLocation;
    }

    if (_priceRange.start > 0) {
      filters['min_price'] = _priceRange.start;
    }

    if (_priceRange.end < 100000) {
      filters['max_price'] = _priceRange.end;
    }

    if (_quantity > 1) {
      filters['quantity'] = _quantity;
    }

    if (_sortBy != 'newest') {
      filters['sort_by'] = _sortBy;
    }

    // Guardar en cache
    _saveFiltersToCache(filters);

    // Aplicar filtros
    widget.onApplyFilters(filters);

    // Cerrar modal
    Navigator.of(context).pop();
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_searchController.text.isNotEmpty) count++;
    if (_selectedType != 'Todos') count++;
    if (_selectedLocation != 'Todos') count++;
    if (_priceRange.start > 0) count++;
    if (_priceRange.end < 100000) count++;
    if (_quantity > 1) count++;
    if (_sortBy != 'newest') count++;
    return count;
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'Todos':
        return 'Todos';
      case 'lechero':
        return 'Lechero';
      case 'engorde':
        return 'Engorde';
      case 'padrote':
        return 'Padrote';
      case 'reproductor':
        return 'Reproductor';
      case 'mixto':
        return 'Mixto';
      default:
        return type;
    }
  }

  String _getLocationDisplayName(String location) {
    switch (location) {
      case 'Todos':
        return 'Todos los estados';
      case 'Toda Venezuela':
        return 'Toda Venezuela';
      case 'carabobo':
        return 'Carabobo';
      case 'aragua':
        return 'Aragua';
      case 'miranda':
        return 'Miranda';
      case 'zulia':
        return 'Zulia';
      case 'merida':
        return 'Mérida';
      case 'tachira':
        return 'Táchira';
      case 'trujillo':
        return 'Trujillo';
      case 'portuguesa':
        return 'Portuguesa';
      case 'barinas':
        return 'Barinas';
      case 'apure':
        return 'Apure';
      case 'guarico':
        return 'Guárico';
      case 'cojedes':
        return 'Cojedes';
      case 'yaracuy':
        return 'Yaracuy';
      case 'lara':
        return 'Lara';
      case 'falcon':
        return 'Falcón';
      case 'sucre':
        return 'Sucre';
      case 'monagas':
        return 'Monagas';
      case 'anzoategui':
        return 'Anzoátegui';
      case 'delta_amacuro':
        return 'Delta Amacuro';
      case 'amazonas':
        return 'Amazonas';
      case 'bolivar':
        return 'Bolívar';
      case 'nueva_esparta':
        return 'Nueva Esparta';
      case 'vargas':
        return 'Vargas';
      case 'distrito_capital':
        return 'Distrito Capital';
      default:
        return location;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            // Header minimalista
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 16 : 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF386A20),
                    const Color(0xFF4A7C2A),
                  ],
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getActiveFiltersCount()} filtros activos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: isTablet ? 24 : 22,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Búsqueda minimalista
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por raza, tipo...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        prefixIcon: Icon(Icons.search,
                            size: 20, color: Colors.grey[600]),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Cantidad minimalista
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Cantidad mínima',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        prefixIcon: Icon(Icons.numbers,
                            size: 20, color: Colors.grey[600]),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _quantity = int.tryParse(value) ?? 1;
                        });
                      },
                    ),

                    SizedBox(height: 20),

                    // Tipo de animal
                    Text('Tipo de Animal',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _types.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(_getTypeDisplayName(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = selected ? type : 'Todos';
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF386A20),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),

                    // Ubicación
                    Text('Ubicación',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _locations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location,
                            child: Text(_getLocationDisplayName(location)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value ?? 'Todos';
                          });
                        },
                      ),
                    ),

                    SizedBox(height: 20),

                    // Rango de precios con RangeSlider
                    Text('Rango de Precio',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 100000,
                            divisions: 100,
                            labels: RangeLabels(
                              '\$${_priceRange.start.round()}',
                              '\$${_priceRange.end.round()}',
                            ),
                            activeColor: const Color(0xFF386A20),
                            inactiveColor: Colors.grey[300],
                            onChanged: (RangeValues values) {
                              setState(() {
                                _priceRange = values;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('\$${_priceRange.start.round()}',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              Text('\$${_priceRange.end.round()}',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Ordenamiento
                    Text('Ordenar por',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        FilterChip(
                          label: Text('Más recientes'),
                          selected: _sortBy == 'newest',
                          onSelected: (selected) {
                            setState(() {
                              _sortBy = 'newest';
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF386A20),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _sortBy == 'newest'
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        FilterChip(
                          label: Text('Menor a Mayor'),
                          selected: _sortBy == 'price_asc',
                          onSelected: (selected) {
                            setState(() {
                              _sortBy = 'price_asc';
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF386A20),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _sortBy == 'price_asc'
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        FilterChip(
                          label: Text('Mayor a Menor'),
                          selected: _sortBy == 'price_desc',
                          onSelected: (selected) {
                            setState(() {
                              _sortBy = 'price_desc';
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF386A20),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _sortBy == 'price_desc'
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer mejorado con botones
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8F9FA),
                    const Color(0xFFF4F4ED),
                  ],
                ),
                borderRadius: BorderRadius.zero,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE0E0E0).withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _clearAllFilters,
                          borderRadius:
                              BorderRadius.circular(isTablet ? 12 : 10),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 14 : 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.clear_all_rounded,
                                  size: isTablet ? 20 : 18,
                                  color: const Color(0xFF74796D),
                                ),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF74796D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF386A20),
                            const Color(0xFF4A7C2A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF386A20).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _applyFilters,
                          borderRadius:
                              BorderRadius.circular(isTablet ? 12 : 10),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 14,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: isTablet ? 20 : 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  'Aplicar Filtros',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
