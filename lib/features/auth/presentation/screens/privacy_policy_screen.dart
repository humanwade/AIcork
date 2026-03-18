import 'package:flutter/material.dart';

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
              'If the bottle scanning feature is used, images of wine labels may be processed to identify the bottle.',
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Device Information', style: headingStyle),
            ),
            paragraph(
              'Basic device information may be collected such as device type, OS version, and app version to improve performance.',
            ),

            sectionTitle('How We Use Information'),
            paragraph('Information is used to:'),
            bullet('provide wine recommendations'),
            bullet('personalize suggestions'),
            bullet('maintain your wine cellar'),
            bullet('improve the Corkey app'),
            bullet('respond to user feedback'),

            sectionTitle('Third-Party Services'),
            paragraph('Corkey may use third-party services for:'),
            bullet('AI-based recommendations'),
            bullet('infrastructure and hosting'),
            bullet('analytics'),

            sectionTitle('Data Retention'),
            paragraph('User data is stored until the user deletes their account or requests deletion.'),

            sectionTitle('Account Deletion'),
            paragraph(
              'Users may delete their account within the app. When deleted, personal data and wine history are removed.',
            ),

            sectionTitle('Children’s Privacy'),
            paragraph('Corkey is intended for users of legal drinking age.'),

            sectionTitle('Changes to This Policy'),
            paragraph('This Privacy Policy may be updated periodically.'),

            sectionTitle('Contact'),
            paragraph('For privacy questions:'),
            paragraph('corkeysupport@gmail.com'),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
