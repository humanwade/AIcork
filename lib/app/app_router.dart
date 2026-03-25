import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/wine_recommendation/domain/entities/wine_entity.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/edit_profile_screen.dart';
import '../features/auth/presentation/screens/about_corkey_screen.dart';
import '../features/auth/presentation/screens/privacy_policy_screen.dart';
import '../features/auth/presentation/screens/terms_of_service_screen.dart';
import '../features/auth/presentation/screens/wine_preferences_screen.dart';
import '../features/auth/presentation/screens/profile_tab_wrapper.dart';
import '../features/wine_recommendation/presentation/screens/intro_splash_page.dart';
import '../features/wine_recommendation/presentation/screens/results_screen.dart';
import '../features/wine_recommendation/presentation/screens/search_screen.dart';
import '../features/wine_recommendation/presentation/screens/splash_screen.dart';
import '../features/wine_recommendation/presentation/screens/wine_detail_screen.dart';
import '../features/cellar/presentation/screens/details/cellar_wine_detail_screen.dart';
import '../features/cellar/presentation/screens/details/tried_wine_detail_screen.dart';
import '../features/cellar/presentation/screens/forms/add_cellar_wine_screen.dart';
import '../features/cellar/presentation/screens/forms/add_tried_wine_screen.dart';
import '../features/cellar/presentation/screens/forms/edit_tried_wine_screen.dart';
import '../features/cellar/domain/models/cellar_wine.dart';
import '../features/cellar/domain/models/tried_wine_entry.dart';
import '../features/discover/domain/models/learn_wine_article.dart';
import '../features/discover/presentation/screens/learn_wine_detail_screen.dart';
import '../ui/pages/cellar_page.dart';
import '../ui/pages/discover_page.dart';
import '../ui/pages/scan_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: IntroSplashPage.routePath,
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: SignupScreen.routePath,
        name: SignupScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SignupScreen(),
        ),
      ),
      GoRoute(
        path: IntroSplashPage.routePath,
        name: IntroSplashPage.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: IntroSplashPage(),
        ),
      ),
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          const surface = Color(0xFFF7F4F1);
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: state.matchedLocation.startsWith('/home'),
                        onTap: () => navigationShell.goBranch(0),
                      ),
                      _NavItem(
                        icon: Icons.search_rounded,
                        label: 'Discover',
                        isSelected:
                            state.matchedLocation.startsWith('/discover'),
                        onTap: () => navigationShell.goBranch(1),
                      ),
                      _ScanNavItem(
                        isSelected: state.matchedLocation.startsWith('/scan'),
                        onTap: () => navigationShell.goBranch(2),
                      ),
                      _NavItem(
                        icon: Icons.wine_bar_rounded,
                        label: 'My Cellar',
                        isSelected: state.matchedLocation.startsWith('/cellar'),
                        onTap: () => navigationShell.goBranch(3),
                      ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'My Page',
                        isSelected:
                            state.matchedLocation.startsWith('/profile'),
                        onTap: () => navigationShell.goBranch(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        branches: [
          // 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SearchScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'results',
                    pageBuilder: (context, state) {
                      final wines =
                          state.extra as List<WineEntity>? ?? <WineEntity>[];
                      return MaterialPage(
                        child: ResultsScreen(wines: wines),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'detail',
                        pageBuilder: (context, state) {
                          final wine = state.extra as WineEntity;
                          return MaterialPage(
                            child: WineDetailScreen(wine: wine),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // 1: Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DiscoverPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'learn',
                    pageBuilder: (context, state) {
                      final article =
                          state.extra as LearnWineArticle;
                      return MaterialPage(
                        child: LearnWineDetailScreen(article: article),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 2: Scan (center FAB)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ScanPage(),
                ),
              ),
            ],
          ),
          // 3: My Cellar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cellar',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CellarPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'add',
                    pageBuilder: (context, state) {
                      final extra = state.extra;
                      final args = extra is AddCellarArgs
                          ? extra
                          : AddCellarArgs(
                              target: (extra as AddCellarTarget?) ??
                                  AddCellarTarget.wants,
                            );
                      return MaterialPage(
                        child: AddCellarWineScreen(
                          target: args.target,
                          prefillTitle: args.prefillTitle,
                          prefillType: args.prefillType,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'add-tried',
                    pageBuilder: (context, state) {
                      final args = state.extra is AddTriedArgs
                          ? state.extra as AddTriedArgs
                          : const AddTriedArgs();
                      return MaterialPage(
                        child: AddTriedWineScreen(
                          prefillTitle: args.prefillTitle,
                          prefillType: args.prefillType,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'want-detail',
                    pageBuilder: (context, state) {
                      final wine = state.extra as CellarWine;
                      return MaterialPage(
                        child: CellarWineDetailScreen(
                          wine: wine,
                          kindLabel: 'Wants',
                          isWant: true,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'tried-detail',
                    pageBuilder: (context, state) {
                      final entry = state.extra as TriedWineEntry;
                      return MaterialPage(
                        child: TriedWineDetailScreen(entry: entry),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'edit-tried',
                    pageBuilder: (context, state) {
                      final entry = state.extra as TriedWineEntry;
                      return MaterialPage(
                        child: EditTriedWineScreen(entry: entry),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 4: My Page (Profile)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileTabWrapper(),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: EditProfileScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'change-password',
                    name: ChangePasswordScreen.routeName,
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: ChangePasswordScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'wine-preferences',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: WinePreferencesScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'privacy',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: PrivacyPolicyScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'terms',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: TermsOfServiceScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'about',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: AboutCorkeyScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF5C4A3F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? primary : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanNavItem extends StatelessWidget {
  const _ScanNavItem({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C4A3F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
