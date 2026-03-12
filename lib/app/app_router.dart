import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/wine_recommendation/domain/entities/wine_entity.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/wine_recommendation/presentation/screens/results_screen.dart';
import '../features/wine_recommendation/presentation/screens/search_screen.dart';
import '../features/wine_recommendation/presentation/screens/splash_screen.dart';
import '../features/wine_recommendation/presentation/screens/wine_detail_screen.dart';
import '../features/cellar/presentation/screens/details/cellar_wine_detail_screen.dart';
import '../features/cellar/presentation/screens/details/tried_wine_detail_screen.dart';
import '../features/cellar/presentation/screens/forms/add_cellar_wine_screen.dart';
import '../features/cellar/presentation/screens/forms/add_tried_wine_screen.dart';
import '../features/cellar/domain/models/cellar_wine.dart';
import '../features/cellar/domain/models/tried_wine_entry.dart';
import '../ui/pages/cellar_page.dart';
import '../ui/pages/discover_page.dart';
import '../ui/pages/scan_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.routePath,
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
        path: MyProfileScreen.routePath,
        name: MyProfileScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MyProfileScreen(),
        ),
        routes: [
          GoRoute(
            path: 'change-password',
            name: ChangePasswordScreen.routeName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChangePasswordScreen(),
            ),
          ),
        ],
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
                    color: Colors.black.withOpacity(0.06),
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
                        icon: Icons.wine_bar_rounded,
                        label: 'My Cellar',
                        isSelected: state.matchedLocation.startsWith('/cellar'),
                        onTap: () => navigationShell.goBranch(1),
                      ),
                      _NavItem(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Discover',
                        isSelected:
                            state.matchedLocation.startsWith('/discover'),
                        onTap: () => navigationShell.goBranch(2),
                      ),
                      _NavItem(
                        icon: Icons.camera_alt_rounded,
                        label: 'Scan',
                        isSelected: state.matchedLocation.startsWith('/scan'),
                        onTap: () => navigationShell.goBranch(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        branches: [
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
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DiscoverPage(),
                ),
              ),
            ],
          ),
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
