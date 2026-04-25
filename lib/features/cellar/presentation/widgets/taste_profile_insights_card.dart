import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/cellar_api_service.dart';

/// Compact insights card for My Cellar, showing taste profile summary.
/// Only shown when enough Tried history exists.
class TasteProfileInsightsCard extends StatelessWidget {
  const TasteProfileInsightsCard({
    super.key,
    required this.insights,
  });

  final CellarInsights insights;

  @override
  Widget build(BuildContext context) {
    if (!insights.enoughData) {
      return _TasteProfileEmptyState();
    }

    final theme = Theme.of(context);
    final tags = <String>[
      ...insights.preferredWineTypes.take(2),
      ...insights.preferredFlavors.take(2),
      ...insights.preferredBodyStyles.take(2),
    ];
    if (insights.averagePreferredPrice != null) {
      final low = (insights.averagePreferredPrice! * 0.8).round();
      final high = (insights.averagePreferredPrice! * 1.2).round();
      tags.add('\$$low–\$$high');
    }
    final uniqueTags = tags.toSet().take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/cellar/taste-profile', extra: insights),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Taste Profile',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (insights.summaryText != null &&
                    insights.summaryText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    insights.summaryText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (uniqueTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: uniqueTags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: theme.textTheme.labelSmall,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state when user has insufficient tried/rated wines for taste profile.
class _TasteProfileEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Taste Profile',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Taste profile will appear after rating a few wines.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Try and rate more wines',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF5C4A3F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
