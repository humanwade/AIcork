import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/discover/data/models/discover_collection.dart';
import '../../features/discover/domain/models/learn_wine_article.dart';
import '../../features/discover/presentation/providers/discover_providers.dart';
import '../../features/discover/presentation/screens/discover_collection_screen.dart';
import '../../features/wine_recommendation/data/models/wine_recommendation.dart';
import '../../features/wine_recommendation/domain/entities/wine_entity.dart';
import '../../features/wine_recommendation/presentation/widgets/wine_card.dart';

/// Static style chips for Explore Styles section.
/// Maps display labels to backend collection slugs.
const _exploreStyles = [
  (label: 'Bold Reds', slug: 'steak-night-reds'),
  (label: 'Crisp Whites', slug: 'crisp-whites'),
  (label: 'Rosé', slug: 'summer-rose'),
  (label: 'Sparkling', slug: 'sparkling-picks'),
  (label: 'Light & Fresh', slug: 'pasta-pairings'),
];

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  static const routePath = '/discover';
  static const routeName = 'discover';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final forYouAsync = ref.watch(discoverForYouProvider);
    final budgetAsync = ref.watch(discoverBudgetProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discover', style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Curated bottles and ideas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.brown.shade300,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(discoverForYouProvider);
            ref.invalidate(discoverBudgetProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
            children: [
              _buildForYouSection(context, theme, forYouAsync),
              const SizedBox(height: 24),
              _buildExploreStylesSection(context, theme),
              const SizedBox(height: 24),
              _buildBudgetSection(context, theme, budgetAsync),
              const SizedBox(height: 24),
              _buildLearnWineSection(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildForYouSection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<WineRecommendationModel>> asyncModels,
  ) {
    return asyncModels.when(
      data: (models) {
        if (models.isEmpty) {
          return _ForYouEmptyState();
        }
        final items = models.take(4).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'For You',
              subtitle: 'Based on your tasting history',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final wine = items[index].toEntity();
                  return SizedBox(
                    width: 276,
                    child: _ForYouWineCard(
                      wine: wine,
                      onTap: () {
                        context.push('/home/results/detail', extra: wine);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => _ForYouEmptyState(),
      error: (_, __) => _ForYouEmptyState(),
    );
  }

  Widget _buildExploreStylesSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Explore Styles',
          subtitle: 'Browse wines by style',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _exploreStyles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final style = _exploreStyles[index];
              final collection = DiscoverCollection(
                slug: style.slug,
                title: style.label,
                subtitle: '',
              );
              return ActionChip(
                label: Text(style.label),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DiscoverCollectionScreen(collection: collection),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<WineRecommendationModel>> asyncModels,
  ) {
    return asyncModels.when(
      data: (models) {
        if (models.isEmpty) return const SizedBox.shrink();
        final items = models.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Budget Picks',
              subtitle: 'Good bottles under \$20',
            ),
            const SizedBox(height: 12),
            ...items.map(
              (m) {
                final wine = m.toEntity();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WineCard(
                    wine: wine,
                    onTap: () {
                      context.push('/home/results/detail', extra: wine);
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLearnWineSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Learn Wine',
          subtitle: 'Short tips for curious drinkers',
        ),
        const SizedBox(height: 12),
        ...LearnWineArticle.all.map(
          (article) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LearnCard(
              article: article,
              onTap: () {
                context.push('/discover/learn', extra: article);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty state when user has insufficient tasting history for For You.
class _ForYouEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
              'For You',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalized picks will appear here once you have enough tasting history.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try and rate a few wines in My Cellar to unlock recommendations.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({
    required this.article,
    required this.onTap,
  });

  final LearnWineArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                article.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForYouWineCard extends StatelessWidget {
  const _ForYouWineCard({
    required this.wine,
    required this.onTap,
  });

  final WineEntity wine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = wine.thumbnailUrl != null && wine.thumbnailUrl!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 62,
                  height: 82,
                  child: hasImage
                      ? Image.network(
                          wine.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFF0E9E2),
                            child: Icon(
                              Icons.wine_bar_outlined,
                              color: Color(0xFFB9A18A),
                            ),
                          ),
                        )
                      : const ColoredBox(
                          color: Color(0xFFF0E9E2),
                          child: Icon(
                            Icons.wine_bar_outlined,
                            color: Color(0xFFB9A18A),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wine.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${wine.price.toStringAsFixed(2)}${wine.sku.isNotEmpty ? ' • SKU ${wine.sku}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if ((wine.tastingNotes ?? '').trim().isNotEmpty)
                      Text(
                        wine.tastingNotes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade800,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
