import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/profiles/providers/profile_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// Pantalla de perfil público de un vendedor/usuario
class PublicProfileScreen extends StatefulWidget {
  final int userId;
  
  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar perfil público al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      profileProvider.fetchPublicProfile(widget.userId);
    });
  }

  @override
  void dispose() {
    // Limpiar perfil público al salir
    context.read<ProfileProvider>().clearPublicProfile();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.fetchPublicProfile(widget.userId, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Perfil del Vendedor',
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          // Estado de carga
          if (profileProvider.isLoadingPublicProfile) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            );
          }

          // Estado de error
          if (profileProvider.publicProfileError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: isTablet ? 64 : 48,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Text(
                    profileProvider.publicProfileError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                  ElevatedButton(
                    onPressed: () {
                      profileProvider.fetchPublicProfile(widget.userId, forceRefresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final profile = profileProvider.publicProfile;

          // Estado sin perfil
          if (profile == null) {
            return Center(
              child: Text(
                'No se pudo cargar el perfil',
                style: TextStyle(
                  color: theme.colorScheme.onBackground,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            );
          }

          // Renderizar perfil público
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header del perfil
                  Container(
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: isTablet ? 80 : 64,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          backgroundImage: profile.photoUsers != null
                              ? CachedNetworkImageProvider(profile.photoUsers!)
                              : null,
                          child: profile.photoUsers == null
                              ? Icon(
                                  Icons.person,
                                  size: isTablet ? 80 : 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        SizedBox(height: isTablet ? 20 : 16),
                        
                        // Nombre (comercial si existe, sino nombre completo)
                        Text(
                          profile.displayName,
                          style: TextStyle(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isTablet ? 10 : 8),
                        
                        // Rating, verificado y premium
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (profile.isVerified) ...[
                              Icon(
                                Icons.verified,
                                color: theme.colorScheme.primary,
                                size: isTablet ? 24 : 20,
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                            ],
                            if (profile.isPremiumSeller) ...[
                              Icon(
                                Icons.workspace_premium,
                                color: Colors.amber,
                                size: isTablet ? 24 : 20,
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                            ],
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: isTablet ? 24 : 20,
                            ),
                            SizedBox(width: isTablet ? 6 : 4),
                            Text(
                              profile.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                            Text(
                              '(${profile.ratingsCount} ${profile.ratingsCount == 1 ? "opinión" : "opiniones"})',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: isTablet ? 20 : 16),
                        
                        // Ubicación (si existe)
                        if (profile.address != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: isTablet ? 20 : 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                profile.address!.formattedLocation,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                        ],
                        
                        // Miembro desde
                        Text(
                          'Miembro desde: ${DateFormat('MMMM yyyy', 'es').format(profile.createdAt)}',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 24 : 16),
                        
                        // Métodos de contacto preferidos
                        Wrap(
                          spacing: isTablet ? 16 : 12,
                          runSpacing: isTablet ? 12 : 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (profile.acceptsCalls)
                              _buildContactChip(
                                icon: Icons.phone,
                                label: 'Llamadas',
                                color: Colors.blue,
                                theme: theme,
                                isTablet: isTablet,
                              ),
                            if (profile.acceptsWhatsapp)
                              _buildContactChip(
                                icon: Icons.chat,
                                label: 'WhatsApp',
                                color: Colors.green,
                                theme: theme,
                                isTablet: isTablet,
                              ),
                            if (profile.acceptsEmails)
                              _buildContactChip(
                                icon: Icons.email,
                                label: 'Email',
                                color: Colors.orange,
                                theme: theme,
                                isTablet: isTablet,
                              ),
                          ],
                        ),
                        
                        SizedBox(height: isTablet ? 32 : 24),
                        
                        // Botón Contactar
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Abrir chat con este vendedor
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chat - Próximamente'),
                              ),
                            );
                          },
                          icon: Icon(Icons.chat_bubble, size: isTablet ? 24 : 20),
                          label: Text(
                            'Contactar Vendedor',
                            style: TextStyle(fontSize: isTablet ? 18 : 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 24,
                              vertical: isTablet ? 16 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Título de publicaciones
                  Text(
                    'Publicaciones de ${profile.displayName}',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // TODO: Mostrar productos del vendedor
                  // Por ahora mostramos un placeholder
                  Container(
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: isTablet ? 64 : 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'Cargando publicaciones del vendedor...',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isTablet ? 18 : 16),
          SizedBox(width: isTablet ? 8 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
