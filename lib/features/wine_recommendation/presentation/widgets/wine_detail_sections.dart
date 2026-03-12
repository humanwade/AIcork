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

  static const _sectionTitles = {
    'summary': 'Summary',
    'pairing logic': 'Pairing Logic',
    'flavor bridge': 'Flavor Bridge',
    'serving tip': 'Serving Tip',
  };

  @override
  Widget build(BuildContext context) {
    final cleaned = _sanitizeNote(note);
    final parsedSections = _parseSections(cleaned);
    final theme = Theme.of(context);

    if (parsedSections.isEmpty) {
      return Text(
        cleaned,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parsedSections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color,
              ),
              children: [
                TextSpan(
                  text: '${section.title}\n',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                TextSpan(
                  text: section.content,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_SommelierSection> _parseSections(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final sections = <_SommelierSection>[];

    final sectionRegex = RegExp(
      r'^(?:\d+\)\s*)?(Summary|Pairing Logic|Flavor Bridge|Serving Tip)\s*:\s*(.*)$',
      caseSensitive: false,
    );

    for (final rawLine in lines) {
      final match = sectionRegex.firstMatch(rawLine);

      if (match != null) {
        final title = match.group(1)!.trim();
        final content = match.group(2)?.trim() ?? '';

        sections.add(
          _SommelierSection(
            title: title,
            content: content,
          ),
        );
      } else if (sections.isNotEmpty) {
        final last = sections.removeLast();
        sections.add(
          _SommelierSection(
            title: last.title,
            content: '${last.content}\n$rawLine',
          ),
        );
      }
    }

    return sections;
  }
}

class _SommelierSection {
  const _SommelierSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

String _sanitizeNote(String input) {
  var text = input.replaceAll('\r', '');

  text = text.replaceAllMapped(
    RegExp(r'\*\*(.*?)\*\*'),
    (m) => m.group(1) ?? '',
  );
  text = text.replaceAllMapped(
    RegExp(r'__(.*?)__'),
    (m) => m.group(1) ?? '',
  );
  text = text.replaceAllMapped(
    RegExp(r'\*(.*?)\*'),
    (m) => m.group(1) ?? '',
  );

  text = text.replaceAllMapped(
    RegExp(r'^\s*[-•]\s+', multiLine: true),
    (_) => '',
  );

  final lines = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .toList();

  final buffer = <String>[];
  var blankStreak = 0;
  for (final line in lines) {
    if (line.isEmpty) {
      blankStreak += 1;
      if (blankStreak <= 1) {
        buffer.add('');
      }
    } else {
      blankStreak = 0;
      buffer.add(line);
    }
  }

  return buffer.join('\n').trim();
}