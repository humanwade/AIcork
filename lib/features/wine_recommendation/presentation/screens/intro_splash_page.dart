import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroSplashPage extends StatefulWidget {
  const IntroSplashPage({super.key});

  static const String routePath = '/intro';
  static const String routeName = 'intro_splash';

  @override
  State<IntroSplashPage> createState() => _IntroSplashPageState();
}

class _IntroSplashPageState extends State<IntroSplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE6DC),
      body: Center(
        child: Image.asset(
          'assets/splash/corkey_splash.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              'IntroSplashPage: failed to load assets/splash/corkey_splash.png ($error)',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

