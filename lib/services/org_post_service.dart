import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // adjust import path to match your project

const String _flaskBase = 'http://192.168.1.11:5000/api/mobile';

dynamic _safeJson(http.Response res) {
  final ct = res.headers['content-type'] ?? '';
  if (!ct.contains('application/json')) {
    final preview = res.body.length > 150 ? res.body.substring(0, 150) + '…' : res.body;
    throw Exception('Server returned non-JSON (HTTP ${res.statusCode}).\nPreview: $preview');
  }
  return jsonDecode(res.body);
}

class OrgAssignment {
  final int assignmentId;
  final int organizationId;
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
    assignmentId:     (j['assignmentId']   as num).toInt(),
    organizationId:   (j['organizationId'] as num).toInt(),
    organizationName: j['organizationName'] ?? '',
    acronym:          j['acronym']          ?? '',
    roleName:         j['roleName']         ?? '',
  );
}

class OrgPostService {
  OrgPostService._();

  static final OrgPostService instance = OrgPostService._();

  // FIX: always fetch the JWT token and include it in every request
  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<OrgAssignment>> fetchMyOrganizations(String studentId) async {
    if (studentId
        .trim()
        .isEmpty) {
      dev.log('[OrgPostService] Empty studentId — aborting', name: 'OrgPost');
      return [];
    }

    final url = '$_flaskBase/my-organizations?studentId=${studentId.trim()}';
    dev.log('[OrgPostService] GET $url', name: 'OrgPost');

    try {
      final response = await http
          .get(Uri.parse(url), headers: await _authHeaders)
          .timeout(const Duration(seconds: 15));

      dev.log(
          '[OrgPostService] Response ${response.statusCode}: ${response.body}',
          name: 'OrgPost');

      if (response.statusCode == 200) {
        final decoded = _safeJson(response);
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          data = decoded['data'] as List<dynamic>;
        } else {
          return [];
        }
        return data.map((e) =>
            OrgAssignment.fromJson(e as Map<String, dynamic>)).toList();
      }

      dev.log('[OrgPostService] Server error ${response.statusCode}: ${response
          .body}', name: 'OrgPost');
      throw Exception('Server error ${response.statusCode}: ${response.body}');
    } catch (e) {
      dev.log('[OrgPostService] Exception: $e', name: 'OrgPost');
      throw Exception('Cannot connect to server.\nError: $e');
    }
  }

  Future<bool> canStudentPost(String studentId) async =>
      (await fetchMyOrganizations(studentId)).isNotEmpty;

  Future<void> postNews({
    required String studentId,
    required int organizationId,
    required String title,
    required String body,
    required String category,
    bool isFeatured = false,
  }) async {
    final response = await http.post(
      Uri.parse('$_flaskBase/news/'),
      headers: await _authHeaders,
      body: jsonEncode({
        'student_id':      studentId,       // ← was 'studentId'
        'organization_id': organizationId,  // ← was 'organizationId'
        'title':           title,
        'body':            body,
        'category':        category,
        'is_featured':     isFeatured,      // ← was 'isFeatured'
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to post news: ${response.body}');
    }
  }

  Future<void> postEvent({
    required String studentId,
    required int organizationId,
    required String shortName,
    required String fullName,
    required String date,
    required String venue,
    required String category,
    required String description,
    String color = '#8B1A1A',
  }) async {
    final response = await http.post(
      Uri.parse('$_flaskBase/events/'),
      headers: await _authHeaders,
      body: jsonEncode({
        'student_id': studentId, // ← was 'studentId'
        'organization_id': organizationId, // ← was 'organizationId'
        'short_name': shortName, // ← was 'shortName'
        'full_name': fullName, // ← was 'fullName'
        'date': date,
        'venue': venue,
        'category': category,
        'description': description,
        'color': color,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to post event: ${response.body}');
    }
  }
}