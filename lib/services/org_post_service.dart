// FILE PATH: lib/services/org_post_service.dart
//
// ⚠️  Update _springBootBase with your PC's current WiFi IP.
//    Run `ipconfig` on Windows → IPv4 Address under your WiFi adapter.
//    Keep port 8080 (Spring Boot).

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Change IP here to match your PC's WiFi IP ────────────────────────────────
const String _springBootBase = 'http://192.168.1.26:8080/api/org-post';

// ── Model: OrgAssignment ──────────────────────────────────────────────────────
class OrgAssignment {
  final int    assignmentId;
  final int    organizationId;
  final String organizationName;
  final String acronym;
  final String roleName;

  const OrgAssignment({
    required this.assignmentId,
    required this.organizationId,
    required this.organizationName,
    required this.acronym,
    required this.roleName,
  });

  factory OrgAssignment.fromJson(Map<String, dynamic> j) => OrgAssignment(
    assignmentId:     (j['assignmentId']    as num).toInt(),
    organizationId:   (j['organizationId']  as num).toInt(),
    organizationName: j['organizationName'] as String,
    acronym:          j['acronym']          as String? ?? '',
    roleName:         j['roleName']         as String,
  );
}

// ── OrgPostService ────────────────────────────────────────────────────────────
class OrgPostService {
  OrgPostService._();
  static final OrgPostService instance = OrgPostService._();

  // No JWT needed — Spring Boot SecurityConfig has /api/** as permitAll()
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Future<List<OrgAssignment>> fetchMyOrganizations(String studentId) async {
    try {
      final res = await http.get(
        Uri.parse('$_springBootBase/my-organizations?studentId=$studentId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        return list.map(OrgAssignment.fromJson).toList();
      }
      throw Exception('Server returned ${res.statusCode}');
    } catch (e) {
      throw Exception(
          'Cannot connect to Spring Boot. '
              'Check: 1) Spring Boot is running  '
              '2) IP ${ _springBootBase} is correct  '
              '3) Phone and PC are on same WiFi. '
              'Details: $e'
      );
    }
  }

  Future<void> postNews({
    required String studentId,
    required int    organizationId,
    required String title,
    required String body,
    required String category,
    bool isFeatured = false,
  }) async {
    final res = await http.post(
      Uri.parse('$_springBootBase/news'),
      headers: _headers,
      body: jsonEncode({
        'studentId':      studentId,
        'organizationId': organizationId,
        'title':          title,
        'body':           body,
        'category':       category,
        'isFeatured':     isFeatured,
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to post news.');
    }
  }

  Future<void> postEvent({
    required String studentId,
    required int    organizationId,
    required String shortName,
    required String fullName,
    required String date,
    required String venue,
    required String category,
    required String description,
    String color = '#8B1A1A',
  }) async {
    final res = await http.post(
      Uri.parse('$_springBootBase/events'),
      headers: _headers,
      body: jsonEncode({
        'studentId':      studentId,
        'organizationId': organizationId,
        'shortName':      shortName,
        'fullName':       fullName,
        'date':           date,
        'venue':          venue,
        'category':       category,
        'description':    description,
        'color':          color,
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to post event.');
    }
  }
}