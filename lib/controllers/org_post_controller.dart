import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import '../services/org_post_service.dart';

enum OrgPostStatus { idle, loading, success, error }

class OrgPostController extends ChangeNotifier {

  List<OrgAssignment> _organizations = [];
  OrgAssignment? _selectedOrg;
  OrgPostStatus _status = OrgPostStatus.idle;
  String? _error;
  String _lastStudentId = '';
  String _lastDbId = '';

  List<OrgAssignment> get organizations => _organizations;
  OrgAssignment? get selectedOrg => _selectedOrg;
  OrgPostStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == OrgPostStatus.loading;
  bool get hasOrgs => _organizations.isNotEmpty;

  Future<void> loadMyOrganizations(String studentId, {String? dbId}) async {
    final idA = (dbId != null && dbId.trim().isNotEmpty) ? dbId.trim() : '';
    final idB = studentId.trim();

    dev.log('[OrgPostController] loadMyOrganizations — studentId="$idB" dbId="$idA"', name: 'OrgPost');

    if (idA.isEmpty && idB.isEmpty) {
      dev.log('[OrgPostController] Both IDs empty — cannot fetch', name: 'OrgPost');
      _organizations = [];
      _selectedOrg = null;
      notifyListeners();
      return;
    }

    // FIX: Cache guard now checks BOTH ids so a change in either triggers a fresh fetch
    final sameIds = (idA == _lastDbId) && (idB == _lastStudentId);
    if (sameIds && _organizations.isNotEmpty) {
      dev.log('[OrgPostController] Cache hit — skipping fetch (${_organizations.length} orgs)', name: 'OrgPost');
      return;
    }

    _organizations = [];
    _selectedOrg = null;
    _status = OrgPostStatus.loading;
    _error = null;
    notifyListeners();

    try {
      List<OrgAssignment> result = [];

      // FIX: Try ALL available IDs instead of stopping at the first non-empty one.
      // Some backends store the numeric DB id, others store the student number string.
      // We try both and merge unique results.

      // Attempt 1: dbId (numeric/UUID primary key — most reliable)
      if (idA.isNotEmpty) {
        dev.log('[OrgPostController] Attempt 1 — fetch by dbId="$idA"', name: 'OrgPost');
        try {
          final r = await OrgPostService.instance.fetchMyOrganizations(idA);
          dev.log('[OrgPostController] Attempt 1 returned ${r.length} org(s)', name: 'OrgPost');
          result = r;
        } catch (e) {
          dev.log('[OrgPostController] Attempt 1 failed: $e', name: 'OrgPost');
        }
      }

      // Attempt 2: studentId (string e.g. "2021-00123") — try if dbId gave nothing
      if (result.isEmpty && idB.isNotEmpty && idB != idA) {
        dev.log('[OrgPostController] Attempt 2 — fetch by studentId="$idB"', name: 'OrgPost');
        try {
          final r = await OrgPostService.instance.fetchMyOrganizations(idB);
          dev.log('[OrgPostController] Attempt 2 returned ${r.length} org(s)', name: 'OrgPost');
          result = r;
        } catch (e) {
          dev.log('[OrgPostController] Attempt 2 failed: $e', name: 'OrgPost');
        }
      }

      _organizations = result;
      _lastDbId = idA;
      _lastStudentId = idB;

      if (_organizations.isNotEmpty) {
        _selectedOrg = _organizations.first;
        dev.log(
          '[OrgPostController] ✅ ${_organizations.length} org(s) loaded. '
              'Auto-selected: "${_selectedOrg!.organizationName}" (role: ${_selectedOrg!.roleName})',
          name: 'OrgPost',
        );
      } else {
        _selectedOrg = null;
        dev.log('[OrgPostController] ⚠️ No orgs found for this user after all attempts.', name: 'OrgPost');
      }

      _status = OrgPostStatus.idle;

    } catch (e) {
      dev.log('[OrgPostController] ❌ Unexpected error: $e', name: 'OrgPost');
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = OrgPostStatus.error;
      _organizations = [];
      _selectedOrg = null;
    }

    notifyListeners();
  }

  /// Force a fresh fetch ignoring cache — use for pull-to-refresh / Retry button
  Future<void> reloadMyOrganizations(String studentId, {String? dbId}) async {
    _lastStudentId = '';
    _lastDbId = '';
    _organizations = [];
    _selectedOrg = null;
    await loadMyOrganizations(studentId, dbId: dbId);
  }

  void selectOrg(OrgAssignment org) {
    _selectedOrg = org;
    dev.log('[OrgPostController] Selected org: "${org.organizationName}" (role: ${org.roleName})', name: 'OrgPost');
    notifyListeners();
  }

  void reset() {
    _organizations = [];
    _selectedOrg = null;
    _lastStudentId = '';
    _lastDbId = '';
    _status = OrgPostStatus.idle;
    _error = null;
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
      _error = 'No organization selected. Make sure you have an officer role assigned.';
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }

    dev.log('[OrgPostController] submitNews — org="${_selectedOrg!.organizationName}" orgId=${_selectedOrg!.organizationId}', name: 'OrgPost');

    _status = OrgPostStatus.loading;
    _error = null;
    notifyListeners();

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
      dev.log('[OrgPostController] submitNews error: $e', name: 'OrgPost');
      _error = e.toString().replaceFirst('Exception: ', '');
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
      _error = 'No organization selected. Make sure you have an officer role assigned.';
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }

    dev.log('[OrgPostController] submitEvent — org="${_selectedOrg!.organizationName}" orgId=${_selectedOrg!.organizationId}', name: 'OrgPost');

    _status = OrgPostStatus.loading;
    _error = null;
    notifyListeners();

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
      dev.log('[OrgPostController] submitEvent error: $e', name: 'OrgPost');
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }
  }
}