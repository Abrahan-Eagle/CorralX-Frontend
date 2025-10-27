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
      print('🔗 DeepLinkService.getInitialLink: $link');
      if (link != null) {
        print('🔗 Link scheme: ${link.scheme}');
        print('🔗 Link path: ${link.path}');
        print('🔗 Link host: ${link.host}');
      }
      return link;
    } catch (e) {
      print('❌ Error obteniendo link inicial: $e');
      return null;
    }
  }

  /// Escuchar cuando la app recibe un deep link
  Stream<Uri> listenToLinks() {
    print('🔗 DeepLinkService.listenToLinks: Configurando listener...');
    return _appLinks.uriLinkStream;
  }

  /// Extraer el ID del producto desde un deep link
  static int? extractProductId(Uri uri) {
    print('🔍 DeepLinkService.extractProductId - URI completo: $uri');
    print('🔍 Scheme: ${uri.scheme}, Path: ${uri.path}, Host: ${uri.host}');

    // Soporta múltiples formatos:
    // - https://corralx.com/product/123
    // - http://corralx.com/product/123
    // - corralx://product/123
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    print('🔍 Path procesado: $path');

    // Verificar si la URL es de corralx.com (HTTP o HTTPS)
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host.contains('corralx.com') ||
            uri.host.contains('corralx') ||
            uri.host.contains('192.168.27.12'))) {
      // Soporta /product/, /products/, /api/product/, y /api/products/
      if (path.startsWith('/product/') ||
          path.startsWith('/products/') ||
          path.startsWith('/api/product/') ||
          path.startsWith('/api/products/')) {
        final productId = int.tryParse(path.split('/').last);
        print('🔍 Product ID extraído (HTTPS): $productId');
        return productId;
      }
    }

    // También soporta el esquema custom corralx://
    if (uri.scheme == 'corralx') {
      // Soporta tanto /product/ como /products/
      if (path.startsWith('/product/') || path.startsWith('/products/')) {
        final productId = int.tryParse(path.split('/').last);
        print('🔍 Product ID extraído (custom scheme): $productId');
        return productId;
      }
    }

    print('🔍 No se encontró patrón /product/ en el path');
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
