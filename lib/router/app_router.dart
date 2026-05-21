import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/community_post.dart';
import '../models/journal_entry.dart';
import '../models/memory_entry.dart';
import '../models/user_profile.dart';
import '../providers/app_state_provider.dart';
import '../providers/user_profile_provider.dart';
import '../screens/auth/password_reset_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/calendar/calendar_view_screen.dart';
import '../screens/checkin/checkin_screen.dart';
import '../screens/community/community_home_screen.dart';
import '../screens/community/community_post_view_screen.dart';
import '../screens/community/create_post_screen.dart';
import '../screens/community/my_posts_screen.dart';
import '../screens/companion/ai_memory_controls_screen.dart';
import '../screens/companion/companion_chat_screen.dart';
import '../screens/harddate/hard_date_screen.dart';
import '../screens/home/home_dashboard_screen.dart';
import '../screens/journal/grief_wave_screen.dart';
import '../screens/journal/journal_entry_view_screen.dart';
import '../screens/journal/journal_freewrite_screen.dart';
import '../screens/journal/journal_home_screen.dart';
import '../screens/journal/journal_prompted_screen.dart';
import '../screens/memory/memory_add_screen.dart';
import '../screens/memory/memory_home_screen.dart';
import '../screens/memory/memory_view_screen.dart';
import '../screens/dev/screen_index_screen.dart';
import '../screens/misc/about_screen.dart';
import '../screens/onboarding/loss_dates_screen.dart';
import '../screens/onboarding/loss_type_screen.dart';
import '../screens/onboarding/loss_who_screen.dart';
import '../screens/onboarding/notification_permission_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/paywall/paywall_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/data_export_screen.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/candle_icon.dart';
import '../widgets/luminary_button.dart';

// Global navigator key — needed for notification tap routing
final navigatorKey = GlobalKey<NavigatorState>();

// Routes that expired users can still access
const _expiredAllowedRoutes = [
  '/paywall',
  '/home/dashboard',
  '/calendar',
  '/settings',
  '/home/profile',
  '/about',
  '/sign-out',
];

// ── Router refresh notifier ───────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen<AppState>(appStateProvider, (prev, next) => notifyListeners());
  }
}

// ── GoRouter provider ─────────────────────────────────────────────────────────

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final appState = ref.read(appStateProvider);

      // Wait for initial prefs load before making any routing decisions
      if (!appState.isLoaded) return null;

      final path = state.matchedLocation;
      final isSplash = path == '/splash';
      final isDev = path.startsWith('/dev');
      final isAuthPage = const ['/sign-in', '/sign-up', '/password-reset']
          .contains(path);
      final isOnboarding = path.startsWith('/onboarding');

      // Splash self-navigates via ref.listen; dev always allowed
      if (isSplash || isDev) return null;

      // Not logged in → sign in (auth pages pass through)
      if (!appState.sessionActive && !isAuthPage) return '/sign-in';

      // Logged in, onboarding not done → start onboarding
      if (appState.sessionActive &&
          !appState.onboardingComplete &&
          !isOnboarding &&
          !isAuthPage) {
        return '/onboarding/welcome';
      }

      // Logged in, onboarding done → redirect away from auth/onboarding pages
      if (appState.sessionActive &&
          appState.onboardingComplete &&
          (isAuthPage || isOnboarding)) {
        return '/home/dashboard';
      }

      // Subscription expired → paywall (with read-only exceptions)
      final user = ref.read(userProfileProvider);
      if (user != null && appState.sessionActive && appState.onboardingComplete) {
        final isExpired =
            user.subscriptionStatus == SubscriptionStatus.expired ||
                (user.subscriptionStatus == SubscriptionStatus.trial &&
                    user.trialEndDate != null &&
                    DateTime.now().isAfter(user.trialEndDate!));

        if (isExpired) {
          final isReadOnly = path.startsWith('/home/journal/entry') ||
              path.startsWith('/home/memory/view');
          final isAllowed = _expiredAllowedRoutes
              .any((r) => path == r || path.startsWith('$r/'));
          if (!isAllowed && !isReadOnly) return '/paywall';
        }
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.bgGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CandleIcon(size: 40),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LuminaryButton(
                label: 'Go to sign in',
                style: LuminaryButtonStyle.primary,
                onTap: () => GoRouter.of(context).go('/sign-in'),
              ),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/sign-up', builder: (ctx, state) => const SignUpScreen()),
      GoRoute(path: '/sign-in', builder: (ctx, state) => const SignInScreen()),
      GoRoute(
          path: '/password-reset',
          builder: (ctx, state) => const PasswordResetScreen()),

      // ── Onboarding ──────────────────────────────────────────────────────────
      GoRoute(
          path: '/onboarding/welcome',
          builder: (ctx, state) => const WelcomeScreen()),
      GoRoute(
          path: '/onboarding/who',
          builder: (ctx, state) => const LossWhoScreen()),
      GoRoute(
          path: '/onboarding/dates',
          builder: (ctx, state) => const LossDatesScreen()),
      GoRoute(
          path: '/onboarding/type',
          builder: (ctx, state) => const LossTypeScreen()),
      GoRoute(
          path: '/onboarding/notifications',
          builder: (ctx, state) => const NotificationPermissionScreen()),
      GoRoute(
          path: '/dev/screens',
          builder: (ctx, state) => const ScreenIndexScreen()),

      // ── Shell with bottom nav ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) => _MainShell(shell: shell),
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/dashboard',
              builder: (ctx, state) => const HomeDashboardScreen(),
            ),
          ]),
          // Branch 1: Companion — no bottom nav bar
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/companion',
              builder: (ctx, state) => const CompanionChatScreen(),
            ),
          ]),
          // Branch 2: Journal
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/journal',
              builder: (ctx, state) => const JournalHomeScreen(),
              routes: [
                GoRoute(
                  path: 'prompted',
                  builder: (ctx, state) => const JournalPromptedScreen(),
                ),
                GoRoute(
                  path: 'freewrite',
                  builder: (ctx, state) => JournalFreewiteScreen(
                    existingEntry: state.extra as JournalEntry?,
                  ),
                ),
                GoRoute(
                  path: 'wave',
                  builder: (ctx, state) => const GriefWaveScreen(),
                ),
                GoRoute(
                  path: 'entry/:id',
                  builder: (ctx, state) {
                    final entry = state.extra as JournalEntry;
                    return JournalEntryViewScreen(entry: entry);
                  },
                ),
              ],
            ),
          ]),
          // Branch 3: Community
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/community',
              builder: (ctx, state) => const CommunityHomeScreen(),
              routes: [
                GoRoute(
                  path: 'post/:id',
                  builder: (ctx, state) {
                    final post = state.extra as CommunityPost;
                    return CommunityPostViewScreen(post: post);
                  },
                ),
                GoRoute(
                  path: 'create',
                  builder: (ctx, state) => const CreatePostScreen(),
                ),
                GoRoute(
                  path: 'my-posts',
                  builder: (ctx, state) => const MyPostsScreen(),
                ),
              ],
            ),
          ]),
          // Branch 4: Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/profile',
              builder: (ctx, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ── Memory ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home/memory',
        builder: (ctx, state) => const MemoryHomeScreen(),
        routes: [
          GoRoute(
              path: 'add',
              builder: (ctx, state) => const MemoryAddScreen()),
          GoRoute(
            path: 'view/:id',
            builder: (ctx, state) {
              final memory = state.extra as MemoryEntry;
              return MemoryViewScreen(memory: memory);
            },
          ),
        ],
      ),

      // ── Modal / full-screen overlays ─────────────────────────────────────────
      GoRoute(
        path: '/checkin',
        pageBuilder: (ctx, state) => const CupertinoPage(
          fullscreenDialog: true,
          child: CheckinScreen(),
        ),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (ctx, state) {
          final dismissible =
              state.uri.queryParameters['dismissible'] == 'true';
          return CupertinoPage(
            fullscreenDialog: true,
            child: PaywallScreen(dismissible: dismissible),
          );
        },
      ),
      GoRoute(
        path: '/hard-date',
        pageBuilder: (ctx, state) => const CupertinoPage(
          fullscreenDialog: true,
          child: HardDateScreen(),
        ),
      ),
      GoRoute(
          path: '/calendar',
          builder: (ctx, state) => const CalendarViewScreen()),
      GoRoute(
        path: '/settings',
        builder: (ctx, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'export',
            builder: (ctx, state) => const DataExportScreen(),
          ),
        ],
      ),
      GoRoute(path: '/about', builder: (ctx, state) => const AboutScreen()),
      GoRoute(
          path: '/ai-memory',
          builder: (ctx, state) => const AiMemoryControlsScreen()),
    ],
  );
  return router;
});

// ── Main shell widget ─────────────────────────────────────────────────────────

class _MainShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const _MainShell({required this.shell});

  NavTab get _activeTab => NavTab.values[shell.currentIndex];

  // Companion tab (index 1) is full-screen — hide nav bar
  bool get _showNavBar => shell.currentIndex != 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    return Scaffold(
      body: Stack(
        children: [
          shell,
          if (_showNavBar)
            BottomNavBar(
              activeTab: _activeTab,
              onTabSelected: (tab) {
                shell.goBranch(
                  tab.index,
                  initialLocation: tab.index == shell.currentIndex,
                );
              },
            ),
          if (isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: const Color(0xFF3B3B4F),
                  child: const Text(
                    'You\'re offline — some features are unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
