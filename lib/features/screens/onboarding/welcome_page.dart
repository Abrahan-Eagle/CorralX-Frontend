import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../../../core/widgets/amazon_widgets.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _mainController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header con logo y información
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Logo y título en una fila
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: CorralXTheme.accentSolid,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Center(
                                child: Text(
                                  'CX',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CorralX',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: CorralXTheme.primarySolid,
                                      fontSize: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Marketplace Ganadero Profesional',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Información principal
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido a CorralX',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'La plataforma líder en comercio ganadero',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Compra y vende ganado de forma segura y confiable',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Conecta con ganaderos verificados, encuentra las mejores ofertas y gestiona tus transacciones de manera profesional.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Estadísticas rápidas
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CorralXTheme.successSolid
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: CorralXTheme.successSolid
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '1,200+',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: CorralXTheme.successSolid,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Vendedores',
                                      style: TextStyle(
                                        color: CorralXTheme.successSolid,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CorralXTheme.secondarySolid
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: CorralXTheme.secondarySolid
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '5,800+',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Publicaciones',
                                      style: TextStyle(
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      CorralXTheme.accentSolid.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: CorralXTheme.accentSolid
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '98%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Satisfacción',
                                      style: TextStyle(
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Características principales
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.02)
                                : Colors.grey.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Características principales',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AmazonListItem(
                          title: 'Vendedores Verificados',
                          subtitle:
                              'Todos los vendedores están certificados y verificados',
                          icon: Icons.verified_user,
                          trailing: '100% Seguro',
                        ),
                        AmazonListItem(
                          title: 'Transacciones Protegidas',
                          subtitle: 'Sistema de pago seguro con garantías',
                          icon: Icons.security,
                          trailing: 'Garantizado',
                        ),
                        AmazonListItem(
                          title: 'Soporte 24/7',
                          subtitle: 'Atención al cliente disponible siempre',
                          icon: Icons.support_agent,
                          trailing: 'Disponible',
                        ),
                        AmazonListItem(
                          title: 'Entrega Rápida',
                          subtitle: 'Conexión directa con vendedores locales',
                          icon: Icons.local_shipping,
                          trailing: 'Inmediato',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Información adicional
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CorralXTheme.primarySolid.withOpacity(0.1)
                          : CorralXTheme.primarySolid.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: CorralXTheme.primarySolid.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: CorralXTheme.primarySolid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Únete a miles de ganaderos que ya confían en CorralX para sus transacciones',
                            style: TextStyle(
                              color: CorralXTheme.primarySolid,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
