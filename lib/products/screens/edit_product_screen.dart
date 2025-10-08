import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

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

  late String _selectedType;
  late String _selectedBreed;
  late String _selectedCurrency;
  late String _selectedSex;
  late String _selectedPurpose;
  late String _selectedDeliveryMethod;
  late String _selectedStatus;
  late bool _isVaccinated;
  late bool _negotiable;
  late bool _documentationIncluded;

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

    _selectedType = widget.product.type;
    _selectedBreed = widget.product.breed;
    _selectedCurrency = widget.product.currency;
    _selectedSex = widget.product.sex ?? 'mixed';
    _selectedPurpose = widget.product.purpose ?? 'mixed';
    _selectedDeliveryMethod = widget.product.deliveryMethod;
    _selectedStatus = widget.product.status;
    _isVaccinated = widget.product.isVaccinated ?? false;
    _negotiable = widget.product.negotiable;
    _documentationIncluded = widget.product.documentationIncluded ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _ageController.dispose();
    _weightAvgController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<ProductProvider>();

    final success = await provider.updateProduct(
      productId: widget.product.id,
      title: _titleController.text,
      description: _descriptionController.text,
      type: _selectedType,
      breed: _selectedBreed,
      age: int.tryParse(_ageController.text),
      quantity: int.tryParse(_quantityController.text),
      price: double.tryParse(_priceController.text),
      currency: _selectedCurrency,
      weightAvg: double.tryParse(_weightAvgController.text),
      sex: _selectedSex,
      purpose: _selectedPurpose,
      isVaccinated: _isVaccinated,
      deliveryMethod: _selectedDeliveryMethod,
      negotiable: _negotiable,
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

  String? _validateBreed(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La raza es obligatoria';
    }
    if (value.trim().length < 2) {
      return 'Mínimo 2 caracteres';
    }
    if (value.trim().length > 50) {
      return 'Máximo 50 caracteres';
    }
    // Validar que solo contenga letras y espacios
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value.trim())) {
      return 'Solo se permiten letras';
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

            // Tipo
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'lechero', child: Text('Lechero')),
                DropdownMenuItem(value: 'engorde', child: Text('Engorde')),
                DropdownMenuItem(value: 'padrote', child: Text('Padrote')),
                DropdownMenuItem(value: 'equipment', child: Text('Equipo')),
                DropdownMenuItem(value: 'feed', child: Text('Alimento')),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Raza
            TextFormField(
              initialValue: _selectedBreed,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                LengthLimitingTextInputFormatter(50),
              ],
              onChanged: (value) {
                _selectedBreed = value;
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Raza *',
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
                helperText: 'Solo letras, máximo 50 caracteres',
              ),
              validator: _validateBreed,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
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

            // Precio y Moneda
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) {
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Precio *',
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
                      helperText: 'Solo números',
                    ),
                    validator: _validatePrice,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Moneda',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'VES', child: Text('VES')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCurrency = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Peso promedio
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
                helperText: 'Máximo 10,000 kg',
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

            // Propósito
            DropdownButtonFormField<String>(
              value: _selectedPurpose,
              decoration: const InputDecoration(
                labelText: 'Propósito',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'breeding', child: Text('Cría')),
                DropdownMenuItem(value: 'meat', child: Text('Carne')),
                DropdownMenuItem(value: 'dairy', child: Text('Leche')),
                DropdownMenuItem(value: 'mixed', child: Text('Mixto')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPurpose = value);
                }
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

            // Switches
            SwitchListTile(
              title: const Text('Vacunado'),
              value: _isVaccinated,
              onChanged: (value) => setState(() => _isVaccinated = value),
            ),
            SwitchListTile(
              title: const Text('Precio Negociable'),
              value: _negotiable,
              onChanged: (value) => setState(() => _negotiable = value),
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
