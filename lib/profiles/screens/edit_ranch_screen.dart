import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import '../models/ranch.dart';
import '../providers/profile_provider.dart';
import '../services/ranch_service.dart';
import '../../shared/services/location_service.dart';
import '../../profiles/services/address_service.dart';

class EditRanchScreen extends StatefulWidget {
  final Ranch ranch;

  const EditRanchScreen({
    super.key,
    required this.ranch,
  });

  @override
  State<EditRanchScreen> createState() => _EditRanchScreenState();
}

class _EditRanchScreenState extends State<EditRanchScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _legalNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _descriptionController;
  late TextEditingController _contactHoursController;

  // Horarios predefinidos
  final List<String> _predefinedSchedules = [
    'Lunes a Viernes 8:00 AM - 5:00 PM',
    'Lunes a Sábado 8:00 AM - 12:00 PM',
    'Lunes a Domingo 8:00 AM - 5:00 PM',
    '24/7 Disponible',
  ];

  String? _selectedSchedule; // Cambiar a selección única
  late TextEditingController _deliveryPolicyController;
  late TextEditingController _returnPolicyController;

  // Nuevos campos
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
  List<Map<String, dynamic>> _existingDocuments = [];
  final List<_SelectedDoc> _pendingDocuments = [];

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

  int? _existingAddressId;

  // GPS
  double? _latitude;
  double? _longitude;
  bool _isCapturingGPS = false;

  late bool _isPrimary;
  bool _isSubmitting = false;

  // Clase helper local para documentos pendientes

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con datos existentes
    _nameController = TextEditingController(text: widget.ranch.name);
    _legalNameController =
        TextEditingController(text: widget.ranch.legalName ?? '');
    _taxIdController = TextEditingController(text: widget.ranch.taxId ?? '');
    _descriptionController =
        TextEditingController(text: widget.ranch.businessDescription ?? '');
    _contactHoursController =
        TextEditingController(text: widget.ranch.contactHours ?? '');

    // Cargar horario seleccionado si existe
    if (widget.ranch.contactHours != null &&
        widget.ranch.contactHours!.isNotEmpty) {
      _selectedSchedule = widget.ranch.contactHours;
    }

    _deliveryPolicyController =
        TextEditingController(text: widget.ranch.deliveryPolicy ?? '');
    _returnPolicyController =
        TextEditingController(text: widget.ranch.returnPolicy ?? '');

    // Inicializar certificaciones y documento
    _selectedCertifications = widget.ranch.certifications ?? [];
    _businessLicenseUrl = widget.ranch.businessLicenseUrl;
    _existingDocuments = widget.ranch.documents ?? [];

    // Inicializar dirección
    _addressDetailController =
        TextEditingController(text: widget.ranch.address?.addresses ?? '');
    _existingAddressId = widget.ranch.address?.id;

    // Si ya tiene dirección, inicializar los IDs y coordenadas
    if (widget.ranch.address != null) {
      _selectedCityId = widget.ranch.address!.cityId;
      _latitude = widget.ranch.address!.latitude;
      _longitude = widget.ranch.address!.longitude;
      // Cargaremos los países, estados, ciudades para mostrar la selección actual
      _loadCountries();
    } else {
      // Si no tiene dirección, solo cargar países
      _loadCountries();
    }

    _isPrimary = widget.ranch.isPrimary;

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

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _descriptionController.dispose();
    _contactHoursController.dispose();
    _deliveryPolicyController.dispose();
    _returnPolicyController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  // Métodos para cargar ubicaciones
  Future<void> _loadCountries() async {
    try {
      final countries = await LocationService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
        });

        // Si ya tiene dirección, cargar los datos de ubicación existentes
        if (widget.ranch.address != null) {
          await _loadLocationHierarchy();
        } else {
          // Si NO tiene dirección, pre-seleccionar Venezuela por defecto
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
      }
    } catch (e) {
      debugPrint('❌ Error loading countries: $e');
    }
  }

  Future<void> _loadLocationHierarchy() async {
    // Este método carga la jerarquía completa cuando ya existe una dirección
    try {
      final address = widget.ranch.address!;
      final cityData = address.city;

      if (cityData != null && cityData['state'] != null) {
        final stateData = cityData['state'] as Map<String, dynamic>;
        final countryData = stateData['country'] as Map<String, dynamic>?;

        if (countryData != null) {
          final countryId = countryData['id'] as int;
          final stateId = stateData['id'] as int;
          final cityId = cityData['id'] as int;

          // Establecer el país seleccionado
          _selectedCountryId = countryId;

          // Cargar estados de ese país
          final states = await LocationService.getStates(countryId);
          if (mounted) {
            setState(() {
              _states = states;
              _selectedStateId = stateId;
            });
          }

          // Cargar ciudades de ese estado
          final cities = await LocationService.getCities(stateId);
          if (mounted) {
            setState(() {
              _cities = cities;
              _selectedCityId = cityId;
            });
          }

          // Si tiene parroquia, cargarla
          if (address.parishId != null) {
            final parishes = await LocationService.getParishes(cityId);
            if (mounted) {
              setState(() {
                _parishes = parishes;
                _selectedParishId = address.parishId;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading location hierarchy: $e');
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int? addressId = _existingAddressId;

      // PASO 1: Crear o actualizar dirección si se proporcionó ubicación
      if (_selectedCityId != null &&
          _addressDetailController.text.trim().isNotEmpty) {
        if (_existingAddressId != null) {
          // Actualizar dirección existente
          final addressResult = await AddressService.updateAddress(
            addressId: _existingAddressId!,
            cityId: _selectedCityId,
            addressDetail: _addressDetailController.text.trim(),
            latitude: _latitude ?? 0.0, // GPS capturado automáticamente
            longitude: _longitude ?? 0.0,
            level: 'ranches', // Dirección de hacienda
          );

          if (addressResult['success'] != true) {
            throw Exception(
                addressResult['message'] ?? 'Error al actualizar dirección');
          }
        } else {
          // Crear nueva dirección
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
      }

      // PASO 2: Actualizar ranch
      final result = await RanchService.updateRanch(
        ranchId: widget.ranch.id,
        name: _nameController.text,
        legalName: _legalNameController.text.isNotEmpty
            ? _legalNameController.text
            : null,
        taxId: _taxIdController.text.isNotEmpty ? _taxIdController.text : null,
        businessDescription: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        certifications:
            _selectedCertifications.isNotEmpty ? _selectedCertifications : null,
        businessLicenseUrl: (_businessLicenseUrl != null &&
                !_businessLicenseUrl!.startsWith('http'))
            ? null
            : _businessLicenseUrl,
        contactHours: _selectedSchedule,
        addressId: addressId, // Asignar el address_id al ranch
        isPrimary: _isPrimary,
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
            content: Text('✅ Hacienda actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Subir documentos pendientes (hasta alcanzar 5)
        try {
          for (final doc in _pendingDocuments) {
            final upload = await RanchService.uploadRanchDocument(
              ranchId: widget.ranch.id,
              filePath: doc.path,
              certificationType: doc.certificationType,
            );
            if (upload['success'] == true) {
              _existingDocuments
                  .add(Map<String, dynamic>.from(upload['document']));
            }
          }
          if (mounted && _pendingDocuments.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📄 Documentos subidos correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
          setState(() {
            _pendingDocuments.clear();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error subiendo documentos: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }

        // Refrescar ranches en ProfileProvider
        await context
            .read<ProfileProvider>()
            .fetchMyRanches(forceRefresh: true);

        if (mounted) {
          // Volver a la vista anterior (lista de haciendas en Mi Perfil)
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al actualizar hacienda'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSubmitting = false);
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

  /// Seleccionar documento usando file_picker (solo PDF)
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;

        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo no puede superar los 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final path = file.path!;
        if (!path.toLowerCase().endsWith('.pdf')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solo se permiten archivos PDF'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _pendingDocuments.add(_SelectedDoc(
            path: path,
            fileName: file.name,
            certificationType: null,
          ));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Documento agregado: ${file.name}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Normalizar razón social preservando acrónimos en mayúsculas
  String _normalizeLegalName(String input) {
    // Lista de acrónimos comunes en Venezuela (en mayúsculas)
    final acronyms = {
      'C.A.',
      'S.A.',
      'S.R.L.',
      'C. POR A.',
      'S.C.S.',
      'S.C.A.',
      'R.L.',
      'E.I.R.L.',
      'S.A.S.',
      'C.A',
      'S.A',
      'S.R.L',
      'R.L',
      // También variaciones sin puntos
      'CA',
      'SA',
      'SRL',
      'RL',
    };

    // Solo eliminar espacios al inicio, mantener espacios al final
    // Normalizar espacios múltiples (pero no eliminar espacios al final)
    String normalized = input;
    if (normalized.isNotEmpty) {
      // Eliminar espacios al inicio
      normalized = normalized.replaceFirst(RegExp(r'^\s+'), '');
      // Normalizar espacios múltiples (pero no eliminar espacios al final)
      normalized = normalized.replaceAll(RegExp(r'[ \t]+'), ' ');
    }

    // Primero, detectar y reemplazar patrones especiales como "C. por A." antes de dividir
    // Patrón: una letra, punto opcional, espacio, "por", espacio, una letra, punto opcional
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b([A-Z]\.?)\s+por\s+([A-Z]\.?)\b', caseSensitive: false),
      (match) => '${match.group(1)!.toUpperCase()} POR ${match.group(2)!.toUpperCase()}',
    );

    // Dividir el texto en palabras
    final words = normalized.split(' ');
    final wordsCount = words.length;

    // Procesar cada palabra
    final processedWords = words.asMap().entries.map((entry) {
      final index = entry.key;
      final word = entry.value;
      final isLastWord = index == wordsCount - 1;

      if (word.isEmpty) return word;

      // Si la palabra es "POR" (parte de "C. POR A."), mantenerla en mayúsculas
      if (word.toUpperCase() == 'POR') {
        return 'POR';
      }

      // Convertir a mayúsculas para comparar con acrónimos
      final upperWord = word.toUpperCase();
      final upperWordNoDot = word.replaceAll('.', '').toUpperCase();

      // Si la palabra es un acrónimo conocido (con formato exacto), mantenerla en mayúsculas
      if (acronyms.contains(upperWord)) {
        // Ya tiene el formato correcto (con puntos)
        return upperWord;
      }

      // Si la palabra sin puntos es un acrónimo conocido Y está al final, formatear
      if (acronyms.contains(upperWordNoDot) && isLastWord && word.length <= 4) {
        // Formatear acrónimo: CA -> C.A., SRL -> S.R.L.
        if (word.length == 2) {
          return '${word[0].toUpperCase()}.${word[1].toUpperCase()}.';
        } else if (word.length == 3) {
          return '${word[0].toUpperCase()}.${word[1].toUpperCase()}.${word[2].toUpperCase()}.';
        } else if (word.length == 4) {
          return '${word[0].toUpperCase()}.${word[1].toUpperCase()}.${word[2].toUpperCase()}.${word[3].toUpperCase()}.';
        }
        return upperWord;
      }

      // Detectar patrones de acrónimos con punto (mantener en mayúsculas)
      // Ejemplos: C., S., C.A., S.A., S.R.L., etc.
      if (word.contains('.')) {
        // Si tiene punto, verificar si es un patrón de acrónimo
        if (RegExp(r'^[A-Z]{1,3}\.?$', caseSensitive: false).hasMatch(word)) {
          return word.toUpperCase();
        }
        // Si tiene múltiples puntos (C.A., S.R.L.), mantener en mayúsculas
        if (word.split('.').length > 2) {
          return word.toUpperCase();
        }
      }

      // Para palabras normales, capitalizar normalmente
      return word[0].toUpperCase() +
          (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).toList();

    return processedWords.join(' ');
  }

  // Normalizar razón social preservando acrónimos
  void _normalizeLegalNameField(TextEditingController controller) {
    final original = controller.text;
    final selection = controller.selection;

    // Permitir letras, números, espacios y puntos
    final cleaned = original.replaceAll(
        RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s.]'), '');

    // Solo eliminar espacios al inicio, mantener espacios al final si el cursor está allí
    // Normalizar espacios múltiples (pero no eliminar espacios al final)
    String normalized = cleaned;
    if (normalized.isNotEmpty) {
      // Eliminar espacios al inicio
      normalized = normalized.replaceFirst(RegExp(r'^\s+'), '');
      // Normalizar espacios múltiples (pero no eliminar espacios al final)
      normalized = normalized.replaceAll(RegExp(r'[ \t]+'), ' ');
    }

    // Aplicar normalización preservando acrónimos
    final finalText = _normalizeLegalName(normalized);

    if (finalText != original) {
      // Calcular nueva posición del cursor preservando la posición relativa
      int newOffset = selection.baseOffset;
      if (newOffset > finalText.length) {
        newOffset = finalText.length;
      }
      controller.value = TextEditingValue(
        text: finalText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    } else {
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
    if (value != null && value.trim().isNotEmpty) {
      final rif = value.trim().toUpperCase();

      // Validar formato: V-12345678-9 o J-12345678-9
      final rifRegex = RegExp(r'^(V|J)-\d{8}-\d$');
      if (!rifRegex.hasMatch(rif)) {
        return 'Formato: V-12345678-9 o J-12345678-9';
      }

      // Validar que tenga exactamente 9 dígitos
      final numbers = rif.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbers.length != 9) {
        return 'El RIF debe tener 9 dígitos';
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

  String? _validatePolicy(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 300) {
        return 'Máximo 300 caracteres';
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
          'Documentos de la Hacienda (hasta 5, solo PDF)',
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
              // Documentos existentes
              if (_existingDocuments.isNotEmpty) ...[
                ..._existingDocuments.map((doc) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (doc['original_filename'] ?? 'Documento PDF')
                                      .toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (doc['certification_type'] != null)
                                  Text(
                                    'Certificación: ${doc['certification_type']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              try {
                                await RanchService.deleteRanchDocument(
                                  ranchId: widget.ranch.id,
                                  documentId: (doc['id'] as int),
                                );
                                setState(() {
                                  _existingDocuments.remove(doc);
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Documento eliminado'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al eliminar: $e'),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(Icons.delete_outline,
                                color: theme.colorScheme.error),
                            tooltip: 'Eliminar',
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Documentos pendientes por subir
              if (_pendingDocuments.isNotEmpty) ...[
                ..._pendingDocuments.map((doc) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.picture_as_pdf,
                                  color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.fileName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _pendingDocuments.remove(doc);
                                  });
                                },
                                icon: Icon(Icons.delete_outline,
                                    color: theme.colorScheme.error),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: doc.certificationType,
                            decoration: InputDecoration(
                              labelText: 'Tipo de certificación (opcional)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                            items: _availableCertifications
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                doc.certificationType = val;
                              });
                            },
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Botón agregar documento
              OutlinedButton.icon(
                onPressed:
                    (_existingDocuments.length + _pendingDocuments.length) >= 5
                        ? null
                        : () => _pickDocument(),
                icon: const Icon(Icons.upload),
                label: Text(
                    (_existingDocuments.length + _pendingDocuments.length) == 0
                        ? 'Agregar Documento (PDF)'
                        : 'Agregar otro Documento (PDF)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hasta 5 PDFs (RIF/licencia/certificaciones).',
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

  /// Widget para la sección de Dirección con selects anidados
  Widget _buildContactInfoSection(ThemeData theme) {
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
          isExpanded: true, // CORRIGE OVERFLOW
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
          isExpanded: true, // CORRIGE OVERFLOW
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
          isExpanded: true, // CORRIGE OVERFLOW
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
            isExpanded: true, // CORRIGE OVERFLOW
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Hacienda'),
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
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s.]')), // Permitir puntos para acrónimos
                LengthLimitingTextInputFormatter(100),
              ],
              onChanged: (_) {
                _normalizeLegalNameField(_legalNameController);
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
                helperText: 'Nombre legal de la empresa (ej: Hacienda La Esperanza C.A.)',
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
              onChanged: (_) {
                _validateForm();
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
                helperText:
                    'Formato: V-12345678-9 (persona natural) o J-12345678-9 (empresa)',
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

            // Certificaciones
            _buildCertificationsSection(theme),
            const SizedBox(height: 16),

            // Documento de Licencia
            _buildBusinessLicenseSection(theme),
            const SizedBox(height: 16),

            // Información de Contacto (Teléfonos y Dirección)
            _buildContactInfoSection(theme),
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
              validator: _validatePolicy,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
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
              validator: _validatePolicy,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),

            // Switch: Hacienda principal
            SwitchListTile(
              title: const Text('Marcar como Hacienda Principal'),
              subtitle: const Text(
                'Solo una hacienda puede ser principal',
                style: TextStyle(fontSize: 12),
              ),
              value: _isPrimary,
              onChanged: (value) => setState(() => _isPrimary = value),
              activeColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Botón Guardar
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

class _SelectedDoc {
  _SelectedDoc(
      {required this.path, required this.fileName, this.certificationType});
  final String path;
  final String fileName;
  String? certificationType;
}

// Formatter para RIF venezolano (V- o J-12345678-9)
class _RIFVenezuelaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase();

    // Si el texto está vacío, permitir que el usuario escriba V o J
    if (text.isEmpty) {
      return newValue;
    }

    // Detectar si el usuario está borrando para cambiar de prefijo
    // Si el texto anterior tenía un prefijo y el nuevo texto es más corto,
    // permitir que el usuario borre y cambie de letra
    bool isDeleting = newValue.text.length < oldValue.text.length;

    // Si el usuario está borrando y quedó solo una letra o el texto es muy corto,
    // permitir que pueda cambiar de prefijo
    if (isDeleting && (text.length <= 2 || text == 'V' || text == 'J')) {
      // Si solo tiene una letra V o J, permitir que se agregue el guión o cambie
      if (text == 'V') {
        return TextEditingValue(
          text: 'V-',
          selection: TextSelection.collapsed(offset: 2),
        );
      } else if (text == 'J') {
        return TextEditingValue(
          text: 'J-',
          selection: TextSelection.collapsed(offset: 2),
        );
      }
      // Si está vacío o tiene solo una letra diferente, permitir continuar
      if (text.length <= 1) {
        return newValue;
      }
    }

    // Detectar el tipo de RIF (V- o J-)
    String? prefix;
    if (text.startsWith('V-')) {
      prefix = 'V-';
    } else if (text.startsWith('J-')) {
      prefix = 'J-';
    } else if (text.startsWith('V')) {
      // Si solo tiene V, agregar el guión
      return TextEditingValue(
        text: 'V-',
        selection: TextSelection.collapsed(offset: 2),
      );
    } else if (text.startsWith('J')) {
      // Si solo tiene J, agregar el guión
      return TextEditingValue(
        text: 'J-',
        selection: TextSelection.collapsed(offset: 2),
      );
    } else {
      // Si no empieza con V o J, no permitir escribir
      return oldValue;
    }

    // Extraer solo los números después del prefijo
    String numbers = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limitar a 9 dígitos máximo
    if (numbers.length > 9) {
      numbers = numbers.substring(0, 9);
    }

    // Si no hay números aún, retornar solo el prefijo
    if (numbers.isEmpty) {
      return TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }

    // Formatear según la cantidad de dígitos
    String formattedText;
    if (numbers.length <= 8) {
      // Si tiene 8 o menos dígitos: V-12345678 o J-12345678
      formattedText = '$prefix$numbers';
    } else {
      // Si tiene 9 dígitos: V-12345678-9 o J-12345678-9
      formattedText =
          '$prefix${numbers.substring(0, 8)}-${numbers.substring(8)}';
    }

    // Calcular la posición del cursor
    int cursorPosition = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
