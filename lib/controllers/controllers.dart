// =============================================================================
// CONTROLLERS: Feature controllers (one per feature)
// Each controller follows the same pattern:
//   1. Holds state (_items, _isLoading, _error)
//   2. Exposes public getters for the View to read
//   3. Exposes public async methods for the View to trigger
//   4. Calls Services (never touches UI or HTTP directly)
//   5. Calls notifyListeners() to refresh the View
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/chat_socket_service.dart'; // ← NEW

// ─────────────────────────────────────────────────────────────────────────────
// NEWS CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class NewsController extends ChangeNotifier {
  List<NewsModel> _articles       = [];
  NewsCategory    _activeCategory = NewsCategory.all;
  bool            _isLoading      = false;
  String?         _error;

  List<NewsModel> get articles       => _articles;
  NewsCategory    get activeCategory => _activeCategory;
  bool            get isLoading      => _isLoading;
  String?         get error          => _error;

  List<NewsModel> get filteredArticles {
    if (_activeCategory == NewsCategory.all) return _articles;
    return _articles.where((a) => a.category == _activeCategory).toList();
  }

  Future<void> loadArticles() async {
    _isLoading = true; notifyListeners();
    try {
      _articles = await NewsService.instance.fetchAll();
      _error    = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  void setCategory(NewsCategory category) {
    _activeCategory = category;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class EventsController extends ChangeNotifier {
  List<EventModel> _events    = [];
  bool             _isLoading = false;
  String?          _error;

  List<EventModel> get events    => _events;
  bool             get isLoading => _isLoading;
  String?          get error     => _error;

  Future<void> loadEvents() async {
    _isLoading = true; notifyListeners();
    try {
      _events = await EventService.instance.fetchAll();
      _error  = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // ── Attend Event ─────────────────────────────────────────────────────────
  /// Marks the current student as attending an event.
  /// Returns a map with keys: ok (bool), message, points, already_attended.
  /// Awards +10 points on first attendance. Safe to call multiple times.
  Future<Map<String, dynamic>> attendEvent(String eventId) async {
    try {
      final result = await EventService.instance.attendEvent(eventId);
      return result;
    } catch (e) {
      return {
        'ok':      false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  // ── Check Attendance ──────────────────────────────────────────────────────
  /// Returns true if the current student has already attended this event.
  /// Called when an EventCard loads to set the Attend/Attended button state.
  Future<bool> hasAttended(String eventId) async {
    try {
      return await EventService.instance.hasAttended(eventId);
    } catch (e) {
      debugPrint('[EventsController] hasAttended error: $e');
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKETPLACE CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class MarketplaceController extends ChangeNotifier {
  List<MarketplaceItemModel> _items     = [];
  String                     _query     = '';
  bool                       _isLoading = false;
  String?                    _error;

  List<MarketplaceItemModel> get items     => _items;
  String                     get query     => _query;
  bool                       get isLoading => _isLoading;
  String?                    get error     => _error;

  Future<void> loadItems() async {
    _isLoading = true; notifyListeners();
    try {
      _items = await MarketplaceService.instance.fetchAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _query     = query;
    _isLoading = true; notifyListeners();
    try {
      _items = await MarketplaceService.instance.search(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> createItem({
    required String name,
    required String description,
    required String condition,
    required double price,
    String? base64Image,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      final newItem = await MarketplaceService.instance.createItem(
        name:        name,
        description: description,
        condition:   condition,
        price:       price,
        base64Image: base64Image,
      );
      _items = [newItem, ..._items];
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOST & FOUND CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class LostFoundController extends ChangeNotifier {
  List<LostFoundModel> _items      = [];
  LostFoundStatus      _activeTab  = LostFoundStatus.lost;
  bool                 _isLoading  = false;
  String?              _error;

  LostFoundStatus      get activeTab   => _activeTab;
  bool                 get isLoading   => _isLoading;
  String?              get error       => _error;

  List<LostFoundModel> get filteredItems =>
      _items.where((i) => i.status == _activeTab).toList();

  Future<void> loadItems() async {
    _isLoading = true; notifyListeners();
    try {
      _items = await LostFoundService.instance.fetchAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  void setTab(LostFoundStatus status) {
    _activeTab = status;
    notifyListeners();
  }

  Future<bool> reportItem({
    required String title,
    required String description,
    required String location,
    required String date,
    required String status,
    String? base64Image,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      final newItem = await LostFoundService.instance.reportItem(
        title:       title,
        description: description,
        location:    location,
        date:        date,
        status:      status,
        base64Image: base64Image,
      );
      _items = [newItem, ..._items];
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT CONTROLLER  — UPDATED with real-time Socket.IO support
// ─────────────────────────────────────────────────────────────────────────────
// =============================================================================
// REPLACE loadConversations() and the onNewMessage handler in ChatController
// inside lib/controllers/controllers.dart
//
// The fix: determine is_mine by comparing sender_id to the logged-in user's id.
// This ensures Jemuel sees his own message as "mine" and Cain sees it as
// "incoming" — both sides show the conversation correctly.
// =============================================================================

// Add this import at the top of controllers.dart if not already there:
// import '../controllers/auth_controller.dart';

// REPLACE the entire ChatController class with this:

class ChatController extends ChangeNotifier {
  List<ChatModel>        _conversations = [];
  List<ChatMessageModel> _messages      = [];
  String?                _activeConvId;
  bool                   _isLoading     = false;
  String?                _error;
  String                 _myId          = '';  // ← ADD THIS FIELD

  // ... existing getters ...

  // ← ADD THIS METHOD
  void setMyId(String id) {
    _myId = id;
  }

  List<ChatModel>        get conversations => _conversations;
  List<ChatMessageModel> get messages      => _messages;
  bool                   get isLoading     => _isLoading;
  String?                get error         => _error;
  String?                get activeConvId  => _activeConvId;

  // ── Load conversations + connect socket ───────────────────────────────────
  Future<void> loadConversations() async {
    _isLoading = true; notifyListeners();
    try {
      _conversations = await ChatService.instance.fetchConversations();
      _error         = null;

      await ChatSocketService.instance.connect();

      ChatSocketService.instance.onNewMessage = (msg) {
        final incomingConvId = msg['conversation_id']?.toString() ?? '';
        final senderId       = msg['sender_id']?.toString()       ?? '';
        final isMine         = senderId == _myId;  // ← uses _myId

        if (_activeConvId != null && incomingConvId == _activeConvId) {
          final alreadyExists = _messages.any(
                (m) => m.text == msg['text'] && m.isMine && isMine &&
                m.sentAt.difference(DateTime.now()).abs().inSeconds < 5,
          );
          if (!alreadyExists || !isMine) {
            final newMsg = ChatMessageModel(
              id:       msg['id']?.toString() ?? '',
              text:     msg['text']      as String? ?? '',
              senderId: senderId,
              sentAt:   DateTime.tryParse(msg['sent_at'] as String? ?? '') ?? DateTime.now(),
              isMine:   isMine,
            );
            _messages = [..._messages, newMsg];
            notifyListeners();
          }
        }
        _silentRefreshConversations();
      };
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> _silentRefreshConversations() async {
    try {
      _conversations = await ChatService.instance.fetchConversations();
      notifyListeners();
    } catch (_) {}
  }

  // Lightweight refresh of conversation list without full reload
  Future<void> _refreshConversationList() async {
    try {
      _conversations = await ChatService.instance.fetchConversations();
      notifyListeners();
    } catch (_) {}
  }

  // ── Open a conversation ───────────────────────────────────────────────────
  Future<void> openConversation(String conversationId) async {
    _activeConvId = conversationId;
    _isLoading    = true; notifyListeners();
    try {
      _messages = await ChatService.instance.fetchMessages(conversationId);
      _error    = null;
      ChatSocketService.instance.joinConversation(conversationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (_activeConvId == null || text.trim().isEmpty) return;
    final optimistic = ChatMessageModel(
      id:       'opt_${DateTime.now().millisecondsSinceEpoch}',
      text:     text.trim(),
      senderId: _myId,       // ← uses _myId instead of 'me'
      sentAt:   DateTime.now(),
      isMine:   true,
    );
    _messages = [..._messages, optimistic];
    notifyListeners();
    await ChatSocketService.instance.sendMessage(_activeConvId!, text.trim());
  }

  // ── Start DM ──────────────────────────────────────────────────────────────
  void startDm(String otherStudentId, void Function(String convId) onReady) {
    ChatSocketService.instance.onDmReady = onReady;
    ChatSocketService.instance.startDm(otherStudentId);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    ChatSocketService.instance.disconnect();
    super.dispose();
  }
}

// =============================================================================
// Also update ChatView.initState() in secondary_views.dart:
// Pass the logged-in user's id when loading conversations.
//
// REPLACE the initState in _ChatViewState with:
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final myId = context.read<AuthController>().user?.id ?? '';
//       context.read<ChatController>().loadConversations(myId: myId);
//     });
//   }
// =============================================================================
// ─────────────────────────────────────────────────────────────────────────────
// CLUBS CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class ClubsController extends ChangeNotifier {
  List<ClubModel> _clubs     = [];
  bool            _isLoading = false;
  String?         _error;

  List<ClubModel> get clubs     => _clubs;
  bool            get isLoading => _isLoading;
  String?         get error     => _error;

  Future<void> loadClubs() async {
    _isLoading = true; notifyListeners();
    try {
      _clubs = await ClubService.instance.fetchAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> toggleMembership(String clubId) async {
    // Orgs from Spring Boot are read-only — skip toggle
    if (clubId.startsWith('org_')) return;

    final idx = _clubs.indexWhere((c) => c.id == clubId);
    if (idx < 0) return;
    _clubs[idx].isJoined = !_clubs[idx].isJoined;
    notifyListeners();
    await ClubService.instance.toggleMembership(clubId, _clubs[idx].isJoined);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class LeaderboardController extends ChangeNotifier {
  List<LeaderboardEntryModel> _entries   = [];
  bool                        _isLoading = false;
  String?                     _error;

  List<LeaderboardEntryModel> get entries   => _entries;
  bool                        get isLoading => _isLoading;
  String?                     get error     => _error;

  List<LeaderboardEntryModel> get topThree  => _entries.take(3).toList();
  List<LeaderboardEntryModel> get theRest   => _entries.skip(3).toList();

  Future<void> loadLeaderboard() async {
    _isLoading = true; notifyListeners();
    try {
      _entries = await LeaderboardService.instance.fetchAll();
      _error   = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class ProfileController extends ChangeNotifier {
  UserModel? _profile;
  bool       _isLoading = false;
  String?    _error;

  UserModel? get profile   => _profile;
  bool       get isLoading => _isLoading;
  String?    get error     => _error;

  Future<void> loadProfile(String userId) async {
    _isLoading = true; notifyListeners();
    try {
      _profile  = await UserService.instance.fetchProfile(userId);
      _error    = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> updateProfile(UserModel updated) async {
    _isLoading = true; notifyListeners();
    try {
      _profile  = await UserService.instance.updateProfile(updated);
      _error    = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS CONTROLLER
// Persists all toggles to SharedPreferences so they survive app restarts.
// ─────────────────────────────────────────────────────────────────────────────
class SettingsController extends ChangeNotifier {
  // ── Preference keys ────────────────────────────────────────────────────────
  static const _kPush             = 'pref_push_notifications';
  static const _kEmail            = 'pref_email_alerts';
  static const _kDarkMode         = 'pref_dark_mode';
  static const _kLocation         = 'pref_location_access';
  static const _kNotifNews        = 'pref_notif_news';
  static const _kNotifEvents      = 'pref_notif_events';
  static const _kNotifLostFound   = 'pref_notif_lost_found';
  static const _kNotifMarketplace = 'pref_notif_marketplace';

  // ── In-memory state (defaults shown) ──────────────────────────────────────
  bool _pushNotifications = true;
  bool _emailAlerts       = false;
  bool _darkMode          = false;
  bool _locationAccess    = true;
  bool _notifNews         = true;
  bool _notifEvents       = true;
  bool _notifLostFound    = true;
  bool _notifMarketplace  = true;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get pushNotifications => _pushNotifications;
  bool get emailAlerts       => _emailAlerts;
  bool get darkMode          => _darkMode;
  bool get locationAccess    => _locationAccess;
  bool get notifNews         => _notifNews;
  bool get notifEvents       => _notifEvents;
  bool get notifLostFound    => _notifLostFound;
  bool get notifMarketplace  => _notifMarketplace;

  // ── Setters (each notifies + persists immediately) ─────────────────────────
  void setPushNotifications(bool v) { _pushNotifications = v; notifyListeners(); _save(_kPush, v); }
  void setEmailAlerts(bool v)       { _emailAlerts = v;       notifyListeners(); _save(_kEmail, v); }
  void setDarkMode(bool v)          { _darkMode = v;          notifyListeners(); _save(_kDarkMode, v); }
  void setLocationAccess(bool v)    { _locationAccess = v;    notifyListeners(); _save(_kLocation, v); }
  void setNotifNews(bool v)         { _notifNews = v;         notifyListeners(); _save(_kNotifNews, v); }
  void setNotifEvents(bool v)       { _notifEvents = v;       notifyListeners(); _save(_kNotifEvents, v); }
  void setNotifLostFound(bool v)    { _notifLostFound = v;    notifyListeners(); _save(_kNotifLostFound, v); }
  void setNotifMarketplace(bool v)  { _notifMarketplace = v;  notifyListeners(); _save(_kNotifMarketplace, v); }

  // ── Load persisted settings on app start ──────────────────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool(_kPush)              ?? true;
    _emailAlerts       = prefs.getBool(_kEmail)             ?? false;
    _darkMode          = prefs.getBool(_kDarkMode)          ?? false;
    _locationAccess    = prefs.getBool(_kLocation)          ?? true;
    _notifNews         = prefs.getBool(_kNotifNews)         ?? true;
    _notifEvents       = prefs.getBool(_kNotifEvents)       ?? true;
    _notifLostFound    = prefs.getBool(_kNotifLostFound)    ?? true;
    _notifMarketplace  = prefs.getBool(_kNotifMarketplace)  ?? true;
    notifyListeners();
  }

  // ── Internal: fire-and-forget save ────────────────────────────────────────
  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}