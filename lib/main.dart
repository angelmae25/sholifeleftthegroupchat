// =============================================================================
// main.dart  (UPDATED)
// - SQLite settings loaded before runApp() to prevent dark mode flicker
// - SettingsController no longer needs loadSettings() called manually in
//   the provider create — it's pre-loaded here
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/controllers.dart';
import 'controllers/org_post_controller.dart';
import '../services/database_service.dart';

// Views
import 'views/splash_view.dart';
import 'views/auth_view.dart';
import 'views/feature_views.dart';
import 'views/secondary_views.dart';
import 'views/create_post_view.dart';
import 'views/sell_item_view.dart';
import 'views/report_lost_found_view.dart';
import 'views/edit_profile_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Pre-load SQLite settings BEFORE runApp so dark mode applies instantly ──
  // This prevents the white flash when dark mode is enabled on app open.
  final settingsRow = await DatabaseService.instance.loadSettings();
  final savedDarkMode = (settingsRow['dark_mode'] as int? ?? 0) == 1;

  // ── Uncomment once Firebase is set up ─────────────────────────────────────
  // await Firebase.initializeApp();
  // await NotificationService.instance.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light));

  runApp(ScholifeApp(initialDarkMode: savedDarkMode));
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER
// ─────────────────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',               builder: (_, __) => const SplashView()),
    GoRoute(path: '/onboarding',     builder: (_, __) => const OnboardingView()),
    GoRoute(path: '/sign-in',        builder: (_, __) => const SignInView()),
    GoRoute(path: '/create-account', builder: (_, __) => const CreateAccountView()),
    GoRoute(path: '/home',           builder: (_, __) => const HomeView()),
    GoRoute(path: '/news',           builder: (_, __) => const NewsView()),
    GoRoute(path: '/events',         builder: (_, __) => const EventsView()),
    GoRoute(path: '/marketplace',    builder: (_, __) => const MarketplaceView()),
    GoRoute(path: '/lost-found',     builder: (_, __) => const LostFoundView()),
    GoRoute(path: '/chat',           builder: (_, __) => const ChatView()),
    GoRoute(path: '/clubs',          builder: (_, __) => const ClubsView()),
    GoRoute(path: '/leaderboard',    builder: (_, __) => const LeaderboardView()),
    GoRoute(path: '/profile',        builder: (_, __) => const ProfileView()),
    GoRoute(path: '/settings',       builder: (_, __) => const SettingsView()),

    GoRoute(
      path: '/create-post',
      builder: (context, state) => CreatePostView(
        initialTab: state.extra as String? ?? 'news',
      ),
    ),
    GoRoute(
      path: '/sell-item',
      builder: (_, __) => const SellItemView(),
    ),
    GoRoute(
      path: '/report-lost-found',
      builder: (context, state) => ReportLostFoundView(
        initialStatus: state.extra as String? ?? 'lost',
      ),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// ROOT APP
// ─────────────────────────────────────────────────────────────────────────────
class ScholifeApp extends StatelessWidget {
  final bool initialDarkMode;
  const ScholifeApp({super.key, required this.initialDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),

        ChangeNotifierProvider(create: (_) => NewsController()),
        ChangeNotifierProvider(create: (_) => EventsController()),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
        ChangeNotifierProvider(create: (_) => LostFoundController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => ClubsController()),
        ChangeNotifierProvider(create: (_) => LeaderboardController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),

        // ── Settings: pre-seeded with the dark mode value loaded before runApp
        // so there's zero flicker. loadSettings() is still called in
        // SplashView to load ALL other settings (notifications etc.)
        ChangeNotifierProvider(
          create: (_) {
            final c = SettingsController();
            c.seedDarkMode(initialDarkMode); // instant, no async needed
            return c;
          },
        ),

        ChangeNotifierProvider(create: (_) => OrgPostController()),
      ],

      child: Consumer<SettingsController>(
        builder: (_, settings, __) => MaterialApp.router(
          title: 'Scholife',
          theme:      AppTheme.theme,
          darkTheme:  AppTheme.darkTheme,
          themeMode:  settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}