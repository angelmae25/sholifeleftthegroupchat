import 'package:flutter/foundation.dart';
import '../services/org_post_service.dart';

enum OrgPostStatus { idle, loading, success, error }

class OrgPostController extends ChangeNotifier {

  List<OrgAssignment> _organizations = [];
  OrgAssignment? _selectedOrg;
  OrgPostStatus _status = OrgPostStatus.idle;
  String? _error;
  String _lastStudentId = '';

  List<OrgAssignment> get organizations => _organizations;
  OrgAssignment? get selectedOrg => _selectedOrg;
  OrgPostStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == OrgPostStatus.loading;

  /// if student has organization role
  bool get hasOrgs => _organizations.isNotEmpty;

  Future<void> loadMyOrganizations(String studentId, {String? dbId}) async {

    final idToUse =
    (dbId != null && dbId.isNotEmpty) ? dbId : studentId;

    if (idToUse.isEmpty) {
      _organizations = [];
      notifyListeners();
      return;
    }

    if (idToUse == _lastStudentId && _organizations.isNotEmpty) {
      return;
    }

    if (idToUse != _lastStudentId) {
      _organizations = [];
      _selectedOrg = null;
    }

    _status = OrgPostStatus.loading;
    _error = null;
    notifyListeners();

    try {

      List<OrgAssignment> result =
      await OrgPostService.instance.fetchMyOrganizations(idToUse);

      if (result.isEmpty &&
          dbId != null &&
          dbId.isNotEmpty &&
          dbId != studentId) {

        result =
        await OrgPostService.instance.fetchMyOrganizations(studentId);
      }

      _organizations = result;
      _lastStudentId = idToUse;

      /// IMPORTANT: AUTO SELECT FIRST ORG
      if (_organizations.isNotEmpty) {
        _selectedOrg = _organizations.first;
      } else {
        _selectedOrg = null;
      }

      _status = OrgPostStatus.idle;

    } catch (e) {

      _error = e.toString().replaceFirst('Exception: ', '');
      _status = OrgPostStatus.error;
      _organizations = [];
      _selectedOrg = null;
    }

    notifyListeners();
  }

  Future<void> reloadMyOrganizations(String studentId, {String? dbId}) async {

    _lastStudentId = '';
    _organizations = [];
    _selectedOrg = null;

    await loadMyOrganizations(studentId, dbId: dbId);
  }

  void reset() {
    _organizations = [];
    _selectedOrg = null;
    _lastStudentId = '';
    _status = OrgPostStatus.idle;
    _error = null;
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
      _error = 'No organization selected.';
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }

    _status = OrgPostStatus.loading;
    _error = null;
    notifyListeners();

    try {

      await OrgPostService.instance.postNews(
        studentId: studentId,
        organizationId: _selectedOrg!.organizationId,
        title: title,
        body: body,
        category: category,
        isFeatured: isFeatured,
      );

      _status = OrgPostStatus.success;
      notifyListeners();
      return true;

    } catch (e) {

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
      _error = 'No organization selected.';
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }

    _status = OrgPostStatus.loading;
    _error = null;
    notifyListeners();

    try {

      await OrgPostService.instance.postEvent(
        studentId: studentId,
        organizationId: _selectedOrg!.organizationId,
        shortName: shortName,
        fullName: fullName,
        date: date,
        venue: venue,
        category: category,
        description: description,
        color: color,
      );

      _status = OrgPostStatus.success;
      notifyListeners();
      return true;

    } catch (e) {

      _error = e.toString().replaceFirst('Exception: ', '');
      _status = OrgPostStatus.error;
      notifyListeners();
      return false;
    }
  }
}