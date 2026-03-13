import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routePath = '/profile/privacy';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('Privacy policy', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data we collect',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We collect account information (name, email, phone) that you provide when signing up. '
              'We store your cellar data (wines you want to try and wines you have tried), '
              'scan history, and profile preferences locally and on our servers to sync across your devices.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How we use your data',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your data is used to provide personalized wine recommendations, '
              'sync your cellar and tasting history, and improve the app experience.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Retention and deletion',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your data is retained while your account is active. '
              'When you delete your account, we remove your account and cellar data from our systems.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For privacy-related questions, contact us at support@example.com.',
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
