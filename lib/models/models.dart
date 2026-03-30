// =============================================================================
// UPDATED: lib/models/models.dart
// Added ClubModel.fromApi() and EventModel.fromJson() for live API data.
// Everything else is unchanged from your original.
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

  // ── NEW: parses response from Flask API ───────────────────────────────────
  factory EventModel.fromJson(Map<String, dynamic> json) {
    // color arrives as hex string '#8B1A1A'
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
// MARKETPLACE ITEM MODEL  (unchanged)
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

  static List<MarketplaceItemModel> get mockList => [
    MarketplaceItemModel(id: 'm1', name: 'Calculus Textbook',     condition: 'Good condition', price: 150, sellerId: 'u2', sellerName: 'Maria S.', postedAt: DateTime.now().subtract(const Duration(hours: 3))),
    MarketplaceItemModel(id: 'm2', name: 'Scientific Calculator', condition: 'Slightly used',  price: 250, sellerId: 'u3', sellerName: 'Jose R.',  postedAt: DateTime.now().subtract(const Duration(hours: 6))),
    MarketplaceItemModel(id: 'm3', name: 'Lab Coat (Size M)',      condition: 'Lightly worn',   price: 80,  sellerId: 'u4', sellerName: 'Ana D.',   postedAt: DateTime.now().subtract(const Duration(days: 1))),
    MarketplaceItemModel(id: 'm4', name: 'Nursing Complete Kit',   condition: 'Complete set',   price: 500, sellerId: 'u5', sellerName: 'Pedro G.', postedAt: DateTime.now().subtract(const Duration(days: 2))),
    MarketplaceItemModel(id: 'm5', name: 'Pastel Art Supplies',    condition: 'Barely used',    price: 200, sellerId: 'u6', sellerName: 'Lisa C.',  postedAt: DateTime.now().subtract(const Duration(days: 3))),
    MarketplaceItemModel(id: 'm6', name: 'Foldable Laptop Stand',  condition: 'Like new',       price: 120, sellerId: 'u7', sellerName: 'Mark T.',  postedAt: DateTime.now().subtract(const Duration(days: 4))),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// LOST & FOUND MODEL  (unchanged)
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

  static List<LostFoundModel> get mockList => [
    LostFoundModel(id: 'lf1', title: 'Black Wallet',          description: 'Lost near the library on March 10.',    location: 'Library Area',      date: DateTime(2024, 3, 10), status: LostFoundStatus.lost,  reporterId: 'u1'),
    LostFoundModel(id: 'lf2', title: 'Scientific Calculator', description: 'Casio FX-991. Lost in Engineering 204.', location: 'Engineering Bldg',  date: DateTime(2024, 3, 11), status: LostFoundStatus.lost,  reporterId: 'u2'),
    LostFoundModel(id: 'lf3', title: 'USB Flash Drive',       description: '16GB Kingston. Contains thesis files.',  location: 'Computer Lab',      date: DateTime(2024, 3, 12), status: LostFoundStatus.lost,  reporterId: 'u3'),
    LostFoundModel(id: 'lf4', title: 'Red Umbrella',          description: 'Found outside the cafeteria.',           location: 'Cafeteria',         date: DateTime(2024, 3, 11), status: LostFoundStatus.found, reporterId: 'u4'),
    LostFoundModel(id: 'lf5', title: 'Student ID (Maria S.)', description: 'Found on 2nd floor hallway.',            location: '2nd Floor Hallway', date: DateTime(2024, 3, 12), status: LostFoundStatus.found, reporterId: 'u5'),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MODEL  (unchanged)
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

  // ✅ ADDED (THIS FIXES YOUR ERROR)
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

  static List<ChatModel> get mockList => [
    ChatModel(id: 'c1', name: 'Maria Santos', lastMessage: 'Thanks for the notes!', lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)), unreadCount: 3),
  ];

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

  // ✅ ADDED (THIS FIXES YOUR ERROR)
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

  static List<ChatMessageModel> get mockMessages => [
    ChatMessageModel(id: 'msg1', text: 'Hello', senderId: 'other', sentAt: DateTime.now(), isMine: false),
  ];

  String get timeLabel {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m ${sentAt.hour < 12 ? 'AM' : 'PM'}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLUB MODEL  — now supports fromApi() for live organization data
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

  // ── NEW: build from Flask /clubs/ response ────────────────────────────────
  factory ClubModel.fromJson(Map<String, dynamic> json) => ClubModel(
    id:         json['id']?.toString() ?? '',
    name:       json['name'] as String? ?? '',
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
// LEADERBOARD ENTRY MODEL  (unchanged)
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

  static List<LeaderboardEntryModel> get mockList => [
    const LeaderboardEntryModel(rank: 1, userId: 'u2', name: 'Maria Santos',  department: '3rd Year CS',          points: 4850),
    const LeaderboardEntryModel(rank: 2, userId: 'u3', name: 'Jose Reyes',    department: '4th Year Engineering', points: 4200),
    const LeaderboardEntryModel(rank: 3, userId: 'u4', name: 'Ana Dela Cruz', department: '2nd Year Nursing',     points: 3980),
    const LeaderboardEntryModel(rank: 4, userId: 'u5', name: 'Pedro Garcia',  department: '3rd Year Education',   points: 3500),
    const LeaderboardEntryModel(rank: 5, userId: 'u6', name: 'Lisa Cruz',     department: '1st Year Architecture',points: 3200),
    const LeaderboardEntryModel(rank: 6, userId: 'u7', name: 'Mark Tan',      department: '4th Year Commerce',    points: 2980),
  ];


}