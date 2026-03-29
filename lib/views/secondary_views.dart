import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/controllers.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/chat_socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'sell_item_view.dart';
import 'report_lost_found_view.dart';
import 'edit_profile_view.dart';
import 'terms_and_conditions_view.dart';
import 'privacy_policy_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MARKETPLACE VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MarketplaceView extends StatefulWidget {
  const MarketplaceView({super.key});
  @override
  State<MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<MarketplaceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MarketplaceController>().loadItems());
  }

  @override
  Widget build(BuildContext context) {
    final cardClr  = AppTheme.cardColor(context);
    final pageClr  = AppTheme.pageColor(context);
    return AppScaffold(
      title: 'Pre-loved Items', currentRoute: '/marketplace',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellItemView())),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        // ← FIXED: Colors.white not AppTheme.cardColor(context) in const TextStyle
        label: const Text('Sell Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Consumer<MarketplaceController>(builder: (_, ctrl, __) => Column(children: [
        Container(
          color: cardClr, padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: ctrl.search,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true, fillColor: pageClr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        if (ctrl.isLoading) const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
        if (!ctrl.isLoading) Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.70,
            ),
            itemCount: ctrl.items.length,
            itemBuilder: (_, i) => _ItemCard(item: ctrl.items[i]),
          ),
        ),
      ])),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final MarketplaceItemModel item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cardClr = AppTheme.cardColor(context);
    return Container(
      decoration: BoxDecoration(
        color: cardClr, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: _ItemImage(imageUrl: item.imageUrl, height: 110),
        ),
        Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(item.condition, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item.formattedPrice, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 15)),
            GestureDetector(
              onTap: () => _chatSeller(context, item.sellerId),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                // ← FIXED: Colors.white not AppTheme.cardColor(context)
                child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 14),
              ),
            ),
          ]),
        ])),
      ]),
    );
  }

  void _chatSeller(BuildContext context, String sellerId) {
    final myId = context.read<AuthController>().user?.id ?? '';
    if (sellerId == myId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is your own listing.'), behavior: SnackBarBehavior.floating));
      return;
    }
    ChatSocketService.instance.onDmReady = (_) { if (context.mounted) context.push('/chat'); };
    ChatSocketService.instance.startDm(sellerId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOST & FOUND VIEW
// ─────────────────────────────────────────────────────────────────────────────
class LostFoundView extends StatefulWidget {
  const LostFoundView({super.key});
  @override
  State<LostFoundView> createState() => _LostFoundViewState();
}

class _LostFoundViewState extends State<LostFoundView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<LostFoundController>().loadItems());
  }

  @override
  Widget build(BuildContext context) {
    final cardClr = AppTheme.cardColor(context);
    final pageClr = AppTheme.pageColor(context);
    return AppScaffold(
      title: 'Lost & Found', currentRoute: '/lost-found',
      body: Consumer<LostFoundController>(builder: (_, ctrl, __) => Column(children: [
        Container(
          color: cardClr, padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(color: pageClr, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _ToggleBtn('Lost Items',  ctrl.activeTab == LostFoundStatus.lost,  () => ctrl.setTab(LostFoundStatus.lost)),
              _ToggleBtn('Found Items', ctrl.activeTab == LostFoundStatus.found, () => ctrl.setTab(LostFoundStatus.found)),
            ]),
          ),
        ),
        if (ctrl.isLoading) const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
        if (!ctrl.isLoading) Expanded(
          child: ListView(padding: const EdgeInsets.all(14),
              children: ctrl.filteredItems.map((item) => _LostFoundCard(item: item)).toList()),
        ),
      ])),
      floatingActionButton: Consumer<LostFoundController>(builder: (_, ctrl, __) {
        final isLost = ctrl.activeTab == LostFoundStatus.lost;
        return FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ReportLostFoundView(initialStatus: isLost ? 'lost' : 'found'))),
          backgroundColor: isLost ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32),
          icon: Icon(isLost ? Icons.search_outlined : Icons.check_circle_outline, color: Colors.white),
          label: Text(isLost ? 'Report Lost' : 'Report Found',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        );
      }),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _ToggleBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3), padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          // ← FIXED: Colors.white not AppTheme.cardColor(context)
          color: active ? Colors.white : AppTheme.textSecondary,
          fontWeight: FontWeight.w600, fontSize: 13,
        )),
      ),
    ),
  );
}

class _LostFoundCard extends StatelessWidget {
  final LostFoundModel item;
  const _LostFoundCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLost = item.status == LostFoundStatus.lost;
    final color  = isLost ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32);
    final cardClr = AppTheme.cardColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardClr, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12),
              child: _LostFoundThumb(imageUrl: item.imageUrl, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain(context)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(isLost ? 'LOST' : 'FOUND', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(item.description, style: TextStyle(color: AppTheme.textSub(context), fontSize: 12, height: 1.4)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSub(context)),
              const SizedBox(width: 2),
              Text(item.location, style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
              const SizedBox(width: 10),
              Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textSub(context)),
              const SizedBox(width: 2),
              Text('${item.date.month}/${item.date.day}', style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
            ]),
          ])),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _contactReporter(context, item.reporterId),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(Icons.chat_bubble_outline, size: 15, color: color),
            label: Text(isLost ? 'Contact Owner' : 'Contact Finder',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  void _contactReporter(BuildContext context, String reporterId) {
    final myId = context.read<AuthController>().user?.id ?? '';
    if (reporterId == myId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is your own report.'), behavior: SnackBarBehavior.floating));
      return;
    }
    ChatSocketService.instance.onDmReady = (_) { if (context.mounted) context.push('/chat'); };
    ChatSocketService.instance.startDm(reporterId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT VIEW
// ─────────────────────────────────────────────────────────────────────────────
class ChatView extends StatefulWidget {
  const ChatView({super.key});
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myId = context.read<AuthController>().user?.id ?? '';
      context.read<ChatController>().setMyId(myId);
      context.read<ChatController>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chat', currentRoute: '/chat',
      body: Consumer<ChatController>(builder: (_, ctrl, __) {
        if (ctrl.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        if (ctrl.conversations.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No conversations yet.', style: TextStyle(color: AppTheme.textSub(context), fontSize: 14)),
              const SizedBox(height: 6),
              Text('Tap "Chat Seller" on a marketplace item\nor "Contact" on a lost & found report.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSub(context), fontSize: 12)),
            ]),
          );
        }
        return ListView.builder(
          itemCount: ctrl.conversations.length,
          itemBuilder: (_, i) {
            final c = ctrl.conversations[i];
            return _ConversationTile(chat: c, onTap: () {
              ctrl.openConversation(c.id);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(value: ctrl, child: _ChatDetailView(chat: c))));
            });
          },
        );
      }),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatModel chat; final VoidCallback onTap;
  const _ConversationTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: chat.isGroup ? AppTheme.accent.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.15),
        child: Icon(chat.isGroup ? Icons.groups : Icons.person,
            color: chat.isGroup ? AppTheme.accent : AppTheme.primary, size: 26),
      ),
      title: Text(chat.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain(context))),
      subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.textSub(context), fontSize: 12)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(chat.timeLabel, style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
        if (chat.unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            // ← FIXED: Colors.white not AppTheme.cardColor(context)
            child: Center(child: Text('${chat.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
          ),
        ],
      ]),
      onTap: onTap,
    ),
  );
}

class _ChatDetailView extends StatefulWidget {
  final ChatModel chat;
  const _ChatDetailView({required this.chat});
  @override
  State<_ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<_ChatDetailView> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardClr = AppTheme.cardColor(context);
    final pageClr = AppTheme.pageColor(context);
    return Scaffold(
      backgroundColor: pageClr,
      appBar: AppBar(
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        title: Text(widget.chat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Expanded(
          child: Consumer<ChatController>(builder: (_, ctrl, __) {
            _scrollToBottom();
            return ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(14),
              itemCount: ctrl.messages.length,
              itemBuilder: (_, i) {
                final msg = ctrl.messages[i];
                return Align(
                  alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: msg.isMine ? AppTheme.primary : cardClr,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isMine ? 16 : 4),
                        bottomRight: Radius.circular(msg.isMine ? 4 : 16),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(msg.text, style: TextStyle(
                        // ← FIXED: Colors.white not AppTheme.cardColor(context)
                        color: msg.isMine ? Colors.white : AppTheme.textMain(context), fontSize: 13,
                      )),
                      const SizedBox(height: 2),
                      Text(msg.timeLabel, style: TextStyle(
                        // ← FIXED: Colors.white60 not AppTheme.cardColor(context)60
                        color: msg.isMine ? Colors.white60 : AppTheme.textSub(context), fontSize: 10,
                      )),
                    ]),
                  ),
                );
              },
            );
          }),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: cardClr,
          child: Row(children: [
            Expanded(child: TextField(
              controller: _msgCtrl, textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...', filled: true,
                fillColor: AppTheme.pageColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_msgCtrl.text.trim().isEmpty) return;
                context.read<ChatController>().sendMessage(_msgCtrl.text);
                _msgCtrl.clear(); _scrollToBottom();
              },
              child: const CircleAvatar(radius: 22, backgroundColor: AppTheme.primary,
                  // ← FIXED: Colors.white not AppTheme.cardColor(context)
                  child: Icon(Icons.send, color: Colors.white, size: 18)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLUBS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class ClubsView extends StatefulWidget {
  const ClubsView({super.key});
  @override
  State<ClubsView> createState() => _ClubsViewState();
}

class _ClubsViewState extends State<ClubsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ClubsController>().loadClubs());
  }

  // ── Show org detail bottom sheet ──────────────────────────────────────────
  void _showOrgDetail(BuildContext context, ClubModel club) {
    // Extract the numeric org id from 'org_<id>'
    final rawId = club.id.startsWith('org_') ? club.id.replaceFirst('org_', '') : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrgDetailSheet(club: club, orgId: rawId),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Clubs & Organizations', currentRoute: '/clubs',
    body: Consumer<ClubsController>(builder: (_, ctrl, __) {
      if (ctrl.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      return GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
        ),
        itemCount: ctrl.clubs.length,
        itemBuilder: (_, i) {
          final club  = ctrl.clubs[i];
          final isOrg = club.id.startsWith('org_');
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: club.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(club.icon, color: club.color, size: 32),
              ),
              const SizedBox(height: 10),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(club.name, textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain(context)))),
              Text(club.department, style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
              const SizedBox(height: 12),
              if (isOrg)
              // ── Tappable "Organization" button ────────────────────────
                GestureDetector(
                  onTap: () => _showOrgDetail(context, club),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: club.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: club.color.withValues(alpha: 0.3)),
                    ),
                    child: Text('Organization', style: TextStyle(color: club.color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => ctrl.toggleMembership(club.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                    decoration: BoxDecoration(
                      color: club.isJoined ? club.color : Colors.transparent,
                      border: Border.all(color: club.color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(club.isJoined ? 'Joined ✓' : 'Join', style: TextStyle(
                      color: club.isJoined ? Colors.white : club.color, fontSize: 12, fontWeight: FontWeight.w700,
                    )),
                  ),
                ),
            ]),
          );
        },
      );
    }),
  );
}

// =============================================================================
// ORG DETAIL BOTTOM SHEET
// Fetches org info + officers from Spring Boot GET /api/org-post/organizations/{id}
// =============================================================================
class _OrgDetailSheet extends StatefulWidget {
  final ClubModel club;
  final String?   orgId;
  const _OrgDetailSheet({required this.club, this.orgId});

  @override
  State<_OrgDetailSheet> createState() => _OrgDetailSheetState();
}

class _OrgDetailSheetState extends State<_OrgDetailSheet> {
  // ── Spring Boot base (same IP as OrgPostService) ──────────────────────────
  // Update this IP to match your PC's WiFi IP.
  static const String _springBase = 'http://192.168.1.11:8080/api/org-post';

  bool                _loading = true;
  String?             _error;
  Map<String, Object> _detail  = {};
  List<dynamic>       _officers = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.orgId == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final res = await http
          .get(Uri.parse('$_springBase/organizations/${widget.orgId}'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _detail   = data.cast<String, Object>();
          _officers = (data['officers'] as List?) ?? [];
          _loading  = false;
        });
      } else {
        setState(() { _error = 'Could not load details (${res.statusCode}).'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Cannot reach server. Check your connection.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color   = widget.club.color;
    final isDark  = AppTheme.isDark(context);
    final cardBg  = AppTheme.cardColor(context);
    final textMain = AppTheme.textMain(context);
    final textSub  = AppTheme.textSub(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle,
                ),
                child: Icon(widget.club.icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.club.name,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textMain)),
                  if (widget.club.department.isNotEmpty)
                    Text(widget.club.department,
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text('Organization', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
          const SizedBox(height: 4),

          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.cloud_off_outlined, color: textSub, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center,
                      style: TextStyle(color: textSub, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _fetchDetail(); },
                      child: const Text('Retry')),
                ]),
              ),
            )
                : ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [

                // ── Info grid ──────────────────────────────────────
                _InfoRow(
                  Icons.person_outline,
                  'Adviser',
                  (_detail['adviser'] as String?)?.isNotEmpty == true
                      ? _detail['adviser'] as String
                      : '—',
                ),
                _InfoRow(
                  Icons.calendar_today_outlined,
                  'Year Founded',
                  _detail['yearFounded'] != null
                      ? _detail['yearFounded'].toString()
                      : '—',
                ),

                // ── Description ────────────────────────────────────
                if ((_detail['description'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  Text('About', style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: textMain)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      _detail['description'] as String,
                      style: TextStyle(fontSize: 13, color: textSub, height: 1.55),
                    ),
                  ),
                ],

                // ── Officers ───────────────────────────────────────
                const SizedBox(height: 18),
                Row(children: [
                  Text('Officers', style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: textMain)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_officers.length}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ),
                ]),
                const SizedBox(height: 10),

                if (_officers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No officers appointed yet.',
                        style: TextStyle(fontSize: 13, color: textSub)),
                  )
                else
                  ...(_officers.map((o) {
                    final officer = o as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(
                            (officer['name'] as String? ?? 'O').substring(0, 1).toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(officer['name'] as String? ?? '—',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textMain)),
                            const SizedBox(height: 2),
                            Text(officer['course'] as String? ?? '',
                                style: TextStyle(fontSize: 11, color: textSub)),
                            Text(officer['studentId'] as String? ?? '',
                                style: TextStyle(fontSize: 11, color: textSub, fontFamily: 'monospace')),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(officer['role'] as String? ?? '',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                        ),
                      ]),
                    );
                  }).toList()),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});
  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<LeaderboardController>().loadLeaderboard());
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Leaderboard', currentRoute: '/leaderboard',
    body: Consumer<LeaderboardController>(builder: (_, ctrl, __) {
      if (ctrl.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      return Column(children: [
        Container(
          color: AppTheme.primaryDark, padding: const EdgeInsets.all(20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (ctrl.topThree.length > 1) _PodiumCol(entry: ctrl.topThree[1], height: 80),
            const SizedBox(width: 12),
            if (ctrl.topThree.isNotEmpty) _PodiumCol(entry: ctrl.topThree[0], height: 100),
            const SizedBox(width: 12),
            if (ctrl.topThree.length > 2) _PodiumCol(entry: ctrl.topThree[2], height: 64),
          ]),
        ),
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.accent.withValues(alpha: 0.1),
          child: const Row(children: [
            Icon(Icons.stars_outlined, size: 16, color: AppTheme.accent),
            SizedBox(width: 8),
            Expanded(child: Text('Attend events to earn points and climb the leaderboard!  +10 pts per event',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500))),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: ctrl.theRest.length,
            itemBuilder: (_, i) {
              final e = ctrl.theRest[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: AppTheme.pageColor(context), shape: BoxShape.circle),
                    child: Center(child: Text('${e.rank}',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSub(context)))),
                  ),
                  const SizedBox(width: 12),
                  _LeaderboardAvatar(avatarUrl: e.avatarUrl, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain(context))),
                    Text(e.department, style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
                  ])),
                  Text('${e.points} pts', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
              );
            },
          ),
        ),
      ]);
    }),
  );
}

class _PodiumCol extends StatelessWidget {
  final LeaderboardEntryModel entry; final double height;
  const _PodiumCol({required this.entry, required this.height});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return Column(children: [
      Text(medals[entry.rank - 1], style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      _LeaderboardAvatar(avatarUrl: entry.avatarUrl, radius: 24),
      const SizedBox(height: 4),
      Text(entry.name.split(' ').first,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      Text('${entry.points}', style: const TextStyle(color: AppTheme.accentLight, fontSize: 11)),
      const SizedBox(height: 4),
      Container(
        width: 70, height: height,
        decoration: BoxDecoration(
          // ← FIXED: Colors.white.withValues not AppTheme.cardColor(context).withOpacity
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(child: Text('#${entry.rank}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE VIEW
// ─────────────────────────────────────────────────────────────────────────────
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<ProfileController>().loadProfile(auth.user?.id ?? '');
    });
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Profile', currentRoute: '/profile',
    body: Consumer<ProfileController>(builder: (_, ctrl, __) {
      if (ctrl.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      final user = ctrl.profile;
      if (user == null) return const Center(child: Text('Could not load profile.'));
      final cardClr = AppTheme.cardColor(context);
      return SingleChildScrollView(child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileView(user: user)))
                  .then((_) {
                if (!context.mounted) return;
                final auth = context.read<AuthController>();
                context.read<ProfileController>().loadProfile(auth.user?.id ?? '');
              }),
              child: Stack(children: [
                _ProfileAvatar(avatarUrl: user.avatarUrl, radius: 48),
                Positioned(bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // ← FIXED: Colors.white not AppTheme.cardColor(context) in on-gradient text
            Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text('${user.course} · ${user.yearLevel}',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
        ),
        Container(color: cardClr, padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              _StatCol('${user.points}', 'Points'),
              _StatCol('#${user.rank}', 'Rank'),
              _StatCol('${user.clubCount}', 'Clubs'),
              _StatCol('${user.postCount}', 'Posts'),
            ])),
        const SizedBox(height: 8),
        _InfoSection('Personal Information', [
          _InfoRow(Icons.person_outline,        'Full Name',   user.fullName),
          _InfoRow(Icons.badge_outlined,         'Student ID',  user.studentId),
          _InfoRow(Icons.school_outlined,        'Course',      user.course),
          _InfoRow(Icons.calendar_today_outlined,'Year Level',  user.yearLevel),
        ]),
        const SizedBox(height: 8),
        _InfoSection('Contact', [
          _InfoRow(Icons.email_outlined, 'Email', user.email),
          if (user.phone != null) _InfoRow(Icons.phone_outlined, 'Phone', user.phone!),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthController>().signOut();
                if (context.mounted) context.go('/sign-in');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]));
    }),
  );
}

class _StatCol extends StatelessWidget {
  final String value, label;
  const _StatCol(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary)),
    Text(label, style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
  ]));
}

class _InfoSection extends StatelessWidget {
  final String title; final List<Widget> rows;
  const _InfoSection(this.title, this.rows);
  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.cardColor(context), padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary)),
      const SizedBox(height: 10),
      ...rows,
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSub(context)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: AppTheme.textSub(context), fontSize: 11)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textMain(context))),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Settings', currentRoute: '/settings',
    body: Consumer<SettingsController>(builder: (_, ctrl, __) => ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _SettingsGroup('Notifications', [
          _ToggleRow('Push Notifications', 'Receive app notifications', Icons.notifications_outlined, ctrl.pushNotifications, ctrl.setPushNotifications),
          _ToggleRow('Email Alerts', 'Get updates via email', Icons.email_outlined, ctrl.emailAlerts, ctrl.setEmailAlerts),
        ]),
        const SizedBox(height: 12),
        _SettingsGroup('Appearance', [
          _ToggleRow('Dark Mode', 'Switch to dark theme', Icons.dark_mode_outlined, ctrl.darkMode, ctrl.setDarkMode),
        ]),
        const SizedBox(height: 12),
        _SettingsGroup('Privacy', [
          _ToggleRow('Location Access', 'Allow location for events', Icons.location_on_outlined, ctrl.locationAccess, ctrl.setLocationAccess),
        ]),
        const SizedBox(height: 12),
        _SettingsGroup('Account', [
          _TapRow('Change Password', Icons.lock_outline, () => _showChangePasswordDialog(context)),
          _TapRow('Terms & Conditions', Icons.description_outlined, () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsView()))),
          _TapRow('Privacy Policy', Icons.policy_outlined, () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyView()))),
          _TapRow('Report a Problem', Icons.flag_outlined, () => _showReportDialog(context)),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) context.go('/sign-in');
            },
          ),
        ),
        const SizedBox(height: 20),
        Text('Scholife v1.0.0', textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSub(context), fontSize: 12)),
        const SizedBox(height: 20),
      ],
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANGE PASSWORD DIALOG
// ─────────────────────────────────────────────────────────────────────────────
void _showChangePasswordDialog(BuildContext context) {
  final currentCtrl = TextEditingController();
  final newCtrl     = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool isSubmitting = false;
  String? errorMsg;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.lock_outline, color: AppTheme.primary, size: 22),
        SizedBox(width: 8),
        Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
      content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _pwField('Current Password', currentCtrl),
        const SizedBox(height: 12),
        _pwField('New Password', newCtrl),
        const SizedBox(height: 12),
        _pwField('Confirm New Password', confirmCtrl),
        if (errorMsg != null) ...[
          const SizedBox(height: 10),
          Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ])),
      actions: [
        TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: isSubmitting ? null : () async {
            final current = currentCtrl.text.trim();
            final newPw   = newCtrl.text.trim();
            final confirm = confirmCtrl.text.trim();
            if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
              setState(() => errorMsg = 'All fields are required.'); return;
            }
            if (newPw != confirm) { setState(() => errorMsg = 'New passwords do not match.'); return; }
            if (newPw.length < 6) { setState(() => errorMsg = 'Password must be at least 6 characters.'); return; }
            setState(() { isSubmitting = true; errorMsg = null; });
            final ok = await context.read<AuthController>().changePassword(current: current, newPassword: newPw);
            if (!context.mounted) return;
            if (ok) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('✅ Password changed successfully!'),
                backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            } else {
              setState(() {
                isSubmitting = false;
                errorMsg = context.read<AuthController>().errorMessage ?? 'Failed to change password.';
              });
            }
          },
          child: isSubmitting
              ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    )),
  );
}

Widget _pwField(String label, TextEditingController ctrl) => TextField(
  controller: ctrl, obscureText: true,
  decoration: InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    prefixIcon: const Icon(Icons.lock_outline, size: 18),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// REPORT A PROBLEM DIALOG
// ─────────────────────────────────────────────────────────────────────────────
void _showReportDialog(BuildContext context) {
  final subjectCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  bool isSubmitting = false;
  String? errorMsg;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.flag_outlined, color: AppTheme.primary, size: 22),
        SizedBox(width: 8),
        Text('Report a Problem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
      content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: subjectCtrl, decoration: InputDecoration(
          labelText: 'Subject', hintText: 'Brief description of the problem',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        )),
        const SizedBox(height: 12),
        TextField(controller: messageCtrl, maxLines: 4, decoration: InputDecoration(
          labelText: 'Message', hintText: 'Describe the issue in detail...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        )),
        if (errorMsg != null) ...[
          const SizedBox(height: 10),
          Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ])),
      actions: [
        TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: isSubmitting ? null : () async {
            final subject = subjectCtrl.text.trim();
            final message = messageCtrl.text.trim();
            if (subject.isEmpty || message.isEmpty) {
              setState(() => errorMsg = 'Please fill in both fields.'); return;
            }
            setState(() { isSubmitting = true; errorMsg = null; });
            try {
              final token = await AuthService.instance.getToken();
              final res = await http.post(
                Uri.parse('http://192.168.1.26:5000/api/mobile/reports/'),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${token ?? ''}'},
                body: jsonEncode({'subject': subject, 'message': message}),
              );
              if (res.statusCode == 201) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('✅ Report submitted successfully!'),
                  backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              } else {
                final body = jsonDecode(res.body);
                setState(() { isSubmitting = false; errorMsg = body['message'] ?? 'Failed to submit report.'; });
              }
            } catch (e) {
              setState(() { isSubmitting = false; errorMsg = 'Network error. Please try again.'; });
            }
          },
          child: isSubmitting
              ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Submit', style: TextStyle(color: Colors.white)),
        ),
      ],
    )),
  );
}

class _SettingsGroup extends StatelessWidget {
  final String title; final List<Widget> rows;
  const _SettingsGroup(this.title, this.rows);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textSub(context)))),
    Container(decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(12)),
        child: Column(children: rows)),
  ]);
}

class _ToggleRow extends StatelessWidget {
  final String title, sub; final IconData icon; final bool value; final ValueChanged<bool> onChanged;
  const _ToggleRow(this.title, this.sub, this.icon, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.primary),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textMain(context))),
    subtitle: Text(sub, style: TextStyle(fontSize: 12, color: AppTheme.textSub(context))),
    // ← FIXED: use activeThumbColor instead of deprecated activeColor
    trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primary),
  );
}

class _TapRow extends StatelessWidget {
  final String title; final IconData icon; final VoidCallback onTap;
  const _TapRow(this.title, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.primary),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textMain(context))),
    trailing: Icon(Icons.chevron_right, color: AppTheme.textSub(context)),
    onTap: onTap,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _ItemImage extends StatelessWidget {
  final String? imageUrl; final double height;
  const _ItemImage({this.imageUrl, required this.height});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return _placeholder();
    if (imageUrl!.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl!.split(',').last);
        return SizedBox(height: height, width: double.infinity, child: Image.memory(bytes, fit: BoxFit.cover));
      } catch (_) { return _placeholder(); }
    }
    return SizedBox(
      height: height, width: double.infinity,
      child: Image.network(imageUrl!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) => progress == null ? child
            : Container(height: height, color: AppTheme.primary.withValues(alpha: 0.06),
            child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: height, color: AppTheme.primary.withValues(alpha: 0.08),
    child: const Center(child: Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.primary)),
  );
}

class _LostFoundThumb extends StatelessWidget {
  final String? imageUrl; final Color color;
  const _LostFoundThumb({this.imageUrl, required this.color});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl!.split(',').last);
        return SizedBox(width: 56, height: 56, child: Image.memory(bytes, fit: BoxFit.cover));
      } catch (_) {}
    }
    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return SizedBox(width: 56, height: 56,
          child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _icon()));
    }
    return _icon();
  }

  Widget _icon() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
    child: const Icon(Icons.help_outline, size: 26, color: AppTheme.textSecondary),
  );
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl; final double radius;
  const _ProfileAvatar({this.avatarUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:image')) {
        try {
          final bytes = base64Decode(avatarUrl!.split(',').last);
          return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes));
        } catch (_) {}
      } else if (avatarUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: radius, backgroundImage: NetworkImage(avatarUrl!),
          onBackgroundImageError: (_, __) {},
          backgroundColor: AppTheme.accentLight,
          child: const Icon(Icons.person, color: AppTheme.primaryDark),
        );
      }
    }
    return CircleAvatar(
      radius: radius, backgroundColor: AppTheme.accentLight,
      child: Icon(Icons.person, size: radius * 1.1, color: AppTheme.primaryDark),
    );
  }
}
class _LeaderboardAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  const _LeaderboardAvatar({this.avatarUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:image')) {
        try {
          final bytes = base64Decode(avatarUrl!.split(',').last);
          return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes));
        } catch (_) {}
      } else if (avatarUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(avatarUrl!),
          onBackgroundImageError: (_, __) {},
          backgroundColor: const Color(0x338B1A1A),
        );
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0x338B1A1A),
      child: Icon(Icons.person, color: Colors.white, size: radius * 1.1),
    );
  }
}