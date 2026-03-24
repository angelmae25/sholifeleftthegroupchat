// =============================================================================
// lib/models/user_model.dart
// =============================================================================

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String studentId;
  final String course;
  final String yearLevel;
  final String department;
  final String? phone;
  final int points;
  final int rank;
  final int clubCount;
  final int postCount;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.course,
    required this.yearLevel,
    required this.department,
    this.phone,
    this.points = 0,
    this.rank = 0,
    this.clubCount = 0,
    this.postCount = 0,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:         json['id']?.toString() ?? '',
    fullName:   json['full_name']   as String? ?? '',
    email:      json['email']       as String? ?? '',
    studentId:  json['student_id']  as String? ?? '',
    course:     json['course']      as String? ?? '',
    yearLevel:  json['year_level']  as String? ?? '',
    department: json['department']  as String? ?? '',
    phone:      json['contact']     as String? ?? json['phone'] as String?,
    points:     (json['points']     as int?) ?? 0,
    rank:       (json['rank']       as int?) ?? 0,
    clubCount:  (json['club_count'] as int?) ?? 0,
    postCount:  (json['post_count'] as int?) ?? 0,
    avatarUrl:  json['avatar_url']  as String?,
  );

  Map<String, dynamic> toJson() => {
    'id':         id,
    'full_name':  fullName,
    'email':      email,
    'student_id': studentId,
    'course':     course,
    'year_level': yearLevel,
    'department': department,
    'phone':      phone,
    'points':     points,
    'rank':       rank,
    'club_count': clubCount,
    'post_count': postCount,
    'avatar_url': avatarUrl,
  };

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? course,
    String? yearLevel,
    String? department,
    int? points,
    int? rank,
    int? clubCount,
    int? postCount,
    String? avatarUrl,
  }) => UserModel(
    id:         id,
    fullName:   fullName   ?? this.fullName,
    email:      email      ?? this.email,
    studentId:  studentId,
    course:     course     ?? this.course,
    yearLevel:  yearLevel  ?? this.yearLevel,
    department: department ?? this.department,
    phone:      phone      ?? this.phone,
    points:     points     ?? this.points,
    rank:       rank       ?? this.rank,
    clubCount:  clubCount  ?? this.clubCount,
    postCount:  postCount  ?? this.postCount,
    avatarUrl:  avatarUrl  ?? this.avatarUrl,
  );

  static UserModel get mock => const UserModel(
    id:         'user_001',
    fullName:   'Juan dela Cruz',
    email:      '',
    studentId:  '2021-00123',
    course:     'BS Computer Science',
    yearLevel:  '3rd Year',
    department: 'College of Information Technology',
    phone:      '+63 912 345 6789',
    points:     3750,
    rank:       12,
    clubCount:  3,
    postCount:  28,
  );
}