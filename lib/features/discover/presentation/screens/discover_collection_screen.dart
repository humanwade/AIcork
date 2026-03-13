import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wine_recommendation/domain/entities/wine_entity.dart';
import '../../../wine_recommendation/presentation/widgets/wine_card.dart';
import '../../data/datasources/discover_api_service.dart';
import '../../data/models/discover_collection.dart';

class DiscoverCollectionScreen extends ConsumerStatefulWidget {
  const DiscoverCollectionScreen({
    super.key,
    required this.collection,
  });

  final DiscoverCollection collection;

  @override
  ConsumerState<DiscoverCollectionScreen> createState() =>
      _DiscoverCollectionScreenState();
}

class _DiscoverCollectionScreenState
    extends ConsumerState<DiscoverCollectionScreen> {
  late Future<List<WineEntity>> _future;

  @override
  void initState() {
    super.initState();
    final api = DiscoverApiService.create();
    _future = api.fetchCollection(widget.collection.slug).then(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.collection.title,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            if (widget.collection.subtitle.isNotEmpty)
              Text(
                widget.collection.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.brown.shade300,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<WineEntity>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'We couldn\'t load this collection right now.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade700),
                  ),
                ),
              );
            }
            final wines = snapshot.data ?? const [];
            if (wines.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No wines available for this collection yet.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade700),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: wines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final wine = wines[index];
                return WineCard(
                  wine: wine,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/home/results/detail',
                      arguments: wine,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

