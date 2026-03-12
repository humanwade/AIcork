import 'package:flutter/material.dart';

class StarRatingSelector extends StatelessWidget {
  const StarRatingSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value; // 1–5 (supports halves)
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ...List.generate(5, (i) {
              final idx = i + 1;
              final filled = value >= idx;
              final half = !filled && value >= (idx - 0.5);
              return Icon(
                filled
                    ? Icons.star_rounded
                    : (half ? Icons.star_half_rounded : Icons.star_border_rounded),
                size: 22,
                color: const Color(0xFFC08B5C),
              );
            }),
            const Spacer(),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5C4A3F),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF5C4A3F),
            inactiveTrackColor: const Color(0xFFE3D9CF),
            thumbColor: const Color(0xFF5C4A3F),
            overlayColor: const Color(0xFF5C4A3F).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 8, // 0.5 steps
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

