// =============================================================================
// FILE: lib/controllers/org_post_controller.dart
// FIXED: Tries both studentId (student number) and id (DB integer id)
// because Spring Boot may expect either format depending on implementation.
// =============================================================================

import 'package:flutter/foundation.dart';
import '../services/org_post_service.dart';

enum OrgPostStatus { idle, loading, success, error }

class OrgPostController extends ChangeNotifier {
  List<OrgAssignment> _organizations = [];
  OrgAssignment?      _selectedOrg;
  OrgPostStatus       _status        = OrgPostStatus.idle;
  String?             _error;
  String              _lastStudentId = '';

  List<OrgAssignment> get organizations => _organizations;
  OrgAssignment?      get selectedOrg   => _selectedOrg;
  OrgPostStatus       get status        => _status;
  String?             get error         => _error;
  bool                get isLoading     => _status == OrgPostStatus.loading;

  // hasOrgs = true  → student has a role in DB → show FAB to post
  // hasOrgs = false → student has no role      → hide FAB
  bool get hasOrgs => _organizations.isNotEmpty;

  /// [studentId] = the student_id number (e.g. "2021-00123")
  /// [dbId]      = the database integer id (e.g. "1", "2", "3")
  /// Spring Boot /api/org-post/my-organizations may expect either.
  /// We try dbId first (more reliable), then fall back to studentId.
  Future<void> loadMyOrganizations(String studentId, {String? dbId}) async {
    // Determine the best id to use
    final idToUse = (dbId != null && dbId.isNotEmpty) ? dbId : studentId;

    if (idToUse.isEmpty) {
      debugPrint('[OrgPost] ⚠️ Empty id — cannot check roles');
      _organizations = [];
      notifyListeners();
      return;
    }

    // Skip reload if same student already loaded
    if (idToUse == _lastStudentId && _organizations.isNotEmpty) {
      debugPrint('[OrgPost] Already loaded for $idToUse');
      return;
    }

    // Reset if switching users
    if (idToUse != _lastStudentId) {
      _organizations = [];
      _selectedOrg   = null;
    }

    debugPrint('[OrgPost] 🔄 Checking roles for id="$idToUse" studentId="$studentId"');
    _status = OrgPostStatus.loading;
    _error  = null;
    notifyListeners();

    try {
      // Try with the primary id first
      List<OrgAssignment> result = await OrgPostService.instance
          .fetchMyOrganizations(idToUse);

      // If empty and we have a different fallback id, try that too
      if (result.isEmpty && dbId != null && dbId.isNotEmpty && dbId != studentId) {
        debugPrint('[OrgPost] Primary id returned empty, trying studentId="$studentId"');
        result = await OrgPostService.instance.fetchMyOrganizations(studentId);
      }

      _organizations = result;
      _lastStudentId = idToUse;

      if (_organizations.isNotEmpty) {
        _selectedOrg = _organizations.first;
        debugPrint('[OrgPost] ✅ ${_organizations.length} role(s) found');
        for (final o in _organizations) {
          debugPrint('   → ${o.organizationName} | ${o.roleName}');
        }
      } else {
        debugPrint('[OrgPost] ℹ️ No roles found for this student');
        _selectedOrg = null;
      }

      _status = OrgPostStatus.idle;
    } catch (e) {
      debugPrint('[OrgPost] ❌ Error: $e');
      _error         = e.toString().replaceFirst('Exception: ', '');
      _status        = OrgPostStatus.error;
      _organizations = [];
      _selectedOrg   = null;
    }

    notifyListeners();
  }

  Future<void> reloadMyOrganizations(String studentId, {String? dbId}) async {
    _lastStudentId = '';
    _organizations = [];
    _selectedOrg   = null;
    await loadMyOrganizations(studentId, dbId: dbId);
  }

  void reset() {
    _organizations = [];
    _selectedOrg   = null;
    _lastStudentId = '';
    _status        = OrgPostStatus.idle;
    _error         = null;
    notifyListeners();
  }

  void selectOrg(OrgAssignment org) {
    _selectedOrg = org;
    notifyListeners();
  }

  Future<bool> submitNews({
    required String studentId,
    required String title,
    required String body,
    required String category,
    bool isFeatured = false,
  }) async {
    if (_selectedOrg == null) {
      _error  = 'No organization selected.';
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }
    _status = OrgPostStatus.loading; _error = null; notifyListeners();
    try {
      await OrgPostService.instance.postNews(
        studentId:      studentId,
        organizationId: _selectedOrg!.organizationId,
        title:          title,
        body:           body,
        category:       category,
        isFeatured:     isFeatured,
      );
      _status = OrgPostStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error  = e.toString().replaceFirst('Exception: ', '');
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitEvent({
    required String studentId,
    required String shortName,
    required String fullName,
    required String date,
    required String venue,
    required String category,
    required String description,
    String color = '#8B1A1A',
  }) async {
    if (_selectedOrg == null) {
      _error  = 'No organization selected.';
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }
    _status = OrgPostStatus.loading; _error = null; notifyListeners();
    try {
      await OrgPostService.instance.postEvent(
        studentId:      studentId,
        organizationId: _selectedOrg!.organizationId,
        shortName:      shortName,
        fullName:       fullName,
        date:           date,
        venue:          venue,
        category:       category,
        description:    description,
        color:          color,
      );
      _status = OrgPostStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error  = e.toString().replaceFirst('Exception: ', '');
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }
  }
}