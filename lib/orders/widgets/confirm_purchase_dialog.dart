import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/products/models/product.dart';
import 'package:corralx/products/providers/product_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  /// Construir la dirección completa de la finca
  String? _getRanchFullAddress() {
    final ranch = _product?.ranch;
    if (ranch == null) {
      debugPrint('⚠️ _getRanchFullAddress: ranch es null');
      return null;
    }

    // El Ranch simplificado ahora puede tener addressData si el backend lo carga
    final addressData = ranch.addressData;
    debugPrint(
        '🔍 _getRanchFullAddress: addressData = ${addressData?.toString()}');
    if (addressData == null) {
      debugPrint('⚠️ _getRanchFullAddress: addressData es null');
      return null;
    }

    final parts = <String>[];

    // Dirección base (puede venir como 'adressses' o 'addresses')
    final addresses = addressData['adressses'] ?? addressData['addresses'];
    if (addresses != null && addresses.toString().isNotEmpty) {
      parts.add(addresses.toString());
    }

    // Ciudad, Estado (puede venir directamente o desde relaciones anidadas)
    String? cityName;
    String? stateName;

    // Intentar obtener desde address directamente
    if (addressData['city_name'] != null) {
      cityName = addressData['city_name'].toString();
    } else if (addressData['city'] != null && addressData['city'] is Map) {
      cityName = addressData['city']['name']?.toString();
    }

    if (addressData['state_name'] != null) {
      stateName = addressData['state_name'].toString();
    } else if (addressData['city'] != null &&
        addressData['city'] is Map &&
        addressData['city']['state'] != null &&
        addressData['city']['state'] is Map) {
      stateName = addressData['city']['state']['name']?.toString();
    }

    if (cityName != null || stateName != null) {
      final locationParts = <String>[];
      if (cityName != null && cityName.isNotEmpty) locationParts.add(cityName);
      if (stateName != null && stateName.isNotEmpty)
        locationParts.add(stateName);
      if (locationParts.isNotEmpty) parts.add(locationParts.join(', '));
    }

    // Nota: Las coordenadas ya no se incluyen en el texto, se mostrarán en un mapa

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Obtener las coordenadas del ranch (si están disponibles)
  LatLng? _getRanchCoordinates() {
    final ranch = _product?.ranch;
    if (ranch == null) return null;

    final addressData = ranch.addressData;
    if (addressData == null) return null;

    final latitude = addressData['latitude'];
    final longitude = addressData['longitude'];
    if (latitude == null || longitude == null) return null;

    final lat = latitude is double
        ? latitude
        : (latitude is int
            ? latitude.toDouble()
            : double.tryParse(latitude.toString()));
    final lng = longitude is double
        ? longitude
        : (longitude is int
            ? longitude.toDouble()
            : double.tryParse(longitude.toString()));

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    // Cargar el producto después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  Future<void> _loadProduct() async {
    // Siempre cargar el producto completo desde el backend para asegurar
    // que tenemos la relación address del ranch (necesaria para mostrar
    // la dirección de la finca en el diálogo)
    try {
      final productProvider = context.read<ProductProvider>();
      await productProvider.fetchProductDetail(widget.productId);

      if (mounted) {
        final loadedProduct = productProvider.selectedProduct;
        if (loadedProduct != null) {
          setState(() {
            _product = loadedProduct;
            _unitPriceController.text = _product!.price.toStringAsFixed(2);
            // Si ya está seleccionado "En la finca", prellenar la dirección
            if (_pickupLocation == 'ranch') {
              final ranchAddress = _getRanchFullAddress();
              if (ranchAddress != null) {
                _pickupAddressController.text = ranchAddress;
              }
            }
          });
        } else {
          // Si no se pudo cargar, mostrar error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo cargar la información del producto'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar producto: $e'),
            backgroundColor: Colors.red,
          ),
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
    final unitPrice =
        double.tryParse(_unitPriceController.text) ?? _product!.price;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;

    // Calcular ancho y alto responsive
    double dialogWidth;
    if (isTablet) {
      final calculatedWidth = screenWidth * 0.7;
      dialogWidth = calculatedWidth < 600 ? calculatedWidth : 600.0;
    } else {
      dialogWidth = screenWidth * 0.95;
    }
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
                    Icon(Icons.shopping_cart,
                        color: theme.colorScheme.onPrimaryContainer),
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
                            initialDate: DateTime.now(),
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
                              orderProvider.isCreating ? null : _handleConfirm,
                          child: orderProvider.isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
                } else {
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
                      // Mostrar mapa si hay coordenadas disponibles
                      Builder(
                        builder: (context) {
                          final coordinates = _getRanchCoordinates();
                          if (coordinates != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Text(
                                  'Ubicación en el mapa:',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: coordinates,
                                      initialZoom: 15.0,
                                      minZoom: 5.0,
                                      maxZoom: 18.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.corralx.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: coordinates,
                                            width: 40,
                                            height: 40,
                                            child: Icon(
                                              Icons.location_on,
                                              color: theme.colorScheme.primary,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
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

      default:
        return [];
    }
  }
}
