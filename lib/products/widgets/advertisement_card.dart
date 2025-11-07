import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/advertisement.dart';
import '../models/product.dart';
import 'product_card.dart';
import 'package:zonix/shared/utils/image_utils.dart';

/// Widget para mostrar un producto patrocinado
/// Similar a ProductCard pero con badge de "Patrocinado"
class SponsoredProductCard extends StatelessWidget {
  final Advertisement advertisement;
  final Product? product; // Producto asociado si está disponible
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final VoidCallback? onAdClick;

  const SponsoredProductCard({
    super.key,
    required this.advertisement,
    this.product,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.onAdClick,
  });

  @override
  Widget build(BuildContext context) {
    // Para productos patrocinados: SIEMPRE intentar usar el producto
    // Si no tenemos el producto pero tenemos productId, mostrar mensaje de carga
    if (advertisement.isSponsoredProduct) {
      // Si tenemos el producto, usar ProductCard con badge de patrocinado (Instagram-like)
      if (product != null) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ProductCard(
              product: product!,
              onTap: () {
                // Registrar click en el anuncio
                onAdClick?.call();
                onTap?.call();
              },
              onFavorite: onFavorite,
              isFavorite: isFavorite,
            ),
            // Badge de "Patrocinado" en la esquina superior izquierda
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade700,
                      Colors.orange.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Patrocinado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      } else {
        // Si no tenemos el producto aún (no debería pasar con la nueva lógica),
        // mostrar un placeholder mientras se carga
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Cargando producto patrocinado...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Si llegamos aquí, es publicidad externa (no debería pasar con el código actual)
    // Mantenemos este código por seguridad, pero no debería ejecutarse
    throw Exception('SponsoredProductCard solo debe usarse para productos patrocinados');
  }
}

/// Widget para mostrar publicidad externa
class ExternalAdCard extends StatelessWidget {
  final Advertisement advertisement;
  final VoidCallback? onAdClick;

  const ExternalAdCard({
    super.key,
    required this.advertisement,
    this.onAdClick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () async {
          // Registrar click
          onAdClick?.call();

          // Abrir URL externa si existe
          if (advertisement.targetUrl != null) {
            final uri = Uri.parse(advertisement.targetUrl!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del anuncio
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  child: isBlockedImageHost(advertisement.imageUrl)
                      ? buildImageFallback(
                          icon: Icons.ads_click,
                          backgroundColor: Colors.grey[200],
                        )
                      : CachedNetworkImage(
                          imageUrl: advertisement.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              buildImageFallback(
                            icon: Icons.ads_click,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                  ),
                ),
                // Badge de "Publicidad"
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                      ],
                    ),
                    child: const Text(
                      'Publicidad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Información del anuncio
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (advertisement.advertiserName != null) ...[
                    Text(
                      advertisement.advertiserName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    advertisement.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (advertisement.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      advertisement.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (advertisement.targetUrl != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ver más',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
