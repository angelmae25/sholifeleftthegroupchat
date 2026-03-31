// lib/models/user_model.dart
//
// FIXES:
//  1. fromJson reads 'phone' key (Flask now returns 'phone' instead of 'contact')
//  2. fromJson reads 'full_name' (Flask builds this from first_name + last_name)
//  3. copyWith preserves all existing fields when a value is not passed

class UserModel {
  final String  id;
  final String  fullName;
  final String  email;
  final String  studentId;
  final String  course;
  final String  yearLevel;
  final String  department;
  final String? phone;       // DB column: contact
  final String? avatarUrl;
  final int     points;
  final int     rank;
  final int     clubCount;
  final int     postCount;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.course,
    required this.yearLevel,
    required this.department,
    this.phone,
    this.avatarUrl,
    this.points    = 0,
    this.rank      = 0,
    this.clubCount = 0,
    this.postCount = 0,
  });

  // ── Deserialize from Flask JSON response ────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Flask returns 'full_name' (built from first_name + last_name on server)
    final fullName = json['full_name'] as String? ?? '';

    return UserModel(
      id:         json['id']?.toString()         ?? '',
      fullName:   fullName,
      email:      json['email']      as String?  ?? '',
      studentId:  json['student_id'] as String?  ?? '',
      course:     json['course']     as String?  ?? '',
      yearLevel:  json['year_level'] as String?  ?? '',
      department: json['department'] as String?  ?? '',
      phone:      json['phone']      as String?,   // ← 'phone' key from Flask
      avatarUrl:  json['avatar_url'] as String?,
      points:     (json['points']    as num?)?.toInt() ?? 0,
      rank:       (json['rank']      as num?)?.toInt() ?? 0,
      clubCount:  (json['club_count']as num?)?.toInt() ?? 0,
      postCount:  (json['post_count']as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'full_name':  fullName,
    'email':      email,
    'student_id': studentId,
    'course':     course,
    'year_level': yearLevel,
    'department': department,
    'phone':      phone,
    'avatar_url': avatarUrl,
    'points':     points,
    'rank':       rank,
    'club_count': clubCount,
    'post_count': postCount,
  };

  // ── Copy with updated fields ─────────────────────────────────────────────────
  UserModel copyWith({
    String?  id,
    String?  fullName,
    String?  email,
    String?  studentId,
    String?  course,
    String?  yearLevel,
    String?  department,
    String?  phone,
    String?  avatarUrl,
    int?     points,
    int?     rank,
    int?     clubCount,
    int?     postCount,
  }) => UserModel(
    id:         id         ?? this.id,
    fullName:   fullName   ?? this.fullName,
    email:      email      ?? this.email,
    studentId:  studentId  ?? this.studentId,
    course:     course     ?? this.course,
    yearLevel:  yearLevel  ?? this.yearLevel,
    department: department ?? this.department,
    phone:      phone      ?? this.phone,
    avatarUrl:  avatarUrl  ?? this.avatarUrl,
    points:     points     ?? this.points,
    rank:       rank       ?? this.rank,
    clubCount:  clubCount  ?? this.clubCount,
    postCount:  postCount  ?? this.postCount,
  );
}