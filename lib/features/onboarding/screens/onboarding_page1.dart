import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../services/onboarding_api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _ciController = TextEditingController();

  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedParroquia;
  String? _selectedOperatorCode;

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _parroquias = [];
  List<Map<String, dynamic>> _operatorCodes = [];

  bool _isLoadingData = false;
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isGettingLocation = false; // Mantenido para funcionalidad GPS interna

  late OnboardingApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = OnboardingApiService();

    // Inicializar campo CI con prefijo V-
    _ciController.text = 'V-';

    // Agregar listeners para validación en tiempo real
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _dateOfBirthController.addListener(_validateForm);
    _addressController.addListener(_validateForm);
    _ciController.addListener(_validateForm);

    _initializeData();
  }

  // Inicializar datos con token
  Future<void> _initializeData() async {
    await _loadAuthToken();
    _loadInitialData();
    _getCurrentLocation();
  }

  // Obtener ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() => _isGettingLocation = true);
    }

    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ FRONTEND: Permisos de ubicación denegados');
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '⚠️ FRONTEND: Permisos de ubicación denegados permanentemente');
        _setDefaultLocation();
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      debugPrint(
          '📍 FRONTEND: Ubicación obtenida - Lat: $_currentLatitude, Lng: $_currentLongitude');
    } catch (e) {
      debugPrint('❌ FRONTEND: Error obteniendo ubicación: $e');
      _setDefaultLocation();
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  // Establecer ubicación por defecto (Caracas, Venezuela)
  void _setDefaultLocation() {
    _currentLatitude = 10.4806;
    _currentLongitude = -66.9036;
    debugPrint(
        '📍 FRONTEND: Usando ubicación por defecto - Lat: $_currentLatitude, Lng: $_currentLongitude');
  }

  // Cargar token de autenticación
  Future<void> _loadAuthToken() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token != null) {
        _apiService.setAuthToken(token);
        debugPrint(
            'Token cargado para onboarding: ${token.substring(0, 10)}...');
      } else {
        debugPrint('No se encontró token de autenticación');
      }
    } catch (e) {
      debugPrint('Error al cargar token: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_validateForm);
    _lastNameController.removeListener(_validateForm);
    _phoneController.removeListener(_validateForm);
    _dateOfBirthController.removeListener(_validateForm);
    _addressController.removeListener(_validateForm);
    _ciController.removeListener(_validateForm);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  // Getter público para verificar si el formulario es válido
  bool get isFormValid {
    // Validar que todos los campos tengan contenido
    bool hasContent = _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _dateOfBirthController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _ciController.text.trim().isNotEmpty &&
        _selectedCountry != null &&
        _selectedState != null &&
        _selectedCity != null &&
        _selectedOperatorCode != null;

    // Validar formato del teléfono EXACTAMENTE 7 dígitos
    bool phoneValid = false;
    if (_phoneController.text.trim().isNotEmpty) {
      String cleanPhone =
          _phoneController.text.trim().replaceAll(RegExp(r'[\s\-]'), '');
      phoneValid =
          cleanPhone.length == 7 && RegExp(r'^\d+$').hasMatch(cleanPhone);
    }

    // Validar formato de la fecha
    bool dateValid = false;
    if (_dateOfBirthController.text.trim().isNotEmpty) {
      final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (datePattern.hasMatch(_dateOfBirthController.text.trim())) {
        try {
          DateTime.parse(_dateOfBirthController.text.trim());
          dateValid = true;
        } catch (e) {
          dateValid = false;
        }
      }
    }

    return hasContent && phoneValid && dateValid;
  }

  // Método para validar el formulario en tiempo real
  void _validateForm() {
    setState(() {
      // Forzar rebuild para actualizar el estado del botón
    });
  }

  // Getter para obtener el progreso del formulario (0.0 a 1.0)
  double get formProgress {
    int completedFields = 0;
    int totalFields = 10; // Total de campos requeridos

    if (_firstNameController.text.trim().isNotEmpty) completedFields++;
    if (_lastNameController.text.trim().isNotEmpty) completedFields++;
    if (_phoneController.text.trim().isNotEmpty) completedFields++;
    if (_dateOfBirthController.text.trim().isNotEmpty) completedFields++;
    if (_addressController.text.trim().isNotEmpty) completedFields++;
    if (_ciController.text.trim().isNotEmpty) completedFields++;
    if (_selectedCountry != null) completedFields++;
    if (_selectedState != null) completedFields++;
    if (_selectedCity != null) completedFields++;
    if (_selectedOperatorCode != null) completedFields++;

    return completedFields / totalFields;
  }

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() => _isLoadingData = true);
    }

    try {
      // Cargar países y códigos de operadora
      await Future.wait([
        _loadCountries(),
        _loadOperatorCodes(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _apiService.getCountries();

      // Filtrar países duplicados por nombre
      final uniqueCountries = <String, Map<String, dynamic>>{};
      for (final country in countries) {
        final name = country['name'] as String?;
        if (name != null && !uniqueCountries.containsKey(name)) {
          uniqueCountries[name] = country;
        }
      }

      if (mounted) {
        setState(() {
          _countries = uniqueCountries.values.toList();

          // Buscar Venezuela como país predeterminado
          final venezuela = _countries.firstWhere(
            (country) =>
                (country['name'] as String).toLowerCase().contains('venezuela'),
            orElse: () => _countries.isNotEmpty ? _countries.first : {},
          );

          if (venezuela.isNotEmpty) {
            _selectedCountry = venezuela['name'] as String?;
            // Cargar estados de Venezuela automáticamente
            _onCountryChanged(_selectedCountry!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading countries: $e');
      // Fallback a datos mock en caso de error
      if (mounted) {
        setState(() {
          _countries = [
            {'id': 1, 'name': 'Venezuela'},
            {'id': 2, 'name': 'Colombia'},
            {'id': 3, 'name': 'Brasil'},
          ];
          _selectedCountry = 'Venezuela';
        });
      }
    }
  }

  Future<void> _loadStates() async {
    if (_selectedCountry == null) return;

    try {
      // Buscar el ID del país seleccionado
      final selectedCountryData = _countries.firstWhere(
        (country) => country['name'] == _selectedCountry,
        orElse: () => {'id': 1, 'name': 'Unknown'},
      );

      final countryId = selectedCountryData['id'];
      debugPrint(
          'Cargando estados para país: ${selectedCountryData['name']} (ID: $countryId)');

      final states = await _apiService.getStates(countryId);
      debugPrint('Estados recibidos: ${states.length} estados');

      if (mounted) {
        setState(() {
          _states = states;
        });
      }
    } catch (e) {
      debugPrint('Error loading states: $e');
      // Fallback a datos mock
      if (mounted) {
        setState(() {
          _states = [
            {'id': 1, 'name': 'Caracas'},
            {'id': 2, 'name': 'Miranda'},
            {'id': 3, 'name': 'Zulia'},
          ];
        });
      }
    }
  }

  Future<void> _loadCities() async {
    if (_selectedState == null) return;

    try {
      // Buscar el ID del estado seleccionado
      final selectedStateData = _states.firstWhere(
        (state) => state['name'] == _selectedState,
        orElse: () => {'id': 1, 'name': 'Unknown'},
      );

      final stateId = selectedStateData['id'];
      debugPrint(
          'Cargando ciudades para estado: ${selectedStateData['name']} (ID: $stateId)');

      final cities = await _apiService.getCities(stateId);
      debugPrint('Ciudades recibidas: ${cities.length} ciudades');

      if (mounted) {
        setState(() {
          _cities = cities;
          // Limpiar parroquias cuando cambia la ciudad
          _parroquias = [];
          _selectedParroquia = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
      // Fallback a datos mock
      if (mounted) {
        setState(() {
          _cities = [
            {'id': 1, 'name': 'Caracas'},
            {'id': 2, 'name': 'Valencia'},
            {'id': 3, 'name': 'Maracaibo'},
          ];
          _parroquias = [];
          _selectedParroquia = null;
        });
      }
    }
  }

  // Cargar parroquias por ciudad
  Future<void> _loadParroquias() async {
    if (_selectedCity == null) return;

    try {
      // Buscar el ID de la ciudad seleccionada
      final selectedCityData = _cities.firstWhere(
        (city) => city['name'] == _selectedCity,
        orElse: () => {'id': 1, 'name': 'Unknown'},
      );

      final cityId = selectedCityData['id'];
      debugPrint(
          'Cargando parroquias para ciudad: ${selectedCityData['name']} (ID: $cityId)');

      final parroquias = await _apiService.getParroquias(cityId);
      debugPrint('Parroquias recibidas: ${parroquias.length} parroquias');

      if (mounted) {
        setState(() {
          _parroquias = parroquias;
        });
      }
    } catch (e) {
      debugPrint('Error loading parroquias: $e');
      // Fallback a datos mock (solo para ciudades venezolanas)
      if (mounted) {
        setState(() {
          _parroquias = [];
        });
      }
    }
  }

  Future<void> _loadOperatorCodes() async {
    // Códigos de operadoras venezolanas principales
    if (mounted) {
      setState(() {
        _operatorCodes = [
          {'id': 1, 'code': '0416'},
          {'id': 2, 'code': '0426'},
          {'id': 3, 'code': '0412'},
          {'id': 4, 'code': '0422'},
          {'id': 5, 'code': '0414'},
          {'id': 6, 'code': '0424'},
        ];
      });
    }
  }

  void _onCountryChanged(String? value) {
    if (mounted) {
      setState(() {
        _selectedCountry = value;
        _selectedState = null;
        _selectedCity = null;
        _states.clear();
        _cities.clear();
      });
    }
    if (value != null) {
      _loadStates();
    }
  }

  void _onStateChanged(String? value) {
    if (mounted) {
      setState(() {
        _selectedState = value;
        _selectedCity = null;
        _cities.clear();
      });
    }
    if (value != null) {
      _loadCities();
    }
  }

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

  String _formatDateYYYYMMDD(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 4 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void _onDateChanged(String value) {
    final formatted = _formatDateYYYYMMDD(value);
    if (formatted != _dateOfBirthController.text) {
      _dateOfBirthController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // Métodos de validación
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

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio';
    }

    // Remover espacios y guiones para validar solo números
    String cleanValue = value.trim().replaceAll(RegExp(r'[\s\-]'), '');

    if (cleanValue.length != 7) {
      return 'Debe tener exactamente 7 dígitos';
    }
    // Validar que solo contenga números
    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Solo se permiten números';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La fecha de nacimiento es obligatoria';
    }

    // Validar formato de fecha YYYY-MM-DD
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value.trim())) {
      return 'Formato: YYYY-MM-DD';
    }

    try {
      final date = DateTime.parse(value.trim());
      final now = DateTime.now();
      final age = now.year - date.year;

      if (age < 18) {
        return 'Debes ser mayor de 18 años';
      }
      if (age > 120) {
        return 'Fecha de nacimiento inválida';
      }
      if (date.isAfter(now)) {
        return 'La fecha no puede ser futura';
      }
    } catch (e) {
      return 'Fecha inválida';
    }

    return null;
  }

  // Validación de CI (Cédula de Identidad)
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

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La dirección es obligatoria';
    }
    if (value.trim().length < 10) {
      return 'Mínimo 10 caracteres';
    }
    if (value.trim().length > 200) {
      return 'Máximo 200 caracteres';
    }
    return null;
  }

  String? _validateOperatorCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona un código de operadora';
    }
    return null;
  }

  String? _validateCountry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona un país';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona un estado';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona una ciudad';
    }
    return null;
  }

  Future<void> saveData() async {
    // Forzar validación del formulario
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ FRONTEND: Formulario no válido - no se puede guardar');
      return;
    }

    debugPrint('✅ FRONTEND: Formulario válido - iniciando guardado');

    try {
      debugPrint('🚀 FRONTEND: Guardando datos del onboarding página 1...');

      // Debug: Mostrar datos que se van a enviar
      debugPrint('📋 FRONTEND: Datos a enviar:');
      debugPrint('  - firstName: ${_firstNameController.text.trim()}');
      debugPrint('  - lastName: ${_lastNameController.text.trim()}');
      debugPrint('  - dateOfBirth: ${_dateOfBirthController.text.trim()}');
      debugPrint('  - ciNumber: ${_ciController.text.trim()}');
      debugPrint('  - phone: ${_phoneController.text.trim()}');
      debugPrint('  - address: ${_addressController.text.trim()}');

      // 1. Crear perfil
      debugPrint('📝 FRONTEND: Enviando petición para crear perfil...');
      final profileResponse = await _apiService.createProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
        ciNumber: _ciController.text.trim(),
        photoUsers: null,
      );

      debugPrint('✅ FRONTEND: Perfil creado exitosamente: $profileResponse');
      // Guardar profile_id para usarlo en el formulario 2 (ranch)
      try {
        final createdProfile = profileResponse['profile'];
        if (createdProfile is Map && createdProfile.containsKey('id')) {
          final profileId = createdProfile['id'];
          const storage = FlutterSecureStorage();
          await storage.write(key: 'profile_id', value: profileId.toString());
          debugPrint(
              '🔐 FRONTEND: profile_id guardado de forma segura: $profileId');
        }
      } catch (e) {
        debugPrint('⚠️ FRONTEND: No se pudo guardar profile_id: $e');
      }

      // 2. Crear teléfono
      debugPrint('📞 FRONTEND: Enviando petición para crear teléfono...');
      final operatorCodeId = _operatorCodes.firstWhere(
        (code) => code['code'] == _selectedOperatorCode,
        orElse: () => {'id': 1},
      )['id'];

      debugPrint('🔢 FRONTEND: OperatorCode ID seleccionado: $operatorCodeId');

      // Obtener el user_id del perfil creado
      final userId = profileResponse['profile']['user_id'];
      debugPrint('👤 FRONTEND: User ID obtenido: $userId');

      final phoneResponse = await _apiService.createPhone(
        number: _phoneController.text.trim(),
        operatorCodeId: operatorCodeId,
        userId: userId,
      );

      debugPrint('✅ FRONTEND: Teléfono creado exitosamente: $phoneResponse');

      // 3. Crear dirección
      debugPrint('🏠 FRONTEND: Enviando petición para crear dirección...');
      final cityId = _cities.firstWhere(
        (city) => city['name'] == _selectedCity,
        orElse: () => {'id': 1},
      )['id'];

      debugPrint('🏙️ FRONTEND: City ID seleccionado: $cityId');
      final addressResponse = await _apiService.createAddress(
        addresses: _addressController.text.trim(),
        cityId: cityId,
        // Usar coordenadas reales obtenidas por GPS o por defecto
        latitude: _currentLatitude ?? 10.4806, // GPS real o Caracas por defecto
        longitude: _currentLongitude ?? -66.9036,
      );

      debugPrint('✅ FRONTEND: Dirección creada exitosamente: $addressResponse');

      debugPrint('🎉 FRONTEND: ¡TODOS LOS DATOS GUARDADOS EXITOSAMENTE!');
      debugPrint('📊 FRONTEND: Resumen de respuestas:');
      debugPrint('  - Profile: $profileResponse');
      debugPrint('  - Phone: $phoneResponse');
      debugPrint('  - Address: $addressResponse');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos personales guardados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // TODO: Navegar a la siguiente página o completar onboarding
        // Navigator.push(context, MaterialPageRoute(builder: (context) => OnboardingPage2()));
      }
    } catch (e) {
      debugPrint('❌ FRONTEND: Error al guardar datos: $e');
      debugPrint('🔍 FRONTEND: Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // No necesitamos setState aquí ya que el widget se va a destruir
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      color: colorScheme.background,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32.0 : 16.0,
                vertical: isTablet ? 24.0 : 16.0,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Indicador de carga de datos
                      if (_isLoadingData)
                        Container(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: isTablet ? 24 : 20,
                                height: isTablet ? 24 : 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Text(
                                'Cargando datos...',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_isLoadingData) const SizedBox(height: 16),

                      // Indicador de progreso
                      if (!isFormValid) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Progreso del formulario',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: formProgress,
                                backgroundColor:
                                    colorScheme.outline.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  formProgress >= 1.0
                                      ? Colors.green
                                      : colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(formProgress * 100).round()}% completado (${(formProgress * 11).round()}/11 campos)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Formulario
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre y Apellido
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                // Layout vertical para pantallas pequeñas
                                return Column(
                                  children: [
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
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: colorScheme.error,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 20 : 16,
                                          vertical: isTablet ? 20 : 16,
                                        ),
                                      ),
                                      validator: _validateFirstName,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                    ),
                                    SizedBox(height: isTablet ? 20 : 16),
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
                                        labelText: 'Apellido *',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: colorScheme.error,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 20 : 16,
                                          vertical: isTablet ? 20 : 16,
                                        ),
                                      ),
                                      validator: _validateLastName,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                    ),
                                  ],
                                );
                              } else {
                                // Layout horizontal para pantallas grandes
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _firstNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Primer Nombre',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: colorScheme.surface,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 20 : 16,
                                            vertical: isTablet ? 20 : 16,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Campo obligatorio';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(
                                                  r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                                        ],
                                        onChanged: (value) {
                                          _normalizeName(_firstNameController);
                                        },
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 20 : 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lastNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Apellido',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: colorScheme.surface,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 20 : 16,
                                            vertical: isTablet ? 20 : 16,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Campo obligatorio';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(
                                                  r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                                        ],
                                        onChanged: (value) {
                                          _normalizeName(_lastNameController);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // Teléfono
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedOperatorCode,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Código',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: CorralXTheme.primarySolid,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  items: _operatorCodes.map((code) {
                                    return DropdownMenuItem<String>(
                                      value: code['code'],
                                      child: Text(code['code']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (mounted) {
                                      setState(() {
                                        _selectedOperatorCode = value;
                                      });
                                    }
                                  },
                                  validator: _validateOperatorCode,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(7),
                                  ],
                                  onChanged: (_) => _validateForm(),
                                  decoration: InputDecoration(
                                    labelText: 'Teléfono *',
                                    hintText: '1234567',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: CorralXTheme.primarySolid,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: colorScheme.error,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: _validatePhone,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // CI y Fecha de Nacimiento en la misma línea
                          Row(
                            children: [
                              // CI (Cédula de Identidad)
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _ciController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    _CIVenezuelaInputFormatter(),
                                  ],
                                  onChanged: (value) {
                                    _validateForm();
                                    // Asegurar que siempre tenga el prefijo V-
                                    if (!value.startsWith('V-')) {
                                      _ciController.value = TextEditingValue(
                                        text: 'V-',
                                        selection: TextSelection.collapsed(offset: 2),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'CI *',
                                    hintText: 'V-12345678',
                                    prefixText: 'V-',
                                    prefixStyle: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: CorralXTheme.primarySolid,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: colorScheme.error,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: _validateCI,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Fecha de Nacimiento
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _dateOfBirthController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9-]')),
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onChanged: _onDateChanged,
                                  decoration: InputDecoration(
                                    labelText: 'Fecha de Nacimiento *',
                                    hintText: 'YYYY-MM-DD',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: CorralXTheme.primarySolid,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: colorScheme.error,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: _validateDateOfBirth,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Dirección
                          TextFormField(
                            controller: _addressController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ#\-.,\s]")),
                              LengthLimitingTextInputFormatter(200),
                            ],
                            onChanged: (_) => _validateForm(),
                            decoration: InputDecoration(
                              labelText: 'Dirección Completa *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: CorralXTheme.primarySolid,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.error,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: _validateAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 16),

                          // País y Estado
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              if (isWide) {
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedCountry,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'País',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: CorralXTheme.primarySolid,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        items: _countries.map((country) {
                                          return DropdownMenuItem<String>(
                                            value: country['name'],
                                            child: Text(
                                              country['name'],
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _onCountryChanged,
                                        validator: _validateCountry,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedState,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'Estado',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: CorralXTheme.primarySolid,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        items: _states.map((state) {
                                          return DropdownMenuItem<String>(
                                            value: state['name'],
                                            child: Text(
                                              state['name'],
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _onStateChanged,
                                        validator: _validateState,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedCountry,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'País',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: CorralXTheme.primarySolid,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      items: _countries.map((country) {
                                        return DropdownMenuItem<String>(
                                          value: country['name'],
                                          child: Text(
                                            country['name'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _onCountryChanged,
                                      validator: _validateCountry,
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: _selectedState,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Estado',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: CorralXTheme.primarySolid,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      items: _states.map((state) {
                                        return DropdownMenuItem<String>(
                                          value: state['name'],
                                          child: Text(
                                            state['name'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _onStateChanged,
                                      validator: _validateState,
                                    ),
                                  ],
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // Ciudad
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: InputDecoration(
                              labelText: 'Ciudad',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: CorralXTheme.primarySolid,
                                  width: 2,
                                ),
                              ),
                            ),
                            items: _cities.map((city) {
                              return DropdownMenuItem<String>(
                                value: city['name'],
                                child: Text(city['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (mounted) {
                                setState(() {
                                  _selectedCity = value;
                                  _selectedParroquia =
                                      null; // Limpiar parroquia seleccionada
                                });
                              }
                              // Cargar parroquias para la ciudad seleccionada
                              _loadParroquias();
                            },
                            validator: _validateCity,
                          ),

                          // Parroquia (solo para Venezuela)
                          if (_selectedCountry
                                  ?.toLowerCase()
                                  .contains('venezuela') ==
                              true) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedParroquia,
                              decoration: InputDecoration(
                                labelText: 'Parroquia',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: CorralXTheme.primarySolid,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: _parroquias.map((parroquia) {
                                return DropdownMenuItem<String>(
                                  value: parroquia['name'],
                                  child: Text(parroquia['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {
                                    _selectedParroquia = value;
                                  });
                                }
                              },
                              validator: _selectedCountry
                                          ?.toLowerCase()
                                          .contains('venezuela') ==
                                      true
                                  ? _validateParroquia
                                  : null,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Validación de parroquia
  String? _validateParroquia(String? value) {
    if (_selectedCountry?.toLowerCase().contains('venezuela') == true) {
      if (value == null || value.isEmpty) {
        return 'Por favor seleccione una parroquia';
      }
    }
    return null;
  }
}

// InputFormatter personalizado para CI venezolano
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
