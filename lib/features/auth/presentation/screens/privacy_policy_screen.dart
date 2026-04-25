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
            bullet('Saved wines (Wants)'),
            bullet('Tried wines'),
            bullet('Wine ratings'),
            bullet('Tasting notes'),
            bullet('Wine preferences'),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Scan Data', style: headingStyle),
            ),
            paragraph(
              'If the bottle scanning feature is used, images of wine labels are processed to identify the bottle, but scan images are not permanently stored by default.',
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Device Information', style: headingStyle),
            ),
            paragraph(
              'Basic device information may be collected such as device type, OS version, and app version to improve performance.',
            ),
            bullet('IP address and request logs for security, abuse prevention, and service reliability'),

            sectionTitle('How We Use Information'),
            paragraph('Information is used to:'),
            bullet('provide wine recommendations'),
            bullet('personalize suggestions'),
            bullet('maintain your wine cellar'),
            bullet('improve the Corkey app'),
            bullet('respond to user feedback'),
            bullet('monitor stability and protect the service from abuse'),

            sectionTitle('Third-Party Services'),
            paragraph('Corkey may use third-party services for:'),
            bullet('Google Gemini API for AI-based recommendations'),
            bullet('Cloudflare for infrastructure performance and security'),
            bullet('cloud hosting providers for application and database hosting'),
            bullet('analytics'),

            sectionTitle('Security'),
            paragraph('All data is transmitted securely using HTTPS encryption.'),

            sectionTitle('Data Retention'),
            paragraph(
              'User data is stored until the user deletes their account or requests deletion. Data is stored on secure servers located in Canada or cloud infrastructure providers.',
            ),

            sectionTitle('Account Deletion'),
            paragraph(
              'Users may delete their account within the app. When deleted, personal data and wine history are removed.',
            ),

            sectionTitle('Account Deletion Requests'),
            paragraph('Users can request account deletion:'),
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
              'After deletion is completed, personal data is permanently deleted and cannot be recovered.',
            ),

            sectionTitle('Data Deletion Procedure'),
            paragraph(
              'When an account deletion request is processed, related personal data is removed from our database permanently.',
            ),

            sectionTitle('Children’s Privacy'),
            paragraph('Corkey is intended for users of legal drinking age.'),

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
