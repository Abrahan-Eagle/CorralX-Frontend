import 'package:meta/meta.dart';
import 'package:zonix/insights/models/ia_insight_metric.dart';
import 'package:zonix/insights/models/ia_insight_recommendation.dart';

/// Contenedor principal de la información entregada por IA Insights.
@immutable
class IAInsightsPayload {
  const IAInsightsPayload({
    required this.role,
    required this.timeRangeLabel,
    required this.generatedAt,
    required this.summaryHeadline,
    required this.summaryDescription,
    required this.metrics,
    required this.recommendations,
    this.projections,
    this.rawData = const {},
    this.isMock = false,
  });

  /// Rol del usuario para el que se generó la información.
  final String role;

  /// Etiqueta del rango de fechas analizado (p.ej. "Últimos 7 días").
  final String timeRangeLabel;

  /// Fecha/hora de generación de los datos.
  final DateTime generatedAt;

  /// Titular destacado generado por IA.
  final String summaryHeadline;

  /// Resumen explicativo complementario.
  final String summaryDescription;

  /// Lista de métricas clave para el rol.
  final List<IAInsightMetric> metrics;

  /// Recomendaciones accionables generadas por IA.
  final List<IAInsightRecommendation> recommendations;

  /// Proyecciones u oportunidades futuras (opcional).
  final List<IAInsightMetric>? projections;

  /// Datos crudos originales (se guardan para depurar o versionar).
  final Map<String, dynamic> rawData;

  /// Indica si la respuesta proviene de datos simulados (mock).
  final bool isMock;

  factory IAInsightsPayload.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    List<IAInsightMetric> parseMetrics(dynamic list) {
      if (list is List) {
        return list
            .map((item) => IAInsightMetric.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return const [];
    }

    List<IAInsightRecommendation> parseRecommendations(dynamic list) {
      if (list is List) {
        return list
            .map((item) => IAInsightRecommendation.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return const [];
    }

    return IAInsightsPayload(
      role: json['role']?.toString() ?? 'users',
      timeRangeLabel: json['time_range_label']?.toString() ?? 'Últimos 7 días',
      generatedAt: parseDate(json['generated_at']),
      summaryHeadline: json['summary_headline']?.toString() ??
          'Explora las oportunidades de tu hacienda',
      summaryDescription: json['summary_description']?.toString() ??
          'Pronto tendremos un resumen personalizado para ti.',
      metrics: parseMetrics(json['metrics']),
      recommendations: parseRecommendations(json['recommendations']),
      projections: json['projections'] != null
          ? parseMetrics(json['projections'])
          : null,
      rawData: Map<String, dynamic>.from(json['raw'] as Map? ?? const {}),
      isMock: json['is_mock'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'time_range_label': timeRangeLabel,
      'generated_at': generatedAt.toIso8601String(),
      'summary_headline': summaryHeadline,
      'summary_description': summaryDescription,
      'metrics': metrics.map((metric) => metric.toJson()).toList(),
      'recommendations':
          recommendations.map((recommendation) => recommendation.toJson()).toList(),
      if (projections != null)
        'projections': projections!.map((metric) => metric.toJson()).toList(),
      'raw': rawData,
      'is_mock': isMock,
    };
  }

  IAInsightsPayload copyWith({
    String? role,
    String? timeRangeLabel,
    DateTime? generatedAt,
    String? summaryHeadline,
    String? summaryDescription,
    List<IAInsightMetric>? metrics,
    List<IAInsightRecommendation>? recommendations,
    List<IAInsightMetric>? projections,
    Map<String, dynamic>? rawData,
    bool? isMock,
  }) {
    return IAInsightsPayload(
      role: role ?? this.role,
      timeRangeLabel: timeRangeLabel ?? this.timeRangeLabel,
      generatedAt: generatedAt ?? this.generatedAt,
      summaryHeadline: summaryHeadline ?? this.summaryHeadline,
      summaryDescription: summaryDescription ?? this.summaryDescription,
      metrics: metrics ?? this.metrics,
      recommendations: recommendations ?? this.recommendations,
      projections: projections ?? this.projections,
      rawData: rawData ?? this.rawData,
      isMock: isMock ?? this.isMock,
    );
  }
}

