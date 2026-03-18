import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  static const routePath = '/auth/signup';
  static const routeName = 'signup';

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isCodeSent = false;
  bool _isVerified = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _confirmPasswordMatches = false;
  // Dropdown's selected value must be unique (even if dialing codes are the same).
  // We store a country key and map it to the dialing code when building the phone number.
  String _countryCodeOption = 'CA';
  String? _emailForVerification;

  String _fullPhoneNumber() {
    final local = _phoneCtrl.text.trim();
    if (local.isEmpty) return '';
    final dialingCode = switch (_countryCodeOption) {
      'KR' => '+82',
      'CA' => '+1',
      'US' => '+1',
      _ => '+1',
    };
    return '$dialingCode$local';
  }

  String? _validatePasswordStrong(String password) {
    final pw = password.trim();
    if (pw.isEmpty) return 'Password is required.';
    if (pw.length < 8) return 'Use at least 8 characters.';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(pw);
    final hasNumber = RegExp(r'[0-9]').hasMatch(pw);
    // Consider "special character" as anything that is not a letter or digit.
    // "Special character" excludes whitespace.
    final hasSpecial = RegExp(r'[^A-Za-z0-9\s]').hasMatch(pw);
    if (!hasLetter || !hasNumber || !hasSpecial) {
      return 'Password must include letters, numbers, and a special character.';
    }
    return null;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSendingCode) return;
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first.')),
      );
      return;
    }
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _fullPhoneNumber();

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name.')),
      );
      return;
    }
    if (lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your last name.')),
      );
      return;
    }
    setState(() {
      _isSendingCode = true;
      _isVerified = false;
      _isCodeSent = false;
      _codeCtrl.clear();
    });
    try {
      setState(() {
        _emailError = null;
      });
      await ref.read(authRepositoryProvider).sendVerificationCode(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phoneNumber: phone,
          );
      if (!mounted) return;
      debugPrint('SignupScreen: verification code requested for $email');
      setState(() {
        _isCodeSent = true;
        _emailForVerification = email;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your email.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('SignupScreen: sendVerificationCode error: $e');
      final message = e.toString();
      if (message.toLowerCase().contains('already registered') ||
          message.toLowerCase().contains('email already registered')) {
        setState(() {
          _emailError = 'This email is already registered';
          _isCodeSent = false;
          _isVerified = false;
          _codeCtrl.clear();
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to send verification code. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    if (authState.isLoading) return;

    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email before signing up.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final phone = _fullPhoneNumber();
    final code = _codeCtrl.text.trim();

    try {
      setState(() {
        _emailError = null;
      });
      await ref.read(authProvider.notifier).signup(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phoneNumber: phone,
            verificationCode: code,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up complete. Please sign in.')),
      );
      context.go('/auth/login');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (message.toLowerCase().contains('already registered') ||
          message.toLowerCase().contains('email already registered')) {
        setState(() {
          _emailError = 'This email is already registered';
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up failed. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(
          'Sign up',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create your Corkey account',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'We will keep your cellar and tasting notes in sync.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                  onChanged: (_) {
                    final newEmail = _emailCtrl.text.trim();
                    final shouldReset = (_isCodeSent || _isVerified) &&
                        _emailForVerification != null &&
                        newEmail.isNotEmpty &&
                        newEmail != _emailForVerification;

                    if (_emailError == null && !shouldReset) return;

                    setState(() {
                      _emailError = null;
                      if (shouldReset) {
                        _isVerified = false;
                        _isCodeSent = false;
                        _codeCtrl.clear();
                        _emailForVerification = null;
                      }
                    });
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required.';
                    }
                    if (!v.contains('@')) {
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                ),
                if (_emailError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _emailError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Email verification code',
                        ),
                        validator: (v) {
                          if (!_isCodeSent) {
                            return null;
                          }
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter the verification code.';
                          }
                          if (v.trim().length != 6) {
                            return 'Code must be 6 digits.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: _isSendingCode ? null : _sendCode,
                      child: Text(
                        _isSendingCode ? 'Sending...' : 'Send code',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isCodeSent)
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: _isVerifyingCode
                            ? null
                            : () async {
                                setState(() {
                                  _isVerifyingCode = true;
                                });
                                try {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .verifyEmailCode(
                                        email: _emailCtrl.text.trim(),
                                        code: _codeCtrl.text.trim(),
                                      );
                                  if (!mounted) return;
                                  setState(() {
                                    _isVerified = true;
                                    _emailForVerification = _emailCtrl.text.trim();
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Email verified.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  debugPrint(
                                      'SignupScreen: verifyEmailCode error: $e');
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Verification failed. Please check the code and try again.',
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isVerifyingCode = false;
                                    });
                                  }
                                }
                              },
                        child: Text(
                          _isVerifyingCode ? 'Verifying...' : 'Verify',
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_isVerified)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    final error = _validatePasswordStrong(value);
                    final confirmText = _confirmPasswordCtrl.text;
                    final matches =
                        confirmText.isNotEmpty && confirmText == value;

                    setState(() {
                      _passwordError = error;
                      _confirmPasswordMatches = matches;
                      if (confirmText.isEmpty) {
                        _confirmPasswordError = null;
                      } else {
                        _confirmPasswordError = matches
                            ? null
                            : 'Password is not match';
                      }
                    });
                  },
                  validator: (v) {
                    final pw = v ?? '';
                    return _validatePasswordStrong(pw);
                  },
                ),
                if (_passwordError != null &&
                    _passwordCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _passwordError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    final matches =
                        value.isNotEmpty && value == _passwordCtrl.text;
                    setState(() {
                      _confirmPasswordMatches = matches;
                      if (value.isEmpty) {
                        _confirmPasswordError = null;
                      } else {
                        _confirmPasswordError =
                            matches ? null : 'Password is not match';
                      }
                    });
                  },
                  validator: (v) {
                    final confirm = v ?? '';
                    if (confirm.isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (confirm != _passwordCtrl.text) {
                      return 'Password is not match';
                    }
                    return null;
                  },
                ),
                if (_confirmPasswordError != null &&
                    _confirmPasswordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _confirmPasswordError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ] else if (_confirmPasswordMatches &&
                    _confirmPasswordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Passwords match',
                        style: TextStyle(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade400,
                        ),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _countryCodeOption,
                          items: const [
                            DropdownMenuItem(
                              value: 'CA',
                              child: Text('Canada (+1)'),
                            ),
                            DropdownMenuItem(
                              value: 'KR',
                              child: Text('South Korea (+82)'),
                            ),
                            DropdownMenuItem(
                              value: 'US',
                              child: Text('United States (+1)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _countryCodeOption = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '555 123 4567',
                        ),
                        validator: (v) {
                          final local = v?.trim() ?? '';
                          if (local.isEmpty) {
                            return 'Phone number is required.';
                          }
                          final normalized =
                              local.replaceAll(RegExp(r'[\s\-]'), '');
                          if (!RegExp(r'^[0-9]+$').hasMatch(normalized)) {
                            return 'Please enter a valid phone number.';
                          }
                          if (normalized.length < 6) {
                            return 'Please enter a valid phone number.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C4A3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      authState.isLoading
                          ? 'Creating account...'
                          : 'Sign up',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/auth/login');
                    }
                  },
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

