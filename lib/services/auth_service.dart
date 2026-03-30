// =============================================================================
// lib/services/auth_service.dart
// Session is now persisted to SQLite via DatabaseService.
// SharedPreferences is no longer used for the auth session.
// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Flask base URL ─────────────────────────────────────────────────────────
  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  // ── REGISTER → POST /auth/register ────────────────────────────────────────
  Future<UserModel> register({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
    required String course,
    required String yearLevel,
    required String department,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name':  fullName,
        'student_id': studentId,
        'email':      email,
        'password':   password,
        'course':     course,
        'year_level': yearLevel,
        'department': department,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 201) {
      final token   = body['access_token'] as String;
      final student = body['student'] as Map<String, dynamic>;
      final user    = UserModel.fromJson(student);
      await _saveSession(token: token, user: user);
      return user;
    }

    throw Exception(body['message'] ?? 'Registration failed.');
  }

  // ── SIGN IN → POST /auth/login ─────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      final token   = body['access_token'] as String;
      final student = body['student']      as Map<String, dynamic>;
      final user    = UserModel.fromJson(student);
      await _saveSession(token: token, user: user);
      return user;
    }

    throw Exception(body['message'] ?? 'Sign in failed. Please try again.');
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await DatabaseService.instance.clearSession();
  }

  // ── AUTO-LOGIN from SQLite ─────────────────────────────────────────────────
  /// Checks SQLite for a saved session. Returns the UserModel if found.
  /// Returns null if no session — app will show Sign In screen.
  Future<UserModel?> tryAutoLogin() async {
    try {
      final row = await DatabaseService.instance.loadSession();
      if (row == null) return null;

      final token = row['token'] as String?;
      if (token == null || token.isEmpty) return null;

      return UserModel(
        id:         row['user_id']   as String? ?? '',
        fullName:   row['full_name'] as String? ?? '',
        email:      row['email']     as String? ?? '',
        studentId:  row['student_id'] as String? ?? '',
        course:     row['course']    as String? ?? '',
        yearLevel:  row['year_level'] as String? ?? '',
        department: row['department'] as String? ?? '',
        avatarUrl:  row['avatar_url'] as String?,
        points:     (row['points']   as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('[AuthService] Auto-login error: $e');
      return null;
    }
  }

  // ── GET JWT TOKEN ──────────────────────────────────────────────────────────
  Future<String?> getToken() async {
    try {
      final row = await DatabaseService.instance.loadSession();
      return row?['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── FETCH ME ───────────────────────────────────────────────────────────────
  Future<UserModel> fetchMe() async {
    final user = await tryAutoLogin();
    if (user == null) throw Exception('Not logged in.');
    return user;
  }

  // ── CHANGE PASSWORD → PUT /auth/change-password ───────────────────────────
  Future<void> changePassword({
    required String current,
    required String newPassword,
  }) async {
    final token = await getToken();

    final res = await http.put(
      Uri.parse('$_base/auth/change-password'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
      },
      body: jsonEncode({
        'current_password': current,
        'new_password':     newPassword,
      }),
    ).timeout(const Duration(seconds: 15));

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to change password.');
    }
  }

  // ── SAVE FCM TOKEN → POST /auth/fcm-token ─────────────────────────────────
  Future<void> saveFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return;

      final res = await http.post(
        Uri.parse('$_base/auth/fcm-token'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('[AuthService] FCM token: ${res.statusCode}');
    } catch (e) {
      debugPrint('[AuthService] FCM token error (non-critical): $e');
    }
  }

  // ── Update cached profile in SQLite ───────────────────────────────────────
  /// Called after profile edit so the cached data stays in sync.
  Future<void> updateCachedProfile({
    String? avatarUrl,
    int? points,
    String? fullName,
    String? course,
    String? yearLevel,
  }) async {
    await DatabaseService.instance.updateSessionProfile(
      avatarUrl: avatarUrl,
      points:    points,
      fullName:  fullName,
      course:    course,
      yearLevel: yearLevel,
    );
  }

  // ── Private: save session to SQLite ───────────────────────────────────────
  Future<void> _saveSession({
    required String token,
    required UserModel user,
  }) async {
    await DatabaseService.instance.saveSession(
      token:      token,
      userId:     user.id,
      email:      user.email,
      fullName:   user.fullName,
      studentId:  user.studentId,
      course:     user.course,
      yearLevel:  user.yearLevel,
      department: user.department,
      avatarUrl:  user.avatarUrl,
      points:     user.points,
    );
  }
}