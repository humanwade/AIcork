import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/controllers/cellar_controller.dart';
import '../../../domain/models/tried_wine_entry.dart';

class TriedWineDetailScreen extends ConsumerWidget {
  const TriedWineDetailScreen({
    super.key,
    required this.entry,
  });

  final TriedWineEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasted = entry.tastedAt;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text('Tasting'),
        actions: [
          IconButton(
            tooltip: 'Remove',
            onPressed: () async {
              await ref.read(cellarControllerProvider.notifier).removeTried(entry.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          children: [
            Text(entry.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              entry.type.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ...List.generate(5, (i) {
                  final idx = i + 1;
                  final filled = entry.rating >= idx;
                  final half = !filled && entry.rating >= (idx - 0.5);
                  return Icon(
                    filled
                        ? Icons.star_rounded
                        : (half
                            ? Icons.star_half_rounded
                            : Icons.star_border_rounded),
                    size: 22,
                    color: const Color(0xFFC08B5C),
                  );
                }),
                const SizedBox(width: 10),
                Text(
                  entry.rating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C4A3F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (tasted != null) ...[
              Text('Date', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '${tasted.year}-${tasted.month.toString().padLeft(2, '0')}-${tasted.day.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (entry.flavorTags.isNotEmpty) ...[
              Text('Flavors', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.flavorTags
                    .map((t) => _TagChip(text: t))
                    .toList(),
              ),
              const SizedBox(height: 18),
            ],
            if (entry.aromaTags.isNotEmpty) ...[
              Text('Aromas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.aromaTags
                    .map((t) => _TagChip(text: t))
                    .toList(),
              ),
              const SizedBox(height: 18),
            ],
            if (entry.styleTags.isNotEmpty) ...[
              Text('Body & style', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.styleTags
                    .map((t) => _TagChip(text: t))
                    .toList(),
              ),
              const SizedBox(height: 18),
            ],
            if (entry.customNotes.trim().isNotEmpty) ...[
              Text('Notes', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                entry.customNotes,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 18),
            ],
            if ((entry.revisitNotes ?? '').trim().isNotEmpty) ...[
              Text('Purchase / Revisit notes', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                entry.revisitNotes!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3D9CF)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5C4A3F),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

