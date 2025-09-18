import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../../../core/widgets/amazon_widgets.dart';

class OnboardingPage5 extends StatefulWidget {
  const OnboardingPage5({super.key});

  @override
  State<OnboardingPage5> createState() => _OnboardingPage5State();
}

class _OnboardingPage5State extends State<OnboardingPage5>
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
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
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

                // Header con título
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.chat,
                              color: CorralXTheme.primarySolid,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chat y Negociación',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: CorralXTheme.primarySolid,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comunícate directamente',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
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
                          'Comunicación Directa',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chat instantáneo con vendedores y compradores',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chatea directamente con vendedores y compradores. Negocia precios, programa visitas y cierra acuerdos de forma segura.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Funciones de comunicación
                        Row(
                          children: [
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
                                    Icon(
                                      Icons.message,
                                      color: CorralXTheme.secondarySolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Chat',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Instantáneo',
                                      style: TextStyle(
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 9,
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
                                    Icon(
                                      Icons.handshake,
                                      color: CorralXTheme.successSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Negociación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.successSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Segura',
                                      style: TextStyle(
                                        color: CorralXTheme.successSolid,
                                        fontSize: 9,
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
                                    Icon(
                                      Icons.shield,
                                      color: CorralXTheme.accentSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Seguridad',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Protegida',
                                      style: TextStyle(
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 9,
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

                // Funciones de comunicación
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
                                'Funciones de comunicación',
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
                          title: 'Mensajes Instantáneos',
                          subtitle:
                              'Chat en tiempo real con vendedores y compradores',
                          icon: Icons.chat_bubble_outline,
                          trailing: 'Real-time',
                        ),
                        AmazonListItem(
                          title: 'Negociación Segura',
                          subtitle:
                              'Acuerda precios y condiciones de forma protegida',
                          icon: Icons.gavel,
                          trailing: 'Seguro',
                        ),
                        AmazonListItem(
                          title: 'Programar Visitas',
                          subtitle:
                              'Coordina visitas a las fincas directamente',
                          icon: Icons.calendar_today,
                          trailing: 'Fácil',
                        ),
                        AmazonListItem(
                          title: 'Historial Completo',
                          subtitle:
                              'Mantén registro de todas tus conversaciones',
                          icon: Icons.history,
                          trailing: 'Completo',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Conversaciones de ejemplo
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 400),
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
                          'Conversaciones Activas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ejemplo de conversaciones en curso',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AmazonFeature(
                                title: 'Finca San José',
                                description: 'Interesado en las Holstein',
                                price: 'Último: \$3,200',
                                rating: '4.9',
                                reviews: 'Activo',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.chat_bubble,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Rancho El Toro',
                                description: 'Negociando precio del toro',
                                price: 'Último: \$4,500',
                                rating: '4.8',
                                reviews: 'Activo',
                                accentColor: CorralXTheme.secondarySolid,
                                icon: Icons.chat_bubble,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AmazonFeature(
                                title: 'Granja Los Andes',
                                description: 'Programando visita mañana',
                                price: 'Último: \$1,800',
                                rating: '4.7',
                                reviews: 'Activo',
                                accentColor: CorralXTheme.accentSolid,
                                icon: Icons.chat_bubble,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Hacienda Verde',
                                description: 'Confirmando entrega',
                                price: 'Último: \$3,200',
                                rating: '4.9',
                                reviews: 'Activo',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.chat_bubble,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Información adicional
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CorralXTheme.secondarySolid.withOpacity(0.1)
                          : CorralXTheme.secondarySolid.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: CorralXTheme.secondarySolid.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat,
                          size: 16,
                          color: CorralXTheme.secondarySolid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Más de 2,500 mensajes enviados diariamente en la plataforma',
                            style: TextStyle(
                              color: CorralXTheme.secondarySolid,
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
