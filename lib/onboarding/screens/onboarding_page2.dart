import 'package:flutter/material.dart';
import '../../config/corral_x_theme.dart';
import '../services/onboarding_api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// InputFormatter personalizado para RIF venezolano (V- o J-12345678-9)
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

class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2> {
  final _formKey = GlobalKey<FormState>();
  final _haciendaNameController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _rifController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _horarioController = TextEditingController();

  // Variables para almacenar datos del usuario
  int? _profileId;

  // Presets compactos
  final List<String> _schedulePresets = <String>[
    'Lun-Vie, 8:00 AM - 5:00 PM',
    'Lun-Sáb, 9:00 AM - 6:00 PM',
    'Lun-Vie, 7:00 AM - 3:00 PM',
    '24/7',
  ];

  final List<String> _dayTemplates = <String>[
    'Lun-Vie',
    'Lun-Sáb',
    '24/7',
  ];

  Future<void> _showScheduleSheet() async {
    String selectedTemplate = _dayTemplates.first;
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar horario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Presets rápidos
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final preset = _schedulePresets[index];
                    return ActionChip(
                      label: Text(preset, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        _horarioController.text = preset;
                        _validateForm();
                        Navigator.pop(context);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _schedulePresets.length,
                ),
              ),
              const SizedBox(height: 12),
              // Personalizar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTemplate,
                    items: _dayTemplates
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) selectedTemplate = v;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Días',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule, size: 16),
                          label: Text('${start.format(context)}'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                            if (picked != null) {
                              start = picked;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule, size: 16),
                          label: Text('${end.format(context)}'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                            if (picked != null) {
                              end = picked;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Usar personalizado'),
                  onPressed: () {
                    if (selectedTemplate == '24/7') {
                      _horarioController.text = '24/7';
                    } else {
                      _horarioController.text =
                          '$selectedTemplate, ${start.format(context)} - ${end.format(context)}';
                    }
                    _validateForm();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  late OnboardingApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = OnboardingApiService();

    // Inicializar campo RIF vacío (el usuario puede escribir V- o J-)

    // Agregar listeners para validación en tiempo real
    _haciendaNameController.addListener(_validateForm);
    _razonSocialController.addListener(_validateForm);
    _rifController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
    _horarioController.addListener(_validateForm);

    _loadAuthToken();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar profile_id cuando el usuario llega a esta página
    _loadAuthToken();
  }

  // Cargar token de autenticación y obtener profile_id
  Future<void> _loadAuthToken() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token != null) {
        _apiService.setAuthToken(token);
        debugPrint(
            'Token cargado para onboarding Page2: ${token.substring(0, 10)}...');

        // Intentar leer profile_id guardado por el Formulario 1
        final savedProfileId = await storage.read(key: 'profile_id');
        debugPrint('🔍 PAGE2: Valor leído de SecureStorage: $savedProfileId');
        if (savedProfileId != null) {
          _profileId = int.tryParse(savedProfileId);
          debugPrint(
              '🔐 PAGE2: profile_id recuperado del SecureStorage: $_profileId');
        } else {
          debugPrint('⚠️ PAGE2: No se encontró profile_id en SecureStorage');
        }
        // Si no está, obtener el profile_id desde el backend
        if (_profileId == null) {
          debugPrint('🔄 PAGE2: Obteniendo profile_id desde backend...');
          await _getProfileIdFromToken();
        } else {
          debugPrint('✅ PAGE2: profile_id disponible: $_profileId');
        }
      } else {
        debugPrint('No se encontró token de autenticación en Page2');
      }
    } catch (e) {
      debugPrint('Error al cargar token en Page2: $e');
    }
  }

  // Obtener profile_id del token
  Future<void> _getProfileIdFromToken() async {
    try {
      final userResponse = await _apiService.getCurrentUser();

      if (userResponse.containsKey('user')) {
        final user = userResponse['user'];
        _profileId = user['id'];
        debugPrint('Profile ID obtenido para Page2: $_profileId');
      }
    } catch (e) {
      debugPrint('Error obteniendo profile ID en Page2: $e');
    }
  }

  @override
  void dispose() {
    _haciendaNameController.removeListener(_validateForm);
    _razonSocialController.removeListener(_validateForm);
    _rifController.removeListener(_validateForm);
    _descriptionController.removeListener(_validateForm);
    _horarioController.removeListener(_validateForm);
    _haciendaNameController.dispose();
    _razonSocialController.dispose();
    _rifController.dispose();
    _descriptionController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  // Getter público para verificar si el formulario es válido
  bool get isFormValid {
    // Validar que los campos obligatorios tengan contenido
    // TODO: Re-habilitar campo horario cuando se descomente el TextFormField
    bool hasRequiredContent = _haciendaNameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
    // _horarioController.text.trim().isNotEmpty;

    // Validar formato del RIF (obligatorio con formato correcto)
    bool rifValid = false;
    if (_rifController.text.trim().isNotEmpty &&
        _rifController.text.trim() != 'V-' &&
        _rifController.text.trim() != 'J-') {
      final rifPattern = RegExp(r'^(V|J)-\d{8}-\d$');
      rifValid = rifPattern.hasMatch(_rifController.text.trim().toUpperCase());
    }

    return hasRequiredContent && rifValid;
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
    // TODO: Re-habilitar campo horario cuando se descomente el TextFormField
    int totalFields =
        3; // Total de campos obligatorios: nombre, RIF, descripción

    if (_haciendaNameController.text.trim().isNotEmpty) completedFields++;
    if (_rifController.text.trim().isNotEmpty &&
        _rifController.text.trim() != 'V-' &&
        _rifController.text.trim() != 'J-') completedFields++;
    if (_descriptionController.text.trim().isNotEmpty) completedFields++;
    // if (_horarioController.text.trim().isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  // Métodos de validación
  String? _validateHaciendaName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la hacienda es obligatorio';
    }
    if (value.trim().length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (value.trim().length > 100) {
      return 'Máximo 100 caracteres';
    }
    // Validar que solo contenga letras, números, espacios y caracteres especiales básicos
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\-\.]+$').hasMatch(value.trim())) {
      return 'Caracteres no válidos';
    }
    return null;
  }

  String? _validateRazonSocial(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La razón social es obligatoria';
    }
    if (value.trim().length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (value.trim().length > 150) {
      return 'Máximo 150 caracteres';
    }
    // Validar que solo contenga letras, números, espacios y caracteres especiales básicos
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\-\.]+$').hasMatch(value.trim())) {
      return 'Caracteres no válidos';
    }
    return null;
  }

  String? _validateRIF(String? value) {
    if (value == null ||
        value.trim().isEmpty ||
        value.trim() == 'V-' ||
        value.trim() == 'J-') {
      return 'El RIF es obligatorio';
    }

    final rif = value.trim().toUpperCase();
    // Validar formato: V-12345678-9 o J-12345678-9
    final rifRegex = RegExp(r'^(V|J)-\d{8}-\d$');
    if (!rifRegex.hasMatch(rif)) {
      return 'Formato: V-12345678-9 o J-12345678-9 (9 dígitos)';
    }

    final numbers = rif.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 9) {
      return 'El RIF debe tener 9 dígitos';
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

  String? _validateContactHours(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El horario de contacto es obligatorio';
    }
    if (value.trim().length < 5) {
      return 'Mínimo 5 caracteres';
    }
    if (value.trim().length > 100) {
      return 'Máximo 100 caracteres';
    }
    return null;
  }

  String _capitalizeWords(String input) {
    // Normalizar espacios múltiples pero preservar espacios al principio y final
    final normalized = input.replaceAll(RegExp(r'\s+'), ' ');
    return normalized
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : (w[0].toUpperCase() +
                (w.length > 1 ? w.substring(1).toLowerCase() : '')))
        .join(' ');
  }

  void _normalizeText(TextEditingController controller) {
    final original = controller.text;
    final selection = controller.selection;
    final normalized = _capitalizeWords(original);
    if (original != normalized) {
      // Preservar la posición del cursor lo mejor posible
      final newOffset = selection.baseOffset.clamp(0, normalized.length);
      controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: newOffset),
      );
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

  Future<void> saveData() async {
    // Forzar validación del formulario
    if (!_formKey.currentState!.validate()) {
      debugPrint(
          '❌ FRONTEND PAGE2: Formulario no válido - no se puede guardar');
      return;
    }

    debugPrint('✅ FRONTEND PAGE2: Formulario válido - iniciando guardado');
    setState(() {});

    try {
      debugPrint('🚀 FRONTEND PAGE2: Guardando datos de la hacienda...');

      // Debug: Mostrar datos que se van a enviar
      debugPrint('📋 FRONTEND PAGE2: Datos a enviar:');
      debugPrint('  - haciendaName: ${_haciendaNameController.text.trim()}');
      debugPrint('  - razonSocial: ${_razonSocialController.text.trim()}');
      debugPrint('  - rif: ${_rifController.text.trim()}');
      debugPrint('  - description: ${_descriptionController.text.trim()}');
      // TODO: Re-habilitar campo horario cuando se descomente el TextFormField
      // debugPrint('  - horario: ${_horarioController.text.trim()}');

      // 1. Crear hacienda
      debugPrint('🏠 FRONTEND PAGE2: Enviando petición para crear hacienda...');
      debugPrint('🔑 FRONTEND PAGE2: Usando profile_id: $_profileId');

      if (_profileId == null) {
        throw Exception('No se pudo obtener el profile_id del usuario');
      }

      final ranchResponse = await _apiService.createRanch(
        name: _haciendaNameController.text.trim(),
        profileId: _profileId!,
        legalName: _razonSocialController.text.trim().isNotEmpty
            ? _razonSocialController.text.trim()
            : null,
        taxId: _rifController.text.trim().isNotEmpty
            ? _rifController.text.trim()
            : null,
        businessDescription: _descriptionController.text.trim(),
        // TODO: Re-habilitar campo horario cuando se descomente el TextFormField
        // contactHours: _horarioController.text.trim(),
        // TODO: Usar la dirección creada en la página anterior
        addressId: null,
      );

      debugPrint(
          '✅ FRONTEND PAGE2: Hacienda creada exitosamente: $ranchResponse');

      // 2. Completar onboarding
      // TODO: Obtener el ID del usuario actual
      // final userId = getCurrentUserId();
      // await _apiService.completeOnboarding(userId);

      debugPrint('🎉 FRONTEND PAGE2: ¡TODOS LOS DATOS GUARDADOS EXITOSAMENTE!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil completado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );

        // TODO: Navegar al dashboard principal
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => DashboardScreen()),
        //   (route) => false,
        // );
      }
    } catch (e) {
      debugPrint('❌ FRONTEND PAGE2: Error al guardar datos: $e');
      debugPrint('🔍 FRONTEND PAGE2: Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }

      // ✅ Re-lanzar la excepción para que _saveCurrentPageData() pueda detectarla
      // y evitar la navegación a la siguiente página
      rethrow;
    } finally {
      setState(() {});
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
                                '${(formProgress * 100).round()}% completado (${(formProgress * 3).round()}/3 campos)',
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
                          // Nombre de la hacienda
                          TextFormField(
                            controller: _haciendaNameController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                              LengthLimitingTextInputFormatter(100),
                            ],
                            onChanged: (_) {
                              _normalizeText(_haciendaNameController);
                              _validateForm();
                            },
                            decoration: InputDecoration(
                              labelText: 'Nombre de la hacienda *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                            validator: _validateHaciendaName,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 16),

                          // Razón Social
                          TextFormField(
                            controller: _razonSocialController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(
                                  r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ#\-.,&()'\s]")), // Ya permite puntos
                              LengthLimitingTextInputFormatter(100),
                            ],
                            onChanged: (_) {
                              _normalizeLegalNameField(_razonSocialController);
                              _validateForm();
                            },
                            decoration: InputDecoration(
                              labelText: 'Razón social *',
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
                              helperText: 'Ej: Hacienda La Esperanza C.A.',
                            ),
                            validator: _validateRazonSocial,
                          ),

                          const SizedBox(height: 16),

                          // RIF
                          TextFormField(
                            controller: _rifController,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              _RIFVenezuelaInputFormatter(), // Formato V- o J-
                            ],
                            onChanged: (_) => _validateForm(),
                            decoration: InputDecoration(
                              labelText: 'RIF *',
                              hintText: 'V-12345678-9 o J-12345678-9',
                              helperText: 'V- (persona natural) o J- (empresa)',
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
                            validator: _validateRIF,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 16),

                          // Descripción de la finca
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Descripción de la finca *',
                              hintText:
                                  'Escriba toda la información que considere relevante',
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
                            validator: _validateDescription,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 16),

                          // TODO: Re-habilitar campo horario en futuras versiones
                          // Horario
                          // TextFormField(
                          //   controller: _horarioController,
                          //   readOnly: false,
                          //   inputFormatters: [
                          //     FilteringTextInputFormatter.allow(
                          //         RegExp(r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ:.,\-\s/]")),
                          //     LengthLimitingTextInputFormatter(100),
                          //   ],
                          //   onChanged: (_) {
                          //     _normalizeText(_horarioController);
                          //     _validateForm();
                          //   },
                          //   decoration: InputDecoration(
                          //     labelText: 'Horario *',
                          //     hintText: 'Elige un preset o personaliza',
                          //     border: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     focusedBorder: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //       borderSide: BorderSide(
                          //         color: CorralXTheme.primarySolid,
                          //         width: 2,
                          //       ),
                          //     ),
                          //     errorBorder: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //       borderSide: BorderSide(
                          //         color: Theme.of(context).colorScheme.error,
                          //         width: 2,
                          //       ),
                          //     ),
                          //     isDense: true,
                          //     suffixIcon: IconButton(
                          //       tooltip: 'Seleccionar horario',
                          //       icon: const Icon(Icons.access_time),
                          //       onPressed: _showScheduleSheet,
                          //     ),
                          //   ),
                          //   validator: _validateContactHours,
                          //   autovalidateMode:
                          //       AutovalidateMode.onUserInteraction,
                          // ),
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
}
