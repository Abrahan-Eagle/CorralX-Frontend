import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Pantalla que muestra el comprobante de venta
class ReceiptScreen extends StatefulWidget {
  final int orderId;

  const ReceiptScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Map<String, dynamic>? _receiptData;

  Map<String, dynamic> get _receipt => _receiptData ?? <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    final orderProvider = context.read<OrderProvider>();
    final receipt = await orderProvider.getReceipt(widget.orderId);
    if (mounted) {
      setState(() {
        _receiptData = receipt;
      });
    }
  }

  Future<void> _shareReceipt() async {
    if (_receiptData == null) return;

    final receiptNumber = _receipt['receipt_number'] ?? 'N/A';
    final receiptText = _buildReceiptText(_receipt);

    await Share.share(
      receiptText,
      subject: 'Comprobante de Venta CorralX - $receiptNumber',
    );
  }

  Future<void> _generatePdf() async {
    if (_receiptData == null) return;

    final receipt = _receipt;
    final doc = pw.Document();

    final seller = receipt['seller'] ?? {};
    final buyer = receipt['buyer'] ?? {};
    final product = receipt['product'] ?? {};
    final delivery = receipt['delivery'] ?? {};

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'COMPROBANTE DE VENTA',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'CORRALX',
                  style: pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Número de Comprobante: ${receipt['receipt_number'] ?? 'N/A'}',
          ),
          pw.Text(
            'Fecha de emisión: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'DATOS DEL VENDEDOR',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Nombre: ${seller['name'] ?? 'N/A'}'),
          pw.Text('Finca: ${seller['ranch_name'] ?? 'N/A'}'),
          pw.Text('Dirección: ${seller['address'] ?? 'N/A'}'),
          if (seller['phone'] != null)
            pw.Text('Teléfono: ${seller['phone']}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'DATOS DEL COMPRADOR',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Nombre: ${buyer['name'] ?? 'N/A'}'),
          pw.Text('Dirección: ${buyer['address'] ?? 'N/A'}'),
          if (buyer['phone'] != null)
            pw.Text('Teléfono: ${buyer['phone']}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'DETALLE DEL PRODUCTO',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Producto: ${product['title'] ?? 'N/A'}'),
          if (product['breed'] != null)
            pw.Text('Raza: ${product['breed']}'),
          pw.Text('Cantidad: ${product['quantity'] ?? 'N/A'}'),
          pw.Text('Precio unitario: ${product['unit_price'] ?? 'N/A'} ${product['currency'] ?? ''}'),
          pw.Text(
            'Total: ${product['total_price'] ?? 'N/A'} ${product['currency'] ?? ''}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (delivery.isNotEmpty) ...[
            pw.Text(
              'ENTREGA',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
                'Método: ${delivery['method_name'] ?? delivery['method'] ?? 'N/A'}'),
            if (delivery['delivery_address'] != null)
              pw.Text('Dirección: ${delivery['delivery_address']}'),
            if (delivery['expected_date'] != null)
              pw.Text('Fecha esperada: ${delivery['expected_date']}'),
          ],
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NOTA IMPORTANTE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'El pago se realiza fuera de la aplicación cuando comprador y vendedor se encuentran físicamente.',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  String _buildReceiptText(Map<String, dynamic> receipt) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('     COMPROBANTE DE VENTA CORRALX');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Número: ${receipt['receipt_number'] ?? 'N/A'}');
    buffer.writeln(
      'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
    );
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('DATOS DEL VENDEDOR');
    buffer.writeln('═══════════════════════════════════════');
    final seller = receipt['seller'] ?? {};
    buffer.writeln('Nombre: ${seller['name'] ?? 'N/A'}');
    buffer.writeln('Finca: ${seller['ranch_name'] ?? 'N/A'}');
    buffer.writeln('Dirección: ${seller['address'] ?? 'N/A'}');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('DATOS DEL COMPRADOR');
    buffer.writeln('═══════════════════════════════════════');
    final buyer = receipt['buyer'] ?? {};
    buffer.writeln('Nombre: ${buyer['name'] ?? 'N/A'}');
    buffer.writeln('Dirección: ${buyer['address'] ?? 'N/A'}');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('DETALLE DEL PRODUCTO');
    buffer.writeln('═══════════════════════════════════════');
    final product = receipt['product'] ?? {};
    buffer.writeln('Producto: ${product['title'] ?? 'N/A'}');
    buffer.writeln('Cantidad: ${product['quantity'] ?? 'N/A'}');
    buffer.writeln('Precio unitario: ${product['unit_price'] ?? 'N/A'} ${product['currency'] ?? ''}');
    buffer.writeln('Total: ${product['total_price'] ?? 'N/A'} ${product['currency'] ?? ''}');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('NOTA IMPORTANTE');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('El pago se realiza fuera de la aplicación');
    buffer.writeln('cuando ambas partes se encuentran físicamente.');
    buffer.writeln('═══════════════════════════════════════');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobante de Venta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'Descargar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReceipt,
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: _receiptData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _ReceiptContent(receiptData: _receiptData!),
            ),
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const _ReceiptContent({required this.receiptData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seller = receiptData['seller'] ?? {};
    final buyer = receiptData['buyer'] ?? {};
    final product = receiptData['product'] ?? {};
    final delivery = receiptData['delivery'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Text(
                'COMPROBANTE DE VENTA',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'CORRALX',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        // Número de comprobante
        _ReceiptSection(
          title: 'Número de Comprobante',
          content: receiptData['receipt_number'] ?? 'N/A',
        ),
        const SizedBox(height: 16),
        // Datos del vendedor
        _ReceiptSection(
          title: 'Vendedor',
          children: [
            Text('${seller['name'] ?? 'N/A'}'),
            if (seller['ranch_name'] != null)
              Text('Finca: ${seller['ranch_name']}'),
            if (seller['address'] != null)
              Text('Dirección: ${seller['address']}'),
            if (seller['phone'] != null) Text('Teléfono: ${seller['phone']}'),
          ],
        ),
        const SizedBox(height: 16),
        // Datos del comprador
        _ReceiptSection(
          title: 'Comprador',
          children: [
            Text('${buyer['name'] ?? 'N/A'}'),
            if (buyer['address'] != null) Text('Dirección: ${buyer['address']}'),
            if (buyer['phone'] != null) Text('Teléfono: ${buyer['phone']}'),
          ],
        ),
        const SizedBox(height: 16),
        // Detalle del producto
        _ReceiptSection(
          title: 'Producto',
          children: [
            Text('${product['title'] ?? 'N/A'}'),
            if (product['breed'] != null) Text('Raza: ${product['breed']}'),
            Text('Cantidad: ${product['quantity'] ?? 'N/A'}'),
            Text('Precio unitario: ${product['unit_price'] ?? 'N/A'} ${product['currency'] ?? ''}'),
            Text(
              'Total: ${product['total_price'] ?? 'N/A'} ${product['currency'] ?? ''}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Información de entrega
        if (delivery.isNotEmpty)
          _ReceiptSection(
            title: 'Entrega',
            children: [
              Text('Método: ${delivery['method_name'] ?? delivery['method'] ?? 'N/A'}'),
              if (delivery['pickup_address'] != null)
                Text('Dirección de recogida: ${delivery['pickup_address']}'),
              if (delivery['delivery_address'] != null)
                Text('Dirección de entrega: ${delivery['delivery_address']}'),
              if (delivery['expected_date'] != null)
                Text('Fecha esperada: ${delivery['expected_date']}'),
            ],
          ),
        const SizedBox(height: 24),
        // Nota importante
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nota Importante',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'El pago se realiza fuera de la aplicación cuando comprador y vendedor se encuentran físicamente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  final String title;
  final String? content;
  final List<Widget>? children;

  const _ReceiptSection({
    required this.title,
    this.content,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (content != null)
          Text(
            content!,
            style: theme.textTheme.bodyMedium,
          ),
        if (children != null) ...children!,
      ],
    );
  }
}

