import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutCorkeyScreen extends StatelessWidget {
  const AboutCorkeyScreen({super.key});

  static const routePath = '/profile/about';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.grey.shade800,
    );

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(text, style: headingStyle),
        );

    Widget paragraph(String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(text, style: bodyStyle),
        );

    Widget bullet(String text) => Padding(
          padding: const EdgeInsets.only(top: 6, left: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: bodyStyle),
              Expanded(child: Text(text, style: bodyStyle)),
            ],
          ),
        );

    Widget feature(String title, String description) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: headingStyle),
              paragraph(description),
            ],
          ),
        );

    Future<void> openSupportEmail() async {
      final uri = Uri(
        scheme: 'mailto',
        path: 'corkeysupport@gmail.com',
        query: 'subject=${Uri.encodeComponent('Corkey Support')}',
      );
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. Please install or configure one.'),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('About Corkey', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            paragraph(
              'Corkey is a modern AI-powered wine companion built to help you discover better bottles, faster.',
            ),
            paragraph(
              'From dinner planning to store visits, Corkey gives you quick, confident wine decisions with recommendations that feel personal.',
            ),

            sectionTitle('Key Features'),

            feature(
              'AI-Powered Recommendations',
              'Tell Corkey your meal, mood, or occasion and get AI-powered recommendations in seconds.',
            ),
            feature(
              'Instant Label Scan',
              'Scan wine labels instantly to identify bottles and view tasting notes and suggestions right away.',
            ),
            feature(
              'Personal Wine Cellar',
              'Save wines you want to try and track wines you already tasted in one clean, simple cellar.',
            ),
            feature(
              'Personalized Taste Profile',
              'As you rate wines, Corkey builds your personalized taste profile to make future picks smarter and more relevant.',
            ),
            feature(
              'Discover Wines',
              'Explore curated picks and new styles based on what you actually enjoy.',
            ),

            sectionTitle('Independent App Notice'),
            paragraph(
              'Corkey is an independent application and is not affiliated with, endorsed by, or operated by the Liquor Control Board of Ontario (LCBO) or any other retailer.',
            ),
            paragraph(
              'Wine information, availability, and pricing may change and should always be verified on the official retailer website.',
            ),

            sectionTitle('Contact'),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: openSupportEmail,
                child: Text(
                  'corkeysupport@gmail.com',
                  style: bodyStyle?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            sectionTitle('App Information'),
            bullet('App Name: Corkey'),
            bullet('Version: 1.0.0'),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

