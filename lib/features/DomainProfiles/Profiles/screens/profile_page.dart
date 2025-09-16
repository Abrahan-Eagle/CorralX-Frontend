import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/edit_profile_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/create_profile_page.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

final logger = Logger();

class ProfileModel with ChangeNotifier {
  Profile? _profile;
  bool _isLoading = true;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> loadProfile(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await ProfileService().getProfileByUserId(userId);
      logger.i('Perfil cargado: $_profile');
    } catch (e) {
      logger.e('Error cargando perfil: $e');
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateProfile(Profile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}

class ProfilePagex extends StatelessWidget {
  final int userId;
  final bool statusId;

  const ProfilePagex({super.key, required this.userId, this.statusId = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileModel()..loadProfile(userId),
      child: Consumer<ProfileModel>(
        builder: (context, profileModel, child) {
          if (profileModel.isLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Mi Perfil'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff0043ba)),
                ),
              ),
            );
          }

          if (profileModel.profile == null) {
            Future.microtask(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateProfilePage(userId: userId),
                ),
              );
            });
            return const SizedBox();
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: isDark ? Colors.white : Colors.black,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Mi Perfil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              centerTitle: false,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Tarjeta principal del perfil
                    _buildMainProfileCard(
                        context, profileModel.profile!, isDark),
                    const SizedBox(height: 32),

                    // Sección de publicaciones activas
                    _buildActivePublicationsSection(context, isDark),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainProfileCard(
      BuildContext context, Profile profile, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar y información principal
            _buildProfileHeader(context, profile, isDark),

            // Divider
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),

            // Información de contacto en grid
            _buildContactGrid(context, profile, isDark),

            const SizedBox(height: 24),

            // Botón de editar perfil
            _buildEditProfileButton(context, profile, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Profile profile, bool isDark) {
    return Column(
      children: [
        // Avatar con borde blanco y sombra (128x128px como en HTML)
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 64, // 128px total (64*2)
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 60, // 120px interno
              backgroundImage: _buildProfileImage(context),
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Nombre del negocio con badge de verificado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              profile.businessName ?? 'Agropecuaria El Futuro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.verified,
              color: Colors.blue,
              size: 20,
            ),
          ],
        ),

        // Nombre personal (Juan Pérez como en HTML)
        Text(
          'Juan Pérez',
          style: TextStyle(
            fontSize: 18,
            color: isDark
                ? Colors.white.withOpacity(0.8)
                : Colors.black.withOpacity(0.7),
          ),
        ),

        // Rating con estrellas
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '4.5',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '(2 opiniones)',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Descripción
        Text(
          'Dedicados a la cría de ganado de alta genética. Más de 20 años de experiencia en el campo venezolano.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
            height: 1.4,
          ),
        ),

        const SizedBox(height: 16),

        // Fecha de membresía
        Text(
          'Miembro desde: mayo de 2023',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildContactGrid(BuildContext context, Profile profile, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildContactItem(
                context,
                Icons.location_on,
                'Valencia, Carabobo',
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildContactItem(
                context,
                Icons.call,
                profile.phone ?? '0414-1234567',
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildContactItem(
                context,
                Icons.mail,
                'juan.perez@elfuturo.com',
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildContactItem(
                context,
                Icons.cake,
                '24/10/1980', // Fecha fija como en HTML
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactItem(
      BuildContext context, IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.8)
                  : Colors.black.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePublicationsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Publicaciones Activas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        // Grid de publicaciones
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7, // Más reducido para eliminar overflow
          children: [
            _buildPublicationCard(context, isDark, 'Brahman Rojo',
                'https://diariolaeconomia.com/media/k2/items/cache/891bc0e45e0849a552d0ba70b9f8ec5e_XL.jpg'),
            _buildPublicationCard(context, isDark, 'Guzerat',
                'https://gruposansimon.com/web/wp-content/uploads/esta.jpg'),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicationCard(
      BuildContext context, bool isDark, String title, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
          // Imagen del ganado
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Botón de favorito
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Información del ganado
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Información del vendedor
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Agropecuaria El Futuro',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Botón ver detalles
                  Text(
                    'Ver Detalles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
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

  Widget _buildEditProfileButton(
      BuildContext context, Profile profile, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _navigateToEditOrCreatePage(context, profile),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'N/A';
    }

    final DateFormat format = DateFormat('dd-MM-yyyy');
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return format.format(parsedDate);
    } catch (e) {
      return 'N/A';
    }
  }

  void _navigateToEditOrCreatePage(BuildContext context, Profile profile) {
    final route = MaterialPageRoute(
      builder: (context) => EditProfilePage(userId: profile.userId),
    );

    Navigator.push(context, route).then((_) {
      Provider.of<ProfileModel>(context, listen: false)
          .loadProfile(profile.userId);
    });
  }

  ImageProvider<Object>? _buildProfileImage(BuildContext context) {
    final profile = context.read<ProfileModel>().profile;
    if (profile?.photo != null &&
        profile!.photo!.isNotEmpty &&
        !profile.photo!.contains('URL de foto no disponible')) {
      return NetworkImage(profile.photo!);
    }
    // Usar imagen de Google como fallback
    if (profile?.user?.profilePic != null &&
        profile!.user!.profilePic!.isNotEmpty) {
      return NetworkImage(profile.user!.profilePic!);
    }
    return const AssetImage('assets/default_avatar.png');
  }
}
