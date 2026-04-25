import 'package:flutter/material.dart';

import '../../../data/datasources/cellar_api_service.dart';

class TasteProfileDetailScreen extends StatelessWidget {
  const TasteProfileDetailScreen({
    super.key,
    required this.insights,
  });

  final CellarInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = <String>[
      ...insights.preferredWineTypes,
      ...insights.preferredFlavors,
      ...insights.preferredBodyStyles,
      if (insights.averagePreferredPrice != null)
        '\$${(insights.averagePreferredPrice! * 0.8).round()}–\$${(insights.averagePreferredPrice! * 1.2).round()}',
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('Taste Profile', style: theme.textTheme.titleLarge),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Taste Profile',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                (insights.summaryText ?? '').trim().isEmpty
                    ? 'Taste profile will appear after rating a few wines.'
                    : insights.summaryText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade800,
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Tags',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .toSet()
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
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
    );
  }
}
