import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Script para verificar conectividad y credenciales de servicios externos
Future<void> main() async {
  print('🔍 Verificando credenciales y conectividad...\n');

  // Cargar variables de entorno
  await dotenv.load(fileName: '.env');

  // ============================================
  // 1. VERIFICAR API BACKEND
  // ============================================
  print('1️⃣ Verificando API Backend...');
  final apiUrlLocal = dotenv.env['API_URL_LOCAL'] ?? '';
  final apiUrlProd = dotenv.env['API_URL_PROD'] ?? '';
  
  print('   📍 API Local: $apiUrlLocal');
  print('   📍 API Prod: $apiUrlProd');

  try {
    final response = await http.get(
      Uri.parse('$apiUrlLocal/api/ping'),
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 5));

    if (response.statusCode == 200) {
      print('   ✅ API Local: Conectada correctamente');
      print('   📦 Respuesta: ${response.body}');
    } else {
      print('   ⚠️ API Local: Responde pero con código ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ API Local: Error de conexión - $e');
  }

  // ============================================
  // 2. VERIFICAR PUSHER CREDENTIALS
  // ============================================
  print('\n2️⃣ Verificando credenciales de Pusher...');
  final pusherKey = dotenv.env['PUSHER_APP_KEY'] ?? '';
  final pusherCluster = dotenv.env['PUSHER_APP_CLUSTER'] ?? '';
  final enablePusher = dotenv.env['ENABLE_PUSHER'] ?? 'false';

  print('   🔑 PUSHER_APP_KEY: ${pusherKey.isNotEmpty ? pusherKey.substring(0, 10) + '...' : '❌ NO CONFIGURADA'}');
  print('   🌍 PUSHER_APP_CLUSTER: $pusherCluster');
  print('   ⚡ ENABLE_PUSHER: $enablePusher');

  if (pusherKey.isEmpty) {
    print('   ❌ PUSHER_APP_KEY no está configurada en .env');
  } else {
    print('   ✅ PUSHER_APP_KEY configurada');
    
    // Intentar verificar conexión a Pusher
    try {
      final pusherUrl = 'https://api-$pusherCluster.pusher.com/apps';
      print('   🔗 Intentando conectar a: $pusherUrl');
      
      final response = await http.get(
        Uri.parse(pusherUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 401) {
        print('   ✅ Servidor Pusher accesible (respuesta ${response.statusCode})');
      } else {
        print('   ⚠️ Servidor Pusher respondió con código ${response.statusCode}');
      }
    } catch (e) {
      print('   ⚠️ No se pudo verificar servidor Pusher: $e');
    }
  }

  // ============================================
  // 3. VERIFICAR FIREBASE
  // ============================================
  print('\n3️⃣ Verificando configuración de Firebase...');
  
  // Verificar si existe google-services.json
  final googleServicesPath = 'android/app/google-services.json';
  final googleServicesFile = File(googleServicesPath);
  
  if (await googleServicesFile.exists()) {
    print('   ✅ google-services.json existe');
    
    try {
      final content = await googleServicesFile.readAsString();
      final json = jsonDecode(content);
      final projectInfo = json['project_info'];
      
      if (projectInfo != null) {
        print('   📦 Project ID: ${projectInfo['project_id']}');
        print('   🔢 Project Number: ${projectInfo['project_number']}');
        
        // Verificar OAuth clients
        final clients = json['client']?[0]?['oauth_client'] ?? [];
        print('   🔑 OAuth Clients configurados: ${clients.length}');
        
        for (var client in clients) {
          if (client['client_type'] == 1) {
            final clientId = client['client_id'] ?? '';
            final certHash = client['android_info']?['certificate_hash'] ?? '';
            print('      - Client ID: ${clientId.substring(0, 30)}...');
            print('        SHA-1: $certHash');
          }
        }
      }
    } catch (e) {
      print('   ⚠️ Error leyendo google-services.json: $e');
    }
  } else {
    print('   ❌ google-services.json NO existe en $googleServicesPath');
  }

  // ============================================
  // 4. VERIFICAR VARIABLES DE ENTORNO CRÍTICAS
  // ============================================
  print('\n4️⃣ Verificando variables de entorno críticas...');
  
  final criticalVars = [
    'API_URL_LOCAL',
    'API_URL_PROD',
    'PUSHER_APP_KEY',
    'PUSHER_APP_CLUSTER',
    'ENABLE_PUSHER',
  ];

  for (var varName in criticalVars) {
    final value = dotenv.env[varName];
    if (value != null && value.isNotEmpty) {
      // Ocultar valores sensibles
      if (varName.contains('KEY') || varName.contains('SECRET')) {
        print('   ✅ $varName: ${value.substring(0, value.length > 10 ? 10 : value.length)}...');
      } else {
        print('   ✅ $varName: $value');
      }
    } else {
      print('   ❌ $varName: NO CONFIGURADA');
    }
  }

  // ============================================
  // 5. VERIFICAR BACKEND PUSHER (comparar keys)
  // ============================================
  print('\n5️⃣ Comparando credenciales Frontend vs Backend...');
  print('   ⚠️ NOTA: Las credenciales de Pusher deben coincidir entre frontend y backend');
  print('   📝 Backend debe tener en .env:');
  print('      PUSHER_APP_KEY=<mismo valor que frontend>');
  print('      PUSHER_APP_SECRET=<secret del dashboard de Pusher>');
  print('      PUSHER_APP_ID=<app id del dashboard de Pusher>');
  print('      PUSHER_APP_CLUSTER=$pusherCluster');
  print('      BROADCAST_DRIVER=pusher');

  print('\n✅ Verificación completada\n');
}

