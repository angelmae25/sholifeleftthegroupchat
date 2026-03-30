// =============================================================================
// CONTROLLER: auth_controller.dart  (UPDATED)
// Added: restoreSession() — called by SplashView after SQLite auto-login
// =============================================================================

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthStatus _status  = AuthStatus.idle;
  UserModel? _user;
  String?    _errorMessage;

  AuthStatus  get status       => _status;
  UserModel?  get user         => _user;
  String?     get errorMessage => _errorMessage;
  bool        get isLoading    => _status == AuthStatus.loading;
  bool        get isLoggedIn   => _status == AuthStatus.authenticated && _user != null;

  // ── Restore session from SQLite (called by SplashView) ────────────────────
  /// Sets the controller to authenticated state without a network call.
  /// Used when the user has a valid saved session in SQLite.
  void restoreSession(UserModel user) {
    _user   = user;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _setLoading();
    try {
      _user   = await AuthService.instance.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
    required String course,
    required String yearLevel,
    required String department,
  }) async {
    _setLoading();
    try {
      _user = await AuthService.instance.register(
        fullName:   fullName,
        studentId:  studentId,
        email:      email,
        password:   password,
        course:     course,
        yearLevel:  yearLevel,
        department: department,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading();
    await AuthService.instance.signOut();
    _user   = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // ── Refresh user after profile update ─────────────────────────────────────
  void refreshUser(UserModel updated) {
    _user = updated;
    notifyListeners();
    // Also update SQLite cache
    AuthService.instance.updateCachedProfile(
      avatarUrl: updated.avatarUrl,
      points:    updated.points,
      fullName:  updated.fullName,
      course:    updated.course,
      yearLevel: updated.yearLevel,
    );
  }

  // ── Refresh points only ────────────────────────────────────────────────────
  void refreshPoints(int newPoints) {
    if (_user == null) return;
    _user = _user!.copyWith(points: newPoints);
    notifyListeners();
    AuthService.instance.updateCachedProfile(points: newPoints);
  }

  // ── Change Password ────────────────────────────────────────────────────────
  Future<bool> changePassword({
    required String current,
    required String newPassword,
  }) async {
    _setLoading();
    try {
      await AuthService.instance.changePassword(
        current:     current,
        newPassword: newPassword,
      );
      _status       = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // ── Save FCM Token ─────────────────────────────────────────────────────────
  Future<void> saveFcmToken(String token) async {
    try {
      await AuthService.instance.saveFcmToken(token);
    } catch (e) {
      debugPrint('[AuthController] FCM token save failed: $e');
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }
}