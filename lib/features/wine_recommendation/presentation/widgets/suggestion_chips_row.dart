import 'package:flutter/material.dart';

class SuggestionChipsRow extends StatelessWidget {
  const SuggestionChipsRow({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ChoiceChip(
            selected: false,
            label: Text(
              suggestion,
              overflow: TextOverflow.ellipsis,
            ),
            onSelected: (_) => onSelected(suggestion),
          );
        },
      ),
    );
  }
}

