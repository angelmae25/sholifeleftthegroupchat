// =============================================================================
// lib/services/all_services.dart
//
// ALL services in one file. Import only this in controllers.dart:
//   import '../services/all_services.dart';
//
// Classes included:
//   - DatabaseService      (SQLite session + settings)
//   - AuthService          (register, login, logout, JWT)
//   - ChatSocketService    (Socket.IO real-time chat)
//   - NotificationService  (Firebase Cloud Messaging)
//   - OrgPostService       (Spring Boot org/news/event posting)
//   - NewsService          (fetch news articles)
//   - EventService         (fetch events, attend, check attendance)
//   - MarketplaceService   (fetch, search, create listings)
//   - LostFoundService     (fetch, report lost/found items)
//   - ChatService          (fetch conversations + messages)
//   - ClubService          (fetch clubs, toggle membership)
//   - LeaderboardService   (fetch leaderboard)
//   - UserService          (fetch + update user profile)
//
// pubspec.yaml dependencies:
//   sqflite: ^2.3.3
//   path: ^1.9.0
//   http: ^1.2.0
//   socket_io_client: ^2.0.3+1
//   firebase_core: ^3.0.0
//   firebase_messaging: ^15.0.0
// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/news_model.dart';
import '../models/models.dart';

// ── Background FCM handler (must be top-level) ────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

// =============================================================================
// SAFE JSON DECODE HELPER
// Prevents "FormatException: Unexpected character <!DOCTYPE" and HTTP 308
// redirect errors when Flask returns HTML instead of JSON.
// =============================================================================
dynamic _safeJson(http.Response res) {
  final ct = res.headers['content-type'] ?? '';
  if (!ct.contains('application/json')) {
    final preview = res.body.length > 200 ? res.body.substring(0, 200) + '\u2026' : res.body;
    throw Exception(
      'Server returned non-JSON (HTTP ${res.statusCode}).\n'
          'The server may be down or unreachable.\n'
          'Preview: $preview\n\n'
          'Check:\n'
          '  \u2022 Flask is running on port 5000\n'
          '  \u2022 Your device is on the same Wi-Fi as your PC\n'
          '  \u2022 The IP address (192.168.1.11) is correct',
    );
  }
  return jsonDecode(res.body);
}


// =============================================================================
// DATABASE SERVICE
// =============================================================================
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'scholife.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE session (
          id          INTEGER PRIMARY KEY,
          token       TEXT NOT NULL,
          user_id     TEXT NOT NULL,
          email       TEXT NOT NULL,
          full_name   TEXT NOT NULL,
          student_id  TEXT NOT NULL,
          course      TEXT NOT NULL,
          year_level  TEXT NOT NULL,
          department  TEXT NOT NULL,
          avatar_url  TEXT,
          points      INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE settings (
          id                  INTEGER PRIMARY KEY,
          dark_mode           INTEGER NOT NULL DEFAULT 0,
          push_notifications  INTEGER NOT NULL DEFAULT 1,
          email_alerts        INTEGER NOT NULL DEFAULT 0,
          location_access     INTEGER NOT NULL DEFAULT 1,
          notif_news          INTEGER NOT NULL DEFAULT 1,
          notif_events        INTEGER NOT NULL DEFAULT 1,
          notif_lost_found    INTEGER NOT NULL DEFAULT 1,
          notif_marketplace   INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.insert('settings', {
        'id': 1, 'dark_mode': 0, 'push_notifications': 1,
        'email_alerts': 0, 'location_access': 1,
        'notif_news': 1, 'notif_events': 1,
        'notif_lost_found': 1, 'notif_marketplace': 1,
      });
    });
  }

  Future<void> saveSession({
    required String token, required String userId,
    required String email, required String fullName,
    required String studentId, required String course,
    required String yearLevel, required String department,
    String? avatarUrl, int points = 0,
  }) async {
    final database = await db;
    await database.insert('session', {
      'id': 1, 'token': token, 'user_id': userId,
      'email': email, 'full_name': fullName, 'student_id': studentId,
      'course': course, 'year_level': yearLevel, 'department': department,
      'avatar_url': avatarUrl, 'points': points,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loadSession() async {
    final rows = await (await db).query('session', where: 'id = 1');
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> clearSession() async =>
      (await db).delete('session', where: 'id = 1');

  Future<void> updateSessionProfile({
    String? avatarUrl, int? points,
    String? fullName, String? course, String? yearLevel,
  }) async {
    final database = await db;
    final rows = await database.query('session', where: 'id = 1');
    if (rows.isEmpty) return;
    final updates = <String, dynamic>{};
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (points    != null) updates['points']     = points;
    if (fullName  != null) updates['full_name']  = fullName;
    if (course    != null) updates['course']     = course;
    if (yearLevel != null) updates['year_level'] = yearLevel;
    if (updates.isNotEmpty) {
      await database.update('session', updates, where: 'id = 1');
    }
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final database = await db;
    final rows = await database.query('settings', where: 'id = 1');
    if (rows.isNotEmpty) return Map<String, dynamic>.from(rows.first);
    final defaults = {
      'id': 1, 'dark_mode': 0, 'push_notifications': 1,
      'email_alerts': 0, 'location_access': 1,
      'notif_news': 1, 'notif_events': 1,
      'notif_lost_found': 1, 'notif_marketplace': 1,
    };
    await database.insert('settings', defaults,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return defaults;
  }

  Future<void> saveSetting(String key, bool value) async =>
      (await db).update('settings', {key: value ? 1 : 0}, where: 'id = 1');

  Future<void> saveAllSettings({
    required bool darkMode, required bool pushNotifications,
    required bool emailAlerts, required bool locationAccess,
    required bool notifNews, required bool notifEvents,
    required bool notifLostFound, required bool notifMarketplace,
  }) async {
    await (await db).update('settings', {
      'dark_mode':          darkMode          ? 1 : 0,
      'push_notifications': pushNotifications ? 1 : 0,
      'email_alerts':       emailAlerts       ? 1 : 0,
      'location_access':    locationAccess    ? 1 : 0,
      'notif_news':         notifNews         ? 1 : 0,
      'notif_events':       notifEvents       ? 1 : 0,
      'notif_lost_found':   notifLostFound    ? 1 : 0,
      'notif_marketplace':  notifMarketplace  ? 1 : 0,
    }, where: 'id = 1');
  }
}

// =============================================================================
// AUTH SERVICE
// =============================================================================
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<UserModel> register({
    required String fullName, required String studentId,
    required String email, required String password,
    required String course, required String yearLevel,
    required String department,
  }) async {
    final res = await http.post(Uri.parse('$_base/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName, 'student_id': studentId, 'email': email,
        'password': password, 'course': course,
        'year_level': yearLevel, 'department': department,
      }),
    );
    final body = (_safeJson(res) as Map<String, dynamic>);
    if (res.statusCode == 201) {
      final user = UserModel.fromJson(body['student'] as Map<String, dynamic>);
      await _saveSession(token: body['access_token'] as String, user: user);
      return user;
    }
    throw Exception(body['message'] ?? 'Registration failed.');
  }

  Future<UserModel> signIn({
    required String email, required String password,
  }) async {
    final res = await http.post(Uri.parse('$_base/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = (_safeJson(res) as Map<String, dynamic>);
    if (res.statusCode == 200) {
      final user = UserModel.fromJson(body['student'] as Map<String, dynamic>);
      await _saveSession(token: body['access_token'] as String, user: user);
      return user;
    }
    throw Exception(body['message'] ?? 'Sign in failed. Please try again.');
  }

  Future<void> signOut() async =>
      DatabaseService.instance.clearSession();

  Future<UserModel?> tryAutoLogin() async {
    try {
      final row = await DatabaseService.instance.loadSession();
      if (row == null) return null;
      final token = row['token'] as String?;
      if (token == null || token.isEmpty) return null;
      return UserModel(
        id:         row['user_id']    as String? ?? '',
        fullName:   row['full_name']  as String? ?? '',
        email:      row['email']      as String? ?? '',
        studentId:  row['student_id'] as String? ?? '',
        course:     row['course']     as String? ?? '',
        yearLevel:  row['year_level'] as String? ?? '',
        department: row['department'] as String? ?? '',
        avatarUrl:  row['avatar_url'] as String?,
        points:     (row['points']    as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('[AuthService] Auto-login error: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      return (await DatabaseService.instance.loadSession())?['token'] as String?;
    } catch (_) { return null; }
  }

  Future<UserModel> fetchMe() async {
    final user = await tryAutoLogin();
    if (user == null) throw Exception('Not logged in.');
    return user;
  }

  Future<void> changePassword({
    required String current, required String newPassword,
  }) async {
    final token = await getToken();
    final res = await http.put(Uri.parse('$_base/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
      },
      body: jsonEncode({
        'current_password': current, 'new_password': newPassword,
      }),
    ).timeout(const Duration(seconds: 15));
    final body = (_safeJson(res) as Map<String, dynamic>);
    if (res.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to change password.');
    }
  }

  Future<void> saveFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return;
      final res = await http.post(Uri.parse('$_base/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      ).timeout(const Duration(seconds: 10));
      debugPrint('[AuthService] FCM token: ${res.statusCode}');
    } catch (e) {
      debugPrint('[AuthService] FCM token error (non-critical): $e');
    }
  }

  Future<void> updateCachedProfile({
    String? avatarUrl, int? points,
    String? fullName, String? course, String? yearLevel,
  }) async {
    await DatabaseService.instance.updateSessionProfile(
      avatarUrl: avatarUrl, points: points,
      fullName: fullName, course: course, yearLevel: yearLevel,
    );
  }

  Future<void> _saveSession({
    required String token, required UserModel user,
  }) async {
    await DatabaseService.instance.saveSession(
      token: token, userId: user.id, email: user.email,
      fullName: user.fullName, studentId: user.studentId,
      course: user.course, yearLevel: user.yearLevel,
      department: user.department, avatarUrl: user.avatarUrl,
      points: user.points,
    );
  }
}

// =============================================================================
// CHAT SOCKET SERVICE
// =============================================================================
class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  io.Socket? _socket;
  bool _isConnected = false;

  Function(Map<String, dynamic>)? onNewMessage;
  Function(String)? onDmReady;
  Function(String)? onError;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected && _socket?.connected == true) return;
    final token = await AuthService.instance.getToken();
    if (token == null) return;
    try {
      _socket = io.io('http://192.168.1.11:5000',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );
      _socket!.onConnect((_) { _isConnected = true; });
      _socket!.onDisconnect((_) { _isConnected = false; });
      _socket!.onConnectError((_) {
        _isConnected = false;
        onError?.call('Connection failed. Please try again.');
      });
      _socket!.onReconnect((_) { _isConnected = true; });
      _socket!.on('new_message', (data) {
        if (onNewMessage != null && data is Map) {
          onNewMessage!(Map<String, dynamic>.from(data));
        }
      });
      _socket!.on('dm_ready', (data) {
        if (onDmReady != null && data is Map) {
          final convId = data['conversation_id']?.toString() ?? '';
          if (convId.isNotEmpty) onDmReady!(convId);
        }
      });
      _socket!.on('error', (data) {
        if (onError != null && data is Map) {
          onError!(data['message']?.toString() ?? 'Unknown socket error.');
        }
      });
      _socket!.connect();
    } catch (e) {
      debugPrint('[Socket] Failed to initialize: $e');
    }
  }

  void joinConversation(String conversationId) {
    if (!_isConnected) return;
    _socket?.emit('join_conversation', {'conversation_id': conversationId});
  }

  void leaveConversation(String conversationId) =>
      _socket?.emit('leave_conversation', {'conversation_id': conversationId});

  Future<void> sendMessage(String conversationId, String text) async {
    if (!_isConnected) return;
    final token = await AuthService.instance.getToken();
    _socket?.emit('send_message', {
      'token': token ?? '', 'conversation_id': conversationId, 'text': text,
    });
  }

  Future<void> startDm(String otherStudentId) async {
    if (!_isConnected) {
      await connect();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    final token = await AuthService.instance.getToken();
    _socket?.emit('start_dm', {
      'token': token ?? '', 'other_student_id': otherStudentId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    onNewMessage = null;
    onDmReady = null;
    onError = null;
  }

  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    await connect();
  }
}

// =============================================================================
// NOTIFICATION SERVICE
// =============================================================================
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Function(RemoteMessage)? onForegroundMessage;
  Function(RemoteMessage)? onNotificationTap;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
      announcement: false, carPlay: false,
      criticalAlert: false, provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _setupNotifications();
    }
  }

  Future<void> _setupNotifications() async {
    await _messaging.subscribeToTopic('all_students');
    await _saveDeviceToken();
    FirebaseMessaging.onMessage.listen((msg) => onForegroundMessage?.call(msg));
    FirebaseMessaging.onMessageOpenedApp.listen((msg) => onNotificationTap?.call(msg));
    final initial = await _messaging.getInitialMessage();
    if (initial != null) onNotificationTap?.call(initial);
  }

  Future<void> _saveDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await AuthService.instance.saveFcmToken(token);
    } catch (e) {
      debugPrint('[FCM] Failed to get/save token: $e');
    }
  }

  void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen(
          (t) async => AuthService.instance.saveFcmToken(t),
    );
  }

  Future<void> refreshTokenAfterLogin() async {
    await _saveDeviceToken();
    listenForTokenRefresh();
  }

  static String getNotificationType(RemoteMessage message) =>
      message.data['type']?.toString() ?? 'general';

  static String? getNotificationId(RemoteMessage message) =>
      message.data['event_id']?.toString() ??
          message.data['news_id']?.toString();
}

// =============================================================================
// ORG POST SERVICE
// =============================================================================
const String _flaskBase = 'http://192.168.1.11:5000/api/mobile';

class OrgAssignment {
  final int    assignmentId;
  final int    organizationId;
  final String organizationName;
  final String acronym;
  final String roleName;

  const OrgAssignment({
    required this.assignmentId, required this.organizationId,
    required this.organizationName, required this.acronym,
    required this.roleName,
  });

  factory OrgAssignment.fromJson(Map<String, dynamic> j) => OrgAssignment(
    assignmentId:     (j['assignmentId']   as num).toInt(),
    organizationId:   (j['organizationId'] as num).toInt(),
    organizationName: j['organizationName'] ?? '',
    acronym:          j['acronym']          ?? '',
    roleName:         j['roleName']         ?? '',
  );
}

class OrgPostService {
  OrgPostService._();
  static final OrgPostService instance = OrgPostService._();

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Tries ?studentId= then ?userId= so it works regardless of which id is passed.
  Future<List<OrgAssignment>> fetchMyOrganizations(String id) async {
    final headers = await _authHeaders;
    // Attempt 1: student number string (e.g. '2021-00123')
    try {
      final res = await http
          .get(Uri.parse('$_flaskBase/my-organizations?studentId=$id'),
          headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = _safeJson(res);
        if (list is List && list.isNotEmpty) {
          return list.map((e) => OrgAssignment.fromJson(e)).toList();
        }
      }
    } catch (_) {}

    // Attempt 2: numeric DB primary key (userId)
    try {
      final res = await http
          .get(Uri.parse('$_flaskBase/my-organizations?userId=$id'),
          headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = _safeJson(res);
        if (list is List) {
          return list.map((e) => OrgAssignment.fromJson(e)).toList();
        }
      }
    } catch (_) {}

    return [];
  }

  Future<bool> canStudentPost(String studentId) async =>
      (await fetchMyOrganizations(studentId)).isNotEmpty;

  Future<void> postNews({
    required String studentId, required int organizationId,
    required String title, required String body,
    required String category, bool isFeatured = false,
  }) async {
    final res = await http.post(Uri.parse('$_flaskBase/news/'),
      headers: await _authHeaders,
      body: jsonEncode({
        'studentId': studentId, 'organizationId': organizationId,
        'title': title, 'body': body,
        'category': category, 'isFeatured': isFeatured,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to post news: ${res.body}');
    }
  }

  Future<void> postEvent({
    required String studentId, required int organizationId,
    required String shortName, required String fullName,
    required String date, required String venue,
    required String category, required String description,
    String color = '#8B1A1A',
  }) async {
    final res = await http.post(Uri.parse('$_flaskBase/events/'),
      headers: await _authHeaders,
      body: jsonEncode({
        'studentId': studentId, 'organizationId': organizationId,
        'shortName': shortName, 'fullName': fullName,
        'date': date, 'venue': venue,
        'category': category, 'description': description, 'color': color,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to post event: ${res.body}');
    }
  }
}

// =============================================================================
// NEWS SERVICE
// =============================================================================
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<List<NewsModel>> fetchAll() async {
    final token = await AuthService.instance.getToken();
    final res = await http.get(Uri.parse('$_base/news'), headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load news (${res.statusCode}).');
  }
}

// =============================================================================
// EVENT SERVICE
// =============================================================================
class EventService {
  EventService._();
  static final EventService instance = EventService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<EventModel>> fetchAll() async {
    final res = await http.get(Uri.parse('$_base/events'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load events (${res.statusCode}).');
  }

  Future<Map<String, dynamic>> attendEvent(String eventId) async {
    final res = await http.post(Uri.parse('$_base/events/$eventId/attend'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    final body = (_safeJson(res) as Map<String, dynamic>);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return {
        'ok': true,
        'message': body['message'] ?? 'Attendance recorded.',
        'points': body['points'] ?? 0,
        'already_attended': body['already_attended'] ?? false,
      };
    }
    throw Exception(body['message'] ?? 'Failed to attend event.');
  }

  Future<bool> hasAttended(String eventId) async {
    try {
      final res = await http.get(Uri.parse('$_base/events/$eventId/attended'),
          headers: await _authHeaders)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return (_safeJson(res) as Map<String, dynamic>)['attended'] == true;
      }
      return false;
    } catch (_) { return false; }
  }
}

// =============================================================================
// MARKETPLACE SERVICE
// =============================================================================
class MarketplaceService {
  MarketplaceService._();
  static final MarketplaceService instance = MarketplaceService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<MarketplaceItemModel>> fetchAll() async {
    final res = await http.get(Uri.parse('$_base/marketplace'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => MarketplaceItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load marketplace items (${res.statusCode}).');
  }

  Future<List<MarketplaceItemModel>> search(String query) async {
    final uri = Uri.parse('$_base/marketplace')
        .replace(queryParameters: {'q': query});
    final res = await http.get(uri, headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => MarketplaceItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Search failed (${res.statusCode}).');
  }

  Future<MarketplaceItemModel> createItem({
    required String name, required String description,
    required String condition, required double price,
    String? contactNumber,
    List<String>? paymentMethods,
    String? base64Image,
  }) async {
    // ── FIX: base64Image already includes the full data URI prefix.
    // Do NOT prepend 'data:image/jpeg;base64,' again.
    String? imageUrl;
    if (base64Image != null) {
      try {
        final uploadRes = await http.post(
          Uri.parse('$_base/upload/image'),
          headers: await _authHeaders,
          body: jsonEncode({
            'image': base64Image, // ← FIXED: pass as-is, no double prefix
            'type': 'marketplace',
          }),
        ).timeout(const Duration(seconds: 30));
        if (uploadRes.statusCode == 200) {
          imageUrl = (_safeJson(uploadRes) as Map<String, dynamic>)['url'] as String?;
        } else {
          debugPrint('[Marketplace] Image upload failed: ${uploadRes.statusCode} ${uploadRes.body}');
        }
      } catch (e) {
        debugPrint('[Marketplace] Image upload exception: $e');
        // Fallback: send base64 directly as image_url
        imageUrl = base64Image;
      }

      // If upload returned no URL, fall back to base64 directly
      imageUrl ??= base64Image;
    }

    final res = await http.post(Uri.parse('$_base/marketplace/'),
      headers: await _authHeaders,
      body: jsonEncode({
        'name': name, 'description': description,
        'condition': condition, 'price': price,
        if (contactNumber != null) 'contact_number': contactNumber,
        if (paymentMethods != null) 'payment_methods': paymentMethods,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 201) {
      return MarketplaceItemModel.fromJson(
          _safeJson(res) as Map<String, dynamic>);
    }
    final body = (_safeJson(res) as Map<String, dynamic>);
    throw Exception(body['message'] ?? 'Failed to create listing.');
  }
}

// =============================================================================
// LOST & FOUND SERVICE
// FIX: base64Image already contains the full data URI
// (e.g. "data:image/jpeg;base64,/9j/4AAQ...") — it must NOT be prefixed again.
// The old code was doing 'data:image/jpeg;base64,$base64Image' which doubled
// the prefix, causing the upload endpoint to reject it silently, leaving
// imageUrl as null and no photo being saved or shown.
// =============================================================================
class LostFoundService {
  LostFoundService._();
  static final LostFoundService instance = LostFoundService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<LostFoundModel>> fetchAll() async {
    final res = await http.get(Uri.parse('$_base/lost-found'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => LostFoundModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load lost & found items (${res.statusCode}).');
  }

  Future<LostFoundModel> reportItem({
    required String title, required String description,
    required String location, required String date,
    required String status, String? base64Image,
  }) async {
    // ── Upload image first if provided ─────────────────────────────────────
    // base64Image already contains the full data URI prefix, e.g.:
    //   "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAA..."
    // So pass it directly — do NOT prepend 'data:image/jpeg;base64,' again.
    String? imageUrl;
    if (base64Image != null) {
      try {
        final uploadRes = await http.post(
          Uri.parse('$_base/upload/image'),
          headers: await _authHeaders,
          body: jsonEncode({
            'image': base64Image, // ← FIXED: was 'data:image/jpeg;base64,$base64Image'
            'type': 'lost_found',
          }),
        ).timeout(const Duration(seconds: 30));

        if (uploadRes.statusCode == 200) {
          imageUrl = (_safeJson(uploadRes) as Map<String, dynamic>)['url'] as String?;
          debugPrint('[LostFound] Image uploaded successfully: $imageUrl');
        } else {
          debugPrint('[LostFound] Image upload failed: ${uploadRes.statusCode} ${uploadRes.body}');
        }
      } catch (e) {
        debugPrint('[LostFound] Image upload exception: $e');
      }

      // Fallback: if upload endpoint is unavailable or fails,
      // send the base64 string directly as image_url so the image
      // is at least stored and shown in the app.
      imageUrl ??= base64Image;
    }

    final res = await http.post(
      Uri.parse('$_base/lost-found/'),
      headers: await _authHeaders,
      body: jsonEncode({
        'title':       title,
        'description': description,
        'location':    location,
        'date':        date,
        'status':      status,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 201) {
      return LostFoundModel.fromJson(_safeJson(res) as Map<String, dynamic>);
    }
    final body = (_safeJson(res) as Map<String, dynamic>);
    throw Exception(body['message'] ?? 'Failed to submit report.');
  }
} // end LostFoundService

// =============================================================================
// CHAT SERVICE
// =============================================================================
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ChatModel>> fetchConversations() async {
    final res = await http.get(Uri.parse('$_base/chat/conversations'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load conversations (${res.statusCode}).');
  }

  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
    final res = await http.get(
        Uri.parse('$_base/chat/conversations/$conversationId/messages'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load messages (${res.statusCode}).');
  }
}

// =============================================================================
// CLUB SERVICE
// =============================================================================
class ClubService {
  ClubService._();
  static final ClubService instance = ClubService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ClubModel>> fetchAll() async {
    final res = await http.get(Uri.parse('$_base/clubs/organizations'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => ClubModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load clubs (${res.statusCode}).');
  }

  Future<void> toggleMembership(String clubId, bool isJoined) async {
    try {
      final endpoint = isJoined
          ? '$_base/clubs/$clubId/join'
          : '$_base/clubs/$clubId/leave';
      await http.post(Uri.parse(endpoint), headers: await _authHeaders)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[ClubService] toggleMembership error (non-critical): $e');
    }
  }
}

// =============================================================================
// LEADERBOARD SERVICE
// =============================================================================
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<List<LeaderboardEntryModel>> fetchAll() async {
    final token = await AuthService.instance.getToken();
    final res = await http.get(Uri.parse('$_base/leaderboard'), headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (_safeJson(res) as List)
          .map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load leaderboard (${res.statusCode}).');
  }
}

// =============================================================================
// USER SERVICE
// =============================================================================
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserModel> fetchProfile(String userId) async {

    final res = await http.get(
        Uri.parse('$_base/students/profile'),
        headers: await _authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return UserModel.fromJson(_safeJson(res) as Map<String, dynamic>);
    }
    throw Exception('Failed to load profile (${res.statusCode}).');
  }

  Future<UserModel> updateProfile(UserModel updated) async {
    final res = await http.put(Uri.parse('$_base/users/${updated.id}'),
      headers: await _authHeaders,
      body: jsonEncode({
        'full_name':  updated.fullName,
        'course':     updated.course,
        'year_level': updated.yearLevel,
        if (updated.avatarUrl != null) 'avatar_url': updated.avatarUrl,
      }),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode == 200) {
      return UserModel.fromJson(_safeJson(res) as Map<String, dynamic>);
    }
    final body = (_safeJson(res) as Map<String, dynamic>);
    throw Exception(body['message'] ?? 'Failed to update profile.');
  }
}