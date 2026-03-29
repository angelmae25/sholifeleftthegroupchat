// =============================================================================
// CONTROLLER: auth_controller.dart
// Manages authentication state. Notifies the View via ChangeNotifier.
// The View (screen) never touches AuthService directly — it only calls
// methods on this controller and reacts to state changes.
// =============================================================================

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Represents all possible auth states
enum AuthStatus { idle, loading, authenticated, error }

class AuthController extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  AuthStatus _status  = AuthStatus.idle;
  UserModel? _user;
  String?    _errorMessage;

  // ── Getters (View reads these) ─────────────────────────────────────────────
  AuthStatus  get status       => _status;
  UserModel?  get user         => _user;
  String?     get errorMessage => _errorMessage;
  bool        get isLoading    => _status == AuthStatus.loading;
  bool        get isLoggedIn   => _status == AuthStatus.authenticated && _user != null;

  // ── Actions (View calls these) ─────────────────────────────────────────────

  /// Sign in with email and password
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

  /// Register a new account
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

  /// Sign out
  Future<void> signOut() async {
    _setLoading();
    await AuthService.instance.signOut();
    _user   = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  /// Called after profile update to keep the drawer/header in sync
  void refreshUser(UserModel updated) {
    _user = updated;
    notifyListeners();
  }

  /// Called after earning points (read news, attend event) to update
  /// the displayed points in the profile/leaderboard without a full reload.
  void refreshPoints(int newPoints) {
    if (_user == null) return;
    _user = _user!.copyWith(points: newPoints);
    notifyListeners();
  }

  // ── Change Password ─────────────────────────────────────────────────────────
  /// Verifies current password then updates to new password.
  /// Returns true on success, false on failure.
  /// On failure, errorMessage is set so the View can display it.
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
      // Stay authenticated — just clear loading state
      _status       = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // ── Save FCM Token ──────────────────────────────────────────────────────────
  /// Sends the Firebase device token to Flask so push notifications work.
  /// Called once on app start after Firebase initializes.
  /// Fails silently — a missing FCM token should never block the user.
  Future<void> saveFcmToken(String token) async {
    try {
      await AuthService.instance.saveFcmToken(token);
    } catch (e) {
      // Non-critical — just log it
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