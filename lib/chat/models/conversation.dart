/// Modelo de conversación entre dos usuarios
class Conversation {
  final int id;
  final int profile1Id;
  final int profile2Id;
  final int? productId; // Producto relacionado (si la conversación inició por un producto)
  final int? ranchId; // Hacienda relacionada
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos del otro participante (para mostrar en la lista)
  final ChatParticipant? otherParticipant;

  Conversation({
    required this.id,
    required this.profile1Id,
    required this.profile2Id,
    this.productId,
    this.ranchId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.otherParticipant,
  });

  /// Crear desde JSON del backend
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      profile1Id: json['profile_id_1'] is String
          ? int.parse(json['profile_id_1'])
          : json['profile_id_1'] as int,
      profile2Id: json['profile_id_2'] is String
          ? int.parse(json['profile_id_2'])
          : json['profile_id_2'] as int,
      productId: json['product_id'] != null
          ? (json['product_id'] is String
              ? int.tryParse(json['product_id'])
              : json['product_id'] as int?)
          : null,
      ranchId: json['ranch_id'] != null
          ? (json['ranch_id'] is String
              ? int.tryParse(json['ranch_id'])
              : json['ranch_id'] as int?)
          : null,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] is String
          ? int.parse(json['unread_count'])
          : (json['unread_count'] as int? ?? 0),
      isActive: json['is_active'] is String
          ? json['is_active'] == 'true' || json['is_active'] == '1'
          : (json['is_active'] as bool? ?? true),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      otherParticipant: json['other_participant'] != null
          ? ChatParticipant.fromJson(json['other_participant'])
          : null,
    );
  }

  /// Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id_1': profile1Id,
      'profile_id_2': profile2Id,
      'product_id': productId,
      'ranch_id': ranchId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copiar con modificaciones
  Conversation copyWith({
    int? id,
    int? profile1Id,
    int? profile2Id,
    int? productId,
    int? ranchId,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatParticipant? otherParticipant,
  }) {
    return Conversation(
      id: id ?? this.id,
      profile1Id: profile1Id ?? this.profile1Id,
      profile2Id: profile2Id ?? this.profile2Id,
      productId: productId ?? this.productId,
      ranchId: ranchId ?? this.ranchId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherParticipant: otherParticipant ?? this.otherParticipant,
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, profile1: $profile1Id, profile2: $profile2Id, '
        'unread: $unreadCount, lastMessage: $lastMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Datos del participante de una conversación
class ChatParticipant {
  final int id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isVerified;

  ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.isVerified = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: (json['name'] as String?) ?? 'Usuario',
      avatar: json['avatar'] as String?,
      isOnline: json['is_online'] is String
          ? (json['is_online'] == 'true' || json['is_online'] == '1')
          : (json['is_online'] as bool? ?? false),
      lastSeen:
          json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      isVerified: json['is_verified'] is String
          ? (json['is_verified'] == 'true' || json['is_verified'] == '1')
          : (json['is_verified'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'is_verified': isVerified,
    };
  }
}
