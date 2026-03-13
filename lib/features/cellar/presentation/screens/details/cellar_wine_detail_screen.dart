import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/controllers/cellar_controller.dart';
import '../../../domain/models/cellar_wine.dart';
import '../../widgets/mark_as_tried_sheet.dart';

class CellarWineDetailScreen extends ConsumerWidget {
  const CellarWineDetailScreen({
    super.key,
    required this.wine,
    required this.kindLabel,
    required this.isWant,
  });

  final CellarWine wine;
  final String kindLabel;
  final bool isWant;

  Future<void> _openInventory(BuildContext context) async {
    final url = wine.inventoryUrl;
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasImage = (wine.imageUrl ?? '').trim().isNotEmpty;
    final hasInventory = (wine.inventoryUrl ?? '').trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(
          kindLabel,
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (isWant)
            PopupMenuButton<_WantDetailAction>(
              tooltip: 'Actions',
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _WantDetailAction.markTried,
                  child: Text('Mark as Tried'),
                ),
                PopupMenuItem(
                  value: _WantDetailAction.delete,
                  child: Text('Delete'),
                ),
              ],
              onSelected: (action) async {
                final controller =
                    ref.read(cellarControllerProvider.notifier);
                switch (action) {
                  case _WantDetailAction.markTried:
                    final saved =
                        await showMarkAsTriedSheet(context, ref, want: wine);
                    if (saved == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
                    return;
                  case _WantDetailAction.delete:
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete entry?'),
                        content: const Text(
                          'This will remove this wine from your Wants.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await controller.removeWant(wine.id);
                    if (context.mounted) Navigator.of(context).pop();
                    return;
                }
              },
              icon: const Icon(Icons.more_vert_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: Colors.white,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: wine.imageUrl!,
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
            const SizedBox(height: 8),
            Text(
              [
                wine.type.label,
                if (wine.price != null) '\$${wine.price!.toStringAsFixed(2)}',
                if ((wine.sku ?? '').isNotEmpty) 'SKU ${wine.sku}',
              ].join(' • '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 18),
            if ((wine.tastingNotes ?? '').trim().isNotEmpty) ...[
              Text('Tasting notes', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                wine.tastingNotes!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 18),
            ],
            if ((wine.sommelierNote ?? '').trim().isNotEmpty) ...[
              Text('Sommelier note', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                wine.sommelierNote!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 18),
            ],
            Text('Added', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${wine.addedAt.year}-${wine.addedAt.month.toString().padLeft(2, '0')}-${wine.addedAt.day.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 22),
            // Keep only the LCBO availability button for Wants.
            if (hasInventory)
              FilledButton.icon(
                onPressed: () => _openInventory(context),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: const Text('View on LCBO.com'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5C4A3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _WantDetailAction {
  markTried,
  delete,
}

