// =============================================================================
// lib/models/models.dart  — TARGETED FIX
// CHANGE: ClubModel.fromJson now prefixes id with 'org_' so the
//         isOrg detection (club.id.startsWith('org_')) in ClubsView works.
// Everything else is unchanged.
// =============================================================================

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENT MODEL
// ─────────────────────────────────────────────────────────────────────────────
class EventModel {
  final String id;
  final String shortName;
  final String fullName;
  final DateTime date;
  final String venue;
  final String category;
  final Color color;
  final String? description;

  const EventModel({
    required this.id, required this.shortName, required this.fullName,
    required this.date, required this.venue, required this.category,
    required this.color, this.description,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return const Color(0xFF8B1A1A);
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    }

    return EventModel(
      id:          json['id']?.toString() ?? '',
      shortName:   json['short_name']  as String? ?? '',
      fullName:    json['full_name']   as String? ?? '',
      date:        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      venue:       json['venue']       as String? ?? '',
      category:    json['category']    as String? ?? '',
      color:       parseColor(json['color'] as String?),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'short_name': shortName, 'full_name': fullName,
    'date': date.toIso8601String(), 'venue': venue,
    'category': category, 'color': color.value,
  };

  static List<EventModel> get mockList => [
    EventModel(id: 'e1', shortName: 'BASD',   fullName: 'Brigada ng Agham at Sining Dula', date: DateTime(2024, 3, 15), venue: 'Main Campus Gym',     category: 'Cultural', color: const Color(0xFF8B0000)),
    EventModel(id: 'e2', shortName: 'MAAD',   fullName: 'Music, Arts & Drama Day',          date: DateTime(2024, 3, 22), venue: 'Open Air Auditorium', category: 'Cultural', color: const Color(0xFF6A1B9A)),
    EventModel(id: 'e3', shortName: 'TECH',   fullName: '5th Annual Technology Summit',     date: DateTime(2024, 4, 3),  venue: 'Engineering Hall',    category: 'Academic', color: const Color(0xFF8B1A1A)),
    EventModel(id: 'e4', shortName: 'SPORTS', fullName: 'Intramural Sports Festival',       date: DateTime(2024, 4, 10), venue: 'University Grounds',  category: 'Sports',   color: const Color(0xFF1565C0)),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKETPLACE ITEM MODEL
// ─────────────────────────────────────────────────────────────────────────────
class MarketplaceItemModel {
  final String id;
  final String name;
  final String condition;
  final double price;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;
  final DateTime postedAt;

  const MarketplaceItemModel({
    required this.id, required this.name, required this.condition,
    required this.price, required this.sellerId, required this.sellerName,
    required this.postedAt, this.imageUrl,
  });

  factory MarketplaceItemModel.fromJson(Map<String, dynamic> json) => MarketplaceItemModel(
    id:         json['id'] as String,
    name:       json['name'] as String,
    condition:  json['condition'] as String,
    price:      (json['price'] as num).toDouble(),
    sellerId:   json['seller_id'] as String,
    sellerName: json['seller_name'] as String,
    postedAt:   DateTime.parse(json['posted_at'] as String),
    imageUrl:   json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'condition': condition, 'price': price,
    'seller_id': sellerId, 'seller_name': sellerName,
    'posted_at': postedAt.toIso8601String(), 'image_url': imageUrl,
  };

  String get formattedPrice => '₱${price.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// LOST & FOUND MODEL
// ─────────────────────────────────────────────────────────────────────────────
enum LostFoundStatus { lost, found }

class LostFoundModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final LostFoundStatus status;
  final String reporterId;
  final String? imageUrl;

  const LostFoundModel({
    required this.id, required this.title, required this.description,
    required this.location, required this.date, required this.status,
    required this.reporterId, this.imageUrl,
  });

  factory LostFoundModel.fromJson(Map<String, dynamic> json) => LostFoundModel(
    id:          json['id'] as String,
    title:       json['title'] as String,
    description: json['description'] as String,
    location:    json['location'] as String,
    date:        DateTime.parse(json['date'] as String),
    status:      json['status'] == 'lost' ? LostFoundStatus.lost : LostFoundStatus.found,
    reporterId:  json['reporter_id'] as String,
    imageUrl:    json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description, 'location': location,
    'date': date.toIso8601String(), 'status': status.name,
    'reporter_id': reporterId, 'image_url': imageUrl,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ChatModel {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isGroup;
  final List<ChatMessageModel> messages;

  const ChatModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isGroup = false,
    this.messages = const [],
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: DateTime.tryParse(
          json['lastMessageAt'] ?? json['updatedAt'] ?? '') ??
          DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      isGroup: json['isGroup'] ?? false,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => ChatMessageModel.fromJson(e))
          .toList(),
    );
  }

  String get timeLabel {
    final diff = DateTime.now().difference(lastMessageAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class ChatMessageModel {
  final String id;
  final String text;
  final String senderId;
  final DateTime sentAt;
  final bool isMine;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.sentAt,
    required this.isMine,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? json['message'] ?? '',
      senderId: json['senderId']?.toString() ?? '',
      sentAt: DateTime.tryParse(
          json['sentAt'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      isMine: json['isMine'] ?? false,
    );
  }

  String get timeLabel {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m ${sentAt.hour < 12 ? 'AM' : 'PM'}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLUB MODEL
// FIX: fromJson now prefixes the id with 'org_' so that
//      club.id.startsWith('org_') == true in ClubsView, enabling:
//      1. The "Organization" button (instead of Join/Leave)
//      2. _showOrgDetail() to extract the correct rawId
// ─────────────────────────────────────────────────────────────────────────────
class ClubModel {
  final String id;
  final String name;
  final String department;
  final Color color;
  final IconData icon;
  bool isJoined;

  ClubModel({
    required this.id, required this.name, required this.department,
    required this.color, required this.icon, this.isJoined = false,
  });

  // FIX: prefix id with 'org_' so isOrg detection works in ClubsView
  factory ClubModel.fromJson(Map<String, dynamic> json) => ClubModel(
    id:         'org_${json['id']?.toString() ?? ''}',   // ← KEY FIX
    name:       json['name']    as String? ?? '',
    department: json['acronym'] as String? ?? '',
    color:      const Color(0xFF8B1A1A),
    icon:       Icons.groups,
  );

  static List<ClubModel> get mockList => [
    ClubModel(id: 'cl1', name: 'CS Society',   department: 'Computer Science', color: const Color(0xFF8B1A1A), icon: Icons.computer,           isJoined: true),
    ClubModel(id: 'cl2', name: 'Math Club',    department: 'Mathematics',      color: const Color(0xFF1565C0), icon: Icons.calculate),
    ClubModel(id: 'cl3', name: 'Art Circle',   department: 'Fine Arts',        color: const Color(0xFF6A1B9A), icon: Icons.palette),
    ClubModel(id: 'cl4', name: 'Science Club', department: 'Natural Sciences', color: const Color(0xFF2E7D32), icon: Icons.science,             isJoined: true),
    ClubModel(id: 'cl5', name: 'Debate Team',  department: 'Liberal Arts',     color: const Color(0xFFE65100), icon: Icons.record_voice_over),
    ClubModel(id: 'cl6', name: 'Photography',  department: 'Media Arts',       color: const Color(0xFF37474F), icon: Icons.camera_alt),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD ENTRY MODEL
// ─────────────────────────────────────────────────────────────────────────────
class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String name;
  final String department;
  final int points;
  final String? avatarUrl;

  const LeaderboardEntryModel({
    required this.rank, required this.userId, required this.name,
    required this.department, required this.points, this.avatarUrl,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryModel(
        rank:       (json['rank'] as int?) ?? 0,
        userId:     json['id']?.toString() ?? '',
        name:       json['full_name'] as String? ?? '',
        department: json['year_level'] as String? ?? '',
        points:     (json['points'] as int?) ?? 0,
        avatarUrl:  json['avatar_url'] as String?,
      );
}