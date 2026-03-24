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
      backgroundColor: AppTheme.surface,
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
      drawer: _AppDrawer(currentRoute: currentRoute),
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

class _AppDrawer extends StatelessWidget {
  final String currentRoute;
  const _AppDrawer({required this.currentRoute});

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
    return Drawer(
      backgroundColor: AppTheme.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            // ── User header with real avatar ─────────────────────────────────
            Consumer<AuthController>(
              builder: (_, auth, __) => Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(children: [
                  // ── Avatar ─────────────────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                    child: Stack(
                      children: [
                        _DrawerAvatar(avatarUrl: auth.user?.avatarUrl),
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  if ((auth.user?.email ?? '').isNotEmpty)
                    Text(
                      auth.user!.email,
                      style: const TextStyle(
                          color: AppTheme.textOnDarkMuted, fontSize: 12),
                    ),
                ]),
              ),
            ),
            const Divider(color: Colors.white24),
            // ── Nav items ────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _navItems.map((item) => _DrawerNavItem(
                  icon: item.$1, label: item.$2,
                  route: item.$3, current: currentRoute,
                )).toList(),
              ),
            ),
            const Divider(color: Colors.white24),
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
class _DrawerAvatar extends StatelessWidget {
  final String? avatarUrl;
  const _DrawerAvatar({this.avatarUrl});

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

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label, route, current;
  const _DrawerNavItem({
    required this.icon, required this.label,
    required this.route, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = current == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            color: isActive ? Colors.white : AppTheme.textOnDarkMuted,
            size: 22),
        title: Text(label, style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textOnDarkMuted,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          fontSize: 14,
        )),
        onTap: () { Navigator.pop(context); context.go(route); },
      ),
    );
  }
}