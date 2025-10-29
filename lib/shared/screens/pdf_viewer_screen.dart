import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String? title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;
  PDFViewController? pdfController;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Descargar PDF a archivo temporal
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode != 200) {
        throw Exception('Error al descargar PDF: ${response.statusCode}');
      }

      // Guardar en directorio temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(widget.pdfUrl).split('?').first;
      final filePath = path.join(tempDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        localPath = filePath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar PDF: $e';
      });
    }
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[300],
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title ?? 'Documento PDF',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (isReady && totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Documento descargado temporalmente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Descargar',
          ),
        ],
      ),
      body: _buildBody(theme, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando documento...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (localPath == null) {
      return Center(
        child: Text(
          'No se pudo cargar el PDF',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 16,
          ),
        ),
      );
    }

    return PDFView(
      filePath: localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      onRender: (pages) {
        setState(() {
          totalPages = pages ?? 0;
          isReady = true;
        });
      },
      onError: (error) {
        setState(() {
          errorMessage = 'Error al renderizar PDF: $error';
        });
      },
      onPageError: (page, error) {
        print('Error en página $page: $error');
      },
      onViewCreated: (PDFViewController controller) {
        pdfController = controller;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          currentPage = page ?? 0;
          totalPages = total ?? 0;
        });
      },
    );
  }
}
