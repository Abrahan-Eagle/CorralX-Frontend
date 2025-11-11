import 'package:flutter/foundation.dart';
import 'package:zonix/insights/models/ia_insight_recommendation.dart';
import 'package:zonix/insights/models/ia_insights_payload.dart';
import 'package:zonix/insights/services/ia_insights_service.dart';

/// Provider que administra el estado del módulo IA Insights.
class IAInsightsProvider with ChangeNotifier {
  IAInsightsPayload? _payload;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentRole;

  IAInsightsPayload? get payload => _payload;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentRole => _currentRole;
  bool get hasData => _payload != null;

  Future<void> loadInsights({
    required String role,
    String timeRange = '7d',
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;

    final bool shouldSkip =
        !forceRefresh && _payload != null && _currentRole == role;
    if (shouldSkip) return;

    _isLoading = true;
    _errorMessage = null;
    _currentRole = role;
    notifyListeners();

    try {
      _payload = await IAInsightsService.fetchDashboard(
        role: role,
        timeRange: timeRange,
      );
    } catch (e) {
      debugPrint('❌ IAInsightsProvider.loadInsights error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({String timeRange = '7d'}) async {
    if (_currentRole == null) return;
    await loadInsights(
      role: _currentRole!,
      timeRange: timeRange,
      forceRefresh: true,
    );
  }

  Future<void> markRecommendationCompleted(
    IAInsightRecommendation recommendation,
    bool isCompleted,
  ) async {
    if (_payload == null) return;

    final updatedList = _payload!.recommendations.map((item) {
      if (item.id == recommendation.id) {
        return item.copyWith(isCompleted: isCompleted);
      }
      return item;
    }).toList();

    _payload = _payload!.copyWith(recommendations: updatedList);
    notifyListeners();

    try {
      await IAInsightsService.updateRecommendationStatus(
        recommendationId: recommendation.id,
        isCompleted: isCompleted,
      );
    } catch (e) {
      debugPrint('⚠️ No se pudo sincronizar recomendación: $e');
      // Revertir estado local si la sincronización falla.
      _payload = _payload!.copyWith(
        recommendations: updatedList.map((item) {
          if (item.id == recommendation.id) {
            return item.copyWith(isCompleted: !isCompleted);
          }
          return item;
        }).toList(),
      );
      _errorMessage = 'No se pudo actualizar la recomendación. Intenta de nuevo.';
      notifyListeners();
    }
  }

  void clear() {
    _payload = null;
    _errorMessage = null;
    _currentRole = null;
    notifyListeners();
  }
}

