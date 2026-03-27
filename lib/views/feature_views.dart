// FILE PATH: lib/views/feature_views.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/controllers.dart';
import '../controllers/org_post_controller.dart';
import '../models/news_model.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOME VIEW
// ─────────────────────────────────────────────────────────────────────────────
class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsController>().loadArticles();
      context.read<EventsController>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardClr = AppTheme.cardColor(context);
    final textSubClr = AppTheme.textSub(context);
    return AppScaffold(
      title: 'Home', currentRoute: '/home',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Consumer<AuthController>(builder: (_, auth, __) {
            final name = auth.user?.fullName ?? 'Student';
            final info = auth.user != null ? '${auth.user!.yearLevel} · ${auth.user!.course}' : '';
            return Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ← FIXED: Colors.white70 not AppTheme.cardColor(context)70
                const Text('Good day, 👋', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                if (info.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20)),
                    child: Text(info, style: const TextStyle(color: AppTheme.primaryDark, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            );
          }),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Quick Access'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12,
            children: [
              _QuickBtn(icon: Icons.newspaper_outlined,   label: 'News',    route: '/news'),
              _QuickBtn(icon: Icons.event_outlined,       label: 'Events',  route: '/events'),
              _QuickBtn(icon: Icons.store_outlined,       label: 'Market',  route: '/marketplace'),
              _QuickBtn(icon: Icons.search_outlined,      label: 'Lost',    route: '/lost-found'),
              _QuickBtn(icon: Icons.chat_bubble_outline,  label: 'Chat',    route: '/chat'),
              _QuickBtn(icon: Icons.groups_outlined,      label: 'Clubs',   route: '/clubs'),
              _QuickBtn(icon: Icons.leaderboard_outlined, label: 'Board',   route: '/leaderboard'),
              _QuickBtn(icon: Icons.person_outline,       label: 'Profile', route: '/profile'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Latest News', onSeeAll: () => context.go('/news')),
          const SizedBox(height: 8),
          Consumer<NewsController>(builder: (_, ctrl, __) {
            if (ctrl.isLoading) return const _LoadingCard();
            final articles = ctrl.articles.take(2).toList();
            return Column(children: articles.map((a) => _NewsCard(article: a)).toList());
          }),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Upcoming Events', onSeeAll: () => context.go('/events')),
          const SizedBox(height: 8),
          Consumer<EventsController>(builder: (_, ctrl, __) {
            if (ctrl.isLoading) return const _LoadingCard();
            return SizedBox(
              height: 130,
              child: ListView(scrollDirection: Axis.horizontal,
                  children: ctrl.events.map((e) => _EventMiniCard(event: e)).toList()),
            );
          }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEWS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      context.read<NewsController>().loadArticles();

      final studentId =
          context.read<AuthController>().user?.studentId ?? '';

      context.read<OrgPostController>().loadMyOrganizations(studentId);

    });
  }

  @override
  Widget build(BuildContext context) {

    final cardClr = AppTheme.cardColor(context);
    final pageClr = AppTheme.pageColor(context);
    final textSubClr = AppTheme.textSub(context);
    final borderClr = AppTheme.borderCol(context);

    return Consumer2<OrgPostController, NewsController>(
      builder: (context, orgCtrl, newsCtrl, child) {

        final hasRole = orgCtrl.hasOrgs;

        return Scaffold(
          backgroundColor: pageClr,

          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: const Text("SchoLife"),
          ),

          drawer: _buildDrawer(context, '/news'),

          floatingActionButton: hasRole
              ? FloatingActionButton.extended(
            heroTag: 'news_fab',
            onPressed: () =>
                context.push('/create-post', extra: 'news'),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Post News',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
          )
              : null,

          body: Column(
            children: [

              if (hasRole)
                _OrgRoleBanner(orgCtrl: orgCtrl),

              Container(
                color: cardClr,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: NewsCategory.values.map((cat) {

                      final isActive =
                          newsCtrl.activeCategory == cat;

                      return GestureDetector(
                        onTap: () =>
                            newsCtrl.setCategory(cat),

                        child: AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),

                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),

                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primary
                                : pageClr,
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primary
                                  : borderClr,
                            ),
                          ),

                          child: Text(
                            cat.label,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : textSubClr,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (newsCtrl.isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.fromLTRB(14, 14, 14, 80),
                    itemCount:
                    newsCtrl.filteredArticles.length,
                    itemBuilder: (_, i) {

                      final article =
                      newsCtrl.filteredArticles[i];

                      return article.isFeatured
                          ? _FeaturedNewsCard(article: article)
                          : _NewsCard(article: article);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class EventsView extends StatefulWidget {
  const EventsView({super.key});
  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsController>().loadEvents();
      final studentId = context.read<AuthController>().user?.studentId ?? '';
      context.read<OrgPostController>().loadMyOrganizations(studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageClr = AppTheme.pageColor(context);
    return Consumer2<OrgPostController, EventsController>(
      builder: (_, orgCtrl, evCtrl, __) {
        final hasRole = true;
        return Scaffold(
          backgroundColor: pageClr,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            leading: Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
            title: Image.asset('assets/images/splash_logo.png', height: 30, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('SchoLife',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: const CircleAvatar(radius: 16, backgroundColor: AppTheme.accentLight,
                      child: Icon(Icons.person, size: 18, color: AppTheme.primaryDark)),
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(context, '/events'),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: hasRole
              ? FloatingActionButton(
            heroTag: 'events_fab',
            onPressed: () => context.push('/create-post', extra: 'event'),
            backgroundColor: AppTheme.primary,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          )
              : null,
          body: Column(children: [
            if (hasRole) _OrgRoleBanner(orgCtrl: orgCtrl),
            if (evCtrl.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
            else if (evCtrl.error != null)
              Expanded(child: _ErrorWidget(evCtrl.error!))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  itemCount: evCtrl.events.length,
                  itemBuilder: (_, i) => EventCardWithAttend(event: evCtrl.events[i]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER BUILDER
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildDrawer(BuildContext context, String currentRoute) {
  const navItems = [
    (Icons.home_outlined,        'Home',            '/home'),
    (Icons.newspaper_outlined,   'News',            '/news'),
    (Icons.event_outlined,       'Events',          '/events'),
    (Icons.store_outlined,       'Pre-loved Items', '/marketplace'),
    (Icons.search_outlined,      'Lost & Found',    '/lost-found'),
    (Icons.chat_bubble_outline,  'Chat',            '/chat'),
    (Icons.groups_outlined,      'Clubs',           '/clubs'),
    (Icons.leaderboard_outlined, 'Leaderboard',     '/leaderboard'),
    (Icons.person_outline,       'Profile',         '/profile'),
    (Icons.settings_outlined,    'Settings',        '/settings'),
  ];
  return Drawer(
    backgroundColor: AppTheme.sidebarBg,
    child: SafeArea(
      child: Column(children: [
        Consumer<AuthController>(
          builder: (_, auth, __) => Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(children: [
              Image.asset('assets/images/splash_logo.png', height: 64,
                  errorBuilder: (_, __, ___) => const CircleAvatar(
                    radius: 32, backgroundColor: AppTheme.accentLight,
                    child: Icon(Icons.menu_book, size: 36, color: AppTheme.primaryDark),
                  )),
              const SizedBox(height: 10),
              Text(auth.user?.fullName ?? 'Student',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              if ((auth.user?.email ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(auth.user!.email,
                    style: const TextStyle(color: AppTheme.textOnDarkMuted, fontSize: 12)),
              ],
            ]),
          ),
        ),
        const Divider(color: Colors.white24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: navItems.map((item) => _DrawerNavItem(
              icon: item.$1, label: item.$2, route: item.$3, current: currentRoute,
            )).toList(),
          ),
        ),
        const Divider(color: Colors.white24),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.redAccent[100], size: 22),
          title: Text('Sign Out',
              style: TextStyle(color: Colors.redAccent[100], fontWeight: FontWeight.w600, fontSize: 14)),
          onTap: () async {
            Navigator.pop(context);
            await context.read<AuthController>().signOut();
            if (context.mounted) context.go('/sign-in');
          },
        ),
        const SizedBox(height: 12),
      ]),
    ),
  );
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label, route, current;
  const _DrawerNavItem({required this.icon, required this.label, required this.route, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = current == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        // ← FIXED: Colors.white.withValues not AppTheme.cardColor(context).withOpacity
        color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isActive ? Colors.white : AppTheme.textOnDarkMuted, size: 22),
        title: Text(label, style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textOnDarkMuted,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, fontSize: 14,
        )),
        onTap: () { Navigator.pop(context); context.go(route); },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORG ROLE BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _OrgRoleBanner extends StatelessWidget {
  final OrgPostController orgCtrl;
  const _OrgRoleBanner({required this.orgCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: Row(children: [
        const Icon(Icons.verified_outlined, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            orgCtrl.organizations.map((o) =>
            '${o.roleName} · ${o.acronym.isNotEmpty ? o.acronym : o.organizationName}').join('  •  '),
            style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
          // ← FIXED: Colors.white not AppTheme.cardColor(context) inside const
          child: const Text('Officer', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT CARD WITH ATTEND BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class EventCardWithAttend extends StatefulWidget {
  final EventModel event;
  const EventCardWithAttend({super.key, required this.event});
  @override
  State<EventCardWithAttend> createState() => _EventCardWithAttendState();
}

class _EventCardWithAttendState extends State<EventCardWithAttend> {
  bool _attended   = false;
  bool _checking   = true;
  bool _submitting = false;

  @override
  void initState() { super.initState(); _checkAttendance(); }

  Future<void> _checkAttendance() async {
    final result = await context.read<EventsController>().hasAttended(widget.event.id);
    if (mounted) setState(() { _attended = result; _checking = false; });
  }

  Future<void> _attend() async {
    if (_attended || _submitting) return;
    setState(() => _submitting = true);
    final result = await context.read<EventsController>().attendEvent(widget.event.id);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result['ok'] == true) {
      setState(() => _attended = true);
      final pts = result['points'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.stars_outlined, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text('🎉 Attendance marked! You now have $pts points.',
              style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      if (result['already_attended'] == true) setState(() => _attended = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Could not mark attendance.'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final event   = widget.event;
    final cardClr = AppTheme.cardColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      child: Column(children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [event.color, event.color.withValues(alpha: 0.6)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          // ← FIXED: Colors.white not AppTheme.cardColor(context) in const TextStyle
          child: Center(child: Text(event.shortName,
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2))),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(event.fullName,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textMain(context)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: event.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(event.category, style: TextStyle(color: event.color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 8),
            _detail(context, Icons.calendar_today_outlined, '${event.date.month}/${event.date.day}/${event.date.year}'),
            const SizedBox(height: 4),
            _detail(context, Icons.location_on_outlined, event.venue),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: event.color,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text('Learn More', style: TextStyle(fontSize: 13, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              _checking
                  ? const SizedBox(width: 36, height: 36,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                  : ElevatedButton.icon(
                onPressed: (_attended || _submitting) ? null : _attend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _attended ? Colors.green.shade600 : AppTheme.accent,
                  foregroundColor: _attended ? Colors.white : AppTheme.primaryDark,
                  disabledBackgroundColor: _attended ? Colors.green.shade600 : Colors.grey.shade300,
                  disabledForegroundColor: _attended ? Colors.white : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _submitting
                    ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_attended ? Icons.check_circle_outline : Icons.how_to_reg_outlined, size: 16),
                label: Text(_attended ? 'Attended' : 'Attend',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _detail(BuildContext context, IconData icon, String text) => Row(children: [
    Icon(icon, size: 15, color: AppTheme.textSub(context)),
    const SizedBox(width: 6),
    Text(text, style: TextStyle(color: AppTheme.textSub(context), fontSize: 13)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textMain(context))),
      if (onSeeAll != null)
        TextButton(onPressed: onSeeAll, child: const Text('See all', style: TextStyle(color: AppTheme.primary, fontSize: 13))),
    ],
  );
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label, route;
  const _QuickBtn({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go(route),
    child: Column(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 26),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSub(context))),
    ]),
  );
}

class _NewsCard extends StatelessWidget {
  final NewsModel article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final cardClr = AppTheme.cardColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: article.category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.article_outlined, color: article.category.color, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: article.category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(article.category.tag, style: TextStyle(color: article.category.color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(article.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain(context))),
          Text(article.body, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textSub(context), fontSize: 12, height: 1.4)),
          const SizedBox(height: 6),
          Text(article.timeAgo, style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
        ])),
      ]),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  final NewsModel article;
  const _FeaturedNewsCard({required this.article});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [article.category.color, article.category.color.withValues(alpha: 0.7)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(article.category.tag,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 12),
        Text(article.title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 8),
        // ← FIXED: Colors.white70 not AppTheme.cardColor(context)70
        Text(article.body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.access_time, color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text(article.timeAgo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text('Read More', style: TextStyle(color: article.category.color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    ),
  );
}

class _EventMiniCard extends StatelessWidget {
  final EventModel event;
  const _EventMiniCard({required this.event});

  @override
  Widget build(BuildContext context) => Container(
    width: 130, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [event.color, event.color.withValues(alpha: 0.7)],
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      // ← FIXED: Colors.white70 not AppTheme.cardColor(context)70
      const Icon(Icons.event, color: Colors.white70, size: 28),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.shortName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        Text('${event.date.month}/${event.date.day}', style: const TextStyle(color: AppTheme.accentLight, fontSize: 12)),
      ]),
    ]),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 80, margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      // ← FIXED: was CAppTheme.cardColor(context) — typo fixed
      color: AppTheme.cardColor(context),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
  );
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget(this.message);
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: AppTheme.primary, size: 48),
      const SizedBox(height: 12),
      Text(message, style: TextStyle(color: AppTheme.textSub(context))),
    ]),
  );
}