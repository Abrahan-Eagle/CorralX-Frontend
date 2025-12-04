import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import '../services/kyc_service.dart';

/// Provider para manejar el estado del flujo KYC.
///
/// Se usa tanto en el onboarding como (en el futuro) desde el perfil.
class KycProvider extends ChangeNotifier {
  KycProvider({KycService? service}) : _service = service ?? KycService();

  final KycService _service;
  final Logger _logger = Logger();

  String _kycStatus = 'no_verified';
  String? _rejectionReason;

  bool _hasDocument = false;
  bool _hasSelfie = false;
  bool _hasSelfieWithDoc = false;

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  bool _hasRif = false;

  String get kycStatus => _kycStatus;
  String? get rejectionReason => _rejectionReason;

  bool get hasDocument => _hasDocument;
  bool get hasRif => _hasRif;
  bool get hasSelfie => _hasSelfie;
  bool get hasSelfieWithDoc => _hasSelfieWithDoc;

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  bool get isVerified => _kycStatus == 'verified';
  bool get isPending => _kycStatus == 'pending';
  bool get isRejected => _kycStatus == 'rejected';

  Future<void> loadStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getStatus();
      _logger.i('KYC status response: $data');

      final status = (data['data'] ?? data)['kyc_status'] ?? data['kyc_status'];
      final reason =
          (data['data'] ?? data)['kyc_rejection_reason'] ?? data['kyc_rejection_reason'];
      final hasDocument =
          (data['data'] ?? data)['has_document'] ?? data['has_document'];
      final hasRif =
          (data['data'] ?? data)['has_rif'] ?? data['has_rif'];
      final hasSelfie =
          (data['data'] ?? data)['has_selfie'] ?? data['has_selfie'];
      final hasSelfieWithDoc =
          (data['data'] ?? data)['has_selfie_with_doc'] ?? data['has_selfie_with_doc'];

      _kycStatus = (status ?? 'no_verified').toString();
      _rejectionReason = reason?.toString();
      _hasDocument = hasDocument == true;
      _hasRif = hasRif == true;
      _hasSelfie = hasSelfie == true;
      _hasSelfieWithDoc = hasSelfieWithDoc == true;
    } catch (e, stack) {
      // Si el error es 404 (perfil no encontrado), es normal durante onboarding
      // No es un error fatal, simplemente el usuario aún no tiene perfil
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.contains('Perfil no encontrado')) {
        _logger.i('Perfil aún no existe (normal durante onboarding), usando estado por defecto');
        _kycStatus = 'no_verified';
        _hasDocument = false;
        _hasRif = false;
        _hasSelfie = false;
        _hasSelfieWithDoc = false;
        _errorMessage = null; // No mostrar error en este caso
      } else {
        _logger.e('Error cargando estado KYC', error: e, stackTrace: stack);
        _errorMessage = 'No se pudo cargar el estado de verificación.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startKyc({
    String? documentType,
    String? countryCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.startKyc(
        documentType: documentType,
        countryCode: countryCode,
      );
      _logger.i('KYC start response: $data');

      await loadStatus();
    } catch (e, stack) {
      _logger.e('Error iniciando KYC', error: e, stackTrace: stack);
      _errorMessage = 'No se pudo iniciar el proceso de verificación.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDocument({
    required XFile front,
    required XFile rif,
    required String documentType,
    String? documentNumber,
    String? countryCode,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.uploadDocument(
        front: front,
        rif: rif,
        documentType: documentType,
        documentNumber: documentNumber,
        countryCode: countryCode,
      );
      _logger.i('KYC upload-document response: $data');

      await loadStatus();
      return true;
    } catch (e, stack) {
      _logger.e('Error subiendo documento KYC', error: e, stackTrace: stack);
      _errorMessage = 'No se pudo subir el documento. Intenta de nuevo.';
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> submitSelfie(XFile selfie) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.uploadSelfie(selfie: selfie);
      _logger.i('KYC upload-selfie response: $data');

      await loadStatus();
      return true;
    } catch (e, stack) {
      _logger.e('Error subiendo selfie KYC', error: e, stackTrace: stack);
      _errorMessage = 'No se pudo subir la selfie. Intenta de nuevo.';
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> submitSelfieWithDoc(XFile selfieWithDoc) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.uploadSelfieWithDoc(
        selfieWithDoc: selfieWithDoc,
      );
      _logger.i('KYC upload-selfie-with-doc response: $data');

      await loadStatus();
      return true;
    } catch (e, stack) {
      _logger.e(
        'Error subiendo selfie con documento KYC',
        error: e,
        stackTrace: stack,
      );
      _errorMessage =
          'No se pudo subir la selfie con documento. Intenta de nuevo.';
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}


