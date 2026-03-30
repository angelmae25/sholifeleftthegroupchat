// =============================================================================
// lib/services/database_service.dart
//
// SQLite persistence layer for:
//   1. JWT session (token + user profile) → auto-login
//   2. App settings (dark mode, notifications, etc.) → survive app close
//
// Add to pubspec.yaml:
//   sqflite: ^2.3.3
//   path: ^1.9.0
// =============================================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  // ── Open / create DB ───────────────────────────────────────────────────────
  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'scholife.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        // ── Session table (only ever 1 row — id = 1) ────────────────────────
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

        // ── Settings table (only ever 1 row — id = 1) ───────────────────────
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

        // Insert default settings row
        await db.insert('settings', {
          'id': 1,
          'dark_mode': 0,
          'push_notifications': 1,
          'email_alerts': 0,
          'location_access': 1,
          'notif_news': 1,
          'notif_events': 1,
          'notif_lost_found': 1,
          'notif_marketplace': 1,
        });
      },
    );
  }

  // ==========================================================================
  // SESSION METHODS
  // ==========================================================================

  /// Save (or replace) the current login session.
  Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
    required String fullName,
    required String studentId,
    required String course,
    required String yearLevel,
    required String department,
    String? avatarUrl,
    int points = 0,
  }) async {
    final database = await db;
    await database.insert(
      'session',
      {
        'id':         1,
        'token':      token,
        'user_id':    userId,
        'email':      email,
        'full_name':  fullName,
        'student_id': studentId,
        'course':     course,
        'year_level': yearLevel,
        'department': department,
        'avatar_url': avatarUrl,
        'points':     points,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Load the saved session. Returns null if no session exists.
  Future<Map<String, dynamic>?> loadSession() async {
    final database = await db;
    final rows = await database.query('session', where: 'id = 1');
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Clear the session on sign-out.
  Future<void> clearSession() async {
    final database = await db;
    await database.delete('session', where: 'id = 1');
  }

  /// Update avatar URL and points after profile edit.
  Future<void> updateSessionProfile({
    String? avatarUrl,
    int? points,
    String? fullName,
    String? course,
    String? yearLevel,
    String? phone,
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

  // ==========================================================================
  // SETTINGS METHODS
  // ==========================================================================

  /// Load settings. Always returns a map (creates defaults if missing).
  Future<Map<String, dynamic>> loadSettings() async {
    final database = await db;
    final rows = await database.query('settings', where: 'id = 1');
    if (rows.isNotEmpty) return Map<String, dynamic>.from(rows.first);

    // Shouldn't happen since we insert defaults on create, but be safe:
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

  /// Save a single boolean setting by key.
  Future<void> saveSetting(String key, bool value) async {
    final database = await db;
    await database.update(
      'settings',
      {key: value ? 1 : 0},
      where: 'id = 1',
    );
  }

  /// Save all settings at once.
  Future<void> saveAllSettings({
    required bool darkMode,
    required bool pushNotifications,
    required bool emailAlerts,
    required bool locationAccess,
    required bool notifNews,
    required bool notifEvents,
    required bool notifLostFound,
    required bool notifMarketplace,
  }) async {
    final database = await db;
    await database.update(
      'settings',
      {
        'dark_mode':          darkMode          ? 1 : 0,
        'push_notifications': pushNotifications ? 1 : 0,
        'email_alerts':       emailAlerts       ? 1 : 0,
        'location_access':    locationAccess    ? 1 : 0,
        'notif_news':         notifNews         ? 1 : 0,
        'notif_events':       notifEvents       ? 1 : 0,
        'notif_lost_found':   notifLostFound    ? 1 : 0,
        'notif_marketplace':  notifMarketplace  ? 1 : 0,
      },
      where: 'id = 1',
    );
  }
}