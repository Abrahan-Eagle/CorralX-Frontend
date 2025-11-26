import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/products/models/product.dart';
import 'package:intl/intl.dart';

/// Diálogo para confirmar compra desde el chat
class ConfirmPurchaseDialog extends StatefulWidget {
  final int productId;
  final int conversationId;
  final Product? product; // Producto opcional si ya está cargado

  const ConfirmPurchaseDialog({
    super.key,
    required this.productId,
    required this.conversationId,
    this.product,
  });

  @override
  State<ConfirmPurchaseDialog> createState() => _ConfirmPurchaseDialogState();
}

class _ConfirmPurchaseDialogState extends State<ConfirmPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryProviderController = TextEditingController();
  final _deliveryTrackingController = TextEditingController();
  final _deliveryCostController = TextEditingController();
  final _notesController = TextEditingController();

  Product? _product;
  String _deliveryMethod = 'buyer_transport';
  String? _pickupLocation;
  DateTime? _expectedPickupDate;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (widget.product != null) {
      setState(() {
        _product = widget.product;
        _unitPriceController.text = _product!.price.toStringAsFixed(2);
      });
      return;
    }

    // Cargar producto desde ProductProvider
    try {
      // TODO: Cargar producto si no viene
      // Por ahora usamos el que viene en widget.product
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar producto: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _deliveryAddressController.dispose();
    _pickupAddressController.dispose();
    _deliveryProviderController.dispose();
    _deliveryTrackingController.dispose();
    _deliveryCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Producto no cargado')),
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? _product!.price;

    final success = await orderProvider.createOrder(
      productId: widget.productId,
      quantity: quantity,
      unitPrice: unitPrice,
      deliveryMethod: _deliveryMethod,
      conversationId: widget.conversationId,
      pickupLocation: _pickupLocation,
      pickupAddress: _pickupAddressController.text.isEmpty
          ? null
          : _pickupAddressController.text,
      deliveryAddress: _deliveryAddressController.text.isEmpty
          ? null
          : _deliveryAddressController.text,
      pickupNotes: _notesController.text.isEmpty ? null : _notesController.text,
      deliveryCost: _deliveryCostController.text.isEmpty
          ? null
          : double.tryParse(_deliveryCostController.text),
      deliveryCostCurrency: _product!.currency,
      deliveryProvider: _deliveryProviderController.text.isEmpty
          ? null
          : _deliveryProviderController.text,
      deliveryTrackingNumber: _deliveryTrackingController.text.isEmpty
          ? null
          : _deliveryTrackingController.text,
      expectedPickupDate: _expectedPickupDate,
      buyerNotes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (success && mounted) {
      Navigator.pop(context); // Cerrar diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Error al crear pedido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Confirmar Compra',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Producto
                      if (_product != null) ...[
                        Text(
                          _product!.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Cantidad
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa la cantidad';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Cantidad debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Precio unitario
                      TextFormField(
                        controller: _unitPriceController,
                        decoration: InputDecoration(
                          labelText: 'Precio Unitario *',
                          border: const OutlineInputBorder(),
                          suffixText: _product?.currency ?? 'USD',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el precio unitario';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Precio debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Método de delivery
                      Text(
                        'Método de Entrega *',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        title: const Text('Transporte del comprador'),
                        value: 'buyer_transport',
                        groupValue: _deliveryMethod,
                        onChanged: (value) {
                          setState(() {
                            _deliveryMethod = value!;
                            _pickupLocation = null;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Transporte del vendedor'),
                        value: 'seller_transport',
                        groupValue: _deliveryMethod,
                        onChanged: (value) {
                          setState(() {
                            _deliveryMethod = value!;
                            _pickupLocation = null;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Delivery externo'),
                        value: 'external_delivery',
                        groupValue: _deliveryMethod,
                        onChanged: (value) {
                          setState(() {
                            _deliveryMethod = value!;
                            _pickupLocation = null;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Delivery CorralX'),
                        value: 'corralx_delivery',
                        groupValue: _deliveryMethod,
                        onChanged: (value) {
                          setState(() {
                            _deliveryMethod = value!;
                            _pickupLocation = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campos dinámicos según método de delivery
                      ..._buildDeliveryFields(theme),
                      const SizedBox(height: 16),
                      // Fecha esperada
                      ListTile(
                        title: const Text('Fecha esperada (opcional)'),
                        subtitle: Text(
                          _expectedPickupDate != null
                              ? DateFormat('dd/MM/yyyy').format(_expectedPickupDate!)
                              : 'No seleccionada',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && mounted) {
                            setState(() {
                              _expectedPickupDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Notas
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas adicionales (opcional)',
                          border: OutlineInputBorder(),
                          hintText: 'Información adicional sobre la compra...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Footer con botones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    Consumer<OrderProvider>(
                      builder: (context, orderProvider, child) {
                        return ElevatedButton(
                          onPressed: orderProvider.isCreating ? null : _handleConfirm,
                          child: orderProvider.isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Confirmar Compra'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDeliveryFields(ThemeData theme) {
    switch (_deliveryMethod) {
      case 'buyer_transport':
        return [
          // Pickup location
          Text(
            'Lugar de Recogida *',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          RadioListTile<String>(
            title: const Text('En la finca'),
            value: 'ranch',
            groupValue: _pickupLocation,
            onChanged: (value) => setState(() => _pickupLocation = value),
          ),
          RadioListTile<String>(
            title: const Text('Otro lugar'),
            value: 'other',
            groupValue: _pickupLocation,
            onChanged: (value) => setState(() => _pickupLocation = value),
          ),
          if (_pickupLocation == 'other') ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _pickupAddressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de recogida *',
                border: OutlineInputBorder(),
                hintText: 'Dirección completa donde se recogerá',
              ),
              maxLines: 2,
              validator: _pickupLocation == 'other'
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa la dirección de recogida';
                      }
                      return null;
                    }
                  : null,
            ),
          ],
        ];

      case 'seller_transport':
        return [
          TextFormField(
            controller: _deliveryAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección de entrega *',
              border: OutlineInputBorder(),
              hintText: 'Dirección donde el vendedor entregará',
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa la dirección de entrega';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryCostController,
            decoration: InputDecoration(
              labelText: 'Costo de entrega (opcional)',
              border: const OutlineInputBorder(),
              suffixText: _product?.currency ?? 'USD',
            ),
            keyboardType: TextInputType.number,
          ),
        ];

      case 'external_delivery':
        return [
          TextFormField(
            controller: _deliveryAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección de entrega *',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa la dirección de entrega';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryProviderController,
            decoration: const InputDecoration(
              labelText: 'Proveedor de delivery *',
              border: OutlineInputBorder(),
              hintText: 'Ej: MRW, Domesa, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa el proveedor de delivery';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryTrackingController,
            decoration: const InputDecoration(
              labelText: 'Número de tracking (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryCostController,
            decoration: InputDecoration(
              labelText: 'Costo de delivery (opcional)',
              border: const OutlineInputBorder(),
              suffixText: _product?.currency ?? 'USD',
            ),
            keyboardType: TextInputType.number,
          ),
        ];

      case 'corralx_delivery':
        return [
          TextFormField(
            controller: _deliveryAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección de entrega *',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa la dirección de entrega';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryTrackingController,
            decoration: const InputDecoration(
              labelText: 'Número de tracking CorralX (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryCostController,
            decoration: InputDecoration(
              labelText: 'Costo de delivery (opcional)',
              border: const OutlineInputBorder(),
              suffixText: _product?.currency ?? 'USD',
            ),
            keyboardType: TextInputType.number,
          ),
        ];

      default:
        return [];
    }
  }

}

