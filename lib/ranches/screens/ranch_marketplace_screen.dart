import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ranch_provider.dart';
import '../widgets/ranch_card.dart';
import '../../profiles/screens/ranch_detail_screen.dart';

class RanchMarketplaceScreen extends StatefulWidget {
  const RanchMarketplaceScreen({super.key});

  @override
  State<RanchMarketplaceScreen> createState() => _RanchMarketplaceScreenState();
}

class _RanchMarketplaceScreenState extends State<RanchMarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar ranchos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RanchProvider>().fetchRanches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Contenido principal
          Positioned.fill(
            child: Consumer<RanchProvider>(
              builder: (context, ranchProvider, child) {
                // Estado de carga inicial
                if (ranchProvider.isLoading && ranchProvider.ranches.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Estado de error
                if (ranchProvider.errorMessage != null) {
                  return Center(
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
                          ranchProvider.errorMessage!,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ranchProvider.refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                // Lista de ranchos
                return RefreshIndicator(
                  onRefresh: () => ranchProvider.refresh(),
                  child: CustomScrollView(
                    slivers: [
                      // Header simple con solo título
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        backgroundColor: theme.colorScheme.surface,
                        elevation: 0,
                        toolbarHeight: isTablet ? 80 : 60,
                        flexibleSpace: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 16,
                            vertical: isTablet ? 20 : 16,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Haciendas',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 32 : 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Estado vacío
                      if (ranchProvider.ranches.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.agriculture_outlined,
                                  size: 80,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron haciendas',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Intenta ajustar los filtros de búsqueda',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        // Lista de ranchos
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ranch = ranchProvider.ranches[index];
                              final isFavorite = ranchProvider.isFavorite(ranch.id);

                              return RanchCard(
                                ranch: ranch,
                                isFavorite: isFavorite,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RanchDetailScreen(
                                        ranch: ranch,
                                      ),
                                    ),
                                  );
                                },
                                onFavorite: () {
                                  ranchProvider.toggleFavorite(ranch);
                                },
                              );
                            },
                            childCount: ranchProvider.ranches.length,
                          ),
                        ),
                      
                      // Espacio inferior
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

