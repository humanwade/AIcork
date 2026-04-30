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
            content: Text('Could not open the link.'),
          ),
        );
      }
    }

    Future<void> openPrivacyEmail() async {
      final uri = Uri(
        scheme: 'mailto',
        path: 'corkeysupport@gmail.com',
        queryParameters: {'subject': 'Corkey Privacy Question',},
      );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. Please install or configure one.'),
          ),
        );
      }
    }

    Future<void> openFullPrivacyPolicy() async {
      final uri = Uri.parse('https://wine-api.wadeverse.net/static/privacy.html');
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

            sectionTitle('Information We Collect'),
            bullet('First name and last name'),
            bullet('Email address'),
            bullet('Encrypted password'),
            bullet(
              'Wine preferences and interactions (saved wines, tried wines, ratings, notes)',
            ),
            bullet(
              'IP address and request logs (used for security, abuse prevention, rate limiting)',
            ),
            bullet('Scan data is processed in memory and not permanently stored on Corkey servers'),
            bullet('Scan images may be securely transmitted to third-party AI services (such as Google Gemini API) for the purpose of extracting wine information'),
            bullet('Scan images are not retained by Corkey after processing'),
            bullet('Third-party providers may process data under their own privacy policies, and Corkey does not control third-party retention practices'),
            bullet('Device information (device type, OS version, app version)'),

            sectionTitle('How We Use Information'),
            bullet('Provide AI-based wine recommendations'),
            bullet('Maintain personal wine cellar'),
            bullet('Improve app experience'),
            bullet('Monitor stability and prevent abuse'),

            sectionTitle('Third-Party Services'),
            bullet('Google Gemini API (AI recommendations)'),
            bullet('Cloudflare (network, security)'),
            bullet('Cloud hosting providers'),

            sectionTitle('Data Sharing'),
            bullet('We do NOT sell personal data'),
            bullet('We may share limited data with third-party service providers (such as AI processing and hosting services) only as necessary to operate Corkey and provide its core functionality'),

            sectionTitle('Security'),
            bullet('All data is transmitted using HTTPS encryption'),

            sectionTitle('Permissions'),
            bullet('Camera permission is requested only when you choose to scan a wine label'),
            bullet('If camera permission is denied, you can still use recommendations and cellar features'),

            sectionTitle('Data Retention & Storage'),
            bullet('Data is stored until the user deletes their account or submits a deletion request'),
            bullet('Data may be processed in Canada or other regions'),

            sectionTitle('Account Deletion'),
            bullet('In-app: My Page > Edit profile > Delete Account'),
            bullet('Web form:'),
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
                        'https://forms.gle/pyjGyhyVQqkTFfXG9',
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

            sectionTitle('Data Deletion Procedure'),
            bullet('Data is permanently deleted'),
            bullet('Cannot be recovered'),

            sectionTitle("Children's Privacy"),
            bullet('Only for users of legal drinking age'),

            sectionTitle('Changes'),
            bullet('Policy may be updated'),

            sectionTitle('Contact'),
            paragraph('Privacy Officer'),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text('Email: ', style: bodyStyle), 
                  InkWell(
                    onTap: openPrivacyEmail,
                    child: Text(
                      'corkeysupport@gmail.com',
                      style: bodyStyle?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: openFullPrivacyPolicy,
                child: Text(
                  'View full Privacy Policy',
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
