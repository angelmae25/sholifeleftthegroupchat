// =============================================================================
// lib/services/auth_service.dart  (UPDATED — uses Flask JWT)
//
// Flutter now calls Flask on port 5000.
// Android Emulator  → 10.0.2.2:5000
// Physical device   → your computer's WiFi IP e.g. 192.168.1.5:5000
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Flask base URL ─────────────────────────────────────────────────────────
  static const String _base = 'http://192.168.1.11:5000/api/mobile';

  static const _kToken      = 'jwt_token';
  static const _kUserId     = 'user_id';
  static const _kUserEmail  = 'user_email';
  static const _kUserName   = 'user_name';
  static const _kStudentId  = 'student_id_key';
  static const _kCourse     = 'course_key';
  static const _kYearLevel  = 'year_level_key';
  static const _kDepartment = 'department_key';

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
        'full_name':   fullName,
        'student_id':  studentId,
        'email':       email,
        'password':    password,
        'course':      course,
        'year_level':  yearLevel,
        'department':  department,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 201) {
      final token   = body['access_token'] as String;
      final student = body['student'] as Map<String, dynamic>;
      final user    = UserModel.fromJson(student);

      await _saveSession(
        token:      token,
        id:         user.id,
        email:      user.email,
        fullName:   user.fullName,
        studentId:  user.studentId,
        course:     user.course,
        yearLevel:  user.yearLevel,
        department: user.department,
      );

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

      await _saveSession(
        token:      token,
        id:         user.id,
        email:      user.email,
        fullName:   user.fullName,
        studentId:  user.studentId,
        course:     user.course,
        yearLevel:  user.yearLevel,
        department: user.department,
      );

      return user;
    }

    throw Exception(body['message'] ?? 'Sign in failed. Please try again.');
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kUserName);
    await prefs.remove(_kStudentId);
    await prefs.remove(_kCourse);
    await prefs.remove(_kYearLevel);
    await prefs.remove(_kDepartment);
  }

  // ── AUTO-LOGIN ─────────────────────────────────────────────────────────────
  Future<UserModel?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final id    = prefs.getString(_kUserId);
    if (token == null || id == null) return null;

    return UserModel(
      id:         id,
      fullName:   prefs.getString(_kUserName)   ?? '',
      email:      prefs.getString(_kUserEmail)  ?? '',
      studentId:  prefs.getString(_kStudentId)  ?? '',
      course:     prefs.getString(_kCourse)     ?? '',
      yearLevel:  prefs.getString(_kYearLevel)  ?? '',
      department: prefs.getString(_kDepartment) ?? '',
    );
  }

  // ── GET JWT TOKEN ──────────────────────────────────────────────────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  // ── FETCH ME ───────────────────────────────────────────────────────────────
  Future<UserModel> fetchMe() async {
    final user = await tryAutoLogin();
    if (user == null) throw Exception('Not logged in.');
    return user;
  }

  // ── CHANGE PASSWORD → PUT /auth/change-password ────────────────────────────
  /// Verifies current password on the server and updates to new password.
  /// Throws an Exception with the server error message on failure.
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
  /// Saves the Firebase device token to Flask so push notifications work.
  /// Called once on app start after Firebase initializes.
  /// Fails silently — never throws, just prints a warning.
  Future<void> saveFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return; // not logged in yet — skip

      final res = await http.post(
        Uri.parse('$_base/auth/fcm-token'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        print('[AuthService] FCM token saved successfully.');
      } else {
        print('[AuthService] FCM token save failed: ${res.statusCode}');
      }
    } catch (e) {
      print('[AuthService] FCM token error (non-critical): $e');
    }
  }

  // ── Save session ───────────────────────────────────────────────────────────
  Future<void> _saveSession({
    required String token,
    required String id,
    required String email,
    required String fullName,
    required String studentId,
    required String course,
    required String yearLevel,
    required String department,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken,      token);
    await prefs.setString(_kUserId,     id);
    await prefs.setString(_kUserEmail,  email);
    await prefs.setString(_kUserName,   fullName);
    await prefs.setString(_kStudentId,  studentId);
    await prefs.setString(_kCourse,     course);
    await prefs.setString(_kYearLevel,  yearLevel);
    await prefs.setString(_kDepartment, department);
  }
}