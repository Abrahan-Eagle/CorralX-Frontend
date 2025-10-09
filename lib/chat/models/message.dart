/// Modelo de mensaje en una conversación
class Message {
  final dynamic id; // Puede ser int (del servidor) o String (temporal local)
  final int conversationId;
  final int senderId;
  final int? receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  
  // Datos del remitente (para UI)
  final MessageSender? sender;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.sender,
  });

  /// Crear desde JSON del backend
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'], // Puede ser int o string
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int?,
      content: json['content'] as String,
      type: _parseMessageType(json['message_type'] as String?),
      status: _parseMessageStatus(json),
      sentAt: DateTime.parse(json['sent_at'] ?? json['created_at']),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      sender: json['sender'] != null
          ? MessageSender.fromJson(json['sender'])
          : null,
    );
  }

  /// Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      if (id is int) 'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      if (receiverId != null) 'receiver_id': receiverId,
      'content': content,
      'message_type': type.name,
      'sent_at': sentAt.toIso8601String(),
      if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
    };
  }

  /// Parsear tipo de mensaje
  static MessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  /// Parsear estado del mensaje
  static MessageStatus _parseMessageStatus(Map<String, dynamic> json) {
    if (json['read_at'] != null) return MessageStatus.read;
    if (json['delivered_at'] != null) return MessageStatus.delivered;
    if (json['sent_at'] != null || json['created_at'] != null) {
      return MessageStatus.sent;
    }
    return MessageStatus.sending;
  }

  /// Copiar con modificaciones
  Message copyWith({
    dynamic id,
    int? conversationId,
    int? senderId,
    int? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    MessageSender? sender,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      sender: sender ?? this.sender,
    );
  }

  /// Verificar si es mensaje propio
  bool isOwnMessage(int currentUserId) {
    return senderId == currentUserId;
  }

  /// Verificar si el mensaje fue leído
  bool get isRead => readAt != null;

  /// Verificar si el mensaje fue entregado
  bool get isDelivered => deliveredAt != null || readAt != null;

  @override
  String toString() {
    return 'Message(id: $id, conv: $conversationId, from: $senderId, '
        'content: ${content.substring(0, content.length > 30 ? 30 : content.length)}..., '
        'status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Tipos de mensaje
enum MessageType {
  text,
  image,
  file,
  location,
}

/// Estados del mensaje
enum MessageStatus {
  sending, // Enviando (optimistic update)
  sent, // Enviado al servidor
  delivered, // Entregado al destinatario
  read, // Leído por el destinatario
  failed, // Falló el envío
}

/// Datos del remitente del mensaje
class MessageSender {
  final int id;
  final String name;
  final String? avatar;

  MessageSender({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}

