import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const routePath = '/profile/terms';

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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('Terms of Service', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service for Corkey',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            paragraph('Last updated: 2026'),
            paragraph('By using the Corkey app you agree to the following terms.'),

            sectionTitle('Service Description'),
            paragraph(
              'Corkey provides wine discovery tools, wine pairing suggestions, bottle scanning features, and personal wine tracking.',
            ),

            sectionTitle('Independent Application'),
            paragraph(
              'Corkey is an independent application and is not affiliated with, endorsed by, or operated by the Liquor Control Board of Ontario (LCBO).',
            ),

            sectionTitle('Wine Information Disclaimer'),
            paragraph(
              'Wine descriptions, tasting notes, and recommendations are generated using algorithms and AI models.',
            ),
            paragraph(
              'Corkey does not guarantee the accuracy of product details, pricing, or availability.',
            ),
            paragraph('Users should verify product information directly with the retailer.'),

            sectionTitle('Recommendations Disclaimer'),
            paragraph(
              'Wine recommendations are informational and should not be considered professional advice.',
            ),

            sectionTitle('External Links'),
            paragraph(
              'Corkey may link to third-party websites such as wine retailers. Corkey is not responsible for their content.',
            ),

            sectionTitle('User Accounts'),
            paragraph(
              'Users must keep their login credentials secure and may not misuse the service.',
            ),

            sectionTitle('Acceptable Use'),
            paragraph('Users must comply with all applicable alcohol laws in their region.'),

            sectionTitle('Limitation of Liability'),
            paragraph(
              'Corkey is not responsible for decisions made based on wine recommendations or external product information.',
            ),

            sectionTitle('Changes to Terms'),
            paragraph('Terms may be updated periodically.'),

            sectionTitle('Contact'),
            paragraph('Questions about these terms can be sent to:'),
            paragraph('corkeysupport@gmail.com'),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
