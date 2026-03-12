import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cellar/domain/controllers/cellar_controller.dart';
import '../providers/auth_providers.dart';
import '../../data/auth_repository.dart';
import 'login_screen.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  static const routePath = '/profile';
  static const routeName = 'profile';

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final me = await repo.fetchProfile();
      _firstNameCtrl.text = me['first_name'] as String? ?? '';
      _lastNameCtrl.text = me['last_name'] as String? ?? '';
      _emailCtrl.text = me['email'] as String? ?? '';
      _phoneCtrl.text = me['phone_number'] as String? ?? '';
      debugPrint('MyProfileScreen: profile loaded for ${_emailCtrl.text}');
    } catch (e) {
      debugPrint('MyProfileScreen: fetchProfile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phone,
      );
      debugPrint('MyProfileScreen: profile updated successfully');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      // Refresh auth state (e.g. firstName) if needed
      await ref.read(authProvider.notifier).hydrate();
    } catch (e) {
      debugPrint('MyProfileScreen: updateProfile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to update profile. Please try again later.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(cellarControllerProvider);
    debugPrint('Invalidating cellarProvider on logout');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _openChangePassword() {
    debugPrint('Opening Change Password flow');
    context.push('${MyProfileScreen.routePath}/change-password');
  }

  Future<void> _deleteAccount() async {
    debugPrint('Delete account requested');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This action will permanently delete your account and cellar data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    debugPrint('Prompting for current password before account deletion');
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteAccountPasswordDialog(
        onCancel: () => Navigator.of(ctx).pop(),
        onSubmit: (p) => Navigator.of(ctx).pop(p),
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteAccount(currentPassword: password);
      debugPrint('Account deletion successful; clearing auth and cellar state');
      await ref.read(authProvider.notifier).logout();
      ref.invalidate(cellarControllerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      context.go(LoginScreen.routePath);
    } catch (e) {
      debugPrint('Delete account password verification failed');
      if (mounted) {
        final message = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to delete account. Please try again.';
        final friendly = message.contains('incorrect') || message.contains('403')
            ? 'Current password is incorrect.'
            : message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(
          'My profile',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Account',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'First name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Last name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return 'Phone number is required.';
                          }
                          if (!RegExp(r'^[+\d][\d\s\-]{6,}$').hasMatch(value)) {
                            return 'Please enter a valid phone number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5C4A3F),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            _isSaving ? 'Saving...' : 'Save changes',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Security',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _openChangePassword,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF5C4A3F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Change password'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Session',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF5C4A3F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Log out'),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Danger zone',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isDeleting ? null : _deleteAccount,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          _isDeleting ? 'Deleting...' : 'Delete account',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DeleteAccountPasswordDialog extends StatefulWidget {
  const _DeleteAccountPasswordDialog({
    required this.onCancel,
    required this.onSubmit,
  });

  final VoidCallback onCancel;
  final void Function(String password) onSubmit;

  @override
  State<_DeleteAccountPasswordDialog> createState() =>
      _DeleteAccountPasswordDialogState();
}

class _DeleteAccountPasswordDialogState
    extends State<_DeleteAccountPasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your current password to delete your account.',
          ),
        ),
      );
      return;
    }
    widget.onSubmit(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm deletion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Please enter your current password to delete your account.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Current password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _passwordController,
          builder: (context, value, _) {
            final hasPassword = value.text.trim().isNotEmpty;
            return FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: hasPassword ? () => _submit() : null,
              child: const Text('Delete my account'),
            );
          },
        ),
      ],
    );
  }
}

