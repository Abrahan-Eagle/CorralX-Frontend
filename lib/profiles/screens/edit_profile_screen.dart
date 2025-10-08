import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zonix/profiles/providers/profile_provider.dart';
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
  final _whatsappNumberController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedMaritalStatus;
  String? _selectedSex;
  bool _acceptsCalls = true;
  bool _acceptsWhatsapp = true;
  bool _acceptsEmails = true;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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
        _whatsappNumberController.text = profile.whatsappNumber ?? '';
        _bioController.text = profile.bio ?? '';
        _selectedDate = profile.dateOfBirth;
        _selectedMaritalStatus = profile.maritalStatus;
        _selectedSex = profile.sex;
        _acceptsCalls = profile.acceptsCalls;
        _acceptsWhatsapp = profile.acceptsWhatsapp;
        _acceptsEmails = profile.acceptsEmails;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _ciNumberController.dispose();
    _whatsappNumberController.dispose();
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
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Mayor de 18
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
              content: Text(profileProvider.updateError ?? 'Error al subir foto'),
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
      acceptsCalls: _acceptsCalls,
      acceptsWhatsapp: _acceptsWhatsapp,
      acceptsEmails: _acceptsEmails,
      whatsappNumber: _acceptsWhatsapp && _whatsappNumberController.text.trim().isNotEmpty
          ? _whatsappNumberController.text.trim()
          : null,
    );

    if (mounted) {
      if (success) {
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
            content: Text(profileProvider.updateError ?? 'Error al actualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurfaceVariant),
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
                          child: _selectedImage == null && profile?.photoUsers == null
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
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Segundo nombre
                  TextFormField(
                    controller: _middleNameController,
                    decoration: InputDecoration(
                      labelText: 'Segundo nombre',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Apellido
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Apellido *',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido es obligatorio';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Segundo apellido
                  TextFormField(
                    controller: _secondLastNameController,
                    decoration: InputDecoration(
                      labelText: 'Segundo apellido',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Biografía
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Biografía',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      hintText: 'Cuéntanos sobre ti...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      helperText: 'Máximo 500 caracteres',
                    ),
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // CI
                  TextFormField(
                    controller: _ciNumberController,
                    decoration: InputDecoration(
                      labelText: 'Cédula de Identidad *',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      hintText: 'V-12345678',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    enabled: profile?.isVerified != true, // No editable si está verificado
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La cédula es obligatoria';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Fecha de nacimiento
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento *',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        suffixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
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
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'single', child: Text('Soltero/a')),
                      DropdownMenuItem(value: 'married', child: Text('Casado/a')),
                      DropdownMenuItem(value: 'divorced', child: Text('Divorciado/a')),
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
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
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

                  // Sección de preferencias de contacto
                  Text(
                    'Preferencias de Contacto',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),

                  SizedBox(height: isTablet ? 16 : 12),

                  // Acepta llamadas
                  SwitchListTile(
                    title: Text(
                      'Acepto llamadas telefónicas',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    value: _acceptsCalls,
                    onChanged: (value) {
                      setState(() {
                        _acceptsCalls = value;
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Acepta WhatsApp
                  SwitchListTile(
                    title: Text(
                      'Acepto mensajes por WhatsApp',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    value: _acceptsWhatsapp,
                    onChanged: (value) {
                      setState(() {
                        _acceptsWhatsapp = value;
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Número de WhatsApp (solo si acepta WhatsApp)
                  if (_acceptsWhatsapp) ...[
                    SizedBox(height: isTablet ? 16 : 12),
                    TextFormField(
                      controller: _whatsappNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Número de WhatsApp',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        hintText: '04121234567',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        prefixIcon: Icon(Icons.phone, color: Colors.green),
                      ),
                    ),
                  ],

                  SizedBox(height: isTablet ? 16 : 12),

                  // Acepta emails
                  SwitchListTile(
                    title: Text(
                      'Acepto correos electrónicos',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    value: _acceptsEmails,
                    onChanged: (value) {
                      setState(() {
                        _acceptsEmails = value;
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
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
                          ...profileProvider.validationErrors!.entries.map((entry) {
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
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
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
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
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
