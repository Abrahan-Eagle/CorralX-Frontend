import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../services/onboarding_api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  bool _isLoading = false;

  late OnboardingApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = OnboardingApiService();

    // Agregar listeners para validación en tiempo real
    _haciendaNameController.addListener(_validateForm);
    _razonSocialController.addListener(_validateForm);
    _rifController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
    _horarioController.addListener(_validateForm);

    _loadAuthToken();
  }

  // Cargar token de autenticación
  Future<void> _loadAuthToken() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token != null) {
        _apiService.setAuthToken(token);
        debugPrint(
            'Token cargado para onboarding Page2: ${token.substring(0, 10)}...');
      } else {
        debugPrint('No se encontró token de autenticación en Page2');
      }
    } catch (e) {
      debugPrint('Error al cargar token en Page2: $e');
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

  // Getter para verificar si el formulario es válido
  bool get isFormValid {
    // Validar que todos los campos tengan contenido
    bool hasContent = _haciendaNameController.text.trim().isNotEmpty &&
        _razonSocialController.text.trim().isNotEmpty &&
        _rifController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _horarioController.text.trim().isNotEmpty;

    // Validar formato del RIF
    bool rifValid = false;
    if (_rifController.text.trim().isNotEmpty) {
      final rifPattern = RegExp(r'^[A-Za-z]-\d{8}-\d$');
      rifValid = rifPattern.hasMatch(_rifController.text.trim());
    }

    return hasContent && rifValid;
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
    int totalFields = 5; // Total de campos requeridos

    if (_haciendaNameController.text.trim().isNotEmpty) completedFields++;
    if (_razonSocialController.text.trim().isNotEmpty) completedFields++;
    if (_rifController.text.trim().isNotEmpty) completedFields++;
    if (_descriptionController.text.trim().isNotEmpty) completedFields++;
    if (_horarioController.text.trim().isNotEmpty) completedFields++;

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
    if (value == null || value.trim().isEmpty) {
      return 'El RIF es obligatorio';
    }

    // Validar formato de RIF venezolano: J-12345678-9
    final rifPattern = RegExp(r'^[A-Za-z]-\d{8}-\d$');
    if (!rifPattern.hasMatch(value.trim())) {
      return 'Formato inválido (ej: J-12345678-9)';
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
    final normalized =
        input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : (w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '')))
        .join(' ');
  }

  void _normalizeText(TextEditingController controller) {
    final original = controller.text;
    final selection = controller.selection;
    final normalized = _capitalizeWords(original);
    if (original != normalized) {
      controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(
            offset: normalized.length.clamp(0, normalized.length)),
      );
    } else {
      controller.selection = selection;
    }
  }

  String _formatRif(String value) {
    // Fuerza letra mayúscula y máscara J-########-#
    final only = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < only.length && i < 10; i++) {
      if (i == 0) {
        buffer.write(only[i]);
        buffer.write('-');
      } else if (i == 9) {
        buffer.write('-');
        buffer.write(only[i]);
      } else {
        buffer.write(only[i]);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'-{2,}'), '-');
  }

  void _onRifChanged(String value) {
    String formatted = _formatRif(value);
    if (formatted != _rifController.text) {
      _rifController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _validateForm();
  }

  Future<void> _saveData() async {
    // Forzar validación del formulario
    if (!_formKey.currentState!.validate()) {
      debugPrint('Formulario no válido - no se puede guardar');
      return;
    }

    debugPrint('Formulario válido - iniciando guardado');
    setState(() => _isLoading = true);

    try {
      debugPrint('Guardando datos de la hacienda...');

      // 1. Crear hacienda
      final ranchResponse = await _apiService.createRanch(
        name: _haciendaNameController.text.trim(),
        legalName: _razonSocialController.text.trim().isNotEmpty
            ? _razonSocialController.text.trim()
            : null,
        taxId: _rifController.text.trim().isNotEmpty
            ? _rifController.text.trim()
            : null,
        businessDescription: _descriptionController.text.trim(),
        contactHours: _horarioController.text.trim(),
        // TODO: Usar la dirección creada en la página anterior
        addressId: null,
      );

      // 2. Completar onboarding
      // TODO: Obtener el ID del usuario actual
      // final userId = getCurrentUserId();
      // await _apiService.completeOnboarding(userId);

      debugPrint('Hacienda creada exitosamente: $ranchResponse');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
                                '${(formProgress * 100).round()}% completado (${(formProgress * 5).round()}/5 campos)',
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
                                  r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ#\-.,&()'\s]")),
                              LengthLimitingTextInputFormatter(100),
                            ],
                            onChanged: (_) {
                              _normalizeText(_razonSocialController);
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
                            ),
                            validator: _validateRazonSocial,
                          ),

                          const SizedBox(height: 16),

                          // RIF
                          TextFormField(
                            controller: _rifController,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9\-]')),
                              LengthLimitingTextInputFormatter(12),
                            ],
                            onChanged: _onRifChanged,
                            decoration: InputDecoration(
                              labelText: 'RIF',
                              hintText: 'J-12345678-9',
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
                            validator: _validateRIF,
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

                          // Horario
                          TextFormField(
                            controller: _horarioController,
                            readOnly: false,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ:.,\-\s/]")),
                              LengthLimitingTextInputFormatter(100),
                            ],
                            onChanged: (_) {
                              _normalizeText(_horarioController);
                              _validateForm();
                            },
                            decoration: InputDecoration(
                              labelText: 'Horario *',
                              hintText: 'Elige un preset o personaliza',
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
                                  color: Theme.of(context).colorScheme.error,
                                  width: 2,
                                ),
                              ),
                              isDense: true,
                              suffixIcon: IconButton(
                                tooltip: 'Seleccionar horario',
                                icon: const Icon(Icons.access_time),
                                onPressed: _showScheduleSheet,
                              ),
                            ),
                            validator: _validateContactHours,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 24),

                          // Botón finalizar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !isFormValid)
                                  ? null
                                  : () {
                                      debugPrint(
                                          'Botón presionado - validando formulario...');
                                      _saveData();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFormValid
                                    ? colorScheme.primary
                                    : Colors.grey,
                                foregroundColor: isFormValid
                                    ? colorScheme.onPrimary
                                    : Colors.grey[300],
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 20 : 16,
                                  horizontal: isTablet ? 24 : 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                shadowColor:
                                    colorScheme.shadow.withOpacity(0.2),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: isTablet ? 24 : 20,
                                      width: isTablet ? 24 : 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      isFormValid
                                          ? 'Finalizar'
                                          : 'Complete todos los campos',
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: isFormValid
                                            ? colorScheme.onPrimary
                                            : Colors.grey[300],
                                      ),
                                    ),
                            ),
                          ),
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
