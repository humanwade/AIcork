import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IosAgeGateScreen extends StatefulWidget {
  const IosAgeGateScreen({super.key});

  static const routePath = '/ios-age-gate';
  static const routeName = 'ios_age_gate';
  static const acceptedKey = 'ios_age_gate_accepted';

  @override
  State<IosAgeGateScreen> createState() => _IosAgeGateScreenState();
}

class _IosAgeGateScreenState extends State<IosAgeGateScreen> {
  bool _isSubmitting = false;
  bool _blocked = false;

  Future<void> _accept() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(IosAgeGateScreen.acceptedKey, true);
    if (!mounted) return;
    context.go('/home');
  }

  void _decline() {
    setState(() => _blocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('Age Verification', style: theme.textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to Corkey',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _blocked
                    ? 'Access is restricted because you indicated you are under the legal drinking age in your region.'
                    : 'To continue, please confirm you are of legal drinking age in your province or territory.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Corkey provides wine recommendations and related alcohol information intended for legal-age users only.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _blocked || _isSubmitting ? null : _accept,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5C4A3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(_isSubmitting ? 'Please wait...' : 'I am of legal drinking age'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _blocked ? null : _decline,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('I am under legal drinking age'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
