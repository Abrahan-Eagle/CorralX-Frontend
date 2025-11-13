import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:corralx/chat/models/conversation.dart';
import 'package:corralx/chat/models/message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Servicio HTTP para comunicación con la API de Chat
/// Maneja todas las operaciones REST relacionadas con conversaciones y mensajes
class ChatService {
  static const storage = FlutterSecureStorage();

  // URL base - Lógica simple: release = producción, debug = local
  static String get _baseUrl {
    final bool isProduction =
        kReleaseMode || const bool.fromEnvironment('dart.vm.product');

    final String baseUrl = isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

    return baseUrl;
  }

  /// GET /api/chat/conversations
  /// Obtiene la lista de conversaciones del usuario autenticado
  static Future<List<Conversation>> getConversations() async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('🌐 ChatService.getConversations iniciado');
      print('🔧 URL: $baseUrl/api/chat/conversations');
      print('🔑 Token: ${token?.substring(0, 20)}...');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible. Usuario no autenticado.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final conversations =
            data.map((json) => Conversation.fromJson(json)).toList();

        print('✅ Conversaciones obtenidas: ${conversations.length}');
        return conversations;
      } else if (response.statusCode == 401) {
        print('❌ Error 401: Token inválido o expirado');
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception(
            'Error al obtener conversaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en getConversations: $e');
      rethrow;
    }
  }

  /// GET /api/chat/conversations/{id}/messages
  /// Obtiene los mensajes de una conversación específica
  static Future<List<Message>> getMessages(int conversationId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('🌐 ChatService.getMessages - ConvID: $conversationId');
      print('🔧 URL: $baseUrl/api/chat/conversations/$conversationId/messages');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((json) => Message.fromJson(json)).toList();

        print('✅ Mensajes obtenidos: ${messages.length}');
        return messages;
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 404) {
        throw Exception('Conversación no encontrada');
      } else {
        throw Exception('Error al obtener mensajes: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en getMessages: $e');
      rethrow;
    }
  }

  /// POST /api/chat/conversations/{id}/messages
  /// Envía un nuevo mensaje en una conversación
  static Future<Message> sendMessage(int conversationId, String content) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('📤 ChatService.sendMessage - ConvID: $conversationId');
      print(
          '💬 Contenido: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'content': content,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final message = Message.fromJson(data);

        print('✅ Mensaje enviado - ID: ${message.id}');
        return message;
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 422) {
        final errors = json.decode(response.body);
        throw Exception('Validación fallida: ${errors['message']}');
      } else {
        throw Exception('Error al enviar mensaje: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en sendMessage: $e');
      rethrow;
    }
  }

  /// POST /api/chat/conversations/{id}/read
  /// Marca los mensajes de una conversación como leídos
  static Future<void> markAsRead(int conversationId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('👁️ ChatService.markAsRead - ConvID: $conversationId');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Mensajes marcados como leídos');
      } else {
        print('⚠️ Error al marcar como leído: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en markAsRead: $e');
      // No re-lanzar error, no es crítico si falla
    }
  }

  /// POST /api/chat/conversations
  /// Crea una nueva conversación con otro usuario
  static Future<Conversation> createConversation(int otherProfileId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('➕ ChatService.createConversation - ProfileID: $otherProfileId');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'profile_id_2': otherProfileId,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final conversation = Conversation.fromJson(data);

        print('✅ Conversación creada - ID: ${conversation.id}');
        return conversation;
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 422) {
        final errors = json.decode(response.body);
        throw Exception('Validación fallida: ${errors['message']}');
      } else {
        throw Exception('Error al crear conversación: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en createConversation: $e');
      rethrow;
    }
  }

  /// DELETE /api/chat/conversations/{id}
  /// Elimina una conversación
  static Future<void> deleteConversation(int conversationId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('🗑️ ChatService.deleteConversation - ConvID: $conversationId');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Conversación eliminada');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 404) {
        throw Exception('Conversación no encontrada');
      } else {
        throw Exception(
            'Error al eliminar conversación: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en deleteConversation: $e');
      rethrow;
    }
  }

  /// GET /api/chat/search?query={query}
  /// Busca mensajes por contenido
  static Future<List<Message>> searchMessages(String query) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('🔍 ChatService.searchMessages - Query: $query');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/chat/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((json) => Message.fromJson(json)).toList();

        print('✅ Mensajes encontrados: ${messages.length}');
        return messages;
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en searchMessages: $e');
      rethrow;
    }
  }

  /// POST /api/chat/conversations/{id}/typing/start
  /// Notifica que el usuario está escribiendo
  static Future<void> notifyTypingStarted(int conversationId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse(
            '$baseUrl/api/chat/conversations/$conversationId/typing/start'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('⌨️ Typing started notificado');
    } catch (e) {
      print('⚠️ Error notificando typing: $e');
      // No crítico, no lanzar error
    }
  }

  /// POST /api/chat/conversations/{id}/typing/stop
  /// Notifica que el usuario dejó de escribir
  static Future<void> notifyTypingStopped(int conversationId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse(
            '$baseUrl/api/chat/conversations/$conversationId/typing/stop'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('⌨️ Typing stopped notificado');
    } catch (e) {
      print('⚠️ Error notificando typing stop: $e');
      // No crítico
    }
  }

  /// POST /api/chat/block
  /// Bloquea a un usuario
  static Future<void> blockUser(int userId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('🚫 ChatService.blockUser - UserID: $userId');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/block'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Usuario bloqueado');
      } else {
        throw Exception('Error al bloquear usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en blockUser: $e');
      rethrow;
    }
  }

  /// DELETE /api/chat/block/{userId}
  /// Desbloquea a un usuario
  static Future<void> unblockUser(int userId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('✅ ChatService.unblockUser - UserID: $userId');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/block/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Usuario desbloqueado');
      } else {
        throw Exception('Error al desbloquear usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en unblockUser: $e');
      rethrow;
    }
  }

  /// GET /api/chat/blocked-users
  /// Obtiene la lista de usuarios bloqueados
  static Future<List<int>> getBlockedUsers() async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('🌐 ChatService.getBlockedUsers');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/blocked-users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final blockedUserIds = data.map((id) => id as int).toList();

        print('✅ Usuarios bloqueados: ${blockedUserIds.length}');
        return blockedUserIds;
      } else {
        throw Exception('Error al obtener bloqueados: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en getBlockedUsers: $e');
      return []; // Retornar lista vacía en caso de error
    }
  }

  /// GET /api/profile/{id}
  /// Obtiene el perfil de un usuario por ID
  static Future<Map<String, dynamic>> getContactProfile(int profileId) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = _baseUrl;

      print('👤 ChatService.getContactProfile iniciado');
      print('🔧 URL: $baseUrl/api/profile/$profileId');
      print('🔑 Token: ${token?.substring(0, 20)}...');

      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible. Usuario no autenticado.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/$profileId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> profile = json.decode(response.body);
        print(
            '✅ Perfil obtenido: ${profile['firstName']} ${profile['lastName']}');
        return profile;
      } else if (response.statusCode == 401) {
        print('❌ Error 401: Token inválido o expirado');
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else if (response.statusCode == 404) {
        print('❌ Error 404: Perfil no encontrado');
        throw Exception('Perfil no encontrado');
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en getContactProfile: $e');
      rethrow;
    }
  }
}
