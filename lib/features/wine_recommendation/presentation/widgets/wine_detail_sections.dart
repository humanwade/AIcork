import 'package:flutter/material.dart';

class WineDetailSections extends StatelessWidget {
  const WineDetailSections({
    super.key,
    required this.tastingNotes,
    required this.sommelierNote,
  });

  final String? tastingNotes;
  final String? sommelierNote;

  @override
  Widget build(BuildContext context) {
    final hasTasting = tastingNotes != null && tastingNotes!.isNotEmpty;
    final hasSommelier = sommelierNote != null && sommelierNote!.isNotEmpty;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTasting) ...[
          Text(
            'Tasting notes',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            tastingNotes!,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        if (hasSommelier) ...[
          Text(
            'Sommelier insight',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          _SommelierRichText(note: sommelierNote!),
        ],
        if (!hasTasting && !hasSommelier)
          Text(
            'No additional notes were provided for this wine.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
      ],
    );
  }
}

class _SommelierRichText extends StatelessWidget {
  const _SommelierRichText({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final cleaned = note.replaceAll('\r', '');
    final lines = cleaned.split('\n');
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .where((line) => line.trim().isNotEmpty)
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

