import 'package:meta/meta.dart';

/// Recomendaciones generadas por IA con acciones sugeridas.
@immutable
class IAInsightRecommendation {
  const IAInsightRecommendation({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'medium',
    this.impactText,
    this.segment,
    this.isCompleted = false,
    this.generatedAt,
    this.dueDate,
  });

  final String id;
  final String title;
  final String description;

  /// Prioridad sugerida por la IA (low, medium, high).
  final String priority;

  /// Texto que resume el impacto esperado al aplicar la sugerencia.
  final String? impactText;

  /// Segmento o módulo relacionado (marketplace, chat, ranch, etc.).
  final String? segment;

  /// Bandera local para marcar la recomendación como atendida.
  final bool isCompleted;

  /// Fecha de generación de la recomendación.
  final DateTime? generatedAt;

  /// Fecha sugerida de vencimiento/seguimiento.
  final DateTime? dueDate;

  factory IAInsightRecommendation.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return IAInsightRecommendation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Recomendación',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      impactText: json['impact_text']?.toString(),
      segment: json['segment']?.toString(),
      isCompleted: json['is_completed'] == true,
      generatedAt: parseDate(json['generated_at']),
      dueDate: parseDate(json['due_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      if (impactText != null) 'impact_text': impactText,
      if (segment != null) 'segment': segment,
      'is_completed': isCompleted,
      if (generatedAt != null) 'generated_at': generatedAt!.toIso8601String(),
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
    };
  }

  IAInsightRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? impactText,
    String? segment,
    bool? isCompleted,
    DateTime? generatedAt,
    DateTime? dueDate,
  }) {
    return IAInsightRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      impactText: impactText ?? this.impactText,
      segment: segment ?? this.segment,
      isCompleted: isCompleted ?? this.isCompleted,
      generatedAt: generatedAt ?? this.generatedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

