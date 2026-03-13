import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/wine_entity.dart';
import '../widgets/wine_detail_sections.dart';
import '../../../cellar/domain/controllers/cellar_controller.dart';
import '../../../discover/presentation/providers/discover_providers.dart';
import '../../data/models/wine_recommendation.dart';
import '../../presentation/providers/recommendation_providers.dart';

class WineDetailScreen extends ConsumerStatefulWidget {
  const WineDetailScreen({
    super.key,
    required this.wine,
  });

  static const String routePath = '/detail';
  static const String routeName = 'detail';

  final WineEntity wine;

  @override
  ConsumerState<WineDetailScreen> createState() => _WineDetailScreenState();
}

class _SimilarWine {
  final WineEntity wine;
  final String? reason;

  const _SimilarWine({required this.wine, this.reason});
}

class _WineDetailScreenState extends ConsumerState<WineDetailScreen> {
  late final TextEditingController _wineryController;
  late final TextEditingController _nameController;
  late final TextEditingController _vintageController;

  bool _savingCustom = false;
  bool _saveAsTried = false;
  double _rating = 4.0;

  bool _loadingSimilar = false;
  List<_SimilarWine> _similar = const [];

  WineEntity get wine => widget.wine;

  String _inferStyleFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('rosé') || lower.contains('rose')) return 'Rosé';
    if (lower.contains('sparkling') ||
        lower.contains('prosecco') ||
        lower.contains('cava')) return 'Sparkling';
    if (lower.contains('white')) return 'White';
    if (lower.contains('red')) return 'Red';
    return '';
  }

  @override
  void initState() {
    super.initState();
    _wineryController = TextEditingController(text: wine.recognizedWinery ?? '');
    _nameController =
        TextEditingController(text: wine.recognizedWineName ?? '');
    _vintageController =
        TextEditingController(text: wine.recognizedVintage ?? '');
    _loadSimilar();
  }

  @override
  void dispose() {
    _wineryController.dispose();
    _nameController.dispose();
    _vintageController.dispose();
    super.dispose();
  }

  Future<void> _loadSimilar() async {
    // Only attempt similar lookup when we have a real SKU from the DB.
    if (wine.sku.trim().isEmpty || wine.matchedDb == false) {
      return;
    }
    if (_loadingSimilar) return;
    setState(() => _loadingSimilar = true);

    try {
      final api = ref.read(wineApiServiceProvider);
      final models = await api.fetchSimilar(wine.sku);
      final items = models
          .where((m) => m.sku != wine.sku)
          .map(
            (m) => _SimilarWine(
              wine: m.toEntity(),
              reason: m.similarityReason,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _similar = items;
        _loadingSimilar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _similar = const [];
        _loadingSimilar = false;
      });
    }
  }

  Future<void> _openInventory(BuildContext context) async {
    final title = wine.title.trim();
    if (title.isEmpty) {
      // No safe way to build a search link without a name.
      return;
    }

    // Prefer explicit inventoryUrl from the backend if present.
    Uri? uri;
    if (wine.inventoryUrl != null && wine.inventoryUrl!.isNotEmpty) {
      uri = Uri.tryParse(wine.inventoryUrl!);
    }

    if (uri == null) {
      final query = Uri.encodeComponent(title);
      final url = 'https://www.lcbo.com/en/search?text=$query';
      uri = Uri.parse(url);
      debugPrint(
          'WineDetailScreen._openInventory: built LCBO search URL=$url for "$title"');
    }

    if (!uri.isScheme('https')) {
      debugPrint(
          'WineDetailScreen._openInventory: non-https URL detected: $uri');
    }

    if (!await canLaunchUrl(uri)) {
      final query = Uri.encodeComponent(title);
      debugPrint(
          'WineDetailScreen._openInventory: cannot launch URL=$uri, wine="$title", encodedQuery=$query');
      _showSnack(context, 'Could not open LCBO.com');
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('WineDetailScreen._openInventory: launch error: $e');
      _showSnack(context, 'Unable to open browser right now.');
    }
  }

  void _copySku(BuildContext context) {
    Clipboard.setData(ClipboardData(text: wine.sku));
    _showSnack(context, 'SKU copied');
  }

  Future<void> _saveCustomToCellar() async {
    if (_savingCustom) return;
    setState(() => _savingCustom = true);

    final editedWinery = _wineryController.text.trim();
    final editedName = _nameController.text.trim();
    final editedVintage = _vintageController.text.trim();

    debugPrint(
        'Saving user-confirmed custom wine to cellar (isTried=$_saveAsTried)');

    try {
      await ref.read(cellarControllerProvider.notifier).addCustomFromScan(
            recognizedName: wine.recognizedWineName,
            recognizedWinery: wine.recognizedWinery,
            recognizedVintage: wine.recognizedVintage,
            editedName: editedName.isEmpty ? null : editedName,
            editedWinery: editedWinery.isEmpty ? null : editedWinery,
            editedVintage: editedVintage.isEmpty ? null : editedVintage,
            isTried: _saveAsTried,
            rating: _saveAsTried ? _rating : null,
            tastingNotes: null,
            imageUrl: wine.thumbnailUrl,
          );
      if (!mounted) return;
      if (_saveAsTried) {
        ref.invalidate(cellarInsightsProvider);
        ref.invalidate(discoverForYouProvider);
      }
      _showSnack(context, 'Saved to My Cellar.');
      Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('WineDetailScreen: save custom error: $e');
      if (!mounted) return;
      _showSnack(context, 'We could not save this wine. Please try again.');
    } finally {
      if (mounted) setState(() => _savingCustom = false);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = wine.thumbnailUrl != null && wine.thumbnailUrl!.isNotEmpty;
    final isDbBacked = wine.matchedDb == true;
    final typeLabel = (wine.wineType ?? '').trim();
    final isSaved = ref
            .watch(cellarControllerProvider)
            .valueOrNull
            ?.wants
            .any((w) => w.sku == wine.sku) ??
        false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(
          wine.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: isDbBacked
            ? [
                IconButton(
                  onPressed: () async {
                    debugPrint(
                        'WineDetailScreen: app bar heart tapped for sku=${wine.sku}');
                    try {
                      await ref
                          .read(cellarControllerProvider.notifier)
                          .toggleWantFromRecommendation(wine);
                    } catch (e) {
                      debugPrint(
                          'WineDetailScreen: toggleWantFromRecommendation error: $e');
                      _showSnack(context,
                          'We could not update your cellar. Please try again.');
                    }
                  },
                  icon: Icon(
                    isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isSaved
                        ? const Color(0xFFC08B5C)
                        : Colors.grey.shade700,
                  ),
                  tooltip: isSaved ? 'Saved to Wants' : 'Save to Wants',
                ),
                const SizedBox(width: 8),
              ]
            : [const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: Colors.white,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: wine.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => Container(
                            color: const Color(0xFFF0E9E2),
                            child: const Center(
                              child: Icon(
                                Icons.wine_bar_outlined,
                                size: 40,
                                color: Color(0xFFB9A18A),
                              ),
                            ),
                          ),
                          errorWidget: (context, _, __) => Container(
                            color: const Color(0xFFF0E9E2),
                            child: const Center(
                              child: Icon(
                                Icons.wine_bar_outlined,
                                size: 40,
                                color: Color(0xFFB9A18A),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0E9E2),
                          child: const Center(
                            child: Icon(
                              Icons.wine_bar_outlined,
                              size: 40,
                              color: Color(0xFFB9A18A),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              wine.title,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (isDbBacked)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    debugPrint(
                        'WineDetailScreen: Save to Wants tapped for sku=${wine.sku}');
                    try {
                      await ref
                          .read(cellarControllerProvider.notifier)
                          .toggleWantFromRecommendation(wine);
                      _showSnack(
                        context,
                        isSaved
                            ? 'Removed from your Wants.'
                            : 'Added to your Wants.',
                      );
                    } catch (e) {
                      debugPrint(
                          'WineDetailScreen: toggleWantFromRecommendation error: $e');
                      _showSnack(context,
                          'We could not update your cellar. Please try again.');
                    }
                  },
                  icon: Icon(
                    isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                  ),
                  label: Text(isSaved ? 'Saved to Wants' : 'Save to Wants'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5C4A3F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1EC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3D9CF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "We couldn't find a perfect match in our database, but our AI identified this wine.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _wineryController,
                      decoration: const InputDecoration(
                        labelText: 'Winery / Producer',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Wine name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _vintageController,
                      decoration: const InputDecoration(
                        labelText: 'Vintage',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mark as tried'),
                      value: _saveAsTried,
                      onChanged: (v) => setState(() => _saveAsTried = v),
                    ),
                    if (_saveAsTried) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Rating'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              min: 0,
                              max: 5,
                              divisions: 10,
                              value: _rating,
                              label: _rating.toStringAsFixed(1),
                              onChanged: (v) => setState(() => _rating = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _savingCustom ? null : _saveCustomToCellar,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5C4A3F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(_savingCustom
                            ? 'Saving...'
                            : 'Confirm & Save to My Cellar'),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            if (isDbBacked)
              Row(
                children: [
                  Text(
                    typeLabel.isNotEmpty
                        ? '$typeLabel • \$${wine.price.toStringAsFixed(2)}'
                        : '\$${wine.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF5C4A3F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: const Color(0xFFF1ECE7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SKU',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7D6B5D),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          wine.sku,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: Color(0xFF5C4A3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Copy SKU',
                    onPressed: () => _copySku(context),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            WineDetailSections(
              tastingNotes: wine.tastingNotes,
              sommelierNote: wine.sommelierNote,
            ),
            const SizedBox(height: 20),
            if (_loadingSimilar) ...[
              Text(
                'Similar wines',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Finding similar bottles...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
            ] else if (_similar.isNotEmpty) ...[
              Text(
                'Similar wines',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._similar.take(5).map(
                (item) {
                  final w = item.wine;
                  final hasThumb =
                      (w.thumbnailUrl ?? '').trim().isNotEmpty;
                  final explicitType = (w.wineType ?? '').trim();
                  final styleHint = explicitType.isNotEmpty
                      ? explicitType
                      : _inferStyleFromTitle(w.title);
                  final topLine = styleHint.isNotEmpty
                      ? '$styleHint • \$${w.price.toStringAsFixed(2)}'
                      : '\$${w.price.toStringAsFixed(2)}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WineDetailScreen(wine: w),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 54,
                                height: 72,
                                color: const Color(0xFFF0E9E2),
                                child: hasThumb
                                    ? CachedNetworkImage(
                                        imageUrl: w.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, _) =>
                                            const Center(
                                          child: Icon(
                                            Icons.wine_bar_outlined,
                                            color: Color(0xFFB9A18A),
                                          ),
                                        ),
                                        errorWidget: (context, _, __) =>
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    topLine,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if ((item.reason ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.reason!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.grey.shade600,
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
                },
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            if (isDbBacked) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: wine.title.trim().isEmpty
                      ? null
                      : () => _openInventory(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'View on LCBO.com',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inventory and pricing are provided by LCBO. We do not store or cache inventory data.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

