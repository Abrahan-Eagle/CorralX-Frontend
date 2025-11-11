import 'package:meta/meta.dart';

/// Métrica individual mostrada dentro del panel de IA Insights.
///
/// Cada métrica contiene la etiqueta principal (`title`), un valor ya
/// formateado listo para mostrarse (`displayValue`) y opcionalmente datos de
/// tendencia para comparaciones rápidas (porcentaje vs. periodo anterior,
/// etiqueta descriptiva y dirección).
@immutable
class IAInsightMetric {
  const IAInsightMetric({
    required this.id,
    required this.title,
    required this.displayValue,
    this.changePercentage,
    this.changeLabel,
    this.trendDirection,
    this.description,
    this.unit,
    this.segment,
  });

  /// Identificador único de la métrica (lo usa la UI para hero tags / keys).
  final String id;

  /// Título amigable de la métrica (p.ej. "Vistas esta semana").
  final String title;

  /// Valor ya listo para mostrarse (p.ej. "12.4K" o "↑ 18 chats").
  final String displayValue;

  /// Cambio porcentual respecto al periodo anterior (puede ser null si no aplica).
  final double? changePercentage;

  /// Texto descriptivo del cambio (p.ej. "vs. semana pasada").
  final String? changeLabel;

  /// Dirección del cambio para elegir ícono/colores (up/down/flat).
  final String? trendDirection;

  /// Descripción adicional para tooltips o acordeones.
  final String? description;

  /// Unidad asociada al valor (p.ej. "%", "USD", "mensajes").
  final String? unit;

  /// Segmento al que pertenece la métrica (p.ej. "marketplace", "chat").
  final String? segment;

  factory IAInsightMetric.fromJson(Map<String, dynamic> json) {
    return IAInsightMetric(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Métrica',
      displayValue: json['display_value']?.toString() ?? '--',
      changePercentage: json['change_percentage'] is num
          ? (json['change_percentage'] as num).toDouble()
          : null,
      changeLabel: json['change_label']?.toString(),
      trendDirection: json['trend_direction']?.toString(),
      description: json['description']?.toString(),
      unit: json['unit']?.toString(),
      segment: json['segment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'display_value': displayValue,
      if (changePercentage != null) 'change_percentage': changePercentage,
      if (changeLabel != null) 'change_label': changeLabel,
      if (trendDirection != null) 'trend_direction': trendDirection,
      if (description != null) 'description': description,
      if (unit != null) 'unit': unit,
      if (segment != null) 'segment': segment,
    };
  }

  IAInsightMetric copyWith({
    String? id,
    String? title,
    String? displayValue,
    double? changePercentage,
    String? changeLabel,
    String? trendDirection,
    String? description,
    String? unit,
    String? segment,
  }) {
    return IAInsightMetric(
      id: id ?? this.id,
      title: title ?? this.title,
      displayValue: displayValue ?? this.displayValue,
      changePercentage: changePercentage ?? this.changePercentage,
      changeLabel: changeLabel ?? this.changeLabel,
      trendDirection: trendDirection ?? this.trendDirection,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      segment: segment ?? this.segment,
    );
  }
}

