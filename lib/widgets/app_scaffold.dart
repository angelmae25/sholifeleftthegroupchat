// =============================================================================
// VIEW (Widget): app_scaffold.dart
// Shared scaffold with sidebar drawer. Used by all authenticated screens.
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageColor(context),
      appBar: AppBar(
        title: _LogoTitle(),
        actions: [
          if (actions != null) ...actions!,
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
          // ── Avatar button — reads from AuthController ──────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Consumer<AuthController>(
              builder: (_, auth, __) => GestureDetector(
                onTap: () => context.push('/profile'),
                child: _AppBarAvatar(avatarUrl: auth.user?.avatarUrl),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

// ── App bar avatar ─────────────────────────────────────────────────────────────
class _AppBarAvatar extends StatelessWidget {
  final String? avatarUrl;
  const _AppBarAvatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      // base64 data URI
      if (avatarUrl!.startsWith('data:image')) {
        try {
          final bytes = base64Decode(avatarUrl!.split(',').last);
          return CircleAvatar(
            radius: 16,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      }
      // network URL
      if (avatarUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(avatarUrl!),
          backgroundColor: AppTheme.accentLight,
          onBackgroundImageError: (_, __) {},
        );
      }
    }
    // default
    return const CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.accentLight,
      child: Icon(Icons.person, size: 18, color: AppTheme.primaryDark),
    );
  }
}

class _LogoTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/splash_logo.png',
    height: 30,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => RichText(
      text: const TextSpan(children: [
        TextSpan(text: 'Scho', style: TextStyle(color: Colors.white,         fontWeight: FontWeight.w900, fontSize: 18)),
        TextSpan(text: 'O',    style: TextStyle(color: AppTheme.accentLight, fontWeight: FontWeight.w900, fontSize: 18)),
        TextSpan(text: 'life', style: TextStyle(color: Colors.white,         fontWeight: FontWeight.w900, fontSize: 18)),
      ]),
    ),
  );
}

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({required this.currentRoute});

  static const _navItems = [
    (Icons.home_outlined,           'Home',            '/home'),
    (Icons.newspaper_outlined,      'News',            '/news'),
    (Icons.event_outlined,          'Events',          '/events'),
    (Icons.store_outlined,          'Pre-loved Items', '/marketplace'),
    (Icons.search_outlined,         'Lost & Found',    '/lost-found'),
    (Icons.chat_bubble_outline,     'Chat',            '/chat'),
    (Icons.groups_outlined,         'Clubs',           '/clubs'),
    (Icons.leaderboard_outlined,    'Leaderboard',     '/leaderboard'),
    (Icons.person_outline,          'Profile',         '/profile'),
    (Icons.settings_outlined,       'Settings',        '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark      = AppTheme.isDark(context);
    final drawerBg    = isDark ? AppTheme.fbDarkCard    : AppTheme.sidebarBg;
    final headerBg    = isDark ? AppTheme.fbDarkBg      : AppTheme.primaryDark;
    final nameClr     = isDark ? AppTheme.fbDarkTextMain : Colors.white;
    final emailClr    = isDark ? AppTheme.fbDarkTextSub  : AppTheme.textOnDarkMuted;
    final dividerClr  = isDark ? AppTheme.fbDarkDivider  : Colors.white24;

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // ── User header with real avatar ─────────────────────────────────
            Consumer<AuthController>(
              builder: (_, auth, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(color: headerBg),
                child: Column(children: [
                  // ── Avatar ─────────────────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                    child: Stack(
                      children: [
                        DrawerAvatar(avatarUrl: auth.user?.avatarUrl),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 22, height: 22,
                            decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.edit,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    auth.user?.fullName ?? 'Student',
                    style: TextStyle(
                        color: nameClr,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  if ((auth.user?.email ?? '').isNotEmpty)
                    Text(
                      auth.user!.email,
                      style: TextStyle(color: emailClr, fontSize: 12),
                    ),
                ]),
              ),
            ),
            Divider(color: dividerClr),
            // ── Nav items ────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _navItems.map((item) => DrawerNavItem(
                  icon: item.$1, label: item.$2,
                  route: item.$3, current: currentRoute,
                )).toList(),
              ),
            ),
            Divider(color: dividerClr),
            // ── Sign out ─────────────────────────────────────────────────────
            ListTile(
              leading: Icon(Icons.logout,
                  color: Colors.redAccent[100], size: 22),
              title: Text('Sign Out',
                  style: TextStyle(
                      color: Colors.redAccent[100],
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthController>().signOut();
                if (context.mounted) context.go('/sign-in');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Drawer avatar (larger, 36 radius) ─────────────────────────────────────────
class DrawerAvatar extends StatelessWidget {
  final String? avatarUrl;
  const DrawerAvatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:image')) {
        try {
          final bytes = base64Decode(avatarUrl!.split(',').last);
          return CircleAvatar(
            radius: 36,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      }
      if (avatarUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: 36,
          backgroundImage: NetworkImage(avatarUrl!),
          backgroundColor: AppTheme.accentLight,
          onBackgroundImageError: (_, __) {},
        );
      }
    }
    return const CircleAvatar(
      radius: 36,
      backgroundColor: AppTheme.accentLight,
      child: Icon(Icons.person, size: 40, color: AppTheme.primaryDark),
    );
  }
}

class DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label, route, current;
  const DrawerNavItem({
    required this.icon, required this.label,
    required this.route, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive     = current == route;
    final isDark       = AppTheme.isDark(context);
    final activeHighlight = isDark
        ? AppTheme.primary.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.2);
    final activeClr    = isDark ? AppTheme.accentLight  : Colors.white;
    final inactiveClr  = isDark ? AppTheme.fbDarkTextSub : AppTheme.textOnDarkMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? activeHighlight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            color: isActive ? activeClr : inactiveClr, size: 22),
        title: Text(label, style: TextStyle(
          color: isActive ? activeClr : inactiveClr,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          fontSize: 14,
        )),
        onTap: () { Navigator.pop(context); context.go(route); },
      ),
    );
  }
}