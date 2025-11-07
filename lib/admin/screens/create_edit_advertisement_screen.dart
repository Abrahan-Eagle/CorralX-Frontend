import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zonix/admin/services/advertisement_admin_service.dart';
import 'package:zonix/products/services/product_service.dart';
import 'package:zonix/products/models/product.dart';
import 'package:zonix/products/models/advertisement.dart';
import 'package:zonix/shared/utils/image_utils.dart';

/// Pantalla para crear o editar un anuncio
class CreateEditAdvertisementScreen extends StatefulWidget {
  final Advertisement? advertisement;

  const CreateEditAdvertisementScreen({
    super.key,
    this.advertisement,
  });

  @override
  State<CreateEditAdvertisementScreen> createState() => _CreateEditAdvertisementScreenState();
}

class _CreateEditAdvertisementScreenState extends State<CreateEditAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _advertiserNameController = TextEditingController();

  String _type = 'sponsored_product';
  bool _isActive = true;
  int _priority = 50;
  int? _selectedProductId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _loadingProducts = false;
  final TextEditingController _productSearchController = TextEditingController();
  bool _isValidImageUrl = false;

  @override
  void initState() {
    super.initState();
    _startDate ??= DateTime.now();
    _productSearchController.addListener(_filterProducts);
    
    // Validar URL de imagen con debounce para evitar cargar mientras se escribe
    _imageUrlController.addListener(_validateImageUrl);
    
    // Cargar datos del anuncio si estamos editando
    if (widget.advertisement != null) {
      _loadAdvertisementData(widget.advertisement!);
    }
    
    // Cargar productos si es necesario (para productos patrocinados)
    if (_type == 'sponsored_product') {
      _loadProducts();
    }
  }

  void _validateImageUrl() {
    final url = _imageUrlController.text.trim();
    
    // Validar que la URL tenga al menos un formato mínimo válido
    if (url.isEmpty) {
      setState(() {
        _isValidImageUrl = false;
      });
      return;
    }

    // Validar formato básico de URL
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() {
        _isValidImageUrl = false;
      });
      return;
    }

    // Solo validar como válida si tiene un dominio completo (al menos 4 caracteres)
    // Esto evita validar mientras el usuario está escribiendo
    if (uri.host.length < 4) {
      setState(() {
        _isValidImageUrl = false;
      });
      return;
    }

    setState(() {
      _isValidImageUrl = true;
    });
  }

  void _filterProducts() {
    final query = _productSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product.title.toLowerCase().contains(query) ||
                 product.id.toString().contains(query);
        }).toList();
      }
    });
  }

  void _loadAdvertisementData(Advertisement ad) {
    setState(() {
      _type = ad.type;
      _isActive = ad.isActive;
      _priority = ad.priority;
      _selectedProductId = ad.productId;
      _startDate = ad.startDate ?? DateTime.now();
      _endDate = ad.endDate;
      
      // Solo cargar datos si es publicidad externa
      if (_type == 'external_ad') {
        _titleController.text = ad.title;
        _descriptionController.text = ad.description ?? '';
        _imageUrlController.text = ad.imageUrl;
        _targetUrlController.text = ad.targetUrl ?? '';
        _advertiserNameController.text = ad.advertiserName ?? '';
        // Validar URL de imagen después de cargar datos
        _validateImageUrl();
      } else {
        // Para productos patrocinados, los datos se obtendrán del producto
        // Solo limpiamos los campos
        _titleController.clear();
        _descriptionController.clear();
        _imageUrlController.clear();
        _targetUrlController.clear();
        _advertiserNameController.clear();
      }
    });
    
    // Si es producto patrocinado, cargar productos (esperar a que se carguen)
    if (_type == 'sponsored_product') {
      _loadProducts().then((_) {
        // Después de cargar productos, actualizar filteredProducts
        if (mounted) {
          setState(() {
            _filteredProducts = _products;
          });
        }
      });
    }
  }

  Future<void> _loadProducts() async {
    if (_type != 'sponsored_product') return;

    setState(() => _loadingProducts = true);
    try {
      final response = await ProductService.getProducts(
        filters: {'status': 'active'},
        perPage: 100,
      );
      setState(() {
        // El backend devuelve los productos en 'data'
        final List<dynamic> productData = response['data'] ?? [];
        _products = productData.map((json) => Product.fromJson(json)).toList();
        _filteredProducts = _products;
        _loadingProducts = false;
      });
      
      // Si estamos editando y hay un producto seleccionado, asegurarnos que esté en la lista
      if (_selectedProductId != null && !_products.any((p) => p.id == _selectedProductId)) {
        // El producto seleccionado no está en la lista, intentar cargarlo por separado
        // O simplemente mostrar el ID si no se puede cargar
        debugPrint('⚠️ Producto seleccionado (ID: $_selectedProductId) no está en la lista de productos activos');
      }
    } catch (e) {
      setState(() {
        _loadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveAdvertisement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validaciones adicionales
    if (_type == 'sponsored_product' && _selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un producto para productos patrocinados')),
      );
      return;
    }

    if (_type == 'external_ad' && _advertiserNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes ingresar el nombre del anunciante para publicidad externa')),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una fecha de inicio')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Construir el objeto de datos base
      final Map<String, dynamic> data = {
        'type': _type,
        'is_active': _isActive,
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'priority': _priority,
      };

      // Agregar end_date solo si está definida
      if (_endDate != null) {
        data['end_date'] = _endDate!.toIso8601String().split('T')[0];
      } else {
        // Si estamos actualizando y no hay end_date, enviar null explícitamente
        if (widget.advertisement != null) {
          data['end_date'] = null;
        }
      }

      // Agregar campos específicos según el tipo
      if (_type == 'sponsored_product') {
        // Para productos patrocinados: NO enviar title, description, image_url
        // El backend los obtendrá automáticamente del producto
        data['product_id'] = _selectedProductId;
        // Limpiar advertiser_name si existía
        data['advertiser_name'] = null;
        // target_url también se genera automáticamente en el backend
      } else if (_type == 'external_ad') {
        // Para publicidad externa: title, description, image_url son OBLIGATORIOS
        data['title'] = _titleController.text.trim();
        data['description'] = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
        data['image_url'] = _imageUrlController.text.trim();
        data['target_url'] = _targetUrlController.text.trim().isEmpty ? null : _targetUrlController.text.trim();
        data['advertiser_name'] = _advertiserNameController.text.trim();
        // Limpiar product_id si existía
        data['product_id'] = null;
      }

      if (widget.advertisement != null) {
        await AdvertisementAdminService.updateAdvertisement(
          widget.advertisement!.id,
          data,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anuncio actualizado exitosamente')),
          );
          Navigator.pop(context, true);
        }
      } else {
        await AdvertisementAdminService.createAdvertisement(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anuncio creado exitosamente')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = 'Error desconocido';
        if (_errorMessage != null && _errorMessage!.isNotEmpty) {
          // Mejorar mensajes de error
          if (_errorMessage!.contains('validación') || _errorMessage!.contains('validation')) {
            errorMessage = 'Error de validación. Verifica que todos los campos estén correctos.';
          } else if (_errorMessage!.contains('autorizado') || _errorMessage!.contains('No autorizado')) {
            errorMessage = 'No tienes permisos para realizar esta acción.';
          } else if (_errorMessage!.contains('Producto no activo')) {
            errorMessage = 'El producto seleccionado no está activo. Selecciona otro producto.';
          } else if (_errorMessage!.contains('no encontrado')) {
            errorMessage = 'El recurso no fue encontrado. Por favor, intenta de nuevo.';
          } else {
            errorMessage = _errorMessage!;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    _advertiserNameController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.advertisement != null ? 'Editar Anuncio' : 'Nuevo Anuncio'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tipo de anuncio
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Anuncio *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'sponsored_product',
                          child: Text('Producto Patrocinado'),
                        ),
                        DropdownMenuItem(
                          value: 'external_ad',
                          child: Text('Publicidad Externa'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          final oldType = _type;
                          _type = value!;
                          
                          // Si cambiamos de sponsored_product a external_ad, limpiar producto
                          if (oldType == 'sponsored_product' && _type == 'external_ad') {
                            _selectedProductId = null;
                            _advertiserNameController.clear();
                          }
                          // Si cambiamos de external_ad a sponsored_product, limpiar anunciante y cargar productos
                          else if (oldType == 'external_ad' && _type == 'sponsored_product') {
                            _advertiserNameController.clear();
                            if (_products.isEmpty) {
                              _loadProducts();
                            }
                          }
                          // Si ya era sponsored_product y sigue siéndolo, solo asegurar productos cargados
                          else if (_type == 'sponsored_product' && _products.isEmpty) {
                            _loadProducts();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campos solo para publicidad externa (external_ad)
                    if (_type == 'external_ad') ...[
                      // Título
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_type == 'external_ad' && (value == null || value.trim().isEmpty)) {
                            return 'El título es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          hintText: 'Opcional',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // URL de imagen con vista previa
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de Imagen *',
                          border: OutlineInputBorder(),
                          hintText: 'https://ejemplo.com/imagen.jpg',
                          prefixIcon: Icon(Icons.image),
                        ),
                        validator: (value) {
                          if (_type == 'external_ad' && (value == null || value.trim().isEmpty)) {
                            return 'La URL de imagen es obligatoria';
                          }
                          if (value != null && value.trim().isNotEmpty) {
                            final uri = Uri.tryParse(value);
                            if (uri == null || !uri.hasScheme) {
                              return 'Debe ser una URL válida';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Vista previa de imagen (solo si la URL es válida)
                      if (_imageUrlController.text.isNotEmpty && _isValidImageUrl)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Builder(
                              builder: (context) {
                                final previewUrl = _imageUrlController.text.trim();
                                if (isBlockedImageHost(previewUrl)) {
                                    return buildImageFallback(
                                      icon: Icons.image_not_supported,
                                      backgroundColor: Colors.grey[200],
                                    );
                                }

                                return Image.network(
                                  previewUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => buildImageFallback(
                                    icon: Icons.broken_image,
                                    backgroundColor: Colors.grey[200],
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        )
                      else if (_imageUrlController.text.isNotEmpty && !_isValidImageUrl)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.orange.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ingresa una URL válida para ver la vista previa',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // URL de destino (opcional)
                      TextFormField(
                        controller: _targetUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de Destino',
                          border: OutlineInputBorder(),
                          hintText: 'Opcional - URL a donde redirigir',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Para productos patrocinados: mostrar información del producto seleccionado
                    if (_type == 'sponsored_product' && _selectedProductId != null)
                      Builder(
                        builder: (context) {
                          Product? selectedProduct;
                          if (_products.isNotEmpty && _selectedProductId != null) {
                            final matchingProducts = _products.where(
                              (p) => p.id == _selectedProductId,
                            );
                            if (matchingProducts.isNotEmpty) {
                              selectedProduct = matchingProducts.first;
                            }
                          }
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Información del Producto Patrocinado',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (selectedProduct != null) ...[
                                  Text(
                                    'El anuncio usará automáticamente los datos del producto:',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '📌 Título: ${selectedProduct.title}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (selectedProduct.description.isNotEmpty)
                                    Text(
                                      '📝 Descripción: ${selectedProduct.description.substring(0, selectedProduct.description.length > 50 ? 50 : selectedProduct.description.length)}...',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '🖼️ Imagen: Se usará la imagen principal del producto',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ] else ...[
                                  Text(
                                    'Los datos del producto se cargarán automáticamente desde el producto seleccionado.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    if (_type == 'sponsored_product') const SizedBox(height: 16),

                    // Producto (solo para sponsored_product) con búsqueda
                    if (_type == 'sponsored_product') ...[
                      _loadingProducts
                          ? const CircularProgressIndicator()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Producto *',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _productSearchController,
                                  builder: (context, value, child) {
                                    return TextField(
                                      controller: _productSearchController,
                                      decoration: InputDecoration(
                                        hintText: 'Buscar producto...',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: value.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _productSearchController.clear();
                                                },
                                              )
                                            : null,
                                        border: const OutlineInputBorder(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _filteredProducts.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            _products.isEmpty
                                                ? 'No hay productos disponibles'
                                                : 'No se encontraron productos',
                                            style: TextStyle(color: Colors.grey[600]),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _filteredProducts.length,
                                          itemBuilder: (context, index) {
                                            final product = _filteredProducts[index];
                                            final isSelected = _selectedProductId == product.id;
                                            return ListTile(
                                              selected: isSelected,
                                              selectedTileColor: theme.colorScheme.primaryContainer,
                                              title: Text(product.title),
                                              subtitle: Text('ID: ${product.id} - ${product.type}'),
                                              trailing: isSelected
                                                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                                                  : null,
                                              onTap: () {
                                                setState(() {
                                                  _selectedProductId = product.id;
                                                  _productSearchController.clear();
                                                });
                                              },
                                            );
                                          },
                                        ),
                                ),
                                if (_selectedProductId != null)
                                  Builder(
                                    builder: (context) {
                                      // Buscar el producto de forma segura
                                      Product? selectedProduct;
                                      if (_products.isNotEmpty && _selectedProductId != null) {
                                        // Verificar primero si existe el producto
                                        final matchingProducts = _products.where(
                                          (p) => p.id == _selectedProductId,
                                        );
                                        if (matchingProducts.isNotEmpty) {
                                          selectedProduct = matchingProducts.first;
                                        }
                                      }
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: selectedProduct != null
                                                ? theme.colorScheme.primaryContainer
                                                : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: selectedProduct == null
                                                ? Border.all(color: Colors.orange.shade300)
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                selectedProduct != null
                                                    ? Icons.check_circle
                                                    : Icons.warning_amber_rounded,
                                                color: selectedProduct != null
                                                    ? theme.colorScheme.primary
                                                    : Colors.orange,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  selectedProduct != null
                                                      ? 'Producto seleccionado: ${selectedProduct.title}'
                                                      : 'Producto seleccionado: ID: $_selectedProductId ${_loadingProducts ? "(cargando...)" : "(no disponible en productos activos)"}',
                                                  style: TextStyle(
                                                    color: selectedProduct != null
                                                        ? theme.colorScheme.onPrimaryContainer
                                                        : Colors.orange.shade900,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() => _selectedProductId = null);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                      const SizedBox(height: 16),
                    ],

                    // Nombre del anunciante (solo para external_ad)
                    if (_type == 'external_ad') ...[
                      TextFormField(
                        controller: _advertiserNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Anunciante *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_type == 'external_ad' && (value == null || value.trim().isEmpty)) {
                            return 'El nombre del anunciante es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Fecha de inicio
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Inicio *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : 'Seleccionar fecha',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fecha de fin
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Fin',
                          border: OutlineInputBorder(),
                          hintText: 'Opcional',
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : 'Seleccionar fecha (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prioridad con indicadores
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Prioridad: $_priority',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _priority > 50
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _priority > 50 ? 'Alta Prioridad' : 'Baja Prioridad',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _priority > 50 ? Colors.orange[700] : Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _priority.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _priority.toString(),
                          onChanged: (value) {
                            setState(() => _priority = value.toInt());
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                              Text('50', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                              Text('100', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Activo
                    SwitchListTile(
                      title: const Text('Activo'),
                      subtitle: const Text('El anuncio estará visible en el marketplace'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveAdvertisement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.advertisement != null ? 'Actualizar Anuncio' : 'Crear Anuncio'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

