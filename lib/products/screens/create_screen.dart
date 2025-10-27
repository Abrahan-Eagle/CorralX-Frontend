import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import '../../profiles/providers/profile_provider.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controladores para los campos de texto
  late TextEditingController _titleController;
  late TextEditingController _ageController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _weightAvgController;
  late TextEditingController _weightMinController; // ✅ NUEVO
  late TextEditingController _weightMaxController; // ✅ NUEVO
  late TextEditingController _deliveryCostController;
  late TextEditingController _deliveryRadiusController;

  // Estados del formulario
  String _selectedType = 'lechero';
  String _selectedBreed = 'Brahman'; // ✅ NUEVO: raza seleccionada
  String _selectedCurrency = 'USD';
  String _selectedDeliveryMethod = 'pickup';
  String _registrationType = 'sin-registro';
  bool _isFeatured = false;
  bool _negotiable = false;
  bool _documentationIncluded = false; // ✅ NUEVO: documentación incluida
  bool _isVaccinated = false; // ✅ NUEVO: vacunado
  int? _selectedRanchId;

  // ✅ NUEVOS: campos opcionales críticos
  String? _selectedSex; // male, female, mixed
  String? _selectedPurpose; // breeding, meat, dairy, mixed

  // Lista de razas según backend (ProductController línea 69)
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

  // Imágenes seleccionadas
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _ageController = TextEditingController();
    _quantityController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _weightAvgController = TextEditingController();
    _weightMinController = TextEditingController(); // ✅ NUEVO
    _weightMaxController = TextEditingController(); // ✅ NUEVO
    _deliveryCostController = TextEditingController();
    _deliveryRadiusController = TextEditingController();

    // Cargar las fincas del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchMyRanches();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ageController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _weightAvgController.dispose();
    _weightMinController.dispose(); // ✅ NUEVO
    _weightMaxController.dispose(); // ✅ NUEVO
    _deliveryCostController.dispose();
    _deliveryRadiusController.dispose();
    super.dispose();
  }

  // Métodos de validación
  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La edad es obligatoria';
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Ingrese un número válido';
    }
    if (age < 0) {
      return 'La edad no puede ser negativa';
    }
    if (age > 30) {
      return 'La edad no puede ser mayor a 30 años';
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

  // Método para validar el formulario en tiempo real
  void _validateForm() {
    setState(() {
      // Forzar rebuild para actualizar el estado de validación
    });
  }

  // Métodos para manejar imágenes
  Future<void> _pickImages() async {
    final theme = Theme.of(context);

    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Máximo 5 imágenes permitidas'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      final int availableSlots = 5 - _selectedImages.length;
      final int imagesToAdd =
          images.length > availableSlots ? availableSlots : images.length;

      setState(() {
        _selectedImages.addAll(images.take(imagesToAdd));
      });

      if (images.length > imagesToAdd) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Solo se agregaron $imagesToAdd de ${images.length} imágenes (máximo 5)'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Método para enviar el formulario
  Future<void> _handleSubmit() async {
    final theme = Theme.of(context);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Por favor complete todos los campos obligatorios'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedRanchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona una finca'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor agrega al menos una imagen'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final productProvider = context.read<ProductProvider>();

      // Log de datos antes de enviar
      print('📦 CreateScreen: Iniciando creación de producto...');
      print('  🏠 Ranch ID: $_selectedRanchId');
      print(
          '  📝 Title: ${_titleController.text.trim().isEmpty ? '${_selectedType.toUpperCase()} - $_selectedBreed' : _titleController.text.trim()}');
      print('  📄 Description: ${_descriptionController.text.trim()}');
      print('  🏷️ Type: $_selectedType');
      print('  🐄 Breed: $_selectedBreed'); // ✅ Mostrar raza del dropdown
      print('  📅 Age: ${_ageController.text.trim()}');
      print('  🔢 Quantity: ${_quantityController.text.trim()}');
      print('  💰 Price: ${_priceController.text.trim()} $_selectedCurrency');
      print('  📦 Delivery Method: $_selectedDeliveryMethod');
      print('  🏷️ Featured: $_isFeatured');
      print('  📸 Images: ${_selectedImages.length}');

      // Obtener el stateId del ranch seleccionado
      int? stateId;
      try {
        final ranchProvider = context.read<ProfileProvider>();
        final ranches = ranchProvider.myRanches;
        final selectedRanch =
            ranches.firstWhere((r) => r.id == _selectedRanchId);

        // Extraer stateId desde address.city.state.id
        if (selectedRanch.address?.city != null) {
          final city = selectedRanch.address!.city;
          if (city?['state'] != null) {
            final state = city!['state'] as Map<String, dynamic>?;
            stateId = state?['id'] as int?;
            print('🗺️ State ID obtenido del ranch: $stateId');
          }
        }
      } catch (e) {
        print('⚠️ No se pudo obtener stateId: $e');
      }

      // Crear el producto
      final success = await productProvider.createProduct(
        ranchId: _selectedRanchId!,
        stateId: stateId, // ✅ Pasar stateId obtenido del ranch
        title: _titleController.text.trim().isEmpty
            ? '${_selectedType.toUpperCase()} - $_selectedBreed'
            : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        breed: _selectedBreed, // ✅ Usar _selectedBreed del dropdown
        age: int.parse(_ageController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        currency: _selectedCurrency,
        weightAvg: _weightAvgController.text.trim().isNotEmpty
            ? double.parse(_weightAvgController.text.trim())
            : null,
        weightMin: _weightMinController.text.trim().isNotEmpty
            ? double.parse(_weightMinController.text.trim())
            : null, // ✅ NUEVO
        weightMax: _weightMaxController.text.trim().isNotEmpty
            ? double.parse(_weightMaxController.text.trim())
            : null, // ✅ NUEVO
        sex: _selectedSex, // ✅ NUEVO: male, female, mixed
        purpose: _selectedPurpose, // ✅ NUEVO: breeding, meat, dairy, mixed
        deliveryMethod: _selectedDeliveryMethod,
        deliveryCost: _deliveryCostController.text.trim().isNotEmpty
            ? double.parse(_deliveryCostController.text.trim())
            : null,
        deliveryRadiusKm: _deliveryRadiusController.text.trim().isNotEmpty
            ? double.parse(_deliveryRadiusController.text.trim())
            : null,
        negotiable: _negotiable,
        isFeatured: _isFeatured, // ✅ NUEVO: checkbox destacado
        documentationIncluded:
            _documentationIncluded, // ✅ NUEVO: checkbox documentación
        isVaccinated: _isVaccinated, // ✅ NUEVO: vacunado
        status:
            'active', // ✅ Backend solo acepta: active, paused, sold, expired
        imagePaths: _selectedImages.map((img) => img.path).toList(),
      );

      print('✅ CreateScreen: Resultado de creación: $success');
      print('🔍 mounted: $mounted');

      if (success && mounted) {
        print('🎯 ENTRANDO a bloque de limpieza (success=true, mounted=true)');

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Producto publicado exitosamente!'),
            backgroundColor: theme.colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refrescar la lista de productos en background
        productProvider.fetchProducts(refresh: true);

        print('🧹 Iniciando limpieza del formulario...');
        print('📸 Imágenes ANTES de limpiar: ${_selectedImages.length}');
        print('📝 Título ANTES de limpiar: "${_titleController.text}"');

        // ✅ LIMPIAR FORMULARIO para crear otro producto
        setState(() {
          print('⚡ DENTRO DE setState - LIMPIANDO...');
          // 1. PRIMERO: Limpiar imágenes
          print('🔄 Limpiando imágenes: ${_selectedImages.length} imágenes');
          _selectedImages.clear();

          // 2. Limpiar controladores de texto (usando .text = '' dentro de setState)
          print('🔄 Limpiando controladores de texto...');
          _titleController.text = '';
          _descriptionController.text = '';
          _ageController.text = '';
          _quantityController.text = '';
          _priceController.text = '';
          _weightAvgController.text = '';
          _weightMinController.text = '';
          _weightMaxController.text = '';
          _deliveryCostController.text = '';
          _deliveryRadiusController.text = '';

          // 3. Resetear dropdowns
          print('🔄 Reseteando dropdowns...');
          _selectedType = 'lechero';
          _selectedBreed = 'Brahman';
          _selectedCurrency = 'USD';
          _selectedDeliveryMethod = 'pickup';
          _selectedSex = null;
          _selectedPurpose = null;

          // 4. Resetear checkboxes
          print('🔄 Reseteando checkboxes...');
          _isFeatured = false;
          _negotiable = false;
          _documentationIncluded = false;
          _isVaccinated = false;
        });

        // 5. Resetear validaciones del formulario con delay
        // Logs después de setState
        print('📸 Imágenes DESPUÉS de limpiar: ${_selectedImages.length}');
        print('📝 Título DESPUÉS de limpiar: "${_titleController.text}"');
        print(
            '📝 Descripción DESPUÉS de limpiar: "${_descriptionController.text}"');
        print(
            '📊 Dropdowns: Tipo=$_selectedType | Raza=$_selectedBreed | Sexo=$_selectedSex');
        print(
            '✅ Checkboxes: Destacado=$_isFeatured | Negociable=$_negotiable | Doc=$_documentationIncluded');

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _formKey.currentState?.reset();
            print('✅ Validaciones reseteadas');
          }
        });

        print(
            '✅ Formulario completamente limpiado y listo para crear otro producto');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                productProvider.errorMessage ?? 'Error al crear el producto'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      // AppBar removido completamente para seguir el patrón de diseño de la app
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 800 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header eliminado completamente - Diseño minimalista sin títulos
                // Photos section
                _buildSection(
                  title: 'Fotos del Animal (hasta 5)',
                  subtitle: 'La primera foto será la imagen de portada.',
                  child: Column(
                    children: [
                      // Imágenes seleccionadas
                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: isTablet ? 120 : 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: isTablet ? 120 : 100,
                                    margin: EdgeInsets.only(
                                        right: isTablet ? 12 : 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          isTablet ? 12 : 10),
                                      border: Border.all(
                                        color: index == 0
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                .withOpacity(0.3),
                                        width: index == 0 ? 2.5 : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.shadow
                                              .withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          isTablet ? 10 : 6),
                                      child: Image.file(
                                        File(_selectedImages[index].path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 8 : 6,
                                          vertical: isTablet ? 4 : 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Portada',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: isTablet ? 11 : 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 4,
                                    right: isTablet ? 16 : 12,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: theme.colorScheme.onError,
                                          size: isTablet ? 18 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      if (_selectedImages.isNotEmpty)
                        SizedBox(height: isTablet ? 16 : 12),
                      // Botón para agregar fotos
                      if (_selectedImages.length < 5)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: isTablet ? 120 : 100,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius:
                                  BorderRadius.circular(isTablet ? 12 : 10),
                              border: Border.all(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: isTablet ? 40 : 36,
                                    color: theme.colorScheme.primary,
                                  ),
                                  SizedBox(height: isTablet ? 10 : 8),
                                  Text(
                                    'Agregar fotos (${_selectedImages.length}/5)',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: isTablet ? 15 : 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                // Registration section
                _buildSection(
                  title: 'Registro del Animal',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'con-registro',
                            groupValue: _registrationType,
                            onChanged: (value) {
                              setState(() {
                                _registrationType = value!;
                              });
                            },
                          ),
                          Text('Con Registro',
                              style: TextStyle(fontSize: isTablet ? 16 : 14)),
                          SizedBox(width: isTablet ? 32 : 24),
                          Radio<String>(
                            value: 'sin-registro',
                            groupValue: _registrationType,
                            onChanged: (value) {
                              setState(() {
                                _registrationType = value!;
                              });
                            },
                          ),
                          Text('Sin Registro',
                              style: TextStyle(fontSize: isTablet ? 16 : 14)),
                        ],
                      ),
                    ],
                  ),
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                // Animal details section
                _buildSection(
                  title: 'Detalles del Animal',
                  child: Column(
                    children: [
                      // Título (opcional, se genera automático si está vacío)
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          labelText: 'Título (opcional)',
                          hintText:
                              'Se generará automáticamente si se deja vacío',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 12 : 8,
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              isExpanded: true, // ✅ Evita overflow
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Tipo *',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 10, // Reducido
                                  vertical: isTablet ? 10 : 8, // Reducido
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'lechero', child: Text('Lechero')),
                                DropdownMenuItem(
                                    value: 'engorde', child: Text('Engorde')),
                                DropdownMenuItem(
                                    value: 'padrote', child: Text('Padrote')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedBreed,
                              isExpanded: true, // ✅ Evita overflow
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Raza *',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 10, // Reducido
                                  vertical: isTablet ? 10 : 8, // Reducido
                                ),
                              ),
                              items: _breedOptions.map((breed) {
                                return DropdownMenuItem<String>(
                                  value: breed,
                                  child: Text(
                                    breed,
                                    overflow: TextOverflow
                                        .ellipsis, // ✅ Evita overflow en textos largos
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBreed = value!;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La raza es obligatoria';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Precio *',
                                prefixText: '\$ ',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El precio es obligatorio';
                                }
                                final price = double.tryParse(value.trim());
                                if (price == null || price <= 0) {
                                  return 'Ingrese un precio válido';
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Moneda',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'USD', child: Text('USD')),
                                DropdownMenuItem(
                                    value: 'VES', child: Text('VES')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              onChanged: (_) {
                                _validateForm();
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.error, width: 2),
                                ),
                                labelText: 'Edad (años) *',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              validator: _validateAge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
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
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.error, width: 2),
                                ),
                                labelText: 'Cantidad *',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              validator: _validateQuantity,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 16),

                      // ✅ NUEVOS: Sexo y Propósito
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSex,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Sexo (opcional)',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: null, child: Text('No especificar')),
                                DropdownMenuItem(
                                    value: 'male', child: Text('Macho')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Hembra')),
                                DropdownMenuItem(
                                    value: 'mixed', child: Text('Mixto')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSex = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPurpose,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Propósito (opcional)',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: null, child: Text('No especificar')),
                                DropdownMenuItem(
                                    value: 'breeding',
                                    child: Text('Reproducción')),
                                DropdownMenuItem(
                                    value: 'meat', child: Text('Carne')),
                                DropdownMenuItem(
                                    value: 'dairy', child: Text('Lechería')),
                                DropdownMenuItem(
                                    value: 'mixed', child: Text('Mixto')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPurpose = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 16),

                      // ✅ NUEVO: Peso Promedio (campo principal)
                      TextFormField(
                        controller: _weightAvgController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          labelText: 'Peso Promedio (kg)',
                          hintText: 'Opcional - Peso promedio del lote',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 12 : 8,
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 20 : 16),

                      // ✅ NUEVOS: Rango de Peso (Mínimo y Máximo)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightMinController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Peso Mínimo (kg)',
                                hintText: 'Opcional',
                                prefixIcon: Icon(Icons.arrow_downward_rounded,
                                    size: 20),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
                          Expanded(
                            child: TextFormField(
                              controller: _weightMaxController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Peso Máximo (kg)',
                                hintText: 'Opcional',
                                prefixIcon:
                                    Icon(Icons.arrow_upward_rounded, size: 20),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                // Farm selection section
                _buildSection(
                  title: 'Información de la Finca',
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      final ranches = profileProvider.myRanches;
                      final isLoadingRanches =
                          profileProvider.isLoadingMyRanches;

                      return Column(
                        children: [
                          if (isLoadingRanches)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (ranches.isEmpty)
                            Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer
                                    .withOpacity(0.3),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 10),
                                border: Border.all(
                                  color:
                                      theme.colorScheme.error.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: theme.colorScheme.error,
                                    size: isTablet ? 48 : 40,
                                  ),
                                  SizedBox(height: isTablet ? 12 : 8),
                                  Text(
                                    'No tienes fincas registradas',
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 8 : 4),
                                  Text(
                                    'Debes crear una finca primero para poder publicar productos',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: theme.colorScheme.onErrorContainer
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: _selectedRanchId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Selecciona la Finca *',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              items: ranches.map((ranch) {
                                return DropdownMenuItem<int>(
                                  value: ranch.id,
                                  child: Text(ranch.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRanchId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Debes seleccionar una finca';
                                }
                                return null;
                              },
                            ),
                          SizedBox(height: isTablet ? 20 : 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            maxLength: 500,
                            onChanged: (_) {
                              _validateForm();
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 10),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 10),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 10),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.error, width: 2),
                              ),
                              labelText: 'Descripción *',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 12 : 8,
                              ),
                              helperText: 'Mínimo 10 caracteres, máximo 500',
                            ),
                            validator: _validateDescription,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                        ],
                      );
                    },
                  ),
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                // Featured checkbox and negotiable
                _buildSection(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _negotiable,
                            onChanged: (value) {
                              setState(() {
                                _negotiable = value ?? false;
                              });
                            },
                          ),
                          Flexible(
                            child: Text(
                              'Precio Negociable',
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _isFeatured,
                            onChanged: (value) {
                              setState(() {
                                _isFeatured = value ?? false;
                              });
                            },
                          ),
                          Flexible(
                            child: Text(
                              'Marcar como Publicación Destacada',
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ),
                        ],
                      ),
                      // ✅ NUEVO: Documentación Incluida
                      Row(
                        children: [
                          Checkbox(
                            value: _documentationIncluded,
                            onChanged: (value) {
                              setState(() {
                                _documentationIncluded = value ?? false;
                              });
                            },
                          ),
                          Flexible(
                            child: Text(
                              'Incluye Documentación (certificados, vacunas, etc.)',
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ),
                        ],
                      ),
                      // ✅ NUEVO: Vacunado
                      Row(
                        children: [
                          Checkbox(
                            value: _isVaccinated,
                            onChanged: (value) {
                              setState(() {
                                _isVaccinated = value ?? false;
                              });
                            },
                          ),
                          Flexible(
                            child: Text(
                              'Animales Vacunados',
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 40 : 32),
                // Action buttons
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 10),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 10),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: isTablet ? 20 : 18,
                                    width: isTablet ? 20 : 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Publicar',
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    String? title,
    String? subtitle,
    required Widget child,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: isTablet ? 16 : 12),
          ],
          child,
        ],
      ),
    );
  }
}
