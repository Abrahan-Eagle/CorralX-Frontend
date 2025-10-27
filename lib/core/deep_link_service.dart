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
    if (uri.path.startsWith('/product/')) {
      return int.tryParse(uri.path.split('/').last);
    }
    return null;
  }

  /// Extraer el ID del ranch desde un deep link
  static int? extractRanchId(Uri uri) {
    if (uri.path.startsWith('/ranch/')) {
      return int.tryParse(uri.path.split('/').last);
    }
    return null;
  }
}
