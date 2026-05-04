import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'core/auth/token_storage.dart';
import 'core/configure_android_photo_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAndroidPhotoPicker();
  await TokenStorage.hydrate();
  runApp(const ProviderScope(child: WineApp()));
}

class WineApp extends ConsumerWidget {
  const WineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Corkey',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
