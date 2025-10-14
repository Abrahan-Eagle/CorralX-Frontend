import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ranch_provider.dart';
import '../widgets/ranch_card.dart';
import '../widgets/ranch_filters_modal.dart';
import '../../profiles/screens/ranch_detail_screen.dart';

class RanchMarketplaceScreen extends StatefulWidget {
  const RanchMarketplaceScreen({super.key});

  @override
  State<RanchMarketplaceScreen> createState() => _RanchMarketplaceScreenState();
}

class _RanchMarketplaceScreenState extends State<RanchMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar ranchos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RanchProvider>().fetchRanches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim();
    context.read<RanchProvider>().searchRanches(searchTerm);
  }

  void _showFiltersModal() {
    showDialog(
      context: context,
      builder: (context) => RanchFiltersModal(
        currentFilters: context.read<RanchProvider>().currentFilters,
        onApplyFilters: (filters) {
          // Agregar búsqueda actual a los filtros
          if (_searchController.text.isNotEmpty) {
            filters['search'] = _searchController.text;
          }
          context.read<RanchProvider>().applyFilters(filters);
        },
      ),
    );
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
                      // Header con búsqueda y filtros
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        backgroundColor: theme.colorScheme.surface,
                        elevation: 0,
                        toolbarHeight: isTablet ? 120 : 100,
                        flexibleSpace: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 16,
                            vertical: isTablet ? 16 : 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título
                              Text(
                                'Haciendas',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 32 : 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Barra de búsqueda y filtros
                              Row(
                                children: [
                                  // Campo de búsqueda
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Buscar haciendas...',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  _performSearch();
                                                },
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 16 : 12,
                                          vertical: isTablet ? 14 : 10,
                                        ),
                                      ),
                                      onSubmitted: (_) => _performSearch(),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Botón de filtros
                                  IconButton.filled(
                                    onPressed: _showFiltersModal,
                                    icon: Badge(
                                      isLabelVisible: ranchProvider.currentFilters.isNotEmpty,
                                      label: Text(
                                        ranchProvider.currentFilters.length.toString(),
                                      ),
                                      child: const Icon(Icons.filter_list),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Mensaje de filtros activos
                      if (ranchProvider.currentFilters.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isTablet ? 24 : 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  size: 18,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${ranchProvider.currentFilters.length} filtro(s) activo(s)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    ranchProvider.clearFilters();
                                  },
                                  child: const Text('Limpiar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Contador de resultados
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 16,
                            vertical: 12,
                          ),
                          child: Text(
                            '${ranchProvider.ranches.length} ${ranchProvider.ranches.length == 1 ? 'hacienda encontrada' : 'haciendas encontradas'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isTablet ? 16 : 14,
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

