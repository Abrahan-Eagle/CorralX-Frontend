import 'package:flutter/material.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFCFDF7),
              border: Border(
                bottom: BorderSide(color: Color(0xFF74796D), width: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Logo y admin button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.network(
                      'https://aiblockweb.com/img/img_renny/2.png',
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.store, size: 48);
                      },
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.admin_panel_settings),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE9E9E2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por raza, tipo o ubicación...',
                    filled: true,
                    fillColor: const Color(0xFFF4F4ED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                // Location filter and market pulse button
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF4F4ED),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        value: 'all',
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Toda Venezuela')),
                          DropdownMenuItem(value: 'carabobo', child: Text('Carabobo')),
                          DropdownMenuItem(value: 'aragua', child: Text('Aragua')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.insights, size: 16),
                      label: const Text('Mercado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9E7CA),
                        foregroundColor: const Color(0xFF131F0D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Lechero', false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Engorde', false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Padrote', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured section
                  const Text(
                    'Destacadas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 2,
                    itemBuilder: (context, index) => _buildCattleCard(),
                  ),
                  const SizedBox(height: 32),
                  // Recent section
                  const Text(
                    'Recientes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) => _buildCattleCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {},
      selectedColor: const Color(0xFFB7F399),
      checkmarkColor: const Color(0xFF082100),
      backgroundColor: const Color(0xFFF4F4ED),
    );
  }

  Widget _buildCattleCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4ED),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.grey,
              ),
              child: const Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Brahman Rojo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Agropecuaria El Futuro',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.verified, size: 16, color: Color(0xFF386A20)),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Ver Detalles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF386A20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
