import 'package:app_links/app_links.dart';

/// Servicio para manejar deep links en la app
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();

  /// Obtener el link inicial cuando la app se abre
  Future<Uri?> getInitialLink() async {
    try {
      final link = await _appLinks.getInitialLink();
      return link;
    } catch (e) {
      print('❌ Error obteniendo link inicial: $e');
      return null;
    }
  }

  /// Escuchar cuando la app recibe un deep link
  Stream<Uri> listenToLinks() {
    return _appLinks.uriLinkStream;
  }

  /// Extraer el ID del producto desde un deep link
  static int? extractProductId(Uri uri) {
    // Soporta ambos formatos: /product/123 y product/123
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    if (path.startsWith('/product/')) {
      return int.tryParse(path.split('/').last);
    }
    return null;
  }

  /// Extraer el ID del ranch desde un deep link
  static int? extractRanchId(Uri uri) {
    // Soporta ambos formatos: /ranch/123 y ranch/123
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    if (path.startsWith('/ranch/')) {
      return int.tryParse(path.split('/').last);
    }
    return null;
  }
}
