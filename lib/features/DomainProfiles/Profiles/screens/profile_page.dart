import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/edit_profile_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/create_profile_page.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:zonix/features/utils/app_colors.dart';

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
            backgroundColor: AppColors.scaffoldBg(context),
            body: CustomScrollView(
              slivers: [
                // App Bar personalizado
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.scaffoldBg(context),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(context, profileModel.profile!, isDark),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.primaryText(context),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: AppColors.primaryText(context),
                      onPressed: () => _navigateToEditOrCreatePage(context, profileModel.profile!),
                    ),
                  ],
                ),
                
                // Contenido del perfil
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Información personal
                        _buildPersonalInfoCard(context, profileModel.profile!),
                        const SizedBox(height: 16),
                        
                        // Información de contacto
                        _buildContactInfoCard(context, profileModel.profile!),
                        const SizedBox(height: 16),
                        
                        // Información de negocio (si aplica)
                        if (_hasBusinessInfo(profileModel.profile!))
                          _buildBusinessInfoCard(context, profileModel.profile!),
                        if (_hasBusinessInfo(profileModel.profile!))
                          const SizedBox(height: 16),
                        
                        // Información de delivery (si aplica)
                        if (_hasDeliveryInfo(profileModel.profile!))
                          _buildDeliveryInfoCard(context, profileModel.profile!),
                        if (_hasDeliveryInfo(profileModel.profile!))
                          const SizedBox(height: 16),
                        
                        // Estado del perfil
                        _buildProfileStatusCard(context, profileModel.profile!),
                        const SizedBox(height: 16),
                        
                        // Botón de editar perfil
                        _buildEditProfileButton(context, profileModel.profile!),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Profile profile, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue,
            AppColors.blue.withOpacity(0.8),
            AppColors.blue.withOpacity(0.6),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar con borde y sombra profesional
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: AppColors.grayLight,
                  child: () {
                    logger.i('🔍 Verificando imagen del perfil:');
                    logger.i('   - photo: ${profile.photo}');
                    logger.i('   - photo != null: ${profile.photo != null}');
                    logger.i('   - photo.isNotEmpty: ${profile.photo?.isNotEmpty}');
                    logger.i('   - contiene placeholder: ${profile.photo?.contains('URL de foto no disponible')}');
                    
                    if (profile.photo != null && profile.photo!.isNotEmpty && !profile.photo!.contains('URL de foto no disponible')) {
                      logger.i('✅ Mostrando imagen del perfil: ${profile.photo}');
                      return ClipOval(
                          child: Image.network(
                            profile.photo!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: AppColors.grayLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.blue,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              logger.e('Error cargando imagen del perfil: $error');
                              logger.i('🔄 Intentando usar imagen de Google como fallback...');
                              
                              // Intentar usar la imagen de Google como fallback
                              if (profile.user?.profilePic != null && profile.user!.profilePic!.isNotEmpty) {
                                logger.i('✅ Usando imagen de Google: ${profile.user!.profilePic}');
                                return ClipOval(
                                  child: Image.network(
                                    profile.user!.profilePic!,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      logger.e('Error también con imagen de Google: $error');
                                      return const Icon(Icons.person, color: AppColors.blue, size: 50);
                                    },
                                  ),
                                );
                              }
                              
                              return const Icon(Icons.person, color: AppColors.blue, size: 50);
                            },
                          ),
                        );
                    } else {
                      logger.w('❌ Usando icono placeholder');
                      return const Icon(Icons.person, color: AppColors.blue, size: 50);
                    }
                  }(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${profile.firstName} ${profile.lastName}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: AppColors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usuario Activo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, Profile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.blueDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(context, 'Nombre', profile.firstName, Icons.person_outline),
            if (profile.middleName != null && profile.middleName!.isNotEmpty)
              _buildInfoRow(context, 'Segundo Nombre', profile.middleName!, Icons.person_outline),
            _buildInfoRow(context, 'Apellido', profile.lastName, Icons.person_outline),
            if (profile.secondLastName != null && profile.secondLastName!.isNotEmpty)
              _buildInfoRow(context, 'Segundo Apellido', profile.secondLastName!, Icons.person_outline),
            _buildInfoRow(context, 'Fecha de Nacimiento', _formatDate(profile.dateOfBirth), Icons.calendar_today),
            _buildInfoRow(context, 'Estado Civil', _translateMaritalStatus(profile.maritalStatus ?? 'N/A'), Icons.favorite),
            _buildInfoRow(context, 'Sexo', _translateSex(profile.sex), Icons.wc),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard(BuildContext context, Profile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.contact_phone,
                    color: AppColors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información de Contacto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.blueDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(context, 'Teléfono', profile.phone ?? 'No especificado', Icons.phone),
            _buildInfoRow(context, 'Dirección', profile.address ?? 'No especificada', Icons.location_on),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard(BuildContext context, Profile profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: AppColors.cardBg(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    color: AppColors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información de Negocio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (profile.businessName != null && profile.businessName!.isNotEmpty)
              _buildInfoRow(context, 'Nombre del Negocio', profile.businessName!, Icons.store),
            if (profile.businessType != null && profile.businessType!.isNotEmpty)
              _buildInfoRow(context, 'Tipo de Negocio', profile.businessType!, Icons.category),
            if (profile.taxId != null && profile.taxId!.isNotEmpty)
              _buildInfoRow(context, 'RFC', profile.taxId!, Icons.receipt),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard(BuildContext context, Profile profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: AppColors.cardBg(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delivery_dining,
                    color: AppColors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información de Delivery',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (profile.vehicleType != null && profile.vehicleType!.isNotEmpty)
              _buildInfoRow(context, 'Tipo de Vehículo', profile.vehicleType!, Icons.two_wheeler),
            if (profile.licenseNumber != null && profile.licenseNumber!.isNotEmpty)
              _buildInfoRow(context, 'Número de Licencia', profile.licenseNumber!, Icons.card_membership),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatusCard(BuildContext context, Profile profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: AppColors.cardBg(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(profile.status).withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: _getStatusColor(profile.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Estado del Perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(context, 'Estado', _translateStatus(profile.status), Icons.info),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.gray,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.blueDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context, Profile profile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _navigateToEditOrCreatePage(context, profile),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.edit, size: 20),
        label: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  bool _hasBusinessInfo(Profile profile) {
    return (profile.businessName != null && profile.businessName!.isNotEmpty) ||
           (profile.businessType != null && profile.businessType!.isNotEmpty) ||
           (profile.taxId != null && profile.taxId!.isNotEmpty);
  }

  bool _hasDeliveryInfo(Profile profile) {
    return (profile.vehicleType != null && profile.vehicleType!.isNotEmpty) ||
           (profile.licenseNumber != null && profile.licenseNumber!.isNotEmpty);
  }

  String _translateMaritalStatus(String status) {
    switch (status) {
      case 'single':
        return 'Soltero';
      case 'married':
        return 'Casado';
      case 'divorced':
        return 'Divorciado';
      case 'widowed':
        return 'Viudo';
      default:
        return 'N/A';
    }
  }

  String _translateSex(String sex) {
    switch (sex) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      case 'O':
        return 'Otro';
      default:
        return 'N/A';
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'completeData':
        return 'Datos Completos';
      case 'incompleteData':
        return 'Datos Incompletos';
      case 'notverified':
        return 'No Verificado';
      default:
        return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completeData':
        return Colors.green;
      case 'incompleteData':
        return Colors.orange;
      case 'notverified':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
      Provider.of<ProfileModel>(context, listen: false).loadProfile(profile.userId);
    });
  }

}
