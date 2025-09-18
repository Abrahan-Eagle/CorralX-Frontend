import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFDF7),
        elevation: 0,
        title: Text(
          'Mis Favoritos',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1C18),
          ),
        ),
        centerTitle: true,
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : double.infinity,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 20 : 16,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 2);
                  final childAspectRatio = isTablet ? 1.1 : 1.0;
              
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: isTablet ? 20 : 16,
                  mainAxisSpacing: isTablet ? 20 : 16,
                ),
                itemCount: 3, // Mock data
                itemBuilder: (context, index) => _buildCattleCard(isTablet),
              );
            },
          ),
        ),
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
          // Image with favorite button
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
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
                Positioned(
                  top: isTablet ? 12 : 8,
                  right: isTablet ? 12 : 8,
                  child: Container(
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 6 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holstein',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                      SizedBox(height: isTablet ? 2 : 1),
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
                          'Finca Los Girasoles',
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

