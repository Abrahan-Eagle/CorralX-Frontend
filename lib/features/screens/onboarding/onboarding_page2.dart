import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../../../core/widgets/amazon_widgets.dart';

class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2>
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
                              Icons.search,
                              color: CorralXTheme.primarySolid,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Búsqueda Inteligente',
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
                          'Encuentra exactamente lo que buscas',
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
                          'Filtros Avanzados',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Búsqueda por ubicación, raza, precio y más',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Utiliza filtros avanzados, búsqueda por ubicación, raza, precio y más. Nuestro algoritmo te ayuda a encontrar las mejores opciones.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tipos de filtros disponibles
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
                                      Icons.filter_list,
                                      color: CorralXTheme.secondarySolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Filtros',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '15+ Opciones',
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
                                      Icons.location_on,
                                      color: CorralXTheme.successSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ubicación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.successSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'GPS',
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
                                      Icons.psychology,
                                      color: CorralXTheme.accentSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'IA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Smart',
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

                // Características de búsqueda
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
                                'Características de búsqueda',
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
                          title: 'Filtros Avanzados',
                          subtitle:
                              'Búsqueda por múltiples criterios simultáneos',
                          icon: Icons.tune,
                          trailing: 'Multi',
                        ),
                        AmazonListItem(
                          title: 'Búsqueda por Ubicación',
                          subtitle: 'Encuentra ganado cerca de tu ubicación',
                          icon: Icons.my_location,
                          trailing: 'GPS',
                        ),
                        AmazonListItem(
                          title: 'Recomendaciones IA',
                          subtitle:
                              'Algoritmo inteligente que aprende de tus preferencias',
                          icon: Icons.auto_awesome,
                          trailing: 'Smart',
                        ),
                        AmazonListItem(
                          title: 'Búsqueda por Voz',
                          subtitle: 'Busca ganado usando comandos de voz',
                          icon: Icons.mic,
                          trailing: 'Voice',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Ejemplos de búsqueda
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
                          'Búsquedas Populares',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Las búsquedas más realizadas por nuestros usuarios',
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
                                title: 'Holstein Frison',
                                description:
                                    'Vacas lecheras de alta producción',
                                price: 'Desde \$3,200',
                                rating: '4.8',
                                reviews: '234',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Angus Negro',
                                description: 'Ganado de carne premium',
                                price: 'Desde \$4,500',
                                rating: '4.9',
                                reviews: '189',
                                accentColor: CorralXTheme.secondarySolid,
                                icon: Icons.trending_up,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AmazonFeature(
                                title: 'Brahman',
                                description: 'Ganado resistente al calor',
                                price: 'Desde \$2,800',
                                rating: '4.7',
                                reviews: '156',
                                accentColor: CorralXTheme.accentSolid,
                                icon: Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Limousin',
                                description: 'Excelente conversión alimenticia',
                                price: 'Desde \$3,800',
                                rating: '4.6',
                                reviews: '98',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.trending_up,
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
                          Icons.search,
                          size: 16,
                          color: CorralXTheme.secondarySolid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Más de 10,000 búsquedas realizadas diariamente',
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
