import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/wine_entity.dart';

class WineCard extends StatelessWidget {
  const WineCard({
    super.key,
    required this.wine,
    required this.onTap,
    this.trailing,
  });

  final WineEntity wine;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = wine.thumbnailUrl != null && wine.thumbnailUrl!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
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
                          imageUrl: wine.thumbnailUrl!,
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
                        if (trailing != null) ...[
                          const SizedBox(width: 10),
                          trailing!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${wine.price.toStringAsFixed(2)} • SKU ${wine.sku}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (wine.tastingNotes != null &&
                        wine.tastingNotes!.isNotEmpty)
                      Text(
                        wine.tastingNotes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade800,
                        ),
                      ),
                    if (wine.sommelierNote != null &&
                        wine.sommelierNote!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _firstLineOfSommelier(wine.sommelierNote!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstLineOfSommelier(String note) {
    final cleaned = note.replaceAll('\r', '');
    final lines = cleaned.split('\n');
    if (lines.isEmpty) return cleaned;
    return lines.firstWhere(
      (l) => l.trim().isNotEmpty,
      orElse: () => lines.first,
    );
  }
}

