import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const routePath = '/profile/terms';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('Terms of service', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Independent app',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This app is unofficial and independent. It is not affiliated with, endorsed by, '
              'or connected to LCBO or any other retailer.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Product information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prices, inventory, and product details may change. '
              'Always confirm final details on the official retailer site before purchasing.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recommendations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wine recommendations are for informational purposes only. '
              'We do not guarantee availability, accuracy, or suitability for your needs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
