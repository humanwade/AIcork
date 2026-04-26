import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

    Future<void> openTermsEmail() async {
      final uri = Uri(
        scheme: 'mailto',
        path: 'corkeysupport@gmail.com',
        query: 'subject=${Uri.encodeComponent('Corkey Terms Question')}',
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
        title: Text('Terms of Service', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            paragraph('Last updated: 2026'),
            paragraph('By using Corkey, you agree to the following terms.'),

            sectionTitle('Use of Service'),
            paragraph(
              'Corkey provides AI-powered wine recommendations based on user input and preferences.',
            ),

            sectionTitle('AI Disclaimer'),
            paragraph(
              'Recommendations are generated using artificial intelligence and may not always be accurate or complete.',
            ),

            sectionTitle('User Responsibilities'),
            paragraph(
              'You agree to use the app responsibly and not misuse the service.',
            ),

            sectionTitle('User Content'),
            paragraph(
              'Users retain ownership of any content they submit. By using the service, you grant Corkey a non-exclusive, worldwide, royalty-free license to use, display, and process such content for service operation.',
            ),

            sectionTitle('Account Suspension'),
            paragraph(
              'We reserve the right to suspend or terminate accounts for misuse or violation of these terms.',
            ),

            sectionTitle('Limitation of Liability'),
            paragraph(
              'Corkey is not responsible for any decisions made based on recommendations provided by the app.',
            ),

            sectionTitle('Governing Law'),
            paragraph(
              'This agreement shall be governed by the laws of Ontario, Canada.',
            ),

            sectionTitle('Alcohol Law Compliance'),
            paragraph(
              'By using Corkey, you represent that you are of legal drinking age in your region. You are responsible for complying with all local laws regarding the purchase and consumption of alcohol.',
            ),

            sectionTitle('Independent Application'),
            paragraph(
              'Corkey is an independent application and is not affiliated with, endorsed by, or operated by the Liquor Control Board of Ontario (LCBO) or any wine retailer.',
            ),

            sectionTitle('Contact'),
            paragraph('Questions about these terms can be sent to:'),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: openTermsEmail,
                child: Text(
                  'corkeysupport@gmail.com',
                  style: bodyStyle?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
