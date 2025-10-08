import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _breedController = TextEditingController();
    _ageController = TextEditingController();
    _quantityController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _breedController.dispose();
    _ageController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Métodos de normalización de texto (copiados del onboarding)
  String _capitalizeWords(String input) {
    final normalized =
        input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : (w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '')))
        .join(' ');
  }

  void _normalizeName(TextEditingController controller) {
    final original = controller.text;
    final selection = controller.selection;
    final normalized = _capitalizeWords(
        original.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), ''));
    if (original != normalized) {
      controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(
            offset: normalized.length.clamp(0, normalized.length)),
      );
    } else {
      // keep selection
      controller.selection = selection;
    }
  }

  // Métodos de validación
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFDF7),
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
        ),
        title: Text(
          'Publicar Nuevo Ganado',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1C18),
          ),
        ),
        centerTitle: true,
      ),
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
                // Photos section
                _buildSection(
                  title: 'Fotos del Animal (hasta 5)',
                  subtitle: 'La primera foto será la imagen de portada.',
                  child: Container(
                    height: isTablet ? 120 : 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4ED),
                      borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: isTablet ? 40 : 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          Text(
                            'Agregar fotos',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                            groupValue: 'sin-registro',
                            onChanged: (value) {},
                          ),
                          Text('Con Registro',
                              style: TextStyle(fontSize: isTablet ? 16 : 14)),
                          SizedBox(width: isTablet ? 32 : 24),
                          Radio<String>(
                            value: 'sin-registro',
                            groupValue: 'sin-registro',
                            onChanged: (value) {},
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
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                labelText: 'Tipo',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
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
                              onChanged: (value) {},
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
                          Expanded(
                            child: TextFormField(
                              controller: _breedController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                                LengthLimitingTextInputFormatter(50),
                              ],
                              onChanged: (_) {
                                _normalizeName(_breedController);
                                _validateForm();
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: const Color(0xFF386A20), width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 2),
                                ),
                                labelText: 'Raza *',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 12 : 8,
                                ),
                              ),
                              validator: _validateBreed,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
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
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: const Color(0xFF386A20), width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 2),
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
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide: BorderSide(
                                      color: const Color(0xFF386A20), width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 2),
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
                    ],
                  ),
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                // Farm selection section
                _buildSection(
                  title: 'Información de la Finca',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          labelText: 'Selecciona la Finca',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 12 : 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'farm1',
                              child: Text('Agropecuaria El Futuro')),
                          DropdownMenuItem(
                              value: 'farm2', child: Text('Hato La Esperanza')),
                        ],
                        onChanged: (value) {},
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
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                            borderSide: BorderSide(
                                color: const Color(0xFF386A20), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          labelText: 'Descripción *',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 12 : 8,
                          ),
                          helperText: 'Mínimo 10 caracteres, máximo 500',
                        ),
                        validator: _validateDescription,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ],
                  ),
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                // Featured checkbox
                _buildSection(
                  child: Row(
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (value) {},
                      ),
                      Flexible(
                        child: Text(
                          'Marcar como Publicación Destacada',
                          style: TextStyle(fontSize: isTablet ? 16 : 14),
                        ),
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
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 30 : 25),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF386A20),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 30 : 25),
                              ),
                            ),
                            child: Text(
                              'Publicar',
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
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
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4ED),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey,
                ),
              ),
            ],
            SizedBox(height: isTablet ? 20 : 16),
          ],
          child,
        ],
      ),
    );
  }
}
