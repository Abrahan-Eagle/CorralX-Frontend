import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/profile_provider.dart';
import '../services/ranch_service.dart';
import '../../shared/services/location_service.dart';
import '../../profiles/services/address_service.dart';

class CreateRanchScreen extends StatefulWidget {
  const CreateRanchScreen({super.key});

  @override
  State<CreateRanchScreen> createState() => _CreateRanchScreenState();
}

class _CreateRanchScreenState extends State<CreateRanchScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _legalNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _descriptionController;

  // Horarios predefinidos
  final List<String> _predefinedSchedules = [
    'Lunes a Viernes 8:00 AM - 5:00 PM',
    'Lunes a Sábado 8:00 AM - 12:00 PM',
    'Lunes a Domingo 8:00 AM - 5:00 PM',
    '24/7 Disponible',
  ];

  String? _selectedSchedule; // Selección única
  late TextEditingController _deliveryPolicyController;
  late TextEditingController _returnPolicyController;

  // Nuevos campos de certificaciones
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
  String? _businessLicenseUrl;

  // Campos de ubicación
  late TextEditingController _addressDetailController;
  int? _selectedCountryId;
  int? _selectedStateId;
  int? _selectedCityId;
  int? _selectedParishId;

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _parishes = [];

  // GPS
  double? _latitude;
  double? _longitude;
  bool _isCapturingGPS = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores vacíos
    _nameController = TextEditingController();
    _legalNameController = TextEditingController();
    _taxIdController = TextEditingController(text: 'J-');
    _descriptionController = TextEditingController();
    _deliveryPolicyController = TextEditingController();
    _returnPolicyController = TextEditingController();
    _addressDetailController = TextEditingController();

    // Cargar países y pre-seleccionar Venezuela
    _loadCountries();

    // Capturar GPS automáticamente (silencioso)
    _captureGPSAutomatically();
  }

  /// Captura GPS automáticamente en segundo plano
  Future<void> _captureGPSAutomatically() async {
    if (_isCapturingGPS) return;

    setState(() => _isCapturingGPS = true);

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permisos de ubicación denegados');
        setState(() => _isCapturingGPS = false);
        return;
      }

      // Obtener posición actual
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isCapturingGPS = false;
        });
        debugPrint('📍 GPS capturado: $_latitude, $_longitude');
      }
    } catch (e) {
      debugPrint('❌ Error capturando GPS: $e');
      setState(() => _isCapturingGPS = false);
    }
  }

  // Métodos para cargar ubicaciones
  Future<void> _loadCountries() async {
    try {
      final countries = await LocationService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
        });

        // Pre-seleccionar Venezuela por defecto
        final venezuela = countries.firstWhere(
          (country) => country['name'] == 'Venezuela',
          orElse: () => {},
        );
        
        if (venezuela.isNotEmpty && mounted) {
          final venezuelaId = venezuela['id'] as int;
          setState(() {
            _selectedCountryId = venezuelaId;
          });
          // Cargar estados de Venezuela automáticamente
          await _loadStates(venezuelaId);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading countries: $e');
    }
  }

  Future<void> _loadStates(int countryId) async {
    try {
      final states = await LocationService.getStates(countryId);
      if (mounted) {
        setState(() {
          _states = states;
          _selectedStateId = null;
          _selectedCityId = null;
          _cities.clear();
          _parishes.clear();
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading states: $e');
    }
  }

  Future<void> _loadCities(int stateId) async {
    try {
      final cities = await LocationService.getCities(stateId);
      if (mounted) {
        setState(() {
          _cities = cities;
          _selectedCityId = null;
          _parishes.clear();
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading cities: $e');
    }
  }

  Future<void> _loadParishes(int cityId) async {
    try {
      final parishes = await LocationService.getParishes(cityId);
      if (mounted) {
        setState(() {
          _parishes = parishes;
          _selectedParishId = null;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading parishes: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _descriptionController.dispose();
    _deliveryPolicyController.dispose();
    _returnPolicyController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int? addressId;

      // PASO 1: Crear dirección si se proporcionó ubicación
      if (_selectedCityId != null &&
          _addressDetailController.text.trim().isNotEmpty) {
        final profileProvider = context.read<ProfileProvider>();
        final profileId = profileProvider.myProfile?.id;

        if (profileId == null) {
          throw Exception('No se encontró el perfil del usuario');
        }

        final addressResult = await AddressService.createAddress(
          profileId: profileId,
          cityId: _selectedCityId!,
          addressDetail: _addressDetailController.text.trim(),
          latitude: _latitude ?? 0.0, // GPS capturado automáticamente
          longitude: _longitude ?? 0.0,
          level: 'ranches', // Dirección de hacienda
        );

        if (addressResult['success'] == true) {
          final newAddress = addressResult['address'];
          addressId = newAddress['id'] as int;
        } else {
          throw Exception(
              addressResult['message'] ?? 'Error al crear dirección');
        }
      }

      // PASO 2: Crear ranch
      final result = await RanchService.createRanch(
        name: _nameController.text,
        legalName: _legalNameController.text.isNotEmpty
            ? _legalNameController.text
            : null,
        taxId: _taxIdController.text.isNotEmpty && _taxIdController.text != 'J-'
            ? _taxIdController.text
            : null,
        businessDescription: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        certifications:
            _selectedCertifications.isNotEmpty ? _selectedCertifications : null,
        businessLicenseUrl: _businessLicenseUrl,
        contactHours: _selectedSchedule,
        addressId: addressId, // Asignar el address_id al ranch
        deliveryPolicy: _deliveryPolicyController.text.isNotEmpty
            ? _deliveryPolicyController.text
            : null,
        returnPolicy: _returnPolicyController.text.isNotEmpty
            ? _returnPolicyController.text
            : null,
      );

      setState(() => _isSubmitting = false);

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Hacienda creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Refrescar ranches en ProfileProvider
        await context
            .read<ProfileProvider>()
            .fetchMyRanches(forceRefresh: true);

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al crear hacienda'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Métodos de normalización de texto
  String _capitalizeWords(String input) {
    // NO eliminar espacios múltiples, solo normalizar espacios excesivos
    final normalized = input.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
    return normalized
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : (w[0].toUpperCase() +
                (w.length > 1 ? w.substring(1).toLowerCase() : '')))
        .join(' ');
  }

  void _normalizeName(TextEditingController controller) {
    final original = controller.text;
    final selection = controller.selection;

    // Solo remover caracteres especiales, MANTENER espacios
    final cleaned =
        original.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s]'), '');

    // Solo capitalizar si hubo cambios (se removieron caracteres)
    if (cleaned != original) {
      final normalized = _capitalizeWords(cleaned);
      controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(
            offset: normalized.length.clamp(0, normalized.length)),
      );
    } else {
      // Mantener selección actual para permitir escribir espacios
      controller.selection = selection;
    }
  }

  // Métodos de validación
  String? _validateRanchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la hacienda es obligatorio';
    }
    if (value.trim().length < 2) {
      return 'Mínimo 2 caracteres';
    }
    if (value.trim().length > 100) {
      return 'Máximo 100 caracteres';
    }
    return null;
  }

  String? _validateLegalName(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length < 2) {
        return 'Mínimo 2 caracteres';
      }
      if (value.trim().length > 100) {
        return 'Máximo 100 caracteres';
      }
    }
    return null;
  }

  String? _validateTaxId(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim() != 'J-') {
      if (value.trim().length < 7) {
        return 'Mínimo 7 caracteres';
      }
      if (value.trim().length > 12) {
        return 'Máximo 12 caracteres';
      }
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 500) {
        return 'Máximo 500 caracteres';
      }
    }
    return null;
  }

  void _validateForm() {
    setState(() {});
  }

  /// Widget para la sección de Certificaciones
  Widget _buildCertificationsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificaciones',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCertificationsModal(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _selectedCertifications.isEmpty
                      ? Text(
                          'Selecciona certificaciones',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedCertifications
                              .map((cert) => Chip(
                                    label: Text(
                                      cert,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Certificaciones sanitarias y de calidad de la hacienda',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Widget para la sección de Documento de Licencia
  Widget _buildBusinessLicenseSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documento de Licencia Comercial',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_businessLicenseUrl != null) ...[
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Documento cargado',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _businessLicenseUrl = null;
                        });
                      },
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error),
                      tooltip: 'Eliminar documento',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _businessLicenseUrl!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.upload_file,
                        color: theme.colorScheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No hay documento cargado',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar file picker para subir documento
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Función de carga de documentos próximamente disponible'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Cargar Documento'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'RIF, licencia comercial o certificados sanitarios (PDF o imagen)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget para la sección de Ubicación con selects anidados
  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación de la Hacienda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Dirección detallada PRIMERO
        TextFormField(
          controller: _addressDetailController,
          maxLines: 2,
          maxLength: 255,
          decoration: InputDecoration(
            labelText: 'Dirección Detallada *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            prefixIcon:
                Icon(Icons.home_outlined, color: theme.colorScheme.primary),
            helperText: 'Ej: Carretera Nacional, Km 45, Sector Los Uveros',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa la dirección detallada';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Select País
        DropdownButtonFormField<int>(
          value: _selectedCountryId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'País *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            prefixIcon: Icon(Icons.public, color: theme.colorScheme.primary),
          ),
          items: _countries.map((country) {
            return DropdownMenuItem<int>(
              value: country['id'] as int,
              child: Text(
                country['name'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCountryId = value;
              });
              _loadStates(value);
            }
          },
          validator: (value) => value == null ? 'Selecciona un país' : null,
        ),
        const SizedBox(height: 16),

        // Select Estado
        DropdownButtonFormField<int>(
          value: _selectedStateId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Estado *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            prefixIcon: Icon(Icons.map, color: theme.colorScheme.primary),
          ),
          items: _states.map((state) {
            return DropdownMenuItem<int>(
              value: state['id'] as int,
              child: Text(
                state['name'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _selectedCountryId == null
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStateId = value;
                    });
                    _loadCities(value);
                  }
                },
          validator: (value) => value == null ? 'Selecciona un estado' : null,
        ),
        const SizedBox(height: 16),

        // Select Ciudad
        DropdownButtonFormField<int>(
          value: _selectedCityId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Ciudad *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            prefixIcon:
                Icon(Icons.location_city, color: theme.colorScheme.primary),
          ),
          items: _cities.map((city) {
            return DropdownMenuItem<int>(
              value: city['id'] as int,
              child: Text(
                city['name'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _selectedStateId == null
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCityId = value;
                    });
                    _loadParishes(value);
                  }
                },
          validator: (value) => value == null ? 'Selecciona una ciudad' : null,
        ),
        const SizedBox(height: 16),

        // Select Parroquia (opcional)
        if (_parishes.isNotEmpty) ...[
          DropdownButtonFormField<int>(
            value: _selectedParishId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Parroquia',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              prefixIcon: Icon(Icons.location_on_outlined,
                  color: theme.colorScheme.primary),
            ),
            items: _parishes.map((parish) {
              return DropdownMenuItem<int>(
                value: parish['id'] as int,
                child: Text(
                  parish['name'] ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedParishId = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// Modal para seleccionar certificaciones
  Future<void> _showCertificationsModal(BuildContext context) async {
    final theme = Theme.of(context);
    List<String> tempSelected = List.from(_selectedCertifications);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_outlined,
                            color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Certificaciones',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona las certificaciones que posee tu hacienda',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: _availableCertifications.map((cert) {
                          final isSelected = tempSelected.contains(cert);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelected.add(cert);
                                } else {
                                  tempSelected.remove(cert);
                                }
                              });
                            },
                            title: Text(cert),
                            activeColor: theme.colorScheme.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCertifications = tempSelected;
                            });
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modal para seleccionar horarios
  Future<void> _showScheduleModal(BuildContext context) async {
    final theme = Theme.of(context);
    String? tempSelectedSchedule = _selectedSchedule;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Horario de Atención',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona un horario',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Horarios predefinidos
                      ..._predefinedSchedules.map((schedule) {
                      final isSelected = tempSelectedSchedule == schedule;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              tempSelectedSchedule = schedule;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline
                                        .withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    schedule,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Botón para horario personalizado
                    OutlinedButton.icon(
                      onPressed: () async {
                        final customSchedule =
                            await _showCustomScheduleDialog(context);
                        if (customSchedule != null) {
                          setModalState(() {
                            tempSelectedSchedule = customSchedule;
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Horario Personalizado'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedSchedule = tempSelectedSchedule;
                            });
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Diálogo para crear horario personalizado
  Future<String?> _showCustomScheduleDialog(BuildContext context) async {
    final theme = Theme.of(context);
    String selectedDays = 'Lunes a Viernes';
    String selectedStartTime = '8:00 AM';
    String selectedEndTime = '5:00 PM';

    final days = [
      'Lunes a Viernes',
      'Lunes a Sábado',
      'Lunes a Domingo',
      'Fines de Semana',
    ];

    final times = [
      '6:00 AM',
      '7:00 AM',
      '8:00 AM',
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
      '6:00 PM',
      '7:00 PM',
      '8:00 PM',
    ];

    return await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 550),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_calendar,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Horario Personalizado',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Selector de días
                        Text(
                          'Días',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedDays,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          items: days.map((day) {
                            return DropdownMenuItem(
                                value: day, child: Text(day));
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDays = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Selector de horas
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Desde',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selectedStartTime,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    items: times.map((time) {
                                      return DropdownMenuItem(
                                          value: time, child: Text(time));
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedStartTime = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hasta',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selectedEndTime,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    items: times.map((time) {
                                      return DropdownMenuItem(
                                          value: time, child: Text(time));
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedEndTime = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.preview,
                                  size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$selectedDays $selectedStartTime - $selectedEndTime',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                final customSchedule =
                                    '$selectedDays $selectedStartTime - $selectedEndTime';
                                Navigator.pop(dialogContext, customSchedule);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: const Text('Agregar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Hacienda'),
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre de la hacienda
            TextFormField(
              controller: _nameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s]')),
                LengthLimitingTextInputFormatter(100),
              ],
              onChanged: (_) {
                _normalizeName(_nameController);
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Nombre de la Hacienda *',
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
                helperText: 'Nombre comercial de tu hacienda',
              ),
              validator: _validateRanchName,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // Razón social
            TextFormField(
              controller: _legalNameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s]')),
                LengthLimitingTextInputFormatter(100),
              ],
              onChanged: (_) {
                _normalizeName(_legalNameController);
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Razón Social',
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
                helperText: 'Nombre legal de la empresa',
              ),
              validator: _validateLegalName,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // RIF/NIT
            TextFormField(
              controller: _taxIdController,
              keyboardType: TextInputType.text,
              inputFormatters: [
                _RIFVenezuelaInputFormatter(),
              ],
              onChanged: (value) {
                _validateForm();
                if (!value.startsWith('J-')) {
                  _taxIdController.value = TextEditingValue(
                    text: 'J-',
                    selection: TextSelection.collapsed(offset: 2),
                  );
                }
              },
              decoration: InputDecoration(
                labelText: 'RIF/NIT',
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
                helperText: 'Identificación fiscal (Ej: J-12345678-9)',
              ),
              validator: _validateTaxId,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // Descripción del negocio
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) {
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Descripción del Negocio',
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
                helperText: 'Máximo 500 caracteres',
              ),
              validator: _validateDescription,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // Horario de atención - Input con modal
            InkWell(
              onTap: () => _showScheduleModal(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Horario de Atención',
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
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon:
                      Icon(Icons.schedule, color: theme.colorScheme.primary),
                ),
                child: _selectedSchedule == null
                    ? Text(
                        'Selecciona horario de atención',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        _selectedSchedule!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Política de entrega
            TextFormField(
              controller: _deliveryPolicyController,
              maxLines: 2,
              maxLength: 300,
              onChanged: (_) {
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Política de Entrega',
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
                helperText: 'Máximo 300 caracteres',
              ),
            ),
            const SizedBox(height: 16),

            // Certificaciones
            _buildCertificationsSection(theme),
            const SizedBox(height: 16),

            // Documento de Licencia
            _buildBusinessLicenseSection(theme),
            const SizedBox(height: 16),

            // Información de Ubicación
            _buildLocationSection(theme),
            const SizedBox(height: 16),

            // Política de devolución
            TextFormField(
              controller: _returnPolicyController,
              maxLines: 2,
              maxLength: 300,
              onChanged: (_) {
                _validateForm();
              },
              decoration: InputDecoration(
                labelText: 'Política de Devolución',
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
                helperText: 'Máximo 300 caracteres',
              ),
            ),
            const SizedBox(height: 24),

            // Botón Crear
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
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
                  : const Text(
                      'Crear Hacienda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Formatter para RIF venezolano (J-12345678-9)
class _RIFVenezuelaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permitir solo números
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limitar a 9 dígitos máximo (RIF empresarial)
    if (newText.length > 9) {
      newText = newText.substring(0, 9);
    }

    // Si está vacío, retornar J-
    if (newText.isEmpty) {
      return TextEditingValue(
        text: 'J-',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    // Formatear como J-12345678-9
    String formattedText;
    if (newText.length <= 8) {
      // Si tiene 8 o menos dígitos, formato: J-12345678
      formattedText = 'J-$newText';
    } else {
      // Si tiene 9 dígitos, formato: J-12345678-9
      formattedText = 'J-${newText.substring(0, 8)}-${newText.substring(8)}';
    }

    // Calcular la posición del cursor
    int cursorPosition = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
