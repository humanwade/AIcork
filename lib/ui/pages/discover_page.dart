import 'package:flutter/material.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  static const routePath = '/discover';
  static const routeName = 'discover';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discover', style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Curated bottles and ideas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.brown.shade300,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Coming soon.\n\nThis tab is reserved for curated picks and collections.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

