// =============================================================================
// FILE PATH: lib/services/notification_service.dart
//
// Handles Firebase Cloud Messaging (FCM) push notifications.
//
// Add to pubspec.yaml:
//   firebase_core: ^3.0.0
//   firebase_messaging: ^15.0.0
//
// SETUP STEPS:
// 1. Go to https://console.firebase.google.com
// 2. Create a project (or use existing)
// 3. Add Android app → download google-services.json
//    → place it in: android/app/google-services.json
// 4. Add to android/build.gradle (project level):
//      classpath 'com.google.gms:google-services:4.4.0'
// 5. Add to android/app/build.gradle:
//      apply plugin: 'com.google.gms.google-services'
// 6. Run: flutter pub get
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_service.dart';

// ── Background message handler (must be top-level function) ──────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
  // Handle background notification silently
  // The notification is automatically shown by the OS
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ── Callback — set this in main.dart to handle navigation on tap ──────────
  /// Called when the user taps a notification while the app is in foreground.
  Function(RemoteMessage)? onForegroundMessage;

  /// Called when the user taps a notification to open the app.
  Function(RemoteMessage)? onNotificationTap;

  // ── Initialize ─────────────────────────────────────────────────────────────
  /// Call this in main() after Firebase.initializeApp().
  ///
  /// Example in main.dart:
  ///   void main() async {
  ///     WidgetsFlutterBinding.ensureInitialized();
  ///     await Firebase.initializeApp();
  ///     await NotificationService.instance.init();
  ///     runApp(const ScholifeApp());
  ///   }
  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // Request notification permission from user
    final settings = await _messaging.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
      announcement:  false,
      carPlay:       false,
      criticalAlert: false,
      provisional:   false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[FCM] ✅ Permission granted');
      await _setupNotifications();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('[FCM] ⚠️ Provisional permission granted');
      await _setupNotifications();
    } else {
      debugPrint('[FCM] ❌ Permission denied by user');
    }
  }

  // ── Setup after permission granted ────────────────────────────────────────
  Future<void> _setupNotifications() async {
    // Subscribe to broadcast topic — Flask sends to this topic
    // when a new event or news article is posted
    await _messaging.subscribeToTopic('all_students');
    debugPrint('[FCM] Subscribed to all_students topic');

    // Get device token and save to Flask
    await _saveDeviceToken();

    // ── Foreground messages ────────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      if (onForegroundMessage != null) {
        onForegroundMessage!(message);
      }
    });

    // ── Background → app opened via notification tap ───────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notification tapped: ${message.data}');
      if (onNotificationTap != null) {
        onNotificationTap!(message);
      }
    });

    // ── App opened from terminated state via notification ──────────────────
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated: ${initialMessage.data}');
      if (onNotificationTap != null) {
        onNotificationTap!(initialMessage);
      }
    }
  }

  // ── Save device token to Flask ─────────────────────────────────────────────
  /// Gets the FCM device token and saves it to Flask via
  /// POST /api/mobile/auth/fcm-token
  /// Flask uses this token to send targeted notifications.
  Future<void> _saveDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Device token: ${token.substring(0, 20)}...');
        await AuthService.instance.saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to get/save token: $e');
    }
  }

  // ── Refresh token listener ─────────────────────────────────────────────────
  /// Called when FCM refreshes the device token.
  /// Automatically re-saves the new token to Flask.
  void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      await AuthService.instance.saveFcmToken(newToken);
    });
  }

  // ── Manual token refresh ───────────────────────────────────────────────────
  /// Call this after login to ensure the token is always up to date.
  Future<void> refreshTokenAfterLogin() async {
    await _saveDeviceToken();
    listenForTokenRefresh();
  }

  // ── Get notification data type ─────────────────────────────────────────────
  /// Helper to extract the notification type from message data.
  /// Returns 'event', 'news', or 'general'.
  ///
  /// Use in onNotificationTap to navigate to the right screen:
  ///   final type = NotificationService.getNotificationType(message);
  ///   if (type == 'event') context.go('/events');
  ///   if (type == 'news')  context.go('/news');
  static String getNotificationType(RemoteMessage message) {
    return message.data['type']?.toString() ?? 'general';
  }

  static String? getNotificationId(RemoteMessage message) {
    return message.data['event_id']?.toString() ??
        message.data['news_id']?.toString();
  }
}