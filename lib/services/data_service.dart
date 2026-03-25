// =============================================================================
// lib/services/data_service.dart
//
// All services call the Flask API.
// JWT token comes from AuthService (stored in SharedPreferences after login).
// SQLite (sqflite) is used as a local cache so the app works offline.
//
// Android Emulator  → 10.0.2.2:5000
// Physical device   → your computer's WiFi IP e.g. 192.168.1.5:5000
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/news_model.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

// ── Base URL ─────────────────────────────────────────────────────────────────
const String _base = 'http://192.168.1.11:5000/api/mobile';

// ── JWT Auth header ───────────────────────────────────────────────────────────
Future<Map<String, String>> _headers() async {
  final token = await AuthService.instance.getToken();
  return {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer ${token ?? ''}',
  };
}

// =============================================================================
// LOCAL DATABASE (SQLite via sqflite)
// =============================================================================
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'scholife_cache.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE news_cache (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE events_cache (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE clubs_cache (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE marketplace_cache (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE lost_found_cache (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE leaderboard_cache (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> cacheList(String table, List<Map<String, dynamic>> items) async {
    final database = await db;
    final batch    = database.batch();
    batch.delete(table);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in items) {
      batch.insert(table, {
        'id':        item['id']?.toString() ?? '',
        'json':      jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCache(String table) async {
    final database = await db;
    final rows     = await database.query(table, orderBy: 'cached_at ASC');
    return rows.map((r) =>
    jsonDecode(r['json'] as String) as Map<String, dynamic>).toList();
  }

  Future<bool> isCacheFresh(String table, {int maxAgeMinutes = 10}) async {
    final database = await db;
    final rows     = await database.query(
        table, orderBy: 'cached_at DESC', limit: 1);
    if (rows.isEmpty) return false;
    final cachedAt = rows.first['cached_at'] as int;
    final age      = DateTime.now().millisecondsSinceEpoch - cachedAt;
    return age < maxAgeMinutes * 60 * 1000;
  }
}

// =============================================================================
// NEWS SERVICE
// =============================================================================
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  Future<List<NewsModel>> fetchAll({String category = 'all'}) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/news/?category=$category'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        await LocalDb.instance.cacheList('news_cache', list);
        return list.map(NewsModel.fromJson).toList();
      }
    } catch (_) {}
    final cached = await LocalDb.instance.getCache('news_cache');
    if (cached.isNotEmpty) return cached.map(NewsModel.fromJson).toList();
    return NewsModel.mockList;
  }

  Future<List<NewsModel>> fetchByCategory(NewsCategory category) =>
      fetchAll(category: category.name);
}

// =============================================================================
// EVENT SERVICE  — updated with attendEvent() and hasAttended()
// =============================================================================
class EventService {
  EventService._();
  static final EventService instance = EventService._();

  Future<List<EventModel>> fetchAll() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/events/'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        await LocalDb.instance.cacheList('events_cache', list);
        return list.map(EventModel.fromJson).toList();
      }
    } catch (_) {}
    final cached = await LocalDb.instance.getCache('events_cache');
    if (cached.isNotEmpty) return cached.map(EventModel.fromJson).toList();
    return EventModel.mockList;
  }

  // ── Attend Event ────────────────────────────────────────────────────────────
  /// POST /api/mobile/events/<id>/attend
  /// Awards +10 points to the student on first attendance.
  /// Returns a map with: ok (bool), message, points, already_attended.
  Future<Map<String, dynamic>> attendEvent(String eventId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/events/$eventId/attend'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          'ok':               true,
          'message':          body['message']          ?? 'Attendance marked!',
          'points':           body['points']           ?? 0,
          'already_attended': body['already_attended'] ?? false,
        };
      }
      return {
        'ok':      false,
        'message': body['message'] ?? 'Failed to mark attendance.',
      };
    } catch (e) {
      return {
        'ok':      false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  // ── Check Attendance ────────────────────────────────────────────────────────
  /// GET /api/mobile/events/<id>/attendance
  /// Returns true if the current student has already attended this event.
  /// Used by EventCardWithAttend to set initial button state on load.
  Future<bool> hasAttended(String eventId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/events/$eventId/attendance'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['attended'] == true;
      }
    } catch (_) {}
    return false; // default to not attended on any error
  }
}

// =============================================================================
// CLUB SERVICE  — updated to also fetch Spring Boot organizations
// =============================================================================
class ClubService {
  ClubService._();
  static final ClubService instance = ClubService._();

  /// Fetches clubs from Flask clubs table AND organizations from Spring Boot
  /// (via the /clubs/organizations endpoint) and merges them into one list.
  /// Spring Boot orgs have ids prefixed with 'org_' and are read-only.
  Future<List<ClubModel>> fetchAll() async {
    List<ClubModel> clubs = [];

    // ── 1. Fetch actual clubs from Flask clubs table ──────────────────────────
    try {
      final res = await http.get(
        Uri.parse('$_base/clubs/'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        clubs = list.map((j) => ClubModel.fromApi(j)).toList();
      }
    } catch (_) {}

    // ── 2. Also fetch organizations posted by Spring Boot admin ───────────────
    try {
      final orgRes = await http.get(
        Uri.parse('$_base/clubs/organizations'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (orgRes.statusCode == 200) {
        final orgList = (jsonDecode(orgRes.body) as List)
            .cast<Map<String, dynamic>>();
        final orgClubs = orgList.map((j) => ClubModel.fromApi(j)).toList();

        // Merge — avoid duplicates by id
        final existingIds = {for (final c in clubs) c.id};
        for (final oc in orgClubs) {
          if (!existingIds.contains(oc.id)) clubs.add(oc);
        }
      }
    } catch (_) {}

    // ── 3. Cache and return if we got data ────────────────────────────────────
    if (clubs.isNotEmpty) {
      await LocalDb.instance.cacheList(
        'clubs_cache',
        clubs.map((c) => {
          'id':      c.id,
          'name':    c.name,
          'acronym': c.department,
        }).toList(),
      );
      return clubs;
    }

    // ── 4. Offline fallback ───────────────────────────────────────────────────
    final cached = await LocalDb.instance.getCache('clubs_cache');
    if (cached.isNotEmpty) {
      return cached.map((j) => ClubModel.fromApi(j)).toList();
    }
    return ClubModel.mockList;
  }

  Future<void> toggleMembership(String clubId, bool join) async {
    // Read-only org clubs cannot be joined/left
    if (clubId.startsWith('org_')) return;

    final endpoint = join ? 'join' : 'leave';
    try {
      await http.post(
        Uri.parse('$_base/clubs/$clubId/$endpoint'),
        headers: await _headers(),
      );
    } catch (_) {
      // Optimistic UI — ignore network error
    }
  }
}

// =============================================================================
// LEADERBOARD SERVICE
// =============================================================================
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  Future<List<LeaderboardEntryModel>> fetchAll() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/leaderboard/'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        await LocalDb.instance.cacheList('leaderboard_cache', list);
        return list
            .asMap()
            .entries
            .map((e) => LeaderboardEntryModel.fromJson({
          ...e.value,
          'rank': (e.value['rank'] as int?) ?? e.key + 1,
        }))
            .toList();
      }
    } catch (_) {}
    final cached = await LocalDb.instance.getCache('leaderboard_cache');
    if (cached.isNotEmpty) {
      return cached
          .asMap()
          .entries
          .map((e) => LeaderboardEntryModel.fromJson(
          {...e.value, 'rank': e.key + 1}))
          .toList();
    }
    return LeaderboardEntryModel.mockList;
  }
}

// =============================================================================
// USER SERVICE
// =============================================================================
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  Future<UserModel> fetchProfile(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/students/profile'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return UserModel.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return AuthService.instance.fetchMe();
  }

  Future<UserModel> updateProfile(UserModel updated) async {
    final body = <String, dynamic>{
      'contact':    updated.phone ?? '',
      'course':     updated.course,
      'year_level': updated.yearLevel,
    };
    if (updated.avatarUrl != null) {
      body['avatar_url'] = updated.avatarUrl;
    }

    final res = await http.put(
      Uri.parse('$_base/students/profile'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    final contentType = res.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error (HTTP ${res.statusCode}). Try again.');
    }

    if (res.statusCode == 200) {
      return UserModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    final err = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(err['message'] ?? 'Failed to update profile.');
  }
}

// =============================================================================
// MARKETPLACE SERVICE
// =============================================================================
class MarketplaceService {
  MarketplaceService._();
  static final MarketplaceService instance = MarketplaceService._();

  Future<List<MarketplaceItemModel>> fetchAll() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/marketplace/'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        await LocalDb.instance.cacheList('marketplace_cache', list);
        return list.map(MarketplaceItemModel.fromJson).toList();
      }
    } catch (_) {}
    final cached =
    await LocalDb.instance.getCache('marketplace_cache');
    if (cached.isNotEmpty) {
      return cached.map(MarketplaceItemModel.fromJson).toList();
    }
    return MarketplaceItemModel.mockList;
  }

  Future<List<MarketplaceItemModel>> search(String query) async {
    if (query.isEmpty) return fetchAll();
    try {
      final res = await http.get(
        Uri.parse(
            '$_base/marketplace/?search=${Uri.encodeComponent(query)}'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        return list.map(MarketplaceItemModel.fromJson).toList();
      }
    } catch (_) {}
    final all = await fetchAll();
    return all
        .where((i) =>
        i.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<MarketplaceItemModel> createItem({
    required String name,
    required String description,
    required String condition,
    required double price,
    String? base64Image,
  }) async {
    final body = <String, dynamic>{
      'name':        name,
      'description': description,
      'condition':   condition,
      'price':       price,
    };
    if (base64Image != null) {
      body['image_url'] = 'data:image/jpeg;base64,$base64Image';
    }

    final res = await http.post(
      Uri.parse('$_base/marketplace/'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    final contentType = res.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server error (HTTP ${res.statusCode}). '
            'The image may be too large — try a smaller photo.',
      );
    }

    if (res.statusCode == 201) {
      return MarketplaceItemModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    final err = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(err['message'] ?? 'Failed to post item.');
  }
}

// =============================================================================
// LOST & FOUND SERVICE
// =============================================================================
class LostFoundService {
  LostFoundService._();
  static final LostFoundService instance = LostFoundService._();

  Future<List<LostFoundModel>> fetchAll() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/lost-found/'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        await LocalDb.instance.cacheList('lost_found_cache', list);
        return list.map(LostFoundModel.fromJson).toList();
      }
    } catch (_) {}
    final cached =
    await LocalDb.instance.getCache('lost_found_cache');
    if (cached.isNotEmpty) {
      return cached.map(LostFoundModel.fromJson).toList();
    }
    return LostFoundModel.mockList;
  }

  Future<List<LostFoundModel>> fetchByStatus(
      LostFoundStatus status) async {
    final all = await fetchAll();
    return all.where((i) => i.status == status).toList();
  }

  Future<LostFoundModel> reportItem({
    required String title,
    required String description,
    required String location,
    required String date,
    required String status,
    String? base64Image,
  }) async {
    final body = <String, dynamic>{
      'title':       title,
      'description': description,
      'location':    location,
      'date':        date,
      'status':      status,
    };
    if (base64Image != null) {
      body['image_url'] = 'data:image/jpeg;base64,$base64Image';
    }

    final res = await http.post(
      Uri.parse('$_base/lost-found/'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    final contentType = res.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
          'Server error (HTTP ${res.statusCode}). Please try again.');
    }

    if (res.statusCode == 201) {
      return LostFoundModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    final err = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(err['message'] ?? 'Failed to submit report.');
  }
}

// =============================================================================
// CHAT SERVICE
// =============================================================================
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Future<List<ChatModel>> fetchConversations() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/chat/conversations'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        return list.map(_chatFromJson).toList();
      }
    } catch (_) {}
    return ChatModel.mockList;
  }

  Future<List<ChatMessageModel>> fetchMessages(
      String conversationId) async {
    try {
      final res = await http.get(
        Uri.parse(
            '$_base/chat/conversations/$conversationId/messages'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        return list.map(_msgFromJson).toList();
      }
    } catch (_) {}
    return ChatMessageModel.mockMessages;
  }

  Future<void> sendMessage(
      String conversationId, String text) async {
    try {
      await http.post(
        Uri.parse(
            '$_base/chat/conversations/$conversationId/messages'),
        headers: await _headers(),
        body: jsonEncode({'text': text}),
      );
    } catch (_) {}
  }

  ChatModel _chatFromJson(Map<String, dynamic> j) => ChatModel(
    id:            j['id']?.toString() ?? '',
    name:          j['name']           as String? ?? '',
    lastMessage:   j['last_message']   as String? ?? '',
    lastMessageAt: DateTime.tryParse(
        j['last_message_at'] as String? ?? '') ??
        DateTime.now(),
    unreadCount: (j['unread_count'] as int?) ?? 0,
    isGroup:     (j['is_group']     as bool?) ?? false,
  );

  ChatMessageModel _msgFromJson(Map<String, dynamic> j) =>
      ChatMessageModel(
        id:       j['id']?.toString() ?? '',
        text:     j['text']      as String? ?? '',
        senderId: j['sender_id'] as String? ?? '',
        sentAt:   DateTime.tryParse(j['sent_at'] as String? ?? '') ??
            DateTime.now(),
        isMine: (j['is_mine'] as bool?) ?? false,
      );
}