import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/GasTicket/gas_button/api/gas_ticket_service.dart';
import 'package:zonix/features/GasTicket/gas_button/models/gas_ticket.dart';
import 'package:zonix/features/GasTicket/gas_button/widgets/ticket_list_view.dart';
import 'package:zonix/features/GasTicket/gas_button/screens/create_gas_ticket_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';

class GasTicketListScreen extends StatefulWidget {
  const GasTicketListScreen({super.key});

  @override
  GasTicketListScreenState createState() => GasTicketListScreenState();
}

class GasTicketListScreenState extends State<GasTicketListScreen>
    with TickerProviderStateMixin {
  final GasTicketService _ticketService = GasTicketService();
  List<GasTicket>? _ticketList;
  bool _isLoading = true; // Para manejar el estado de carga
  String? _errorMessage; // Para manejar errores
  Timer? _refreshTimer; // Timer para refresh automático
  int _userId = 0; // Almacenar userId para el timer

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _userId = userProvider.userId;
      _loadTickets(_userId);
      _startAutoRefresh(); // Iniciar refresh automático
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancelar timer al destruir el widget
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh automático cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _userId > 0) {
        _loadTickets(_userId);
      }
    });
  }

  Future<void> _loadTickets(int userId) async {
    setState(() {
      _isLoading = true; // Iniciar carga
      _errorMessage = null; // Reiniciar mensaje de error
    });

    try {
      logger.i('User ID: fetchGasTickets $userId');
      final tickets = await _ticketService.fetchGasTickets(userId);
      logger.i('_ticketService.fetchGasTickets $tickets');

      if (!mounted) return; // Verificar si el widget sigue montado

      setState(() {
        _ticketList = tickets;
        _isLoading = false; // Carga completa
      });
    } catch (e) {
      print('Error al cargar tickets: $e');
      setState(() {
        _errorMessage =
            'Error al cargar los tickets. Inténtalo de nuevo.'; // Mensaje de error
        _isLoading = false; // Carga completa
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gas Ticket'),
            actions: [
              // Botón de refresh manual
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadTickets(_userId),
                tooltip: 'Actualizar lista',
              ),
              // Botón de agregar ticket
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  iconSize: 24,
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateGasTicketScreen(userId: userProvider.userId),
                      ),
                    ).then((_) =>
                        _loadTickets(userProvider.userId)); // Recargar lista
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _loadTickets(_userId),
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage!,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadTickets(_userId),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _ticketList!.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No hay tickets disponibles.',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Text(
                                      'La lista se actualiza automáticamente cada 30 segundos',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            )
                          : TicketListView(tickets: _ticketList!),
            ),
          ),
        );
      },
    );
  }
}
