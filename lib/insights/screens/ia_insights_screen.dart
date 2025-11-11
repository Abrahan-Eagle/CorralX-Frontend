import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/user_provider.dart';
import 'package:zonix/insights/models/ia_insight_metric.dart';
import 'package:zonix/insights/models/ia_insight_recommendation.dart';
import 'package:zonix/insights/providers/ia_insights_provider.dart';

class IAInsightsScreen extends StatefulWidget {
  const IAInsightsScreen({super.key});

  @override
  State<IAInsightsScreen> createState() => _IAInsightsScreenState();
}

class _IAInsightsScreenState extends State<IAInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final role =
          userProvider.userRole.isNotEmpty ? userProvider.userRole : 'users';
      context
          .read<IAInsightsProvider>()
          .loadInsights(role: role, forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Insights'),
        actions: [
          IconButton(
            tooltip: '¿Cómo interpretar esta vista?',
            onPressed: _showHelpSheet,
            icon: const Icon(Icons.help_outline),
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer2<IAInsightsProvider, UserProvider>(
          builder: (context, insightsProvider, userProvider, _) {
            final role = userProvider.userRole;

            if (insightsProvider.isLoading && !insightsProvider.hasData) {
              return _buildLoading(theme);
            }

            if (insightsProvider.errorMessage != null &&
                !insightsProvider.hasData) {
              return _buildErrorState(
                context,
                theme,
                insightsProvider.errorMessage!,
                onRetry: () => insightsProvider.loadInsights(
                  role: role.isNotEmpty ? role : 'users',
                  forceRefresh: true,
                ),
              );
            }

            final payload = insightsProvider.payload;
            if (payload == null) {
              return _buildEmptyState(theme);
            }

            final normalizedRole =
                _normalizeRole(payload.role.isNotEmpty ? payload.role : role);
            final roleDefinition = _roleDefinition(normalizedRole);
            final metrics = payload.metrics;
            final projections = payload.projections ?? const [];
            final recommendations = payload.recommendations;

            return RefreshIndicator(
              onRefresh: () => insightsProvider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSummary(
                      headline: payload.summaryHeadline,
                      description: payload.summaryDescription,
                      timeRangeLabel: payload.timeRangeLabel,
                      generatedAt: payload.generatedAt,
                      roleLabel: roleDefinition.badgeLabel,
                      roleDescription: roleDefinition.tagline,
                      roleIcon: roleDefinition.icon,
                    ),
                    const SizedBox(height: 16),
                    _AudienceLegend(
                      currentRole: normalizedRole,
                      definitions: _roleDefinitions(),
                    ),
                    const SizedBox(height: 20),
                    _MetricsGrid(metrics: metrics),
                    if (normalizedRole != _InsightAudience.free &&
                        projections.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _ProjectionsSection(projections: projections),
                    ],
                    const SizedBox(height: 28),
                    _RecommendationsSection(
                      recommendations: recommendations,
                      isPremium: normalizedRole != _InsightAudience.free,
                      onToggle: (recommendation, completed) {
                        insightsProvider.markRecommendationCompleted(
                          recommendation,
                          completed,
                        );
                      },
                    ),
                    if (payload.isMock) ...[
                      const SizedBox(height: 24),
                      _MockInfoBanner(
                        message:
                            'Mostrando datos simulados mientras finalizamos la API de IA Insights.',
                      ),
                    ],
                    if (insightsProvider.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _WarningBanner(
                        message: insightsProvider.errorMessage!,
                        onRetry: () => insightsProvider.refresh(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Preparando tus insights personalizados…',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Sin datos todavía',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactúa con el marketplace para desbloquear tus primeras recomendaciones.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String message, {
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 72,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tus insights',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    required this.headline,
    required this.description,
    required this.timeRangeLabel,
    required this.generatedAt,
    required this.roleLabel,
    required this.roleDescription,
    required this.roleIcon,
  });

  final String headline;
  final String description;
  final String timeRangeLabel;
  final DateTime generatedAt;
  final String roleLabel;
  final String roleDescription;
  final IconData roleIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  roleIcon,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  roleLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  timeRangeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              roleDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(.85),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Actualizado ${_formatRelativeDate(generatedAt)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceLegend extends StatelessWidget {
  const _AudienceLegend({
    required this.currentRole,
    required this.definitions,
  });

  final String currentRole;
  final List<_RoleDefinition> definitions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu nivel en IA Insights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Identifica qué capacidades tienes disponibles y cómo escalar al siguiente nivel.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: definitions.map((definition) {
            final bool isActive = definition.key == currentRole;
            final ColorScheme palette = theme.colorScheme;
            final Color backgroundColor = isActive
                ? palette.primaryContainer
                : palette.surfaceVariant.withOpacity(0.4);
            final Color textColor = isActive
                ? palette.onPrimaryContainer
                : palette.onSurfaceVariant;

            return SizedBox(
              width: (MediaQuery.of(context).size.width - 52) / 2,
              child: Card(
                elevation: isActive ? 2 : 0,
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isActive
                        ? palette.primary.withOpacity(.4)
                        : palette.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            definition.icon,
                            color: isActive
                                ? palette.onPrimaryContainer
                                : palette.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              definition.badgeLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isActive)
                            Icon(
                              Icons.verified,
                              color: palette.onPrimaryContainer,
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        definition.tagline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        definition.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withOpacity(.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<IAInsightMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics.map((metric) {
        final colorScheme = theme.colorScheme;
        final isTrendPositive = metric.trendDirection == 'up';
        final isTrendNegative = metric.trendDirection == 'down';

        final Color indicatorColor = isTrendPositive
            ? colorScheme.primary
            : isTrendNegative
                ? colorScheme.error
                : colorScheme.secondary;

        final IconData indicatorIcon = isTrendPositive
            ? Icons.trending_up
            : isTrendNegative
                ? Icons.trending_down
                : Icons.trending_flat;

        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        indicatorIcon,
                        size: 18,
                        color: indicatorColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          metric.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    metric.displayValue,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (metric.changePercentage != null ||
                      metric.changeLabel != null)
                    Text(
                      _buildChangeLabel(metric),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: indicatorColor,
                      ),
                    ),
                  if (metric.description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      metric.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({
    required this.recommendations,
    required this.onToggle,
    required this.isPremium,
  });

  final List<IAInsightRecommendation> recommendations;
  final bool isPremium;
  final void Function(IAInsightRecommendation recommendation, bool completed)
      onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendaciones de IA',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (!isPremium)
          _UpsellBanner(
            message:
                'Hazte Premium para desbloquear comparativas del marketplace y proyecciones personalizadas.',
          ),
        const SizedBox(height: 12),
        ...recommendations.map((recommendation) {
          final priorityColor = _priorityColor(
            context,
            recommendation.priority,
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: priorityColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recommendation.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      Chip(
                        avatar: Icon(
                          Icons.flag,
                          size: 16,
                          color: priorityColor,
                        ),
                        label: Text(
                          'Prioridad ${recommendation.priority.toUpperCase()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: priorityColor.withOpacity(0.12),
                      ),
                      if (recommendation.segment != null)
                        Chip(
                          avatar: const Icon(
                            Icons.category,
                            size: 16,
                          ),
                          label: Text(
                            recommendation.segment!,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      if (recommendation.impactText != null)
                        Chip(
                          avatar: const Icon(
                            Icons.trending_up,
                            size: 16,
                          ),
                          label: Text(
                            recommendation.impactText!,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => onToggle(
                            recommendation,
                            !recommendation.isCompleted,
                          ),
                          icon: Icon(
                            recommendation.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                          ),
                          label: Text(recommendation.isCompleted
                              ? 'Marcada como realizada'
                              : 'Marcar como realizada'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ProjectionsSection extends StatelessWidget {
  const _ProjectionsSection({required this.projections});

  final List<IAInsightMetric> projections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proyecciones',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...projections.map(
          (projection) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projection.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    projection.displayValue,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (projection.changeLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      projection.changeLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpsellBanner extends StatelessWidget {
  const _UpsellBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockInfoBanner extends StatelessWidget {
  const _MockInfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Reintentar',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _buildChangeLabel(IAInsightMetric metric) {
  final percentage = metric.changePercentage != null
      ? '${metric.changePercentage!.toStringAsFixed(1)}%'
      : null;
  final label = metric.changeLabel;

  if (percentage != null && label != null) {
    return '$percentage · $label';
  } else if (percentage != null) {
    return percentage;
  } else if (label != null) {
    return label;
  }
  return '';
}

Color _priorityColor(BuildContext context, String priority) {
  final palette = Theme.of(context).colorScheme;
  switch (priority.toLowerCase()) {
    case 'high':
      return palette.error;
    case 'low':
      return palette.secondary;
    default:
      return palette.primary;
  }
}

String _normalizeRole(String role) {
  final normalized = role.toLowerCase();
  if (normalized.contains('admin')) return _InsightAudience.admin;
  if (normalized.contains('premium') || normalized.contains('plus')) {
    return _InsightAudience.premium;
  }
  return _InsightAudience.free;
}

String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return 'hace un momento';
  } else if (difference.inMinutes < 60) {
    return 'hace ${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return 'hace ${difference.inHours} h';
  } else {
    return 'el ${date.day}/${date.month}/${date.year}';
  }
}

class _InsightAudience {
  static const free = 'free';
  static const premium = 'premium';
  static const admin = 'admin';
}

class _RoleDefinition {
  const _RoleDefinition({
    required this.key,
    required this.badgeLabel,
    required this.tagline,
    required this.description,
    required this.icon,
  });

  final String key;
  final String badgeLabel;
  final String tagline;
  final String description;
  final IconData icon;
}

_RoleDefinition _roleDefinition(String normalizedRole) {
  switch (normalizedRole) {
    case _InsightAudience.admin:
      return const _RoleDefinition(
        key: _InsightAudience.admin,
        badgeLabel: 'Vista Administrativa',
        tagline: 'Control total del marketplace',
        description:
            'Supervisa métricas globales, campañas y reportes en tiempo real.',
        icon: Icons.admin_panel_settings,
      );
    case _InsightAudience.premium:
      return const _RoleDefinition(
        key: _InsightAudience.premium,
        badgeLabel: 'Insights Premium',
        tagline: 'Optimización comercial avanzada',
        description:
            'Comparativas con el mercado, proyecciones y recomendaciones priorizadas.',
        icon: Icons.workspace_premium,
      );
    default:
      return const _RoleDefinition(
        key: _InsightAudience.free,
        badgeLabel: 'Insights Free',
        tagline: 'Monitorea tu tracción inicial',
        description:
            'Vistas, favoritos y conversaciones clave para tus primeros pasos.',
        icon: Icons.lightbulb_outline,
      );
  }
}

List<_RoleDefinition> _roleDefinitions() => const [
      _RoleDefinition(
        key: _InsightAudience.free,
        badgeLabel: 'Insights Free',
        tagline: 'Monitorea tu tracción inicial',
        description:
            'Vistas, favoritos y conversaciones clave para tus primeros pasos.',
        icon: Icons.lightbulb_outline,
      ),
      _RoleDefinition(
        key: _InsightAudience.premium,
        badgeLabel: 'Insights Premium',
        tagline: 'Optimización comercial avanzada',
        description:
            'Comparativas con el mercado, proyecciones y recomendaciones priorizadas.',
        icon: Icons.workspace_premium,
      ),
      _RoleDefinition(
        key: _InsightAudience.admin,
        badgeLabel: 'Vista Administrativa',
        tagline: 'Control total del marketplace',
        description:
            'Supervisa métricas globales, campañas y reportes en tiempo real.',
        icon: Icons.admin_panel_settings,
      ),
    ];

extension on _IAInsightsScreenState {
  void _showHelpSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ListView(
              children: [
                Text(
                  '¿Cómo interpretar IA Insights?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cada bloque de esta pantalla resume tu desempeño y las acciones sugeridas según tu nivel (Free, Premium o Admin).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _HelpSection(
                  title: 'Resumen y titular',
                  description:
                      'El recuadro superior resume los principales cambios del periodo seleccionado. Muestra el rango de fechas analizado y cuándo se generó la información.',
                ),
                _HelpSection(
                  title: 'Leyenda de niveles',
                  description:
                      'Indica tu nivel actual (Free, Premium o Admin) y qué capacidades tienes habilitadas. Usa esta referencia para saber qué beneficios puedes desbloquear.',
                ),
                _HelpSection(
                  title: 'Métricas clave',
                  description:
                      'Tarjetas con indicadores del periodo (vistas, favoritos, conversaciones, etc.). Observa la tendencia (↑, ↓ o →) para saber si vas mejorando.',
                ),
                _HelpSection(
                  title: 'Proyecciones',
                  description:
                      'Disponible para niveles Premium y Admin. Estima resultados futuros con base en tu actividad reciente. Úsalas para planificar campañas o inventario.',
                ),
                _HelpSection(
                  title: 'Recomendaciones de IA',
                  description:
                      'Acciones concretas priorizadas por impacto. Los chips indican la prioridad (color rojo = urgente, verde/amarillo = secundaria), el segmento afectado y el beneficio estimado (por ejemplo, +28% contactos). Cuando ejecutes la acción, marca la tarjeta como realizada: el estado se envía al backend, se sincroniza con tu cuenta y la IA podrá proponerte la siguiente tarea más relevante en la próxima recarga.',
                ),
                _HelpSection(
                  title: 'Mensajes de alerta',
                  description:
                      'Si ocurre un error al cargar datos o el servicio está en modo mock, verás banners informativos para que sepas el estado real de la información.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
