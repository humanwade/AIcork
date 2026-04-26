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

    Future<void> openFullTermsOfService() async {
      final uri = Uri.parse('https://wine-api.wadeverse.net/static/terms.html');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link.'),
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
              'Terms of Service for Corkey',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            paragraph('Last updated: 2026'),

            sectionTitle('Use of Service'),
            bullet('AI-powered wine recommendations'),

            sectionTitle('AI Disclaimer'),
            bullet('Recommendations may not be accurate'),
            bullet('Informational only'),

            sectionTitle('User Responsibilities'),
            bullet('Users must use the app responsibly'),

            sectionTitle('User Content'),
            bullet('Users own their content'),
            bullet('Corkey has limited license to use it'),

            sectionTitle('Account Suspension'),
            bullet('Misuse may result in suspension or termination'),

            sectionTitle('Limitation of Liability'),
            bullet('Corkey is not responsible for user decisions'),

            sectionTitle('Alcohol Law Compliance'),
            bullet('Users must be of legal drinking age'),

            sectionTitle('Independent Application'),
            bullet('Not affiliated with LCBO or any retailer'),

            sectionTitle('External Links'),
            bullet('Corkey is not responsible for third-party sites'),

            sectionTitle('Governing Law'),
            bullet('Ontario, Canada'),

            sectionTitle('Changes'),
            bullet('Terms may be updated'),

            sectionTitle('Contact'),
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: openFullTermsOfService,
                child: Text(
                  'View full Terms of Service',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blueGrey.shade400,
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
