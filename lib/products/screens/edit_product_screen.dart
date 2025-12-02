import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/product_service.dart'; // ✅ NUEVO: para obtener tasa BCV

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _ageController;
  late TextEditingController _weightAvgController;
  late TextEditingController _otherBreedController; // ✅ NUEVO: controlador para raza "Otra"

  late String _selectedBreed;
  late String _selectedCurrency;
  late String _selectedSex;
  late String _selectedPurpose;
  late String? _selectedFeedingType; // ✅ NUEVO: tipo de alimento
  late String _selectedDeliveryMethod;
  late String _selectedStatus;
  late bool _isVaccinated;
  late bool _documentationIncluded;
  
  // ✅ NUEVO: Tasa de cambio USD a Bs
  double? _exchangeRate; // Se carga automáticamente desde el backend (BCV) - SIN VALORES HARDCODEADOS
  bool _isLoadingExchangeRate = false;
  
  // Lista completa de razas según backend
  static const List<String> _breedOptions = [
    'Brahman',
    'Holstein',
    'Guzerat',
    'Gyr',
    'Nelore',
    'Jersey',
    'Angus',
    'Simmental',
    'Pardo Suizo',
    'Charolais',
    'Limousin',
    'Santa Gertrudis',
    'Brangus',
    'Girolando',
    'Carora',
    'Criollo Limonero',
    'Mosaico Perijanero',
    'Indubrasil',
    'Sardo Negro',
    'Senepol',
    'Romosinuano',
    'Sahiwal',
    'Búfalo Murrah',
    'Búfalo Jafarabadi',
    'Búfalo Mediterráneo',
    'Búfalo Carabao',
    'Búfalo Nili-Ravi',
    'Búfalo Surti',
    'Búfalo Pandharpuri',
    'Búfalo Nagpuri',
    'Búfalo Mehsana',
    'Búfalo Bhadawari',
    'Búfalo Toda',
    'Búfalo Kundi',
    'Búfalo Nili',
    'Búfalo Ravi',
    'Otra',
  ];
  
  // Lista de opciones de tipo de alimento
  static const List<Map<String, String>> _feedingTypeOptions = [
    {'value': 'pastura_natural', 'label': 'Pastura natural'},
    {'value': 'pasto_corte', 'label': 'Pasto de corte'},
    {'value': 'concentrado', 'label': 'Concentrado'},
    {'value': 'mixto', 'label': 'Mixto (pasto + suplemento)'},
    {'value': 'otro', 'label': 'Otro (especificar en descripción)'},
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con datos existentes
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _quantityController =
        TextEditingController(text: widget.product.quantity.toString());
    _ageController = TextEditingController(text: widget.product.age.toString());
    _weightAvgController =
        TextEditingController(text: widget.product.weightAvg?.toString() ?? '');
    
    // ✅ Inicializar controlador de raza "Otra"
    final breed = widget.product.breed;
    _otherBreedController = TextEditingController(
      text: _breedOptions.contains(breed) ? '' : breed,
    );

    _selectedBreed = _breedOptions.contains(breed) ? breed : 'Otra';
    _selectedCurrency = widget.product.currency;
    _selectedSex = widget.product.sex ?? 'mixed';
    _selectedPurpose = widget.product.purpose ?? 'mixed';
    _selectedFeedingType = widget.product.feedingType; // ✅ NUEVO: tipo de alimento
    _selectedDeliveryMethod = widget.product.deliveryMethod;
    _selectedStatus = widget.product.status;
    _isVaccinated = widget.product.isVaccinated ?? false;
    _documentationIncluded = widget.product.documentationIncluded ?? false;
    
    // ✅ Cargar tasa de cambio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExchangeRate();
    });
    
    // ✅ Escuchar cambios en precio para actualizar conversión
    _priceController.addListener(_updatePriceConversion);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.removeListener(_updatePriceConversion); // ✅ NUEVO
    _priceController.dispose();
    _quantityController.dispose();
    _ageController.dispose();
    _weightAvgController.dispose();
    _otherBreedController.dispose(); // ✅ NUEVO
    super.dispose();
  }
  
  // ✅ NUEVO: Cargar tasa de cambio del BCV automáticamente (SIN VALORES HARDCODEADOS)
  Future<void> _loadExchangeRate() async {
    setState(() {
      _isLoadingExchangeRate = true;
    });
    try {
      final rate = await ProductService.getExchangeRate();
      if (mounted) {
        setState(() {
          _exchangeRate = rate; // Puede ser null si no se pudo obtener del BCV
          _isLoadingExchangeRate = false;
        });
        if (rate != null) {
          _updatePriceConversion(); // Actualizar conversión solo si hay tasa válida
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exchangeRate = null; // No hay tasa disponible
          _isLoadingExchangeRate = false;
        });
      }
    }
  }
  
  // ✅ NUEVO: Actualizar conversión USD a Bs cuando cambia el precio
  void _updatePriceConversion() {
    if (_selectedCurrency == 'USD' && _priceController.text.isNotEmpty) {
      final price = double.tryParse(_priceController.text);
      if (price != null && mounted) {
        setState(() {}); // Forzar rebuild para mostrar conversión
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<ProductProvider>();

    // ✅ Calcular automáticamente peso mínimo y máximo con 15% de variación
    final weightAvg = _weightAvgController.text.trim().isNotEmpty
        ? double.tryParse(_weightAvgController.text.trim())
        : null;
    final weightMin =
        weightAvg != null ? (weightAvg * 0.85) : null; // promedio - 15%
    final weightMax =
        weightAvg != null ? (weightAvg * 1.15) : null; // promedio + 15%

    // ✅ Determinar raza final (si es "Otra", usar el texto del autocompletado)
    final finalBreed = _selectedBreed == 'Otra' 
        ? _otherBreedController.text.trim()
        : _selectedBreed;
    
    if (finalBreed.isEmpty && _selectedBreed == 'Otra') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor ingresa el nombre de la raza'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }
    
    // ✅ Validar propósito y tipo de alimento
    if (_selectedPurpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona el propósito'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }
    
    if (_selectedFeedingType == null || _selectedFeedingType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona el tipo de alimento'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final success = await provider.updateProduct(
      productId: widget.product.id,
      title: _titleController.text,
      description: _descriptionController.text,
      breed: finalBreed, // ✅ Raza final (puede ser del dropdown o texto personalizado)
      age: int.tryParse(_ageController.text),
      quantity: int.tryParse(_quantityController.text),
      price: double.tryParse(_priceController.text),
      currency: _selectedCurrency,
      weightAvg: weightAvg,
      weightMin: weightMin,
      weightMax: weightMax,
      sex: _selectedSex,
      purpose: _selectedPurpose,
      feedingType: _selectedFeedingType, // ✅ NUEVO: tipo de alimento
      isVaccinated: _isVaccinated,
      deliveryMethod: _selectedDeliveryMethod,
      // ✅ Eliminado: negotiable (se guarda como false por defecto)
      documentationIncluded: _documentationIncluded,
      status: _selectedStatus,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Producto actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Retornar true para indicar éxito
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Error al actualizar producto'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Métodos de validación
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El título es obligatorio';
    }
    if (value.trim().length < 5) {
      return 'Mínimo 5 caracteres';
    }
    if (value.trim().length > 100) {
      return 'Máximo 100 caracteres';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    if (value.trim().length < 10) {
      return 'Mínimo 10 caracteres';
    }
    if (value.trim().length > 500) {
      return 'Máximo 500 caracteres';
    }
    return null;
  }


  String? _validateAge(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final age = int.tryParse(value.trim());
      if (age == null) {
        return 'Ingrese un número válido';
      }
      if (age < 0) {
        return 'La edad no puede ser negativa';
      }
      if (age > 360) {
        // máximo 30 años en meses
        return 'La edad no puede ser mayor a 360 meses';
      }
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cantidad es obligatoria';
    }
    final quantity = int.tryParse(value.trim());
    if (quantity == null) {
      return 'Ingrese un número válido';
    }
    if (quantity < 1) {
      return 'La cantidad debe ser mayor a 0';
    }
    if (quantity > 1000) {
      return 'La cantidad no puede ser mayor a 1000';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio es obligatorio';
    }
    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Ingrese un número válido';
    }
    if (price < 0) {
      return 'El precio no puede ser negativo';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final weight = double.tryParse(value.trim());
      if (weight == null) {
        return 'Ingrese un número válido';
      }
      if (weight < 0) {
        return 'El peso no puede ser negativo';
      }
      if (weight > 10000) {
        return 'El peso no puede ser mayor a 10,000 kg';
      }
    }
    return null;
  }

  // Método para validar el formulario en tiempo real
  void _validateForm() {
    setState(() {
      // Forzar rebuild para actualizar el estado de validación
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _titleController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(100),
              ],
              onChanged: (_) {
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                helperText: 'Mínimo 5 caracteres, máximo 100',
              ),
              validator: _validateTitle,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) {
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Descripción *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                helperText: 'Mínimo 10 caracteres, máximo 500',
              ),
              validator: _validateDescription,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // ✅ Raza (con autocompletado si selecciona "Otra")
            DropdownButtonFormField<String>(
              value: _selectedBreed,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Raza *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _breedOptions.map((breed) {
                return DropdownMenuItem<String>(
                  value: breed,
                  child: Text(breed),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBreed = value;
                    if (value != 'Otra') {
                      _otherBreedController.clear();
                    }
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La raza es obligatoria';
                }
                return null;
              },
            ),
            // ✅ Campo de texto para raza "Otra" con autocompletado
            if (_selectedBreed == 'Otra') ...[
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _breedOptions.where((breed) {
                    return breed.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ) &&
                        breed != 'Otra';
                  });
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Sincronizar con nuestro controlador
                  if (textEditingController.text != _otherBreedController.text) {
                    _otherBreedController.text = textEditingController.text;
                  }
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la raza *',
                      hintText: 'Escribe el nombre de la raza',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (_selectedBreed == 'Otra' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Ingresa el nombre de la raza';
                      }
                      return null;
                    },
                  );
                },
                onSelected: (String selection) {
                  _otherBreedController.text = selection;
                },
              ),
            ],
            const SizedBox(height: 16),

            // Edad y Cantidad
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (_) {
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Edad (meses)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.error, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      helperText: 'Máximo 360 meses',
                    ),
                    validator: _validateAge,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (_) {
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Cantidad *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.error, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      helperText: 'Máximo 1000',
                    ),
                    validator: _validateQuantity,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ Precio con conversión USD a Bs
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (_) {
                    _validateForm();
                    _updatePriceConversion();
                  },
                  decoration: InputDecoration(
                    labelText: 'Precio (USD) *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.error, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: _validatePrice,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                // ✅ Mostrar conversión a Bs cuando hay precio en USD y tasa válida del BCV
                if (_selectedCurrency == 'USD' &&
                    _priceController.text.isNotEmpty &&
                    !_isLoadingExchangeRate &&
                    _exchangeRate != null &&
                    _exchangeRate! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Text(
                      '≈ ${(_exchangeRate! * (double.tryParse(_priceController.text) ?? 0)).toStringAsFixed(2)} Bs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_isLoadingExchangeRate)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                // ✅ Mostrar mensaje si no se pudo obtener la tasa del BCV
                if (!_isLoadingExchangeRate &&
                    _selectedCurrency == 'USD' &&
                    _priceController.text.isNotEmpty &&
                    _exchangeRate == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Text(
                      'No se pudo obtener la tasa de cambio del BCV',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Peso promedio: calcula automáticamente mínimo (promedio - 15%) y máximo (promedio + 15%)
            TextFormField(
              controller: _weightAvgController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: (_) {
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Peso Promedio (kg)',
                hintText: 'El mínimo y máximo se calcularán automáticamente',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                helperText:
                    'Máximo 10,000 kg - El mínimo y máximo se calcularán automáticamente (promedio ± 15%)',
              ),
              validator: _validateWeight,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // Sexo
            DropdownButtonFormField<String>(
              value: _selectedSex,
              decoration: const InputDecoration(
                labelText: 'Sexo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Macho')),
                DropdownMenuItem(value: 'female', child: Text('Hembra')),
                DropdownMenuItem(value: 'mixed', child: Text('Mixto')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSex = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // ✅ Propósito (obligatorio)
            DropdownButtonFormField<String>(
              value: _selectedPurpose,
              decoration: const InputDecoration(
                labelText: 'Propósito *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'breeding', child: Text('Reproducción')),
                DropdownMenuItem(value: 'meat', child: Text('Carne')),
                DropdownMenuItem(value: 'dairy', child: Text('Lechería')),
                DropdownMenuItem(value: 'mixed', child: Text('Mixto')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPurpose = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El propósito es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // ✅ Tipo de alimento (obligatorio)
            DropdownButtonFormField<String>(
              value: _selectedFeedingType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tipo de alimento *',
                border: OutlineInputBorder(),
              ),
              items: _feedingTypeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFeedingType = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El tipo de alimento es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Método de entrega
            DropdownButtonFormField<String>(
              value: _selectedDeliveryMethod,
              decoration: const InputDecoration(
                labelText: 'Método de Entrega',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'pickup', child: Text('Recoger en sitio')),
                DropdownMenuItem(
                    value: 'delivery', child: Text('Entrega a domicilio')),
                DropdownMenuItem(value: 'both', child: Text('Ambos')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDeliveryMethod = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Estado
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Activo')),
                DropdownMenuItem(value: 'paused', child: Text('Pausado')),
                DropdownMenuItem(value: 'sold', child: Text('Vendido')),
                DropdownMenuItem(value: 'expired', child: Text('Expirado')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // ✅ Switches (eliminado "Precio Negociable")
            SwitchListTile(
              title: const Text('Vacunado'),
              value: _isVaccinated,
              onChanged: (value) => setState(() => _isVaccinated = value),
            ),
            SwitchListTile(
              title: const Text('Incluye Documentación'),
              value: _documentationIncluded,
              onChanged: (value) =>
                  setState(() => _documentationIncluded = value),
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Guardar Cambios',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
