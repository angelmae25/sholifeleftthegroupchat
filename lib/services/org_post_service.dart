import 'dart:convert';
import 'package:http/http.dart' as http;

// IMPORTANT: must match your PC IPv4
const String _springBootBase = 'http://192.168.1.11:8080/api/org-post';

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
    final url = '$_springBootBase/my-organizations?studentId=$studentId';

    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => OrgAssignment.fromJson(e)).toList();
      }

      throw Exception("Server error ${response.statusCode}: ${response.body}");
    } catch (e) {
      throw Exception(
        "Cannot connect to Spring Boot.\n\n"
            "Check:\n"
            "1️⃣ Spring Boot running\n"
            "2️⃣ Correct IP ($_springBootBase)\n"
            "3️⃣ Same WiFi network\n\n"
            "Error: $e",
      );
    }
  }

  // ─────────────────────────────────────────────
  // CHECK IF STUDENT CAN POST
  // (Used to show + button)
  // ─────────────────────────────────────────────
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
    final url = '$_springBootBase/news';

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
    final url = '$_springBootBase/events';

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