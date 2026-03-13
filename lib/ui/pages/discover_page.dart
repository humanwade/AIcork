import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/discover/presentation/providers/discover_providers.dart';
import '../../features/discover/data/models/discover_collection.dart';
import '../../features/discover/presentation/screens/discover_collection_screen.dart';
import '../../features/wine_recommendation/data/models/wine_recommendation.dart';
import '../../features/wine_recommendation/domain/entities/wine_entity.dart';
import '../../features/wine_recommendation/presentation/widgets/wine_card.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  static const routePath = '/discover';
  static const routeName = 'discover';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dailyAsync = ref.watch(discoverDailyProvider);
    final collectionsAsync = ref.watch(discoverCollectionsProvider);
    final recommendedAsync = ref.watch(discoverRecommendedProvider);
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
            ref.invalidate(discoverDailyProvider);
            ref.invalidate(discoverCollectionsProvider);
            ref.invalidate(discoverRecommendedProvider);
            ref.invalidate(discoverBudgetProvider);
          },
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1) Today's Picks
              _buildDailySection(context, theme, dailyAsync),
              const SizedBox(height: 24),

              // 2) Recommended for You
              _buildRecommendedSection(context, theme, recommendedAsync),
              const SizedBox(height: 24),

              // 3) Collections
              _buildCollectionsSection(context, theme, collectionsAsync),
              const SizedBox(height: 24),

              // 4) Best Under $20
              _buildBudgetSection(context, theme, budgetAsync),
              const SizedBox(height: 24),

              // 5) Optional Learn Wine (lightweight, static)
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

  Widget _buildDailySection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<WineRecommendationModel>> asyncModels,
  ) {
    return asyncModels.when(
      data: (models) {
        if (models.isEmpty) return const SizedBox.shrink();
        final items = models.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Today\'s Picks',
              subtitle: 'Three bottles to consider tonight',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final m = items[index];
                  return SizedBox(
                    width: 190,
                    child: _DiscoverWineCard(model: m),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Today\'s Picks',
          ),
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecommendedSection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<WineRecommendationModel>> asyncModels,
  ) {
    return asyncModels.when(
      data: (models) {
        if (models.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = models.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Recommended for You',
              subtitle: 'Based on your tasting history',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final m = items[index];
                  return SizedBox(
                    width: 190,
                    child: _DiscoverWineCard(model: m),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCollectionsSection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<DiscoverCollection>> asyncCollections,
  ) {
    return asyncCollections.when(
      data: (collections) {
        if (collections.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Collections',
              subtitle: 'Browse themed groups of wines',
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: collections.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.7,
              ),
              itemBuilder: (context, index) {
                final c = collections[index];
                return _CollectionCard(collection: c);
              },
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Collections'),
          const SizedBox(height: 8),
        ],
      ),
      error: (e, _) => const SizedBox.shrink(),
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
        final items = models.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Best Under \$20',
              subtitle: 'Good bottles that won\'t break the budget',
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
                      Navigator.of(context).pushNamed(
                        '/home/results/detail',
                        arguments: wine,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildLearnWineSection(BuildContext context, ThemeData theme) {
    final cards = [
      const _LearnCard(
        title: 'What is tannin?',
        subtitle: 'Understand structure and grip in red wines.',
      ),
      const _LearnCard(
        title: 'Red vs white basics',
        subtitle: 'Simple rules for pairing at the table.',
      ),
      const _LearnCard(
        title: 'Shopping at LCBO',
        subtitle: 'Tips for choosing a bottle with confidence.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Learn Wine',
          subtitle: 'Short tips for curious drinkers',
        ),
        const SizedBox(height: 12),
        ...cards.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: c,
          ),
        ),
      ],
    );
  }
}

class _DiscoverWineCard extends StatelessWidget {
  const _DiscoverWineCard({required this.model});

  final WineRecommendationModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wine = model.toEntity();
    final typeLabel = (wine.wineType ?? '').trim();
    final reason = model.similarityReason ?? '';
    final hasImage =
        wine.thumbnailUrl != null && wine.thumbnailUrl!.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).pushNamed(
          '/home/results/detail',
          arguments: wine,
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: const Color(0xFFF0E9E2),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: wine.thumbnailUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, _) => const Center(
                            child: Icon(
                              Icons.wine_bar_outlined,
                              color: Color(0xFFB9A18A),
                            ),
                          ),
                          errorWidget: (context, _, __) => const Center(
                            child: Icon(
                              Icons.wine_bar_outlined,
                              color: Color(0xFFB9A18A),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.wine_bar_outlined,
                            color: Color(0xFFB9A18A),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                wine.title,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (typeLabel.isNotEmpty) typeLabel,
                  '\$${wine.price.toStringAsFixed(2)}',
                ].join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.brown.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection});

  final DiscoverCollection collection;

  IconData _iconForSlug(String slug) {
    switch (slug) {
      case 'steak-night-reds':
        return Icons.dinner_dining_rounded;
      case 'under-20':
        return Icons.attach_money_rounded;
      case 'crisp-whites':
        return Icons.wb_sunny_rounded;
      case 'pasta-pairings':
        return Icons.restaurant_rounded;
      case 'summer-rose':
        return Icons.local_florist_rounded;
      case 'sparkling-picks':
        return Icons.local_bar_rounded;
      default:
        return Icons.local_drink_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DiscoverCollectionScreen(collection: collection),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF0E9E2),
                child: Icon(
                  _iconForSlug(collection.slug),
                  size: 18,
                  color: const Color(0xFFB58A63),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                collection.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                collection.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

