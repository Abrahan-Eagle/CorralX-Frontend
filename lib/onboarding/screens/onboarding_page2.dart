import 'dart:convert';

import 'package:flutter/material.dart';
import '../../config/corral_x_theme.dart';
import '../models/onboarding_draft.dart';
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
  OnboardingPage2State createState() => OnboardingPage2State();
}

class OnboardingPage2State extends State<OnboardingPage2> {
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

  @override
  void initState() {
    super.initState();
    // Inicializar campo RIF vacío (el usuario puede escribir V- o J-)

    // Agregar listeners para validación en tiempo real
    _haciendaNameController.addListener(_validateForm);
    _razonSocialController.addListener(_validateForm);
    _rifController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
    _horarioController.addListener(_validateForm);

    // Cargar datos extraídos del OCR después de inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOCRData();
    });
  }

  // Cargar datos extraídos del OCR del RIF
  Future<void> _loadOCRData() async {
    try {
      const storage = FlutterSecureStorage();
      final rifDataJson = await storage.read(key: 'kyc_extracted_rif_data');
      
      if (rifDataJson != null && rifDataJson.isNotEmpty) {
        final rifData = jsonDecode(rifDataJson) as Map<String, dynamic>;
        
        debugPrint('📋 Datos RIF del OCR recibidos: $rifData');
        
        // Solo pre-llenar RIF; el usuario llena manualmente nombre de hacienda y razón social.
        // Pre-llenar RIF si está vacío o solo tiene 'V-' o 'J-'
        if ((_rifController.text.isEmpty || 
             _rifController.text.trim() == 'V-' || 
             _rifController.text.trim() == 'J-') && 
            rifData['rifNumber'] != null && (rifData['rifNumber'] as String).isNotEmpty) {
          final rifNumber = (rifData['rifNumber'] as String).trim().toUpperCase();
          // Asegurar formato correcto V-12345678-9 o J-12345678-9
          if (rifNumber.startsWith('V') || rifNumber.startsWith('J')) {
            _rifController.text = rifNumber;
            debugPrint('✅ RIF pre-llenado: ${_rifController.text}');
          }
        }
        
        if (mounted) {
          setState(() {
            _formKey.currentState?.validate();
          });
        }
        
        debugPrint('✅ Datos RIF del OCR cargados y pre-llenados correctamente');
      } else {
        debugPrint('⚠️ No se encontraron datos RIF del OCR para pre-llenar');
      }
    } catch (e) {
      debugPrint('❌ Error cargando datos del OCR: $e');
      // No mostrar error al usuario, solo log
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

    final isValid = hasRequiredContent && rifValid;

    // Debug para identificar qué campo falta
    if (!isValid) {
      debugPrint('❌ ONBOARDING PAGE2 isFormValid: Formulario no válido');
      debugPrint('  - hasRequiredContent: $hasRequiredContent');
      debugPrint('  - rifValid: $rifValid');
      debugPrint('  - nombreHacienda: "${_haciendaNameController.text.trim()}"');
      debugPrint('  - descripcion: "${_descriptionController.text.trim()}"');
      debugPrint('  - rif: "${_rifController.text.trim()}"');
    }

    return isValid;
  }

  // Método para validar el formulario en tiempo real
  void _validateForm() {
    setState(() {
      // Forzar rebuild para actualizar el estado del botón
    });
    // ✅ Notificar al padre (OnboardingScreen) que el formulario cambió
    // Esto actualiza el estado del botón "Siguiente"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // Buscar el State del OnboardingScreen usando visitAncestorElements
        context.visitAncestorElements((element) {
          if (element is StatefulElement) {
            final state = element.state;
            if (state != null) {
              final dynamic parentState = state;
              // Verificar si es OnboardingScreenState por nombre de tipo
              final typeName = parentState.runtimeType.toString();
              if (typeName.contains('OnboardingScreenState')) {
                if (parentState.mounted) {
                  // Llamar a setState en el padre para forzar actualización del botón
                  parentState.setState(() {});
                  debugPrint(
                      '✅ ONBOARDING PAGE2: Notificado cambio al OnboardingScreen - Botón actualizado');
                  return false; // Detener búsqueda
                }
              }
            }
          }
          return true; // Continuar buscando
        });
      } catch (e) {
        debugPrint(
            '⚠️ ONBOARDING PAGE2: Error notificando cambio al padre: $e');
      }
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

  Future<RanchInfoDraft?> collectFormData() async {
    debugPrint('🔵 ONBOARDING PAGE2: collectFormData() llamado');
    debugPrint('  - nombreHacienda: "${_haciendaNameController.text.trim()}"');
    debugPrint('  - razonSocial: "${_razonSocialController.text.trim()}"');
    debugPrint('  - rif: "${_rifController.text.trim()}"');
    debugPrint('  - descripcion: "${_descriptionController.text.trim()}"');
    debugPrint('  - horario: "${_horarioController.text.trim()}"');
    debugPrint('  - isFormValid: $isFormValid');

    if (!_formKey.currentState!.validate()) {
      debugPrint(
          '❌ FRONTEND PAGE2: Formulario no válido (validación fallida) - no se puede guardar');
      return null;
    }

    if (!isFormValid) {
      debugPrint(
          '❌ FRONTEND PAGE2: Formulario no válido (isFormValid=false) - no se puede guardar');
      return null;
    }

    final draft = RanchInfoDraft(
      name: _haciendaNameController.text.trim(),
      legalName: _razonSocialController.text.trim(),
      rif: _rifController.text.trim(),
      description: _descriptionController.text.trim(),
      contactHours: _horarioController.text.trim().isNotEmpty
          ? _horarioController.text.trim()
          : null,
    );

    debugPrint('✅ ONBOARDING PAGE2: RanchInfoDraft creado exitosamente');
    debugPrint('  - draft.name: "${draft.name}"');
    debugPrint('  - draft.legalName: "${draft.legalName}"');
    debugPrint('  - draft.rif: "${draft.rif}"');
    debugPrint('  - draft.description: "${draft.description}"');

    return draft;
  }

  // Restaurar datos desde un draft guardado
  Future<void> restoreFromDraft(RanchInfoDraft draft) async {
    debugPrint('🔄 ONBOARDING PAGE2: Restaurando datos desde draft...');
    
    try {
      _haciendaNameController.text = draft.name;
      _razonSocialController.text = draft.legalName;
      _rifController.text = draft.rif;
      _descriptionController.text = draft.description;
      if (draft.contactHours != null && draft.contactHours!.isNotEmpty) {
        _horarioController.text = draft.contactHours!;
      }

      // Validar formulario para actualizar estado
      if (mounted) {
        setState(() {
          _formKey.currentState?.validate();
        });
      }

      debugPrint('✅ ONBOARDING PAGE2: Datos restaurados exitosamente');
    } catch (e) {
      debugPrint('❌ ONBOARDING PAGE2: Error restaurando datos: $e');
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
