import 'dart:convert';
import 'dart:developer' as dev; // ← for debug logging
import 'package:http/http.dart' as http;

// IMPORTANT: must match your PC IPv4
const String _flaskBase = 'http://192.168.1.11:5000/api/mobile';

dynamic _safeJson(http.Response res) {
  final ct = res.headers['content-type'] ?? '';
  if (!ct.contains('application/json')) {
    final preview = res.body.length > 150 ? res.body.substring(0, 150) + '…' : res.body;
    throw Exception(
      'Server returned non-JSON (HTTP ${res.statusCode}).\n'
          'Flask may be down or unreachable.\n'
          'Preview: $preview',
    );
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

  factory OrgAssignment.fromJson(Map<String, dynamic> j) {
    return OrgAssignment(
      assignmentId: (j['assignmentId'] as num).toInt(),
      organizationId: (j['organizationId'] as num).toInt(),
      organizationName: j['organizationName'] ?? '',
      acronym: j['acronym'] ?? '',
      roleName: j['roleName'] ?? '',
    );
  }
}

class OrgPostService {
  OrgPostService._();
  static final OrgPostService instance = OrgPostService._();

  static const Map<String, String> _headers = {
    "Content-Type": "application/json"
  };

  // ─────────────────────────────────────────────
  // FETCH ORGANIZATIONS WHERE STUDENT HAS ROLE
  // ─────────────────────────────────────────────
  Future<List<OrgAssignment>> fetchMyOrganizations(String studentId) async {
    // FIX 1: Guard against empty ID before even hitting the network
    if (studentId.trim().isEmpty) {
      dev.log('[OrgPostService] fetchMyOrganizations called with EMPTY studentId — aborting', name: 'OrgPost');
      return [];
    }

    final url = '$_flaskBase/my-organizations?studentId=${studentId.trim()}';
    dev.log('[OrgPostService] GET $url', name: 'OrgPost'); // ← see this in your IDE console

    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      dev.log('[OrgPostService] Response ${response.statusCode}: ${response.body}', name: 'OrgPost');

      if (response.statusCode == 200) {
        final dynamic decoded = _safeJson(response);

        // FIX 2: Handle both array response AND wrapped { "data": [...] } response
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          data = decoded['data'] as List<dynamic>;
        } else {
          dev.log('[OrgPostService] Unexpected response shape: $decoded', name: 'OrgPost');
          return [];
        }

        final result = data.map((e) => OrgAssignment.fromJson(e as Map<String, dynamic>)).toList();
        dev.log('[OrgPostService] Parsed ${result.length} org(s): ${result.map((o) => o.organizationName).toList()}', name: 'OrgPost');
        return result;
      }

      // FIX 3: Log the actual server error body so you know what went wrong
      dev.log('[OrgPostService] Server error ${response.statusCode}: ${response.body}', name: 'OrgPost');
      throw Exception("Server error ${response.statusCode}: ${response.body}");

    } catch (e) {
      dev.log('[OrgPostService] Exception: $e', name: 'OrgPost');
      throw Exception(
        "Cannot connect to Spring Boot.\n\n"
            "Check:\n"
            "1️⃣ Spring Boot running\n"
            "2️⃣ Correct IP ($_flaskBase)\n"
            "3️⃣ Same WiFi network\n\n"
            "Error: $e",
      );
    }
  }

  Future<bool> canStudentPost(String studentId) async {
    final orgs = await fetchMyOrganizations(studentId);
    return orgs.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  // POST NEWS
  // ─────────────────────────────────────────────
  Future<void> postNews({
    required String studentId,
    required int organizationId,
    required String title,
    required String body,
    required String category,
    bool isFeatured = false,
  }) async {
    final url = '$_flaskBase/news';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({
        "studentId": studentId,
        "organizationId": organizationId,
        "title": title,
        "body": body,
        "category": category,
        "isFeatured": isFeatured
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to post news: ${response.body}");
    }
  }

  // ─────────────────────────────────────────────
  // POST EVENT
  // ─────────────────────────────────────────────
  Future<void> postEvent({
    required String studentId,
    required int organizationId,
    required String shortName,
    required String fullName,
    required String date,
    required String venue,
    required String category,
    required String description,
    String color = "#8B1A1A",
  }) async {
    final url = '$_flaskBase/events';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({
        "studentId": studentId,
        "organizationId": organizationId,
        "shortName": shortName,
        "fullName": fullName,
        "date": date,
        "venue": venue,
        "category": category,
        "description": description,
        "color": color
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to post event: ${response.body}");
    }
  }
}