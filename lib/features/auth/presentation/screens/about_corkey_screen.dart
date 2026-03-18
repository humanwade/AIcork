import 'package:flutter/material.dart';

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
              'Corkey is an AI-powered wine discovery and pairing companion designed to help wine lovers explore new bottles, remember what they’ve tried, and discover wines that match their personal taste.',
            ),
            paragraph(
              'Whether you are choosing a wine for dinner, scanning a bottle at a store, or building your personal wine cellar, Corkey helps make wine selection easier and more enjoyable.',
            ),

            sectionTitle('Key Features'),

            feature(
              'AI Wine Pairing',
              'Describe your meal, occasion, or mood, and Corkey will recommend wines that pair well with your request using natural language understanding.',
            ),
            feature(
              'Bottle Scanning',
              'Scan a wine label to quickly identify the bottle and view tasting notes and recommendations.',
            ),
            feature(
              'Personal Wine Cellar',
              'Save wines you want to try and track wines you’ve already tasted. Add ratings and notes to build your personal wine history.',
            ),
            feature(
              'Taste Profile',
              'As you rate wines, Corkey learns your preferences and helps generate more personalized wine recommendations.',
            ),
            feature(
              'Discover Wines',
              'Browse curated wine suggestions based on your taste profile and explore different wine styles.',
            ),

            sectionTitle('Independent App Notice'),
            paragraph(
              'Corkey is an independent application and is not affiliated with, endorsed by, or operated by the Liquor Control Board of Ontario (LCBO) or any other retailer.',
            ),
            paragraph(
              'Wine information, availability, and pricing may change and should always be verified on the official retailer website.',
            ),

            sectionTitle('Contact'),
            paragraph('corkeysupport@gmail.com'),

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

