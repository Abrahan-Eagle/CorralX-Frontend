/// Modelo de usuario en el contexto de chat
/// Representa la información de un participante de conversación
class ChatUser {
  final int id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isVerified;
  final bool isBlocked;

  ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.isVerified = false,
    this.isBlocked = false,
  });

  /// Crear desde JSON del backend
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      isVerified: json['is_verified'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'is_verified': isVerified,
      'is_blocked': isBlocked,
    };
  }

  /// Copiar con modificaciones
  ChatUser copyWith({
    int? id,
    String? name,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isVerified,
    bool? isBlocked,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  /// Obtener iniciales del nombre para avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Obtener texto de estado (online / última vez visto)
  String get statusText {
    if (isOnline) return 'En línea';
    if (lastSeen == null) return 'Sin conexión';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) return 'Activo hace un momento';
    if (difference.inMinutes < 60) {
      return 'Activo hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Activo hace ${difference.inHours} h';
    }
    if (difference.inDays < 7) {
      return 'Activo hace ${difference.inDays} días';
    }
    return 'Inactivo';
  }

  @override
  String toString() {
    return 'ChatUser(id: $id, name: $name, online: $isOnline, verified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

