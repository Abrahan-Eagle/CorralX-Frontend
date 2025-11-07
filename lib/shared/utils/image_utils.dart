import 'package:flutter/material.dart';

/// Lista de hosts bloqueados o que no están disponibles en entornos cerrados.
const Set<String> _blockedImageHosts = {
  'via.placeholder.com',
};

/// Verifica si una URL de imagen apunta a un host bloqueado.
bool isBlockedImageHost(String? url) {
  if (url == null || url.isEmpty) {
    return false;
  }

  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) {
    return false;
  }

  return _blockedImageHosts.contains(uri.host.toLowerCase());
}

/// Construye un widget de fallback para mostrar cuando una imagen remota no está disponible.
Widget buildImageFallback({
  required IconData icon,
  Color? backgroundColor,
  Color? iconColor,
  double iconSize = 50,
}) {
  return Container(
    color: backgroundColor ?? Colors.grey[200],
    child: Icon(
      icon,
      size: iconSize,
      color: iconColor ?? Colors.grey[500],
    ),
  );
}

