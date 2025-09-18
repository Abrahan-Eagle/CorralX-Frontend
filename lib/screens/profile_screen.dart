import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'profile';

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
          'Mi Perfil',
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
        child: Column(
          children: [
            // Tabs
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: isTablet ? 120 : 100,
                      child: _buildTabButton('profile', 'Perfil', isTablet),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    SizedBox(
                      width: isTablet ? 160 : 140,
                      child: _buildTabButton(
                          'myListings', 'Mis Publicaciones', isTablet),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    SizedBox(
                      width: isTablet ? 120 : 100,
                      child: _buildTabButton('farms', 'Mis Fincas', isTablet),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            // Content
            Expanded(
              child: _buildTabContent(isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, bool isTablet) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 12 : 8,
          horizontal: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFB7F399) : const Color(0xFFF4F4ED),
          borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? const Color(0xFF082100) : const Color(0xFF1A1C18),
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isTablet) {
    switch (_activeTab) {
      case 'myListings':
        return _buildMyListingsContent(isTablet);
      case 'farms':
        return _buildFarmsContent(isTablet);
      case 'profile':
      default:
        return _buildProfileContent(isTablet);
    }
  }

  Widget _buildProfileContent(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          // Profile info card
          Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4ED),
              borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isTablet ? 80 : 64,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.person,
                    size: isTablet ? 80 : 64,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),
                Text(
                  'Juan Pérez',
                  style: TextStyle(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isTablet ? 10 : 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: isTablet ? 24 : 20,
                    ),
                    SizedBox(width: isTablet ? 6 : 4),
                    Text(
                      '4.5',
                      style: TextStyle(fontSize: isTablet ? 20 : 18),
                    ),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      '(2 opiniones)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 20 : 16),
                Text(
                  'Este usuario no ha agregado una biografía.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),
                Text(
                  'Miembro desde: mayo 2023',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: isTablet ? 32 : 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF386A20),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 24,
                      vertical: isTablet ? 16 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                    ),
                  ),
                  child: Text(
                    'Editar Perfil',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListingsContent(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          _buildListingItem(
              'Brahman Rojo', 'Agropecuaria El Futuro', '124 vistas', isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          _buildListingItem(
              'Guzerat', 'Agropecuaria El Futuro', '210 vistas', isTablet),
        ],
      ),
    );
  }

  Widget _buildFarmsContent(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.add, size: isTablet ? 24 : 20),
            label: Text(
              'Agregar Nueva Finca',
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF386A20),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          _buildFarmItem(
              'Agropecuaria El Futuro', 'Valencia, Carabobo', isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          _buildFarmItem('Hato La Esperanza', 'San Carlos, Cojedes', isTablet),
        ],
      ),
    );
  }

  Widget _buildListingItem(
      String breed, String farm, String views, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isTablet ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 80 : 64,
            height: isTablet ? 80 : 64,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            ),
            child: Icon(
              Icons.image,
              color: Colors.white,
              size: isTablet ? 40 : 32,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breed,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  'De la finca: $farm',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  views,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, size: isTablet ? 24 : 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.delete,
                    color: Colors.red, size: isTablet ? 24 : 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmItem(String name, String location, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isTablet ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 80 : 64,
            height: isTablet ? 80 : 64,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            ),
            child: Icon(
              Icons.home,
              color: Colors.white,
              size: isTablet ? 40 : 32,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, size: isTablet ? 24 : 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.delete,
                    color: Colors.red, size: isTablet ? 24 : 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
