import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../cellar/domain/controllers/cellar_controller.dart'
    show cellarControllerProvider, cellarNavigateToTabProvider;
import '../../../scan/presentation/providers/scan_providers.dart';
import '../providers/auth_providers.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'about_corkey_screen.dart';
import 'wine_preferences_screen.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  static const routePath = '/profile';
  static const routeName = 'profile';

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profile = const {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final me = await repo.fetchProfile();
      if (mounted) {
        setState(() {
          _profile = me;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(cellarControllerProvider);
    ref.invalidate(winePreferencesProvider);
    if (!mounted) return;
    context.go(LoginScreen.routePath);
  }

  void _openChangePassword() {
    context.push('${MyProfileScreen.routePath}/change-password');
  }

  Future<void> _openEditProfile() async {
    await context.push('${MyProfileScreen.routePath}/edit');
    if (mounted) _loadProfile();
  }

  void _navigateToCellarTried() {
    ref.read(cellarNavigateToTabProvider.notifier).state = 1;
    context.go('/cellar');
  }

  void _navigateToCellarWants() {
    ref.read(cellarNavigateToTabProvider.notifier).state = 0;
    context.go('/cellar');
  }

  void _navigateToScan() {
    context.go('/scan');
  }

  Future<void> _sendFeedback() async {
    const version = '1.0.0';
    final device = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;
    final body = [
      'App version:',
      version,
      '',
      'Device:',
      device,
      '',
      'OS version:',
      osVersion,
      '',
      'Feedback:',
      '',
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: 'corkeysupport@gmail.com',
      query: _encodeQuery({
        'subject': 'Corkey App Feedback',
        'body': body,
      }),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 24,
          title: Text('My Page', style: theme.textTheme.titleLarge),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final firstName = _profile['first_name'] as String? ?? '';
    final lastName = _profile['last_name'] as String? ?? '';
    final email = _profile['email'] as String? ?? '';
    final displayName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('My Page', style: theme.textTheme.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileCard(
                displayName: displayName.isEmpty ? 'Wine explorer' : displayName,
                subtitle: displayName.isEmpty ? email : null,
                onEdit: () => _openEditProfile(),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Your Wine Stats'),
              const SizedBox(height: 12),
              _WineStatsRow(
                onTriedTap: _navigateToCellarTried,
                onSavedTap: _navigateToCellarWants,
                onScannedTap: _navigateToScan,
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Preferences'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.wine_bar_rounded,
                    label: 'Wine preferences',
                    onTap: () => context.push('/profile/wine-preferences'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Support'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.feedback_outlined,
                    label: 'Send feedback',
                    onTap: _sendFeedback,
                  ),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy policy',
                    onTap: () => context.push(PrivacyPolicyScreen.routePath),
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of service',
                    onTap: () => context.push(TermsOfServiceScreen.routePath),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About Corkey',
                    onTap: () => context.push(AboutCorkeyScreen.routePath),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Account'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: () => _openEditProfile()),
                  _SettingsRow(icon: Icons.lock_outline_rounded, label: 'Change password', onTap: _openChangePassword),
                  _SettingsRow(icon: Icons.logout_rounded, label: 'Log out', onTap: _logout),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.displayName,
    this.subtitle,
    required this.onEdit,
  });

  final String displayName;
  final String? subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFF0E9E2),
              child: Icon(Icons.person_rounded, size: 36, color: Colors.brown.shade300),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Edit profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _WineStatsRow extends ConsumerWidget {
  const _WineStatsRow({
    required this.onTriedTap,
    required this.onSavedTap,
    required this.onScannedTap,
  });

  final VoidCallback onTriedTap;
  final VoidCallback onSavedTap;
  final VoidCallback onScannedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellarAsync = ref.watch(cellarControllerProvider);
    final scanCountAsync = ref.watch(scanHistoryCountProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: cellarAsync.valueOrNull?.tried.length ?? 0,
            label: 'Tried wines',
            onTap: onTriedTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: cellarAsync.valueOrNull?.wants.length ?? 0,
            label: 'Saved wines',
            onTap: onSavedTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: scanCountAsync.valueOrNull ?? 0,
            label: 'Scanned wines',
            onTap: onScannedTap,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C4A3F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final list = children;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            list[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.grey.shade600),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade800,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
      onTap: onTap,
    );
  }
}

