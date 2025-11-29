import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/orders/models/order.dart';
import 'package:intl/intl.dart';

/// Diálogo para editar un pedido pendiente (vendedor)
class EditOrderDialog extends StatefulWidget {
  final Order order;

  const EditOrderDialog({
    super.key,
    required this.order,
  });

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _deliveryAddressController;
  late final TextEditingController _pickupAddressController;
  late final TextEditingController _deliveryProviderController;
  late final TextEditingController _deliveryTrackingController;
  late final TextEditingController _deliveryCostController;
  late final TextEditingController _sellerNotesController;
  late final TextEditingController _pickupNotesController;

  late String _deliveryMethod;
  late String? _pickupLocation;
  DateTime? _expectedPickupDate;

  /// Construir la dirección completa de la finca
  String? _getRanchFullAddress() {
    // Intentar obtener la dirección desde order.ranch primero (tiene address completo)
    // Si no está disponible, intentar desde product.ranch (puede no tener address)
    final ranch = widget.order.ranch;
    if (ranch == null || ranch.address == null) return null;

    final address = ranch.address!;
    final parts = <String>[];

    // Dirección base
    if (address.addresses.isNotEmpty) {
      parts.add(address.addresses);
    }

    // Ciudad, Estado
    if (address.fullLocation.isNotEmpty &&
        address.fullLocation != 'Ubicación no disponible') {
      parts.add(address.fullLocation);
    }

    // Coordenadas (opcional, solo si están disponibles)
    if (address.latitude != null && address.longitude != null) {
      parts.add(
          '📍 ${address.latitude!.toStringAsFixed(6)}, ${address.longitude!.toStringAsFixed(6)}');
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  @override
  void initState() {
    super.initState();
    // Inicializar valores desde el pedido existente
    _quantityController =
        TextEditingController(text: widget.order.quantity.toString());
    _unitPriceController =
        TextEditingController(text: widget.order.unitPrice.toStringAsFixed(2));
    _deliveryAddressController =
        TextEditingController(text: widget.order.deliveryAddress ?? '');
    _pickupAddressController =
        TextEditingController(text: widget.order.pickupAddress ?? '');
    _deliveryProviderController =
        TextEditingController(text: widget.order.deliveryProvider ?? '');
    _deliveryTrackingController =
        TextEditingController(text: widget.order.deliveryTrackingNumber ?? '');
    _deliveryCostController = TextEditingController(
      text: widget.order.deliveryCost != null
          ? widget.order.deliveryCost!.toStringAsFixed(2)
          : '',
    );
    _sellerNotesController =
        TextEditingController(text: widget.order.sellerNotes ?? '');
    _pickupNotesController =
        TextEditingController(text: widget.order.pickupNotes ?? '');

    // Si el método de entrega es 'corralx_delivery' (ya no disponible), usar 'buyer_transport' por defecto
    _deliveryMethod = widget.order.deliveryMethod == 'corralx_delivery'
        ? 'buyer_transport'
        : widget.order.deliveryMethod;
    _pickupLocation = widget.order.pickupLocation;
    _expectedPickupDate = widget.order.expectedPickupDate;

    // Si pickup_location es 'ranch' y no hay pickup_address, prellenar con dirección de la finca
    if (_pickupLocation == 'ranch' &&
        (_pickupAddressController.text.isEmpty ||
            _pickupAddressController.text == widget.order.pickupAddress)) {
      final ranchAddress = _getRanchFullAddress();
      if (ranchAddress != null && _pickupAddressController.text.isEmpty) {
        _pickupAddressController.text = ranchAddress;
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
    _sellerNotesController.dispose();
    _pickupNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final orderProvider = context.read<OrderProvider>();
    final quantity =
        int.tryParse(_quantityController.text) ?? widget.order.quantity;
    final unitPrice =
        double.tryParse(_unitPriceController.text) ?? widget.order.unitPrice;

    // Solo enviar campos que han cambiado
    final success = await orderProvider.updateOrder(
      orderId: widget.order.id,
      quantity: quantity != widget.order.quantity ? quantity : null,
      unitPrice: unitPrice != widget.order.unitPrice ? unitPrice : null,
      deliveryMethod: _deliveryMethod != widget.order.deliveryMethod
          ? _deliveryMethod
          : null,
      pickupLocation: _pickupLocation != widget.order.pickupLocation
          ? _pickupLocation
          : null,
      pickupAddress:
          _pickupAddressController.text != (widget.order.pickupAddress ?? '')
              ? (_pickupAddressController.text.isEmpty
                  ? null
                  : _pickupAddressController.text)
              : null,
      deliveryAddress: _deliveryAddressController.text !=
              (widget.order.deliveryAddress ?? '')
          ? (_deliveryAddressController.text.isEmpty
              ? null
              : _deliveryAddressController.text)
          : null,
      pickupNotes:
          _pickupNotesController.text != (widget.order.pickupNotes ?? '')
              ? (_pickupNotesController.text.isEmpty
                  ? null
                  : _pickupNotesController.text)
              : null,
      deliveryCost: _deliveryCostController.text.isNotEmpty
          ? (double.tryParse(_deliveryCostController.text) ??
              widget.order.deliveryCost)
          : null,
      deliveryCostCurrency: widget.order.currency,
      deliveryProvider: _deliveryProviderController.text !=
              (widget.order.deliveryProvider ?? '')
          ? (_deliveryProviderController.text.isEmpty
              ? null
              : _deliveryProviderController.text)
          : null,
      deliveryTrackingNumber: _deliveryTrackingController.text !=
              (widget.order.deliveryTrackingNumber ?? '')
          ? (_deliveryTrackingController.text.isEmpty
              ? null
              : _deliveryTrackingController.text)
          : null,
      expectedPickupDate: _expectedPickupDate != widget.order.expectedPickupDate
          ? _expectedPickupDate
          : null,
      sellerNotes:
          _sellerNotesController.text != (widget.order.sellerNotes ?? '')
              ? (_sellerNotesController.text.isEmpty
                  ? null
                  : _sellerNotesController.text)
              : null,
    );

    if (success && mounted) {
      Navigator.pop(
          context, true); // Retornar true para indicar que se actualizó
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(orderProvider.errorMessage ?? 'Error al actualizar pedido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;

    final dialogWidth = isTablet ? 600.0 : screenWidth * 0.95;
    final dialogHeight = screenHeight * 0.9;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal:
            isTablet ? (screenWidth - dialogWidth) / 2 : screenWidth * 0.025,
        vertical: screenHeight * 0.05,
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Editar Pedido',
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
                      // Información del producto (solo lectura)
                      if (widget.order.product != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Producto',
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.order.product!.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                          suffixText: widget.order.currency,
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
                      DropdownButtonFormField<String>(
                        value: _deliveryMethod,
                        decoration: const InputDecoration(
                          labelText: 'Método de Entrega *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'buyer_transport',
                            child: Text('Transporte del comprador'),
                          ),
                          DropdownMenuItem(
                            value: 'seller_transport',
                            child: Text('Transporte del vendedor'),
                          ),
                          DropdownMenuItem(
                            value: 'external_delivery',
                            child: Text('Delivery externo'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _deliveryMethod = value;
                              _pickupLocation = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona un método de entrega';
                          }
                          return null;
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
                              ? DateFormat('dd/MM/yyyy')
                                  .format(_expectedPickupDate!)
                              : 'No seleccionada',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _expectedPickupDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && mounted) {
                            setState(() {
                              _expectedPickupDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Notas del vendedor
                      TextFormField(
                        controller: _sellerNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas del vendedor (opcional)',
                          border: OutlineInputBorder(),
                          hintText:
                              'Comentarios o sugerencias sobre el pedido...',
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
                    top: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2)),
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
                          onPressed:
                              orderProvider.isUpdating ? null : _handleSave,
                          child: orderProvider.isUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Guardar Cambios'),
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
          DropdownButtonFormField<String>(
            value: _pickupLocation,
            decoration: const InputDecoration(
              labelText: 'Lugar de Recogida *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'ranch',
                child: Text('En la finca'),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text('Otro lugar'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _pickupLocation = value;
                // Prellenar dirección de la finca cuando se selecciona "En la finca"
                if (value == 'ranch') {
                  final ranchAddress = _getRanchFullAddress();
                  if (ranchAddress != null) {
                    _pickupAddressController.text = ranchAddress;
                  }
                } else if (value == 'other' &&
                    widget.order.pickupLocation == 'ranch') {
                  // Si cambia de "ranch" a "other", limpiar solo si venía de ranch
                  _pickupAddressController.clear();
                }
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecciona un lugar de recogida';
              }
              return null;
            },
          ),
          // Mostrar dirección de la finca cuando se selecciona "En la finca"
          if (_pickupLocation == 'ranch') ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final ranchAddress = _getRanchFullAddress();
                if (ranchAddress == null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La dirección de la finca no está disponible',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dirección de la finca',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ranchAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          if (_pickupLocation == 'other') ...[
            const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _pickupNotesController,
            decoration: const InputDecoration(
              labelText: 'Notas de recogida (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
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
              suffixText: widget.order.currency,
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
              suffixText: widget.order.currency,
            ),
            keyboardType: TextInputType.number,
          ),
        ];

      default:
        return [];
    }
  }
}
