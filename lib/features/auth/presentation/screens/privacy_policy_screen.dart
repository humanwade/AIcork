import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routePath = '/profile/privacy';

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

    Future<void> openDeletionForm() async {
      final uri = Uri.parse('https://forms.gle/pyjGyhyVQqkTFfXG9');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the account deletion form.'),
          ),
        );
      }
    }

    Future<void> openPrivacyEmail() async {
      final uri = Uri(
        scheme: 'mailto',
        path: 'corkeysupport@gmail.com',
        query: 'subject=${Uri.encodeComponent('Corkey Privacy Question')}',
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
        title: Text('Privacy Policy', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Corkey',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            paragraph('Last updated: 2026'),
            paragraph(
              'Corkey respects your privacy and is committed to protecting your personal information.',
            ),

            sectionTitle('Information We Collect'),

            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Account Information', style: headingStyle),
            ),
            bullet('First name'),
            bullet('Last name'),
            bullet('Email address'),
            bullet('Encrypted password'),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Wine Activity Data', style: headingStyle),
            ),
            bullet('Wine preferences and interactions'),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Usage Data', style: headingStyle),
            ),
            bullet('IP address and request logs'),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Data Processing', style: headingStyle),
            ),
            paragraph(
              'Wine scan images may be processed to generate recommendations but are not permanently stored.',
            ),

            sectionTitle('How We Use Information'),
            paragraph('Information is used to:'),
            bullet('Provide AI-based wine recommendations'),
            bullet('Improve app performance and user experience'),
            bullet('Ensure system security and prevent abuse'),

            sectionTitle('Third-Party Services'),
            paragraph('Corkey may use third-party services for:'),
            bullet('Google Gemini API for AI-based recommendations'),
            bullet('Cloudflare (network and security services)'),
            bullet('Cloud hosting providers (server infrastructure)'),

            sectionTitle('Security'),
            paragraph('All data is transmitted securely using HTTPS encryption.'),

            sectionTitle('Data Retention'),
            paragraph(
              'Data is stored on secure servers located in Canada or cloud infrastructure providers.',
            ),

            sectionTitle('Account Deletion'),
            paragraph(
              'You can request deletion of your account and personal data.',
            ),

            sectionTitle('Account Deletion Requests'),
            paragraph('You can request deletion of your account and personal data:'),
            bullet('within the app, or'),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: bodyStyle),
                  Expanded(
                    child: InkWell(
                      onTap: openDeletionForm,
                      child: Text(
                        'via this form: https://forms.gle/pyjGyhyVQqkTFfXG9',
                        style: bodyStyle?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            paragraph(
              'All deletion requests are processed within a reasonable timeframe. Once deleted, data cannot be recovered.',
            ),

            sectionTitle('Data Deletion Procedure'),
            paragraph(
              'When a deletion request is received, all associated user data is permanently removed from our database and cannot be restored.',
            ),

            sectionTitle('Children’s Privacy'),
            paragraph(
              'Corkey is intended for users who are of legal drinking age in their jurisdiction. We do not knowingly collect personal information from individuals under the legal drinking age.',
            ),

            sectionTitle('Changes to This Policy'),
            paragraph('This Privacy Policy may be updated periodically.'),

            sectionTitle('Contact'),
            paragraph('For privacy questions:'),
            paragraph('Privacy Officer'),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: openPrivacyEmail,
                child: Text(
                  'Email: corkeysupport@gmail.com',
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
