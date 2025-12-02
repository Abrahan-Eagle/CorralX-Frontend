import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:corralx/profiles/providers/profile_provider.dart';
import 'package:corralx/profiles/services/profile_service.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  final _ciNumberController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedMaritalStatus;
  String? _selectedSex;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Estado de completitud
  bool _isCheckingCompleteness = false;
  bool _profileComplete = true;
  bool _ranchComplete = true;
  List<String> _missingProfileFields = [];
  List<String> _missingRanchFields = [];

  @override
  void initState() {
    super.initState();
    // Cargar datos actuales del perfil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      final profile = profileProvider.myProfile;

      if (profile != null) {
        _firstNameController.text = profile.firstName;
        _middleNameController.text = profile.middleName ?? '';
        _lastNameController.text = profile.lastName;
        _secondLastNameController.text = profile.secondLastName ?? '';
        _ciNumberController.text = profile.ciNumber;
        _bioController.text = profile.bio ?? '';
        _selectedDate = profile.dateOfBirth;
        _selectedMaritalStatus = profile.maritalStatus;
        _selectedSex = profile.sex;
        setState(() {});
      }
      // Verificar completitud al cargar
      _checkCompleteness();
    });
  }

  /// Verificar completitud del perfil y hacienda
  Future<void> _checkCompleteness() async {
    setState(() {
      _isCheckingCompleteness = true;
    });

    try {
      final result = await ProfileService.checkCompleteness();
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        setState(() {
          _profileComplete = data['profile_complete'] ?? true;
          _ranchComplete = data['ranch_complete'] ?? true;
          _missingProfileFields = List<String>.from(
            data['missing_profile_fields'] ?? [],
          );
          _missingRanchFields = List<String>.from(
            data['missing_ranch_fields'] ?? [],
          );
          _isCheckingCompleteness = false;
        });
      }
    } catch (e) {
      print('❌ Error al verificar completitud: $e');
      setState(() {
        _isCheckingCompleteness = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _ciNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // Mayor de 18
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  // Métodos de validación (copiados del onboarding)
  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El primer nombre es obligatorio';
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

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El apellido es obligatorio';
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

  String? _validateMiddleName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El segundo nombre es obligatorio';
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

  String? _validateSecondLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El segundo apellido es obligatorio';
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

  // Validaciones adicionales
  String? _validateBio(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 500) {
        return 'Máximo 500 caracteres';
      }
    }
    return null;
  }

  String? _validateCI(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == 'V-') {
      return 'El CI es obligatorio';
    }

    final ci = value.trim();

    // Validar formato de CI venezolano V-12345678
    final ciRegex = RegExp(r'^V-\d{7,8}$');
    if (!ciRegex.hasMatch(ci)) {
      return 'Formato: V-12345678 (7-8 dígitos)';
    }

    // Extraer solo los números para validar longitud
    final numbers = ci.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length < 7 || numbers.length > 8) {
      return 'El CI debe tener entre 7 y 8 dígitos';
    }

    return null;
  }

  // Método para validar el formulario en tiempo real
  void _validateForm() {
    setState(() {
      // Forzar rebuild para actualizar el estado de validación
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileProvider = context.read<ProfileProvider>();

    // Primero, subir la foto si hay una nueva
    if (_selectedImage != null) {
      final photoSuccess = await profileProvider.uploadPhoto(_selectedImage!);
      if (!photoSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(profileProvider.updateError ?? 'Error al subir foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Luego, actualizar el perfil
    final success = await profileProvider.updateProfile(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isNotEmpty
          ? _middleNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim(),
      secondLastName: _secondLastNameController.text.trim().isNotEmpty
          ? _secondLastNameController.text.trim()
          : null,
      bio: _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : null,
      dateOfBirth: _selectedDate,
      maritalStatus: _selectedMaritalStatus,
      sex: _selectedSex,
      ciNumber: _ciNumberController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Verificar completitud después de guardar
        await _checkCompleteness();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                profileProvider.updateError ?? 'Error al actualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Widget de banner de completitud
  Widget _buildCompletenessBanner(ThemeData theme, bool isTablet) {
    if (_isCheckingCompleteness) {
      return Container(
        margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Verificando completitud...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 14 : 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_profileComplete && _ranchComplete) {
      return Container(
        margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '✅ Tu perfil y hacienda están completos. Puedes publicar productos.',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Hay campos faltantes
    final allMissingFields = <String>[];
    if (!_profileComplete) {
      allMissingFields.addAll(_missingProfileFields.map((field) {
        final fieldNames = {
          'firstName': 'Primer Nombre',
          'middleName': 'Segundo Nombre',
          'lastName': 'Primer Apellido',
          'secondLastName': 'Segundo Apellido',
          'date_of_birth': 'Fecha de Nacimiento',
          'ci_number': 'Cédula de Identidad',
          'sex': 'Sexo',
          'user_type': 'Tipo de Usuario',
          'photo_users': 'Foto de Perfil',
        };
        return fieldNames[field] ?? field;
      }));
    }
    if (!_ranchComplete) {
      allMissingFields.addAll(_missingRanchFields.map((field) {
        final fieldNames = {
          'name': 'Nombre de la Hacienda',
          'address': 'Dirección',
          'address.city': 'Ciudad de la Dirección',
          'address.adressses': 'Dirección Detallada',
          'ranch': 'Hacienda Principal',
        };
        return fieldNames[field] ?? field;
      }));
    }

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Para publicar productos, completa los siguientes campos:',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (allMissingFields.isNotEmpty) ...[
            SizedBox(height: 8),
            ...allMissingFields.map((field) => Padding(
                  padding: EdgeInsets.only(left: 32, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.orange.shade700),
                      SizedBox(width: 8),
                      Text(
                        field,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: isTablet ? 13 : 11,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: theme.colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          final profile = profileProvider.myProfile;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner de completitud
                  _buildCompletenessBanner(theme, isTablet),
                  
                  // Foto de perfil
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: isTablet ? 80 : 64,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (profile?.photoUsers != null
                                  ? NetworkImage(profile!.photoUsers!)
                                  : null) as ImageProvider?,
                          child: _selectedImage == null &&
                                  profile?.photoUsers == null
                              ? Icon(
                                  Icons.person,
                                  size: isTablet ? 80 : 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 3,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                color: theme.colorScheme.onPrimary,
                                size: isTablet ? 24 : 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 32 : 24),

                  // Nombre
                  TextFormField(
                    controller: _firstNameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    onChanged: (_) {
                      _normalizeName(_firstNameController);
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Primer Nombre *',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 20 : 16,
                      ),
                    ),
                    validator: _validateFirstName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Segundo nombre
                  TextFormField(
                    controller: _middleNameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    onChanged: (_) {
                      _normalizeName(_middleNameController);
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Segundo Nombre *',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 20 : 16,
                      ),
                    ),
                    validator: _validateMiddleName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Apellido
                  TextFormField(
                    controller: _lastNameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    onChanged: (_) {
                      _normalizeName(_lastNameController);
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Primer Apellido *',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 20 : 16,
                      ),
                    ),
                    validator: _validateLastName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Segundo apellido
                  TextFormField(
                    controller: _secondLastNameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    onChanged: (_) {
                      _normalizeName(_secondLastNameController);
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Segundo Apellido *',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 20 : 16,
                      ),
                    ),
                    validator: _validateSecondLastName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Biografía
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (_) {
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Biografía',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      hintText: 'Cuéntanos sobre ti...',
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 20 : 16,
                      ),
                      helperText: 'Máximo 500 caracteres',
                    ),
                    validator: _validateBio,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // CI
                  TextFormField(
                    controller: _ciNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      _CIVenezuelaInputFormatter(),
                    ],
                    onChanged: (value) {
                      _validateForm();
                      // Asegurar que siempre tenga el prefijo V-
                      if (!value.startsWith('V-')) {
                        _ciNumberController.value = TextEditingValue(
                          text: 'V-',
                          selection: TextSelection.collapsed(offset: 2),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Cédula de Identidad *',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      hintText: 'V-12345678',
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 20 : 16,
                      ),
                    ),
                    enabled: profile?.isVerified !=
                        true, // No editable si está verificado
                    validator: _validateCI,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Fecha de nacimiento
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento *',
                        labelStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
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
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        suffixIcon: Icon(Icons.calendar_today,
                            color: theme.colorScheme.primary),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Selecciona una fecha',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Estado civil
                  DropdownButtonFormField<String>(
                    value: _selectedMaritalStatus,
                    decoration: InputDecoration(
                      labelText: 'Estado civil',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'single', child: Text('Soltero/a')),
                      DropdownMenuItem(
                          value: 'married', child: Text('Casado/a')),
                      DropdownMenuItem(
                          value: 'divorced', child: Text('Divorciado/a')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMaritalStatus = value;
                      });
                    },
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Sexo
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    decoration: InputDecoration(
                      labelText: 'Sexo',
                      labelStyle:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Masculino')),
                      DropdownMenuItem(value: 'F', child: Text('Femenino')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSex = value;
                      });
                    },
                  ),

                  SizedBox(height: isTablet ? 32 : 24),

                  // Errores de validación del servidor
                  if (profileProvider.validationErrors != null) ...[
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Errores de validación:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...profileProvider.validationErrors!.entries
                              .map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${entry.value}',
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                  ],

                  // Botón guardar
                  ElevatedButton(
                    onPressed: profileProvider.isUpdating ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding:
                          EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: profileProvider.isUpdating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  SizedBox(height: isTablet ? 16 : 12),

                  // Nota sobre verificación
                  if (profile?.isVerified != true)
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onSecondaryContainer,
                            size: isTablet ? 24 : 20,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: Text(
                              'Tu cuenta no está verificada. Algunos campos no podrán editarse una vez verificada.',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: theme.colorScheme.onSecondaryContainer,
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
        },
      ),
    );
  }
}

// Formatter para CI venezolano (copiado del onboarding)
class _CIVenezuelaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permitir solo números
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limitar a 8 dígitos máximo
    if (newText.length > 8) {
      newText = newText.substring(0, 8);
    }

    // Si está vacío, retornar V-
    if (newText.isEmpty) {
      return TextEditingValue(
        text: 'V-',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    // Formatear como V-12345678
    String formattedText = 'V-$newText';

    // Calcular la posición del cursor
    int cursorPosition = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
