import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wine_entity.dart';
import '../widgets/wine_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cellar/domain/controllers/cellar_controller.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({
    super.key,
    required this.wines,
  });

  static const String routePath = '/results';
  static const String routeName = 'results';

  final List<WineEntity> wines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasResults = wines.isNotEmpty;
    final cellarState = ref.watch(cellarControllerProvider);
    final savedSkus = {
      if (cellarState.valueOrNull != null)
        for (final w in cellarState.valueOrNull!.wants) w.sku,
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text('Recommendations'),
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: hasResults
            ? RefreshIndicator(
                onRefresh: () async {
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                },
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: wines.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    if (index == wines.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 4),
                        child: Center(
                          child: Text(
                            '* AI-based recommendations may not always be accurate.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      );
                    }
                    final wine = wines[index];
                    final isSaved = savedSkus.contains(wine.sku);
                    return WineCard(
                      wine: wine,
                      onTap: () {
                        context.push('/home/results/detail', extra: wine);
                      },
                      trailing: IconButton(
                        onPressed: () async {
                          debugPrint(
                              'ResultsScreen: heart tapped for sku=${wine.sku}');
                          final auth = ref.read(authProvider);
                          if (!auth.isAuthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Sign in is required to save wines.'),
                              ),
                            );
                            return;
                          }
                          try {
                            await ref
                                .read(cellarControllerProvider.notifier)
                                .toggleWantFromRecommendation(wine);
                          } catch (e) {
                            debugPrint(
                                'ResultsScreen: toggleWantFromRecommendation error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sign in is required to save wines.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isSaved
                              ? const Color(0xFFC08B5C)
                              : Colors.grey.shade600,
                        ),
                        tooltip: isSaved ? 'Saved' : 'Save',
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: EmptyState(
                  title: 'No wines found',
                  message:
                      'Try widening your budget or adjusting your query slightly.',
                ),
              ),
      ),
      bottomNavigationBar: !hasResults
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ErrorState.inline(
                message: 'We weren\'t able to find matches this time.',
                onRetry: () => context.pop(),
              ),
            )
          : null,
    );
  }
}

