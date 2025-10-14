import 'package:flutter/foundation.dart';
import '../services/ranch_marketplace_service.dart';
import '../../profiles/models/ranch.dart';

class RanchProvider extends ChangeNotifier {
  final RanchMarketplaceService _service = RanchMarketplaceService();

  // Estado
  List<Ranch> _ranches = [];
  List<Ranch> _favoriteRanches = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _currentFilters = {};

  // Getters
  List<Ranch> get ranches => _ranches;
  List<Ranch> get favoriteRanches => _favoriteRanches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get currentFilters => _currentFilters;

  /// Obtener todos los ranchos públicos
  Future<void> fetchRanches({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🌐 RanchProvider: Fetching ranches with filters: $filters');
      _ranches = await _service.getAllRanches(filters: filters);
      debugPrint('✅ RanchProvider: ${_ranches.length} ranches fetched');
    } catch (e) {
      _errorMessage = 'Error al cargar haciendas: $e';
      debugPrint('❌ RanchProvider: Error fetching ranches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aplicar filtros de búsqueda
  void applyFilters(Map<String, dynamic> filters) {
    _currentFilters = filters;
    fetchRanches(filters: filters);
  }

  /// Limpiar filtros
  void clearFilters() {
    _currentFilters = {};
    fetchRanches();
  }

  /// Buscar ranchos por término
  void searchRanches(String searchTerm) {
    if (searchTerm.isEmpty) {
      clearFilters();
    } else {
      applyFilters({'search': searchTerm});
    }
  }

  /// Toggle favorito (placeholder - implementar cuando exista endpoint)
  Future<void> toggleFavorite(Ranch ranch) async {
    try {
      final isFavorite = _favoriteRanches.any((r) => r.id == ranch.id);
      
      if (isFavorite) {
        _favoriteRanches.removeWhere((r) => r.id == ranch.id);
        debugPrint('💔 Ranch ${ranch.id} removed from favorites');
      } else {
        _favoriteRanches.add(ranch);
        debugPrint('💚 Ranch ${ranch.id} added to favorites');
      }
      
      notifyListeners();
      
      // TODO: Implementar llamada al backend cuando exista endpoint
      // await _service.toggleFavorite(ranch.id);
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Verificar si un rancho está en favoritos
  bool isFavorite(int ranchId) {
    return _favoriteRanches.any((r) => r.id == ranchId);
  }

  /// Refrescar lista
  Future<void> refresh() async {
    await fetchRanches(filters: _currentFilters);
  }
}

