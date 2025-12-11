import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/products/models/product.dart';
import 'package:corralx/products/providers/product_provider.dart';
import 'package:corralx/profiles/providers/profile_provider.dart';
import 'package:corralx/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final _notesController = TextEditingController();

  Product? _product;
  String? _deliveryMethod;
  String? _pickupLocation;
  String? _deliveryLocation; // 'ranch' o 'other' para transporte del vendedor
  DateTime? _expectedPickupDate;
  LatLng? _selectedDeliveryCoordinates; // Coordenadas GPS cuando es "Otro lugar"
  LatLng? _selectedPickupCoordinates; // Coordenadas GPS para pickup cuando es "Otro lugar"

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

  /// Obtener la dirección completa de la finca del comprador
  String? _getBuyerRanchFullAddress() {
    final profileProvider = context.read<ProfileProvider>();
    final buyerProfile = profileProvider.myProfile;
    
    if (buyerProfile == null || buyerProfile.ranches == null || buyerProfile.ranches!.isEmpty) {
      debugPrint('⚠️ _getBuyerRanchFullAddress: comprador no tiene finca');
      return null;
    }

    // Obtener la finca principal del comprador
    final buyerRanch = buyerProfile.ranches!.firstWhere(
      (r) => r.isPrimary,
      orElse: () => buyerProfile.ranches!.first,
    );

    if (buyerRanch.address == null) {
      debugPrint('⚠️ _getBuyerRanchFullAddress: finca del comprador no tiene dirección');
      return null;
    }

    final address = buyerRanch.address!;
    final parts = <String>[];

    if (address.addresses.isNotEmpty) {
      parts.add(address.addresses);
    }
    
    if (address.fullLocation.isNotEmpty && address.fullLocation != 'Ubicación no disponible') {
      parts.add(address.fullLocation);
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Obtener las coordenadas de la finca del comprador
  LatLng? _getBuyerRanchCoordinates() {
    final profileProvider = context.read<ProfileProvider>();
    final buyerProfile = profileProvider.myProfile;
    
    if (buyerProfile == null || buyerProfile.ranches == null || buyerProfile.ranches!.isEmpty) {
      return null;
    }

    final buyerRanch = buyerProfile.ranches!.firstWhere(
      (r) => r.isPrimary,
      orElse: () => buyerProfile.ranches!.first,
    );

    if (buyerRanch.address == null) return null;
    final address = buyerRanch.address!;

    if (address.latitude != null && address.longitude != null) {
      return LatLng(address.latitude!, address.longitude!);
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    // Cargar el producto y el perfil del comprador después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadProduct();
      _loadBuyerProfile();
    });
  }

  /// Cargar el perfil del comprador con sus ranches y direcciones
  Future<void> _loadBuyerProfile() async {
    try {
      final profileProvider = context.read<ProfileProvider>();
      // Cargar perfil con ranches si no está cargado
      if (profileProvider.myProfile == null) {
        await profileProvider.fetchMyProfile();
      }
      // Cargar ranches con direcciones si no están cargados
      if (profileProvider.myRanches.isEmpty) {
        await profileProvider.fetchMyRanches();
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar perfil del comprador: $e');
    }
  }

  /// Geocodificación inversa: convertir coordenadas GPS a dirección escrita
  Future<String?> _reverseGeocode(LatLng coordinates) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=18&addressdetails=1',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CorralX App (${AppConfig.contactEmail})',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        if (address != null) {
          final parts = <String>[];
          
          // Construir dirección legible
          if (address['road'] != null) {
            parts.add(address['road']);
          }
          if (address['house_number'] != null) {
            parts.insert(0, address['house_number']);
          }
          if (address['suburb'] != null || address['neighbourhood'] != null) {
            parts.add(address['suburb'] ?? address['neighbourhood']);
          }
          if (address['city'] != null || address['town'] != null || address['village'] != null) {
            parts.add(address['city'] ?? address['town'] ?? address['village']);
          }
          if (address['state'] != null) {
            parts.add(address['state']);
          }
          if (address['country'] != null) {
            parts.add(address['country']);
          }
          
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
          
          // Fallback: usar display_name si está disponible
          if (data['display_name'] != null) {
            return data['display_name'];
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error en geocodificación inversa: $e');
    }
    
    // Si falla, retornar coordenadas como fallback
    return '${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}';
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
            // Si ya está seleccionado "En mi finca" para entrega, prellenar la dirección
            if (_deliveryLocation == 'ranch') {
              final buyerRanchAddress = _getBuyerRanchFullAddress();
              if (buyerRanchAddress != null) {
                _deliveryAddressController.text = buyerRanchAddress;
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
    
    if (_deliveryMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un método de entrega')),
      );
      return;
    }

    // Validar pickup_location (requerido por el backend siempre)
    if (_deliveryMethod == 'buyer_transport' && _pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un lugar de recogida')),
      );
      return;
    }

    // Validar que deliveryAddress no esté vacío cuando el método es seller_transport
    if (_deliveryMethod == 'seller_transport') {
      if (_deliveryLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un lugar de entrega')),
        );
        return;
      }
      if (_deliveryAddressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La dirección de entrega es requerida para este método de delivery'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Validar que la fecha esperada sea obligatoria
    if (_expectedPickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha esperada de recogida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final unitPrice =
        double.tryParse(_unitPriceController.text) ?? _product!.price;

    // El backend requiere pickup_location siempre, usar 'ranch' por defecto si no se especifica
    final pickupLocation = _pickupLocation ?? 'ranch';

    final success = await orderProvider.createOrder(
      productId: widget.productId,
      quantity: quantity,
      unitPrice: unitPrice,
      deliveryMethod: _deliveryMethod!,
      conversationId: widget.conversationId,
      pickupLocation: pickupLocation,
      pickupAddress: _pickupAddressController.text.isEmpty
          ? null
          : _pickupAddressController.text,
      pickupLatitude: _selectedPickupCoordinates?.latitude,
      pickupLongitude: _selectedPickupCoordinates?.longitude,
      deliveryAddress: _deliveryAddressController.text.isEmpty
          ? null
          : _deliveryAddressController.text,
      deliveryLatitude: _selectedDeliveryCoordinates?.latitude,
      deliveryLongitude: _selectedDeliveryCoordinates?.longitude,
      pickupNotes: _notesController.text.isEmpty ? null : _notesController.text,
      // El costo de entrega será establecido por el vendedor al aceptar el pedido
      deliveryCost: null,
      deliveryCostCurrency: null,
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
    final viewPadding = MediaQuery.of(context).viewPadding;
    
    // Calcular ancho y alto responsive
    double dialogWidth;
    if (isTablet) {
      final calculatedWidth = screenWidth * 0.65;
      dialogWidth = calculatedWidth < 550 ? calculatedWidth : 550.0;
    } else {
      dialogWidth = screenWidth * 0.92;
    }
    
    // Altura máxima más conservadora para mejor posicionamiento
    final maxDialogHeight = screenHeight * 0.85;
    final minDialogHeight = 400.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? (screenWidth - dialogWidth) / 2 : screenWidth * 0.04,
        vertical: viewPadding.top + 20, // Mejor posicionamiento desde arriba
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
          minHeight: minDialogHeight,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header mejorado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shopping_cart_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Confirmar Compra',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 24,
                    ),
                  ],
                ),
              ),
              // Content mejorado
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Producto con mejor presentación
                      if (_product != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                          _product!.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Cantidad
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Cantidad *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                      const SizedBox(height: 18),
                      // Precio unitario
                      TextFormField(
                        controller: _unitPriceController,
                        decoration: InputDecoration(
                          labelText: 'Precio Unitario *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          suffixText: _product?.currency ?? 'USD',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                        decoration: InputDecoration(
                          labelText: 'Método de Entrega *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                        ),
                      ),
                          hintText: 'Seleccionar...',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        dropdownColor: theme.colorScheme.surface,
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Seleccionar...'),
                          ),
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
                          setState(() {
                            _deliveryMethod = value;
                            // Limpiar campos relacionados cuando se cambia o resetea el método
                            _pickupLocation = null;
                            _deliveryLocation = null;
                            _pickupAddressController.clear();
                            _deliveryAddressController.clear();
                            _deliveryProviderController.clear();
                            _deliveryTrackingController.clear();
                            _selectedDeliveryCoordinates = null;
                            _selectedPickupCoordinates = null;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona un método de entrega';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campos dinámicos según método de delivery
                      ..._buildDeliveryFields(theme),
                      const SizedBox(height: 16),
                      // Fecha esperada mejorada
                      InkWell(
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _expectedPickupDate != null
                                  ? theme.colorScheme.outline.withOpacity(0.2)
                                  : theme.colorScheme.error.withOpacity(0.5),
                              width: _expectedPickupDate != null ? 1 : 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha esperada *',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _expectedPickupDate != null
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _expectedPickupDate != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_expectedPickupDate!)
                                          : 'Selecciona una fecha *',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: _expectedPickupDate != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: _expectedPickupDate != null
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Notas mejoradas
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notas adicionales (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          hintText: 'Información adicional sobre la compra...',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Footer con botones mejorado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Expanded(
                        child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Consumer<OrderProvider>(
                      builder: (context, orderProvider, child) {
                        return ElevatedButton(
                              onPressed:
                                  orderProvider.isCreating ? null : _handleConfirm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                          child: orderProvider.isCreating
                                  ? SizedBox(
                                  width: 20,
                                  height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                )
                                  : const Text(
                                      'Comprar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                        );
                      },
                        ),
                    ),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDeliveryFields(ThemeData theme) {
    if (_deliveryMethod == null) {
      return [];
    }
    
    switch (_deliveryMethod) {
      case 'buyer_transport':
        return [
          // Pickup location
          DropdownButtonFormField<String>(
            value: _pickupLocation,
            decoration: InputDecoration(
              labelText: 'Lugar de Recogida *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              hintText: 'Seleccionar...',
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: theme.colorScheme.surface,
            items: const [
              DropdownMenuItem(
                value: null,
                child: Text('Seleccionar...'),
              ),
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
                  } else {
                    _pickupAddressController.clear();
                  }
                  _selectedPickupCoordinates = null;
                } else {
                  // Limpiar dirección cuando se selecciona "Otro lugar" o "Seleccionar..."
                  _pickupAddressController.clear();
                  _selectedPickupCoordinates = null;
                }
              });
            },
            validator: (value) {
              if (value == null) {
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
              decoration: InputDecoration(
                labelText: 'Dirección de recogida *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                hintText: 'Dirección completa donde se recogerá',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () async {
                    // Solicitar permisos de ubicación
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, activa el servicio de ubicación'),
                          ),
                        );
                      }
                      return;
                    }

                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Se necesitan permisos de ubicación para usar GPS'),
                            ),
                          );
                        }
                        return;
                      }
                    }

                    if (permission == LocationPermission.deniedForever) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Los permisos de ubicación están permanentemente denegados'),
                          ),
                        );
                      }
                      return;
                    }

                    // Obtener ubicación actual
                    try {
                      Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );

                      final coordinates = LatLng(
                        position.latitude,
                        position.longitude,
                      );

                      // Mostrar indicador de carga
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Obteniendo dirección...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      // Realizar geocodificación inversa
                      final address = await _reverseGeocode(coordinates);

                      if (mounted) {
                        setState(() {
                          _selectedPickupCoordinates = coordinates;
                          // Actualizar el campo de dirección con la dirección escrita
                          _pickupAddressController.text = address ?? 
                              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ubicación obtenida: ${address ?? "Coordenadas: ${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}"}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al obtener ubicación: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
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
            // Mostrar mapa si hay coordenadas GPS seleccionadas
            if (_selectedPickupCoordinates != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toca el mapa para mover el marcador a la ubicación deseada',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedPickupCoordinates!,
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                    onTap: (tapPosition, point) async {
                      // Actualizar coordenadas cuando el usuario toca el mapa
                      setState(() {
                        _selectedPickupCoordinates = point;
                      });

                      // Mostrar indicador de carga
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Obteniendo dirección...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }

                      // Realizar geocodificación inversa
                      final address = await _reverseGeocode(point);
                      if (mounted) {
                        setState(() {
                          _pickupAddressController.text = address ?? 
                              '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
                        });
                      }
                    },
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
                          point: _selectedPickupCoordinates!,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              // El marcador también puede ser tocado para centrar
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: theme.colorScheme.primary,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ];

      case 'seller_transport':
        return [
          // Lugar de entrega (dropdown)
          DropdownButtonFormField<String>(
            value: _deliveryLocation,
            decoration: InputDecoration(
              labelText: 'Lugar de Entrega *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              hintText: 'Seleccionar...',
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: theme.colorScheme.surface,
            items: const [
              DropdownMenuItem(
                value: null,
                child: Text('Seleccionar...'),
              ),
              DropdownMenuItem(
                value: 'ranch',
                child: Text('En mi finca'),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text('Otro lugar'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _deliveryLocation = value;
                // Prellenar dirección de la finca cuando se selecciona "En mi finca"
                if (value == 'ranch') {
                  final buyerRanchAddress = _getBuyerRanchFullAddress();
                  if (buyerRanchAddress != null) {
                    _deliveryAddressController.text = buyerRanchAddress;
                  } else {
                    _deliveryAddressController.clear();
                  }
                  _selectedDeliveryCoordinates = null;
                } else {
                  // Limpiar dirección cuando se selecciona "Otro lugar" o "Seleccionar..."
                  _deliveryAddressController.clear();
                  _selectedDeliveryCoordinates = null;
                }
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Selecciona un lugar de entrega';
              }
              return null;
            },
          ),
          // Mostrar dirección de la finca del comprador cuando se selecciona "En mi finca"
          if (_deliveryLocation == 'ranch') ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final buyerRanchAddress = _getBuyerRanchFullAddress();
                if (buyerRanchAddress == null) {
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
                            'La dirección de tu finca no está disponible',
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
                            'Dirección de tu finca',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        buyerRanchAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      // Mostrar mapa si hay coordenadas disponibles
                      Builder(
                        builder: (context) {
                          final coordinates = _getBuyerRanchCoordinates();
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
          // Campo de dirección manual y GPS cuando se selecciona "Otro lugar"
          if (_deliveryLocation == 'other') ...[
            const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryAddressController,
              decoration: InputDecoration(
              labelText: 'Dirección de entrega *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                hintText: 'Dirección completa donde el vendedor entregará',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () async {
                    // Solicitar permisos de ubicación
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, activa el servicio de ubicación'),
                          ),
                        );
                      }
                      return;
                    }

                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Se necesitan permisos de ubicación para usar GPS'),
                            ),
                          );
                        }
                        return;
                      }
                    }

                    if (permission == LocationPermission.deniedForever) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Los permisos de ubicación están permanentemente denegados'),
                          ),
                        );
                      }
                      return;
                    }

                    // Obtener ubicación actual
                    try {
                      Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );

                      final coordinates = LatLng(
                        position.latitude,
                        position.longitude,
                      );

                      // Mostrar indicador de carga
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Obteniendo dirección...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      // Realizar geocodificación inversa
                      final address = await _reverseGeocode(coordinates);

                      if (mounted) {
                        setState(() {
                          _selectedDeliveryCoordinates = coordinates;
                          // Actualizar el campo de dirección con la dirección escrita
                          _deliveryAddressController.text = address ?? 
                              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ubicación obtenida: ${address ?? "Coordenadas: ${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}"}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al obtener ubicación: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  tooltip: 'Usar GPS para obtener ubicación',
                ),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa la dirección de entrega';
              }
              return null;
            },
          ),
            // Mostrar mapa si hay coordenadas GPS seleccionadas
            if (_selectedDeliveryCoordinates != null) ...[
          const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toca el mapa para mover el marcador a la ubicación deseada',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedDeliveryCoordinates!,
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                    onTap: (tapPosition, point) async {
                      // Actualizar coordenadas cuando el usuario toca el mapa
                      setState(() {
                        _selectedDeliveryCoordinates = point;
                      });

                      // Mostrar indicador de carga
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Obteniendo dirección...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }

                      // Realizar geocodificación inversa
                      final address = await _reverseGeocode(point);
                      if (mounted) {
                        setState(() {
                          _deliveryAddressController.text = address ?? 
                              '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
                        });
                      }
                    },
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
                          point: _selectedDeliveryCoordinates!,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              // El marcador también puede ser tocado para centrar
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: theme.colorScheme.primary,
                                size: 30,
          ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
          // El costo de entrega será establecido por el vendedor al aceptar el pedido
        ];

      case 'external_delivery':
        return [
          TextFormField(
            controller: _deliveryAddressController,
            decoration: InputDecoration(
              labelText: 'Dirección de entrega *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              hintText: 'Dirección completa donde se entregará',
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.my_location,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () async {
                  // Solicitar permisos de ubicación
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, activa el servicio de ubicación'),
                        ),
                      );
                    }
                    return;
                  }

                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Se necesitan permisos de ubicación para usar GPS'),
                          ),
                        );
                      }
                      return;
                    }
                  }

                  if (permission == LocationPermission.deniedForever) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Los permisos de ubicación están permanentemente denegados'),
                        ),
                      );
                    }
                    return;
                  }

                  // Obtener ubicación actual
                  try {
                    Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );

                    final coordinates = LatLng(
                      position.latitude,
                      position.longitude,
                    );

                    // Mostrar indicador de carga
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Obteniendo dirección...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    // Realizar geocodificación inversa
                    final address = await _reverseGeocode(coordinates);

                    if (mounted) {
                      setState(() {
                        _selectedDeliveryCoordinates = coordinates;
                        // Actualizar el campo de dirección con la dirección escrita
                        _deliveryAddressController.text = address ?? 
                            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ubicación obtenida: ${address ?? "Coordenadas: ${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}"}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al obtener ubicación: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa la dirección de entrega';
              }
              return null;
            },
          ),
          // Mostrar mapa si hay coordenadas seleccionadas
          if (_selectedDeliveryCoordinates != null) ...[
          const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toca el mapa para mover el marcador a la ubicación deseada',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedDeliveryCoordinates!,
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                    onTap: (tapPosition, point) async {
                      // Actualizar coordenadas cuando el usuario toca el mapa
                      setState(() {
                        _selectedDeliveryCoordinates = point;
                      });

                      // Mostrar indicador de carga
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Obteniendo dirección...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }

                      // Realizar geocodificación inversa
                      final address = await _reverseGeocode(point);
                      if (mounted) {
                        setState(() {
                          _deliveryAddressController.text = address ?? 
                              '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
                        });
                      }
            },
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
                          point: _selectedDeliveryCoordinates!,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              // El marcador también puede ser tocado para centrar
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: theme.colorScheme.primary,
                                size: 30,
                              ),
            ),
          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryProviderController,
            decoration: InputDecoration(
              labelText: 'Proveedor de delivery *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
            ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              hintText: 'Ej: MRW, Domesa, etc.',
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
            decoration: InputDecoration(
              labelText: 'Número de tracking (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
          ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
          // El costo de delivery será establecido por el vendedor al aceptar el pedido
        ];

      default:
        return [];
    }
  }
}
