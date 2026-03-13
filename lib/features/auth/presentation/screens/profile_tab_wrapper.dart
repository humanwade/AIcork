import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// Shows MyProfileScreen when authenticated, LoginScreen when not.
/// Used for the Profile tab in bottom navigation.
class ProfileTabWrapper extends ConsumerWidget {
  const ProfileTabWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isAuthenticated) {
      return const MyProfileScreen();
    }
    return const LoginScreen();
  }
}
