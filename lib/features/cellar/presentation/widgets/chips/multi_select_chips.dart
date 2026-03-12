import 'package:flutter/material.dart';

class MultiSelectChips extends StatelessWidget {
  const MultiSelectChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isOn = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: isOn,
          onSelected: (v) {
            final next = {...selected};
            if (v) {
              next.add(o);
            } else {
              next.remove(o);
            }
            onChanged(next);
          },
          selectedColor: const Color(0xFFF1ECE7),
          checkmarkColor: const Color(0xFF5C4A3F),
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            color: isOn ? const Color(0xFF5C4A3F) : Colors.grey.shade800,
            fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isOn ? const Color(0xFFE3D9CF) : const Color(0xFFE3D9CF),
          ),
        );
      }).toList(),
    );
  }
}

