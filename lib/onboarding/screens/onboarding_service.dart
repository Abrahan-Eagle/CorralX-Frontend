import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:corralx/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Usa AppConfig que detecta automáticamente los 3 entornos (local/test/production)
final String baseUrl = AppConfig.apiUrl;

class OnboardingService {
  final _storage = const FlutterSecureStorage();

  // Recuperar el token del almacenamiento seguro
  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'token');
    logger.i('Token recuperado: $token');
    return token;
  }

  // Completar el proceso de onboarding del usuario
  Future<void> completeOnboarding(int userId) async {
    final token = await _getToken();

    if (token == null) {
      logger.e("Token no encontrado. No se puede completar el onboarding.");
      throw Exception("Token no encontrado.");
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/onboarding/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'completed_onboarding': true}),
      );

      if (response.statusCode == 200) {
        // Manejo de éxito
        debugPrint("Onboarding completado con éxito.");
        logger.i("Onboarding completado con éxito.");
      } else {
        // Manejo de error
        logger.e(
            "Error al completar el onboarding: ${response.statusCode} - ${response.body}");
        throw Exception(
            "Error al completar el onboarding: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("Excepción al hacer la solicitud de onboarding: $e");
      throw Exception("Error en la solicitud de onboarding");
    }
  }

  // Opción A: Completar onboarding recibiendo userId explícito y valor 0/1
  Future<void> completeOnboardingById(int userId, {int completed = 1}) async {
    final token = await _getToken();

    if (token == null) {
      logger.e("Token no encontrado. No se puede completar el onboarding.");
      throw Exception("Token no encontrado.");
    }

    final uri = Uri.parse('$baseUrl/api/onboarding/$userId');
    final payload = {'completed_onboarding': completed};

    logger.i('[Onboarding:A] PUT $uri');
    logger.i('[Onboarding:A] Payload: ${jsonEncode(payload)}');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    logger.i('[Onboarding:A] Response status: ${response.statusCode}');
    logger.i('[Onboarding:A] Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Error al completar el onboarding: ${response.statusCode}');
    }
  }
}
