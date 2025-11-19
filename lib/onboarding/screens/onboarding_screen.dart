import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'welcome_page.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
// import 'onboarding_page4.dart';
// import 'onboarding_page5.dart';
// import 'onboarding_page6.dart';
import 'package:provider/provider.dart';
import 'package:corralx/config/user_provider.dart';
import 'onboarding_service.dart';
import 'package:corralx/main.dart';
import '../../shared/widgets/amazon_widgets.dart';
import '../models/onboarding_draft.dart';
import '../services/onboarding_api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final OnboardingService _onboardingService = OnboardingService();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // GlobalKeys para acceder a los métodos de las páginas
  final GlobalKey<OnboardingPage1State> _page1Key =
      GlobalKey<OnboardingPage1State>();
  final GlobalKey<OnboardingPage2State> _page2Key =
      GlobalKey<OnboardingPage2State>();

  final OnboardingApiService _apiService = OnboardingApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _apiTokenInitialized = false;
  PersonalInfoDraft? _personalInfoDraft;
  RanchInfoDraft? _ranchInfoDraft;

  late final List<Widget> onboardingPages;

  @override
  void initState() {
    super.initState();

    onboardingPages = [
      const WelcomePage(),
      OnboardingPage1(key: _page1Key),
      OnboardingPage2(key: _page2Key),
      const OnboardingPage3(),
      // OnboardingPage4(),
      // OnboardingPage5(),
      // OnboardingPage6(),
    ];

    // Cargar datos guardados si existen
    _loadSavedDrafts();
  }

  // Cargar datos guardados del onboarding
  Future<void> _loadSavedDrafts() async {
    try {
      debugPrint('🔄 ONBOARDING: Cargando datos guardados del onboarding...');
      
      // Cargar datos personales
      final personalJson = await _storage.read(key: 'onboarding_personal_draft');
      if (personalJson != null && personalJson.isNotEmpty) {
        final personalMap = json.decode(personalJson) as Map<String, dynamic>;
        _personalInfoDraft = PersonalInfoDraft.fromJson(personalMap);
        debugPrint('✅ ONBOARDING: Datos personales cargados desde almacenamiento');
      }

      // Cargar datos de hacienda
      final ranchJson = await _storage.read(key: 'onboarding_ranch_draft');
      if (ranchJson != null && ranchJson.isNotEmpty) {
        final ranchMap = json.decode(ranchJson) as Map<String, dynamic>;
        _ranchInfoDraft = RanchInfoDraft.fromJson(ranchMap);
        debugPrint('✅ ONBOARDING: Datos de hacienda cargados desde almacenamiento');
      }

      // NO restaurar datos automáticamente - el usuario debe comenzar desde 0
      // Los datos se guardan solo como respaldo, pero no se restauran automáticamente
      // if (_personalInfoDraft != null || _ranchInfoDraft != null) {
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     _restoreSavedData();
      //   });
      // }
    } catch (e) {
      debugPrint('❌ ONBOARDING: Error cargando datos guardados: $e');
    }
  }

  // Restaurar datos guardados en los formularios
  Future<void> _restoreSavedData() async {
    try {
      if (_personalInfoDraft != null) {
        final page1State = _page1Key.currentState;
        if (page1State != null) {
          await page1State.restoreFromDraft(_personalInfoDraft!);
          debugPrint('✅ ONBOARDING: Datos personales restaurados en formulario');
          
          // Si también hay datos de hacienda, navegar a página 2
          if (_ranchInfoDraft != null) {
            final page2State = _page2Key.currentState;
            if (page2State != null) {
              await page2State.restoreFromDraft(_ranchInfoDraft!);
              debugPrint('✅ ONBOARDING: Datos de hacienda restaurados en formulario');
              // Navegar a página 2 si tenemos ambos formularios
              _navigateToPage(2);
            } else {
              // Solo datos personales, navegar a página 1
              _navigateToPage(1);
            }
          } else {
            // Solo datos personales, navegar a página 1
            _navigateToPage(1);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ ONBOARDING: Error restaurando datos: $e');
    }
  }

  // Guardar datos personales persistentemente
  Future<void> _savePersonalDraft(PersonalInfoDraft draft) async {
    try {
      debugPrint('💾 ONBOARDING: Iniciando guardado de datos personales...');
      final jsonMap = draft.toJson();
      debugPrint('💾 ONBOARDING: JSON generado: ${jsonMap.toString()}');
      final jsonString = json.encode(jsonMap);
      debugPrint('💾 ONBOARDING: String JSON generado (${jsonString.length} caracteres)');
      
      await _storage.write(key: 'onboarding_personal_draft', value: jsonString);
      debugPrint('💾 ONBOARDING: Datos personales guardados persistentemente en FlutterSecureStorage');
      
      // Verificar que se guardó correctamente
      final verify = await _storage.read(key: 'onboarding_personal_draft');
      if (verify != null && verify.isNotEmpty) {
        debugPrint('✅ ONBOARDING: Verificación exitosa - datos personales confirmados en storage');
      } else {
        debugPrint('⚠️ ONBOARDING: ADVERTENCIA - No se pudo verificar el guardado de datos personales');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ONBOARDING: Error guardando datos personales: $e');
      debugPrint('❌ ONBOARDING: Stack trace: $stackTrace');
      rethrow; // Re-lanzar para que el error sea visible
    }
  }

  // Guardar datos de hacienda persistentemente
  Future<void> _saveRanchDraft(RanchInfoDraft draft) async {
    try {
      debugPrint('💾 ONBOARDING: Iniciando guardado de datos de hacienda...');
      final jsonMap = draft.toJson();
      debugPrint('💾 ONBOARDING: JSON generado: ${jsonMap.toString()}');
      final jsonString = json.encode(jsonMap);
      debugPrint('💾 ONBOARDING: String JSON generado (${jsonString.length} caracteres)');
      
      await _storage.write(key: 'onboarding_ranch_draft', value: jsonString);
      debugPrint('💾 ONBOARDING: Datos de hacienda guardados persistentemente en FlutterSecureStorage');
      
      // Verificar que se guardó correctamente
      final verify = await _storage.read(key: 'onboarding_ranch_draft');
      if (verify != null && verify.isNotEmpty) {
        debugPrint('✅ ONBOARDING: Verificación exitosa - datos de hacienda confirmados en storage');
      } else {
        debugPrint('⚠️ ONBOARDING: ADVERTENCIA - No se pudo verificar el guardado de datos de hacienda');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ONBOARDING: Error guardando datos de hacienda: $e');
      debugPrint('❌ ONBOARDING: Stack trace: $stackTrace');
      rethrow; // Re-lanzar para que el error sea visible
    }
  }

  // Limpiar todos los datos guardados
  Future<void> _clearSavedDrafts() async {
    try {
      await _storage.delete(key: 'onboarding_personal_draft');
      await _storage.delete(key: 'onboarding_ranch_draft');
      debugPrint('🗑️ ONBOARDING: Datos guardados eliminados');
    } catch (e) {
      debugPrint('❌ ONBOARDING: Error eliminando datos guardados: $e');
    }
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    debugPrint("🚀 _completeOnboarding: INICIANDO...");

    if (_personalInfoDraft == null || _ranchInfoDraft == null) {
      _showSnackBar('Faltan datos para completar el onboarding');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _ensureApiToken();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userDetails = await userProvider.getUserDetails();
      final userId = userDetails['userId'];

      if (userId == null || userId == 0) {
        throw Exception("ID de usuario no encontrado");
      }

      await _submitOnboardingData(userId);
      await _onboardingService.completeOnboarding(userId);
      await _storage.write(key: 'userCompletedOnboarding', value: '1');

      // Limpiar datos guardados del onboarding ya que se completó exitosamente
      await _clearSavedDrafts();

      userProvider.setProfileCreated(true);
      userProvider.setPhoneCreated(true);
      userProvider.setAdresseCreated(true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainRouter()),
      );
    } catch (e) {
      debugPrint("Error al completar el onboarding: $e");
      
      if (!mounted) return;
      
      // Extraer el mensaje de error de forma más clara
      String errorMessage = e.toString();
      String cleanErrorMessage = errorMessage.replaceAll('Exception: ', '').replaceAll('Exception: Exception: ', '');
      
      // Detectar el tipo de error y navegar a la página correspondiente
      if (errorMessage.toLowerCase().contains('cédula') || 
          errorMessage.toLowerCase().contains('cedula') || 
          errorMessage.toLowerCase().contains('ci_number') ||
          errorMessage.toLowerCase().contains('número de cédula')) {
        // Error de CI -> Navegar a página 1 (datos personales)
        debugPrint('🔄 ONBOARDING: Error de CI detectado, navegando a página 1');
        _showSnackBar(cleanErrorMessage);
        _navigateToPage(1);
      } else if (errorMessage.toLowerCase().contains('rif') || 
                 errorMessage.toLowerCase().contains('tax_id')) {
        // Error de RIF -> Navegar a página 2 (datos de hacienda)
        debugPrint('🔄 ONBOARDING: Error de RIF detectado, navegando a página 2');
        _showSnackBar(cleanErrorMessage);
        _navigateToPage(2);
      } else if (errorMessage.toLowerCase().contains('number') && 
                 (errorMessage.toLowerCase().contains('unique') || 
                  errorMessage.toLowerCase().contains('ya ha sido') || 
                  errorMessage.toLowerCase().contains('ya existe'))) {
        // Error de teléfono -> Navegar a página 1 (datos personales)
        debugPrint('🔄 ONBOARDING: Error de teléfono detectado, navegando a página 1');
        _showSnackBar(cleanErrorMessage);
        _navigateToPage(1);
      } else if (errorMessage.toLowerCase().contains('dirección') || 
                 errorMessage.toLowerCase().contains('direccion') ||
                 errorMessage.toLowerCase().contains('address')) {
        // Error de dirección -> Navegar a página 1 (datos personales) para corregir
        // Pero si es "ya tiene una dirección", solo mostrar mensaje y continuar (ya se maneja arriba)
        if (errorMessage.contains('ya tiene') || errorMessage.contains('ya existe')) {
          debugPrint('ℹ️ ONBOARDING: Dirección ya existe, continuando...');
          // No navegar, solo mostrar mensaje informativo
          _showSnackBar('Ya tienes una dirección guardada. Continuando con el onboarding...');
        } else {
          debugPrint('🔄 ONBOARDING: Error de dirección detectado, navegando a página 1');
          _showSnackBar(cleanErrorMessage);
          _navigateToPage(1);
        }
      } else {
        // Para otros errores, mostrar un mensaje genérico
        _showSnackBar('Error al completar el onboarding. Por favor, verifique sus datos e intente nuevamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  Future<void> _handleNext() async {
    debugPrint(
        '🎯 ONBOARDING SCREEN: _handleNext() llamado para página $_currentPage');

    if (_isLoading) {
      debugPrint('⏳ ONBOARDING SCREEN: Ya está cargando, ignorando llamada');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PRIMERO: Guardar datos de la página actual ANTES de navegar
      debugPrint(
          '💾 ONBOARDING SCREEN: Guardando datos de la página $_currentPage...');
      bool saveSuccessful = await _saveCurrentPageData();

      if (!saveSuccessful) {
        debugPrint(
            '❌ ONBOARDING SCREEN: Error al guardar datos, cancelando navegación');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Complete todos los campos correctamente para continuar'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      debugPrint(
          '✅ ONBOARDING SCREEN: Datos guardados exitosamente, procediendo con navegación...');

      // SEGUNDO: Navegar solo si el guardado fue exitoso
      if (_currentPage == onboardingPages.length - 1) {
        debugPrint(
            '🏁 ONBOARDING SCREEN: Última página, completando onboarding...');
        await _completeOnboarding(context);
      } else {
        debugPrint('➡️ ONBOARDING SCREEN: Avanzando a la siguiente página...');
        _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      debugPrint('❌ ONBOARDING SCREEN: Error en _handleNext: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Verificar si el formulario actual es válido
  bool get _isCurrentPageValid {
    switch (_currentPage) {
      case 0: // WelcomePage - siempre válida
        return true;
      case 1: // OnboardingPage1 - verificar formulario
        final page1State = _page1Key.currentState;
        return page1State?.isFormValid ?? false;
      case 2: // OnboardingPage2 - verificar formulario
        final page2State = _page2Key.currentState;
        return page2State?.isFormValid ?? false;
      case 3: // OnboardingPage3 - siempre válida
        return true;
      default:
        return true;
    }
  }

  // Método para que las páginas puedan notificar cambios en el formulario
  void notifyFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Método para navegar a una página específica
  void _navigateToPage(int targetPage) {
    if (targetPage >= 0 && targetPage < onboardingPages.length) {
      _controller.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = targetPage;
      });
      debugPrint('🔄 ONBOARDING: Navegando a página $targetPage');
    }
  }

  // Verificar si se puede navegar a una página específica
  bool _canNavigateToPage(int targetPage) {
    // Permitir navegación hacia atrás siempre (para que el usuario pueda corregir errores)
    if (targetPage < _currentPage) {
      return true;
    }

    // Permitir navegación hacia adelante solo si la página actual es válida
    if (targetPage > _currentPage) {
      return _isCurrentPageValid;
    }

    // Si es la misma página, permitir
    return true;
  }

  Future<bool> _saveCurrentPageData() async {
    try {
      debugPrint(
          '🚀 ONBOARDING SCREEN: _saveCurrentPageData() llamado para página $_currentPage');

      switch (_currentPage) {
        case 0: // WelcomePage - no necesita guardado
          debugPrint(
              '✅ ONBOARDING SCREEN: Página 0 (Welcome) - no necesita guardado');
          return true;
        case 1: // OnboardingPage1 - Datos Personales
          debugPrint(
              '📝 ONBOARDING SCREEN: Procesando página 1 (Datos Personales)');
          final page1State = _page1Key.currentState;
          if (page1State == null) {
            debugPrint(
                '❌ ONBOARDING SCREEN: Error: No se pudo acceder al estado de la página 1');
            return false;
          }

          if (!page1State.isFormValid) {
            debugPrint(
                '❌ ONBOARDING SCREEN: Formulario página 1 no válido - campos incompletos');
            return false;
          }

          final draft = await page1State.collectFormData();
          if (draft == null) {
            debugPrint(
                '❌ ONBOARDING SCREEN: No se pudo recopilar la información de la página 1');
            return false;
          }
          _personalInfoDraft = draft;
          // Guardar persistentemente
          try {
            await _savePersonalDraft(draft);
            debugPrint(
                '✅ ONBOARDING SCREEN: Datos de la página 1 almacenados en memoria y persistentemente');
            return true;
          } catch (e) {
            debugPrint('❌ ONBOARDING SCREEN: Error al guardar datos personales persistentemente: $e');
            // Aún así retornar true porque los datos están en memoria
            // El usuario puede continuar aunque falle el guardado persistente
            return true;
          }

        case 2: // OnboardingPage2 - Datos de Hacienda
          final page2State = _page2Key.currentState;
          if (page2State == null) {
            debugPrint('Error: No se pudo acceder al estado de la página 2');
            return false;
          }

          if (!page2State.isFormValid) {
            debugPrint('Formulario página 2 no válido - campos incompletos');
            return false;
          }

          final ranchDraft = await page2State.collectFormData();
          if (ranchDraft == null) {
            debugPrint(
                '❌ ONBOARDING SCREEN: No se pudo recopilar la información de la página 2');
            return false;
          }
          _ranchInfoDraft = ranchDraft;
          // Guardar persistentemente
          try {
            await _saveRanchDraft(ranchDraft);
            debugPrint('✅ ONBOARDING SCREEN: Datos de la página 2 almacenados en memoria y persistentemente');
            return true;
          } catch (e) {
            debugPrint('❌ ONBOARDING SCREEN: Error al guardar datos de hacienda persistentemente: $e');
            // Aún así retornar true porque los datos están en memoria
            // El usuario puede continuar aunque falle el guardado persistente
            return true;
          }

        case 3: // OnboardingPage3 - Página final
          return true;
        default:
          return true;
      }
    } catch (e) {
      debugPrint("Error guardando datos de página $_currentPage: $e");
      return false;
    }
  }

  Future<void> _ensureApiToken() async {
    if (_apiTokenInitialized) return;
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw Exception('Token de autenticación no disponible');
    }
    _apiService.setAuthToken(token);
    _apiTokenInitialized = true;
  }

  Future<void> _submitOnboardingData(int userId) async {
    final personal = _personalInfoDraft!;
    final ranch = _ranchInfoDraft!;

    try {
      // 1. Crear perfil - Si el CI ya está registrado, detener el proceso
      debugPrint('📝 ONBOARDING: Paso 1/4 - Creando perfil...');
      debugPrint('📝 ONBOARDING: Datos personales: firstName=${personal.firstName}, lastName=${personal.lastName}, ciNumber=${personal.ciNumber}');
      
      int? profileId;
      
      try {
        debugPrint('📝 ONBOARDING: Creando nuevo perfil...');
        final profileResponse = await _apiService.createProfile(
          firstName: personal.firstName,
          lastName: personal.lastName,
          dateOfBirth: personal.dateOfBirthIso,
          ciNumber: personal.ciNumber,
          photoUsers: null,
        );

        debugPrint('📝 ONBOARDING: Respuesta de creación de perfil: $profileResponse');

        final profileMap = profileResponse['profile'] ??
            profileResponse['data']?['profile'] ??
            profileResponse;
        profileId = _parseInt(profileMap?['id']);

        if (profileId == null) {
          debugPrint('❌ ONBOARDING: No se pudo obtener profileId de la respuesta');
          throw Exception('No se pudo crear el perfil del usuario. Respuesta: $profileResponse');
        }

        debugPrint('✅ ONBOARDING: Perfil creado exitosamente con ID: $profileId');
      } catch (e) {
        // Verificar si el error es por CI duplicado
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('ci_number') || errorMessage.contains('cédula') || 
            errorMessage.contains('cedula') || errorMessage.contains('número de cédula')) {
          if (errorMessage.contains('ya ha sido') || errorMessage.contains('ya existe') || 
              errorMessage.contains('unique') || errorMessage.contains('registrado') ||
              errorMessage.contains('ya está registrado')) {
            debugPrint('❌ ONBOARDING: CI ya registrado - deteniendo proceso');
            // Usar el mensaje del backend si está disponible, de lo contrario usar uno genérico
            final backendMessage = e.toString().replaceAll('Exception: ', '');
            if (backendMessage.toLowerCase().contains('cédula') || 
                backendMessage.toLowerCase().contains('cedula')) {
              throw Exception(backendMessage);
            } else {
              throw Exception('El número de cédula ${personal.ciNumber} ya está registrado en el sistema. Por favor, verifique sus datos o contacte soporte si cree que esto es un error.');
            }
          }
        }
        // Si es otro error, relanzarlo
        rethrow;
      }

      // 2. Crear teléfono (o verificar si ya existe)
      debugPrint('📞 ONBOARDING: Paso 2/4 - Creando/verificando teléfono...');
      debugPrint('📞 ONBOARDING: Datos: number=${personal.phoneNumber}, operatorCodeId=${personal.operatorCodeId}, userId=$userId');
      
      try {
        await _apiService.createPhone(
          number: personal.phoneNumber,
          operatorCodeId: personal.operatorCodeId,
          userId: userId,
        );
        debugPrint('✅ ONBOARDING: Teléfono creado exitosamente');
      } catch (e) {
        // Si el error es porque el número ya existe, continuar sin problema
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('number') && 
            (errorMessage.contains('unique') || errorMessage.contains('ya ha sido') || errorMessage.contains('ya existe'))) {
          debugPrint('ℹ️ ONBOARDING: El teléfono ya existe, continuando...');
        } else {
          // Si es otro error, relanzarlo
          rethrow;
        }
      }

      // 3. Crear dirección (o verificar si ya existe)
      debugPrint('🏠 ONBOARDING: Paso 3/4 - Creando/verificando dirección...');
      debugPrint('🏠 ONBOARDING: Datos: address=${personal.address}, cityId=${personal.cityId}, profileId=$profileId');
      
      int? addressId;
      try {
        final addressResponse = await _apiService.createAddress(
          profileId: profileId,
          addresses: personal.address,
          cityId: personal.cityId,
          latitude: personal.latitude,
          longitude: personal.longitude,
        );

        debugPrint('🏠 ONBOARDING: Respuesta de creación de dirección: $addressResponse');

        final addressMap = addressResponse['address'] ??
            addressResponse['data']?['address'] ??
            addressResponse;
        addressId = _parseInt(addressMap?['id']);

        debugPrint('✅ ONBOARDING: Dirección creada exitosamente con ID: $addressId');
      } catch (e) {
        // Si el error es porque la dirección ya existe o hay un problema de validación, continuar
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('ya existe') || 
            errorMessage.contains('already exists') || 
            errorMessage.contains('ya ha sido') ||
            errorMessage.contains('ya tiene una dirección personal guardada') ||
            errorMessage.contains('ya tiene') && errorMessage.contains('dirección')) {
          debugPrint('ℹ️ ONBOARDING: La dirección ya existe o ya hay una dirección guardada, continuando sin addressId...');
          addressId = null; // Continuar sin addressId
        } else {
          // Si es otro error, relanzarlo
          rethrow;
        }
      }

      // 4. Crear hacienda - Si el RIF ya está registrado, detener el proceso
      debugPrint('🏡 ONBOARDING: Paso 4/4 - Creando hacienda...');
      debugPrint('🏡 ONBOARDING: Datos: name=${ranch.name}, profileId=$profileId, addressId=$addressId, taxId=${ranch.rif}');
      
      try {
        await _apiService.createRanch(
          name: ranch.name,
          profileId: profileId,
          legalName: ranch.legalName,
          taxId: ranch.rif,
          businessDescription: ranch.description,
          contactHours: ranch.contactHours,
          addressId: addressId,
        );
        debugPrint('✅ ONBOARDING: Hacienda creada exitosamente');
      } catch (e) {
        // Verificar si el error es por RIF duplicado
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('tax_id') || errorMessage.contains('rif') || 
            errorMessage.contains('tax id')) {
          if (errorMessage.contains('ya ha sido') || errorMessage.contains('ya existe') || 
              errorMessage.contains('unique') || errorMessage.contains('registrado') ||
              errorMessage.contains('ya está registrado')) {
            debugPrint('❌ ONBOARDING: RIF ya registrado - deteniendo proceso');
            // Usar el mensaje del backend si está disponible, de lo contrario usar uno genérico
            final backendMessage = e.toString().replaceAll('Exception: ', '');
            if (backendMessage.toLowerCase().contains('rif') || 
                backendMessage.toLowerCase().contains('tax_id')) {
              throw Exception(backendMessage);
            } else {
              throw Exception('El RIF ${ranch.rif} ya está registrado en el sistema. Esta hacienda ya existe. Por favor, verifique sus datos o contacte soporte si cree que esto es un error.');
            }
          }
        }
        // Si es otro error, relanzarlo
        rethrow;
      }
      
      debugPrint('🎉 ONBOARDING: Proceso de onboarding completado');
    } catch (e) {
      debugPrint('❌ ONBOARDING: Error en _submitOnboardingData: $e');
      rethrow; // Re-lanzar el error para que _completeOnboarding lo maneje
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: colorScheme.background, // Usar color del tema
        body: Stack(
          children: [
            // Contenido principal
            PageView(
              controller: _controller,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (index) {
                debugPrint(
                    '🔄 ONBOARDING SCREEN: onPageChanged llamado - de $_currentPage a $index');

                // Solo actualizar la página actual
                // El guardado se maneja en _handleNext()
                if (_canNavigateToPage(index)) {
                  setState(() => _currentPage = index);
                  HapticFeedback.lightImpact();
                  debugPrint(
                      '✅ ONBOARDING SCREEN: Navegación permitida a página $index');
                } else {
                  debugPrint(
                      '❌ ONBOARDING SCREEN: Navegación rechazada a página $index');
                  // Rechazar el cambio - volver a la página actual
                  Future.microtask(() {
                    _controller.animateToPage(
                      _currentPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                  HapticFeedback.heavyImpact();
                }
              },
              children: onboardingPages,
            ),

            // Barra de navegación inferior simple
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicador de progreso Amazon
                      AmazonProgressIndicator(
                        currentPage: _currentPage,
                        totalPages: onboardingPages.length,
                      ),

                      const SizedBox(height: 24),

                      // Botón de navegación unidireccional
                      Center(
                        child: AmazonButton(
                          text: _currentPage == onboardingPages.length - 1
                              ? 'Comenzar'
                              : 'Siguiente',
                          onPressed: _isLoading ? null : _handleNext,
                          isLoading: _isLoading,
                          width: 200,
                          icon: _currentPage == onboardingPages.length - 1
                              ? Icons.play_arrow
                              : Icons.arrow_forward,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
