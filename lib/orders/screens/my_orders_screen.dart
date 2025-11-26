import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/orders/providers/order_provider.dart';
import 'package:corralx/orders/widgets/order_card.dart';
import 'order_detail_screen.dart';

/// Pantalla que muestra los pedidos del usuario con tabs para Comprador/Vendedor
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedStatus = null;
      });
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final orderProvider = context.read<OrderProvider>();
    if (_tabController.index == 0) {
      await orderProvider.loadBuyerOrders(refresh: true);
    } else {
      await orderProvider.loadSellerOrders(refresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final orderProvider = context.read<OrderProvider>();
    if (_tabController.index == 0) {
      await orderProvider.loadBuyerOrders(refresh: true);
    } else {
      await orderProvider.loadSellerOrders(refresh: true);
    }
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _StatusFilterBottomSheet(
          selectedStatus: _selectedStatus,
          onStatusSelected: (status) {
            setState(() {
              _selectedStatus = status;
            });
            Navigator.pop(context);
            _loadInitialData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Como Comprador'),
            Tab(text: 'Como Vendedor'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showStatusFilter,
            tooltip: 'Filtrar por estado',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(
            role: 'buyer',
            status: _selectedStatus,
            onRefresh: _handleRefresh,
          ),
          _OrdersList(
            role: 'seller',
            status: _selectedStatus,
            onRefresh: _handleRefresh,
          ),
        ],
      ),
    );
  }
}

/// Lista de pedidos para un rol específico
class _OrdersList extends StatelessWidget {
  final String role;
  final String? status;
  final VoidCallback onRefresh;

  const _OrdersList({
    required this.role,
    this.status,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final orders = role == 'buyer'
            ? orderProvider.buyerOrders
            : orderProvider.sellerOrders;
        final isLoading = role == 'buyer'
            ? orderProvider.isLoadingBuyerOrders
            : orderProvider.isLoadingSellerOrders;

        if (isLoading && orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orders.isEmpty && !isLoading) {
          return RefreshIndicator(
            onRefresh: () async {
              if (role == 'buyer') {
                await orderProvider.loadBuyerOrders(
                  status: status,
                  refresh: true,
                );
              } else {
                await orderProvider.loadSellerOrders(
                  status: status,
                  refresh: true,
                );
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes pedidos ${role == 'buyer' ? 'como comprador' : 'como vendedor'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (role == 'buyer') {
              await orderProvider.loadBuyerOrders(
                status: status,
                refresh: true,
              );
            } else {
              await orderProvider.loadSellerOrders(
                status: status,
                refresh: true,
              );
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(orderId: order.id),
                    ),
                  ).then((_) {
                    // Refrescar después de volver
                    onRefresh();
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Bottom Sheet para filtrar por estado
class _StatusFilterBottomSheet extends StatelessWidget {
  final String? selectedStatus;
  final Function(String?) onStatusSelected;

  const _StatusFilterBottomSheet({
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      null,
      'pending',
      'accepted',
      'rejected',
      'delivered',
      'completed',
      'cancelled',
    ];

    final statusLabels = {
      null: 'Todos',
      'pending': 'Pendiente',
      'accepted': 'Aceptado',
      'rejected': 'Rechazado',
      'delivered': 'Entregado',
      'completed': 'Completado',
      'cancelled': 'Cancelado',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filtrar por estado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...statuses.map((status) {
            return RadioListTile<String?>(
              title: Text(statusLabels[status] ?? 'Todos'),
              value: status,
              groupValue: selectedStatus,
              onChanged: (value) => onStatusSelected(value),
            );
          }),
        ],
      ),
    );
  }
}

