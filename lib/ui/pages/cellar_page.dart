import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/cellar/domain/controllers/cellar_controller.dart'
    show
        cellarControllerProvider,
        cellarInsightsProvider,
        cellarNavigateToTabProvider;
import '../../features/cellar/domain/models/cellar_wine.dart';
import '../../features/cellar/presentation/widgets/taste_profile_insights_card.dart';
import '../../features/cellar/domain/models/tried_wine_entry.dart';
import '../../features/cellar/domain/models/wine_type.dart';
import '../../features/cellar/presentation/screens/forms/add_cellar_wine_screen.dart';
import '../../features/cellar/presentation/widgets/mark_as_tried_sheet.dart';

class CellarPage extends ConsumerStatefulWidget {
  const CellarPage({super.key});

  static const String routePath = '/cellar';
  static const String routeName = 'cellar';

  @override
  ConsumerState<CellarPage> createState() => _CellarPageState();
}

class _CellarPageState extends ConsumerState<CellarPage>
    with SingleTickerProviderStateMixin {
  WineType? _wantsFilter;
  WineType? _triedFilter;
  String _triedQuery = '';
  late final TextEditingController _triedSearchController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _triedSearchController = TextEditingController(text: _triedQuery);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _triedSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);

    debugPrint(
        'CellarPage: opening My Cellar. Authenticated=${auth.isAuthenticated}');

    // If not authenticated, show an auth-required empty state and avoid
    // triggering cellar API calls.
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 24,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Cellar', style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Your personal wine wishlist and history',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.brown.shade300,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 42,
                  color: Color(0xFFB9A18A),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please sign in to view your cellar.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to keep your Wants and Tried history in sync across devices.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  child: FilledButton(
                    onPressed: () {
                      context.push(LoginScreen.routePath);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C4A3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final state = ref.watch(cellarControllerProvider);
    ref.listen<int?>(cellarNavigateToTabProvider, (prev, next) {
      if (next != null && next >= 0 && next <= 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tabController.animateTo(next);
            ref.read(cellarNavigateToTabProvider.notifier).state = null;
          }
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            debugPrint('Cellar load error: $e');
            return const _EmptyMessage(
              title: 'Your cellar is resting',
              message:
                  'We could not load your cellar right now. Try again in a moment.',
            );
          },
          data: (cellar) {
            final wants = _applyWineTypeFilter(cellar.wants, _wantsFilter);
            final tried = _applyTried(
              cellar.tried,
              filter: _triedFilter,
              query: _triedQuery,
            );
            final insightsAsync = ref.watch(cellarInsightsProvider);

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Cellar',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wants and tasting history',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.brown.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: insightsAsync.when(
                      data: (insights) =>
                          TasteProfileInsightsCard(insights: insights),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarSliverDelegate(
                      tabBar: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.hintColor,
                        indicatorColor: theme.colorScheme.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: 'Wants'),
                          Tab(text: 'Tried'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _WantsTab(
                    entries: wants,
                    selectedFilter: _wantsFilter,
                    onFilterChanged: (t) =>
                        setState(() => _wantsFilter = t),
                    onMarkAsTried: (w) =>
                        showMarkAsTriedSheet(context, ref, want: w),
                  ),
                  _TriedTab(
                    entries: tried,
                    searchController: _triedSearchController,
                    selectedFilter: _triedFilter,
                    onFilterChanged: (t) =>
                        setState(() => _triedFilter = t),
                    onQueryChanged: (q) =>
                        setState(() => _triedQuery = q),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context) async {
    debugPrint('CellarPage: plus button tapped, showing add menu');
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.favorite_border_rounded),
                title: const Text('Add to Wants'),
                subtitle: const Text('A bottle you want to buy'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push(
                    '/cellar/add',
                    extra: const AddCellarArgs(target: AddCellarTarget.wants),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_border_rounded),
                title: const Text('Add to Tried'),
                subtitle: const Text('Log a tasting with rating & tags'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/cellar/add-tried');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<CellarWine> _applyWineTypeFilter(List<CellarWine> list, WineType? type) {
    if (type == null) return list;
    return list.where((w) => w.type == type).toList();
  }

  List<TriedWineEntry> _applyTried(
    List<TriedWineEntry> list, {
    required WineType? filter,
    required String query,
  }) {
    Iterable<TriedWineEntry> out = list;
    if (filter != null) {
      out = out.where((t) => t.type == filter);
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return out.toList();

    final tokens = _expandQueryTokens(q);
    return out.where((t) {
      final haystack = [
        t.title,
        t.customNotes,
        ...t.flavorTags,
        ...t.styleTags,
      ].join(' ').toLowerCase();
      return tokens.any((tok) => haystack.contains(tok));
    }).toList();
  }

  Set<String> _expandQueryTokens(String q) {
    final base = q
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final out = {...base};

    const synonyms = {
      'chocolate': ['cocoa', 'dark chocolate'],
      'cocoa': ['chocolate', 'dark chocolate'],
      'dark': ['dark chocolate'],
    };
    for (final b in base) {
      final s = synonyms[b];
      if (s != null) out.addAll(s);
    }
    if (q.contains('dark chocolate')) {
      out.add('chocolate');
      out.add('cocoa');
    }
    return out;
  }

  // Mark-as-tried UI lives in a shared sheet widget now.
}

class _WantsTab extends ConsumerWidget {
  const _WantsTab({
    required this.entries,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onMarkAsTried,
  });
  final List<CellarWine> entries;
  final WineType? selectedFilter;
  final ValueChanged<WineType?> onFilterChanged;
  final ValueChanged<CellarWine> onMarkAsTried;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 72;
    return CustomScrollView(
      key: const PageStorageKey<String>('wants'),
      slivers: [
        SliverToBoxAdapter(
          child: _TypeFilterChips(
            selected: selectedFilter,
            onChanged: onFilterChanged,
          ),
        ),
        if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: false,
            child: Center(
              child: _EmptyMessage(
                title: 'No saved wines yet',
                message:
                    'Save wines from recommendations or tap + to add one.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final w = entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _CellarWineCard(
                      wine: w,
                      trailing: const SizedBox.shrink(),
                      onTap: () =>
                          context.push('/cellar/want-detail', extra: w),
                    ),
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),
      ],
    );
  }
}
 

class _TriedTab extends ConsumerWidget {
  const _TriedTab({
    required this.entries,
    required this.searchController,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onQueryChanged,
  });
  final List<TriedWineEntry> entries;
  final TextEditingController searchController;
  final WineType? selectedFilter;
  final ValueChanged<WineType?> onFilterChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 72;
    return CustomScrollView(
      key: const PageStorageKey<String>('tried'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: searchController,
              onChanged: onQueryChanged,
              decoration: const InputDecoration(
                labelText: 'Search Tried',
                hintText: 'e.g. chocolate, crisp, cherry',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _TypeFilterChips(
            selected: selectedFilter,
            onChanged: onFilterChanged,
          ),
        ),
        if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: false,
            child: Center(
              child: _EmptyMessage(
                title: 'No tastings yet',
                message:
                    'Tap + and log a wine you tried with quick tags and a rating.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final t = entries[index];
                  final hasImage =
                      (t.imageUrl ?? '').trim().isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () =>
                            context.push('/cellar/tried-detail', extra: t),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 56,
                                  height: 72,
                                  color: const Color(0xFFF0E9E2),
                                  child: hasImage
                                      ? CachedNetworkImage(
                                          imageUrl: t.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, _) =>
                                              const Center(
                                            child: Icon(
                                              Icons.wine_bar_outlined,
                                              color: Color(0xFFB9A18A),
                                            ),
                                          ),
                                          errorWidget:
                                              (context, _, __) =>
                                                  const Center(
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
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t.type.label +
                                          (t.price != null && t.price! > 0
                                              ? ' · \$${t.price!.toStringAsFixed(0)}'
                                              : ''),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) {
                                          final filled =
                                              (i + 1) <= t.rating.round();
                                          return Icon(
                                            filled
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 18,
                                            color: const Color(0xFFC08B5C),
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        Text(
                                          t.rating.toStringAsFixed(1),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF5C4A3F),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (t.customNotes.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        t.customNotes,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pinned header: Wants / Tried tab row only. Filters and search scroll with content.
class _TabBarSliverDelegate extends SliverPersistentHeaderDelegate {
  _TabBarSliverDelegate({required this.tabBar});
  final TabBar tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(alignment: Alignment.centerLeft, child: tabBar),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _TypeFilterChips extends StatelessWidget {
  const _TypeFilterChips({
    required this.selected,
    required this.onChanged,
  });

  final WineType? selected;
  final ValueChanged<WineType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <WineType?>[null, ...WineType.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: options.map((t) {
          final isOn = selected == t;
          final label = t == null ? 'All' : t.label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isOn,
              onSelected: (_) => onChanged(isOn ? null : t),
              selectedColor: const Color(0xFFF1ECE7),
              checkmarkColor: const Color(0xFF5C4A3F),
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                color: isOn ? const Color(0xFF5C4A3F) : Colors.grey.shade800,
                fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
              ),
              side: const BorderSide(color: Color(0xFFE3D9CF)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CellarWineCard extends StatelessWidget {
  const _CellarWineCard({
    required this.wine,
    required this.onTap,
    required this.trailing,
  });

  final CellarWine wine;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = (wine.imageUrl ?? '').trim().isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 70,
                  height: 90,
                  color: const Color(0xFFF0E9E2),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: wine.imageUrl!,
                          fit: BoxFit.cover,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            wine.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 10),
                        trailing,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        wine.type.label,
                        if (wine.price != null) '\$${wine.price!.toStringAsFixed(2)}',
                        if ((wine.sku ?? '').isNotEmpty) 'SKU ${wine.sku}',
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((wine.tastingNotes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        wine.tastingNotes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
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

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
