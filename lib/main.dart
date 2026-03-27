// =============================================================================
// main.dart — Application entry point
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/controllers.dart';
import 'controllers/org_post_controller.dart';

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

  // ── Uncomment these lines once Firebase is set up ─────────────────────────
  // await Firebase.initializeApp();
  // await NotificationService.instance.init();
  // NotificationService.instance.onNotificationTap = (message) {
  //   final type = NotificationService.getNotificationType(message);
  //   if (type == 'event') _router.go('/events');
  //   if (type == 'news')  _router.go('/news');
  // };

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light));

  runApp(const ScholifeApp());
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
    

    // ── Create Post route (for org-assigned students) ──────────────────────
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
  const ScholifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Auth ───────────────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AuthController()),

        // ── Feature controllers ────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => NewsController()),
        ChangeNotifierProvider(create: (_) => EventsController()),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
        ChangeNotifierProvider(create: (_) => LostFoundController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => ClubsController()),
        ChangeNotifierProvider(create: (_) => LeaderboardController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),

        // ── Settings — loaded first so dark mode applies on startup ────────
        ChangeNotifierProvider(
          create: (_) {
            final c = SettingsController();
            c.loadSettings(); // load dark mode preference from SharedPreferences
            return c;
          },
        ),

        // ── Org posting (assigned students only) ───────────────────────────
        ChangeNotifierProvider(create: (_) => OrgPostController()),
      ],

      // ── Consumer<SettingsController> drives light/dark theme ──────────────
      child: Consumer<SettingsController>(
        builder: (_, settings, __) => MaterialApp.router(
          title: 'Scholife',
          theme:      AppTheme.theme,       // light theme
          darkTheme:  AppTheme.darkTheme,   // dark theme
          themeMode:  settings.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}