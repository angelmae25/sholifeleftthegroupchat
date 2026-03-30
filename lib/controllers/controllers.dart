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
import '../models/news_model.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import '../services/all_services.dart';
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

  // REMOVED: contactNumber & paymentMethods — no longer part of the item model.
  // base64Image is passed directly (already includes "data:image/jpeg;base64,...").
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
        base64Image: base64Image, // already includes "data:image/jpeg;base64,..."
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

  // base64Image is passed directly (already includes "data:image/jpeg;base64,...").
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
        base64Image: base64Image, // already includes "data:image/jpeg;base64,..."
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
class ChatController extends ChangeNotifier {
  List<ChatModel>        _conversations = [];
  List<ChatMessageModel> _messages      = [];
  String?                _activeConvId;
  bool                   _isLoading     = false;
  String?                _error;
  String                 _myId          = '';

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
        final isMine         = senderId == _myId;

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
      senderId: _myId,
      sentAt:   DateTime.now(),
      isMine:   true,
    );
    _messages = [..._messages, optimistic];
    notifyListeners();
    await ChatSocketService.instance.sendMessage(_activeConvId!, text.trim());
  }

  // ── Start DM ──────────────────────────────────────────────────────────────
  void startDm(String otherStudentId) {
    ChatSocketService.instance.startDm(otherStudentId);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    ChatSocketService.instance.disconnect();
    super.dispose();
  }
}

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
    // Organizations from Spring Boot are read-only — skip toggle
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
// Persists all toggles to SQLite (DatabaseService) so they survive app restarts.
// ─────────────────────────────────────────────────────────────────────────────
class SettingsController extends ChangeNotifier {

  // ── SQLite column key constants ────────────────────────────────────────────
  static const _kDarkMode         = 'dark_mode';
  static const _kPush             = 'push_notifications';
  static const _kEmail            = 'email_alerts';
  static const _kLocation         = 'location_access';
  static const _kNotifNews        = 'notif_news';
  static const _kNotifEvents      = 'notif_events';
  static const _kNotifLostFound   = 'notif_lost_found';
  static const _kNotifMarketplace = 'notif_marketplace';

  // ── In-memory state (defaults) ─────────────────────────────────────────────
  bool _darkMode          = false;
  bool _pushNotifications = true;
  bool _emailAlerts       = false;
  bool _locationAccess    = true;
  bool _notifNews         = true;
  bool _notifEvents       = true;
  bool _notifLostFound    = true;
  bool _notifMarketplace  = true;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get darkMode          => _darkMode;
  bool get pushNotifications => _pushNotifications;
  bool get emailAlerts       => _emailAlerts;
  bool get locationAccess    => _locationAccess;
  bool get notifNews         => _notifNews;
  bool get notifEvents       => _notifEvents;
  bool get notifLostFound    => _notifLostFound;
  bool get notifMarketplace  => _notifMarketplace;

  // ── Setters — each immediately writes to SQLite ───────────────────────────
  void setDarkMode(bool v) {
    _darkMode = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kDarkMode, v);
  }

  void setPushNotifications(bool v) {
    _pushNotifications = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kPush, v);
  }

  void setEmailAlerts(bool v) {
    _emailAlerts = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kEmail, v);
  }

  void setLocationAccess(bool v) {
    _locationAccess = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kLocation, v);
  }

  void setNotifNews(bool v) {
    _notifNews = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kNotifNews, v);
  }

  void setNotifEvents(bool v) {
    _notifEvents = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kNotifEvents, v);
  }

  void setNotifLostFound(bool v) {
    _notifLostFound = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kNotifLostFound, v);
  }

  void setNotifMarketplace(bool v) {
    _notifMarketplace = v;
    notifyListeners();
    DatabaseService.instance.saveSetting(_kNotifMarketplace, v);
  }

  // ── Seed dark mode instantly (called from main() before runApp) ───────────
  /// Sets darkMode in-memory only — no async, no DB call.
  /// Used to prevent flicker: main() reads dark_mode from SQLite before
  /// runApp(), then passes it here so the theme is correct on first frame.
  void seedDarkMode(bool value) {
    _darkMode = value;
    // No notifyListeners() needed here — called before the widget tree exists
  }

  // ── Load all settings from SQLite on app start ─────────────────────────────
  Future<void> loadSettings() async {
    final row = await DatabaseService.instance.loadSettings();
    _darkMode          = (row[_kDarkMode]         as int? ?? 0) == 1;
    _pushNotifications = (row[_kPush]             as int? ?? 1) == 1;
    _emailAlerts       = (row[_kEmail]            as int? ?? 0) == 1;
    _locationAccess    = (row[_kLocation]         as int? ?? 1) == 1;
    _notifNews         = (row[_kNotifNews]        as int? ?? 1) == 1;
    _notifEvents       = (row[_kNotifEvents]      as int? ?? 1) == 1;
    _notifLostFound    = (row[_kNotifLostFound]   as int? ?? 1) == 1;
    _notifMarketplace  = (row[_kNotifMarketplace] as int? ?? 1) == 1;
    notifyListeners();
  }
}