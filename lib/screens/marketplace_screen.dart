import 'package:flutter/material.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFCFDF7),
              border: Border(
                bottom: BorderSide(color: Color(0xFF74796D), width: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por raza, tipo o ubicación...',
                    filled: true,
                    fillColor: const Color(0xFFF4F4ED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, size: isTablet ? 24 : 20),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 16 : 12,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 12),
                // Location filter and market pulse button
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF4F4ED),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 12 : 8,
                          ),
                        ),
                        value: 'all',
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('Toda Venezuela')),
                          DropdownMenuItem(
                              value: 'carabobo', child: Text('Carabobo')),
                          DropdownMenuItem(
                              value: 'aragua', child: Text('Aragua')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.insights, size: isTablet ? 20 : 16),
                      label: Text('Mercado',
                          style: TextStyle(fontSize: isTablet ? 16 : 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9E7CA),
                        foregroundColor: const Color(0xFF131F0D),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isTablet ? 12 : 8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 12 : 8,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 12),
                // Filter buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 2),
                    child: Row(
                      children: [
                        _buildFilterChip('Todos', true, isTablet),
                        SizedBox(width: isTablet ? 12 : 8),
                        _buildFilterChip('Lechero', false, isTablet),
                        SizedBox(width: isTablet ? 12 : 8),
                        _buildFilterChip('Engorde', false, isTablet),
                        SizedBox(width: isTablet ? 12 : 8),
                        _buildFilterChip('Padrote', false, isTablet),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured section
                  Text(
                    'Destacadas',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 2);
                      final childAspectRatio = isTablet ? 1.3 : 1.2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: isTablet ? 20 : 16,
                          mainAxisSpacing: isTablet ? 20 : 16,
                        ),
                        itemCount: 2,
                        itemBuilder: (context, index) =>
                            _buildCattleCard(isTablet),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 40 : 32),
                  // Recent section
                  Text(
                    'Recientes',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 2);
                      final childAspectRatio = isTablet ? 1.3 : 1.2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: isTablet ? 20 : 16,
                          mainAxisSpacing: isTablet ? 20 : 16,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) =>
                            _buildCattleCard(isTablet),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, bool isTablet) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontSize: isTablet ? 16 : 14),
      ),
      selected: isActive,
      onSelected: (selected) {},
      selectedColor: const Color(0xFFB7F399),
      checkmarkColor: const Color(0xFF082100),
      backgroundColor: const Color(0xFFF4F4ED),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 4,
      ),
    );
  }

  Widget _buildCattleCard(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4ED),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isTablet ? 6 : 4,
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isTablet ? 20 : 16),
                ),
                color: Colors.grey,
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: isTablet ? 64 : 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 2 : 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brahman Rojo',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 1 : 0),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isTablet ? 14 : 12,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          size: isTablet ? 18 : 16,
                        ),
                      ),
                      SizedBox(width: isTablet ? 10 : 8),
                      Expanded(
                        child: Text(
                          'Agropecuaria El Futuro',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.verified,
                        size: isTablet ? 18 : 16,
                        color: const Color(0xFF386A20),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Ver Detalles',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF386A20),
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
