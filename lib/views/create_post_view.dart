// FILE PATH: lib/views/create_post_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/org_post_controller.dart';
import '../services/org_post_service.dart';
import '../theme/app_theme.dart';

class CreatePostView extends StatefulWidget {
  final String initialTab;
  const CreatePostView({super.key, this.initialTab = 'news'});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {

  final _newsTitleCtrl = TextEditingController();
  final _newsBodyCtrl  = TextEditingController();
  String _newsCategory = 'campus';
  bool   _isFeatured   = false;

  final _shortNameCtrl = TextEditingController();
  final _fullNameCtrl  = TextEditingController();
  final _venueCtrl     = TextEditingController();
  final _descCtrl      = TextEditingController();
  String    _eventCategory = 'General';
  DateTime? _eventDate;
  String    _eventColor    = '#8B1A1A';

  bool _isSubmitting = false;

  bool get _isNewsMode => widget.initialTab == 'news';

  static const _newsCategories  = ['all', 'health', 'academic', 'campus', 'sports'];
  static const _eventCategories = ['General', 'Academic', 'Cultural', 'Sports', 'Service'];
  static const _colorOptions    = [
    _ColorOpt('#8B1A1A', 'Crimson'),
    _ColorOpt('#1565C0', 'Blue'),
    _ColorOpt('#2E7D32', 'Green'),
    _ColorOpt('#6A1B9A', 'Purple'),
    _ColorOpt('#E65100', 'Orange'),
    _ColorOpt('#37474F', 'Slate'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().user;
      if (user != null) {
        context.read<OrgPostController>().loadMyOrganizations(
          user.studentId,
          dbId: user.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _newsTitleCtrl.dispose();
    _newsBodyCtrl.dispose();
    _shortNameCtrl.dispose();
    _fullNameCtrl.dispose();
    _venueCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String get _studentId =>
      context.read<AuthController>().user?.studentId ?? '';

  OrgAssignment? get _selectedOrg =>
      context.read<OrgPostController>().selectedOrg;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _submitNews() async {
    final title = _newsTitleCtrl.text.trim();
    final body  = _newsBodyCtrl.text.trim();

    if (title.isEmpty) { _showError('Title is required.'); return; }
    if (body.isEmpty)  { _showError('Content is required.'); return; }
    if (_selectedOrg == null) {
      _showError('No organization selected. Make sure you have an officer role assigned.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ok = await context.read<OrgPostController>().submitNews(
        studentId:  _studentId,
        title:      title,
        body:       body,
        category:   _newsCategory,
        isFeatured: _isFeatured,
      );
      if (!mounted) return;
      if (ok) {
        _showSuccess('News posted successfully!');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pop();
      } else {
        _showError(context.read<OrgPostController>().error ?? 'Failed to post.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEvent() async {
    final shortName = _shortNameCtrl.text.trim();
    final fullName  = _fullNameCtrl.text.trim();
    final venue     = _venueCtrl.text.trim();
    final desc      = _descCtrl.text.trim();

    if (shortName.isEmpty) { _showError('Short name is required.'); return; }
    if (fullName.isEmpty)  { _showError('Full name is required.'); return; }
    if (venue.isEmpty)     { _showError('Venue is required.'); return; }
    if (_eventDate == null){ _showError('Please select a date.'); return; }
    if (_selectedOrg == null) {
      _showError('No organization selected. Make sure you have an officer role assigned.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ok = await context.read<OrgPostController>().submitEvent(
        studentId:   _studentId,
        shortName:   shortName,
        fullName:    fullName,
        date:        DateFormat('yyyy-MM-dd').format(_eventDate!),
        venue:       venue,
        category:    _eventCategory,
        description: desc,
        color:       _eventColor,
      );
      if (!mounted) return;
      if (ok) {
        _showSuccess('Event posted successfully!');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pop();
      } else {
        _showError(context.read<OrgPostController>().error ?? 'Failed to post event.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final isDark = AppTheme.isDark(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(primary: AppTheme.primary)
              : const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = AppTheme.isDark(context);
    final pageBg   = AppTheme.pageColor(context);
    final textMain = AppTheme.textMain(context);

    return Consumer<OrgPostController>(
      builder: (_, orgCtrl, __) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            title: Text(
              _isNewsMode ? 'Post News Article' : 'Post Event',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: _isNewsMode
              ? _buildNewsForm(isDark, textMain, orgCtrl)
              : _buildEventForm(isDark, textMain, orgCtrl),
        );
      },
    );
  }

  // ── Organization selector widget ──────────────────────────────────────────
  Widget _buildOrgSelector(OrgPostController orgCtrl, Color textMain) {
    final borderClr = AppTheme.borderCol(context);
    final cardBg    = AppTheme.cardColor(context);
    final textSub   = AppTheme.textSub(context);

    // Still loading
    if (orgCtrl.isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderClr),
        ),
        child: const Row(children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
          SizedBox(width: 10),
          Text('Loading your organizations...', style: TextStyle(fontSize: 13)),
        ]),
      );
    }

    // No orgs found
    if (orgCtrl.organizations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No officer role found. Contact your organization admin to assign you a role.',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              final user = context.read<AuthController>().user;
              if (user != null) {
                orgCtrl.loadMyOrganizations(user.studentId, dbId: user.id);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
          ),
        ]),
      );
    }

    // Has exactly one org — show info card (no need to pick)
    if (orgCtrl.organizations.length == 1) {
      final org = orgCtrl.organizations.first;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.verified_outlined, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                org.acronym.isNotEmpty ? org.acronym : org.organizationName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary),
              ),
              Text(
                org.roleName,
                style: TextStyle(fontSize: 12, color: textSub),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
            child: const Text('Officer',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
    }

    // Has multiple orgs — show a dropdown picker
    final selectedOrg = orgCtrl.selectedOrg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectedOrg != null ? AppTheme.primary : borderClr,
          width: selectedOrg != null ? 1.5 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrgAssignment>(
          isExpanded: true,
          value: selectedOrg,
          hint: Text('Select organization to post as', style: TextStyle(fontSize: 13, color: textSub)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
          dropdownColor: cardBg,
          items: orgCtrl.organizations.map((org) {
            final label = org.acronym.isNotEmpty ? org.acronym : org.organizationName;
            return DropdownMenuItem<OrgAssignment>(
              value: org,
              child: Row(children: [
                const Icon(Icons.verified_outlined, color: AppTheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13, color: textMain)),
                      Text(org.roleName,
                          style: TextStyle(fontSize: 11, color: textSub)),
                    ],
                  ),
                ),
              ]),
            );
          }).toList(),
          onChanged: (org) {
            if (org != null) {
              context.read<OrgPostController>().selectOrg(org);
            }
          },
        ),
      ),
    );
  }

  Widget _buildNewsForm(bool isDark, Color textMain, OrgPostController orgCtrl) {
    final cardBg    = AppTheme.cardColor(context);
    final borderClr = AppTheme.borderCol(context);
    final textSub   = AppTheme.textSub(context);
    final inputFill = AppTheme.inputFill(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Organization selector ──────────────────────────────────────────
        _label('Posting as *', textMain),
        const SizedBox(height: 8),
        _buildOrgSelector(orgCtrl, textMain),
        const SizedBox(height: 20),

        _label('Title *', textMain),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newsTitleCtrl,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: textMain),
          decoration: _deco('Enter news headline', inputFill, borderClr, textSub),
          maxLength: 255,
        ),
        const SizedBox(height: 16),

        _label('Content *', textMain),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newsBodyCtrl,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: textMain),
          decoration: _deco('Write the full news article...', inputFill, borderClr, textSub),
        ),
        const SizedBox(height: 16),

        _label('Category', textMain),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _newsCategories.map((cat) {
            final sel = _newsCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _newsCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppTheme.primary : borderClr),
                ),
                child: Text(
                  cat[0].toUpperCase() + cat.substring(1),
                  style: TextStyle(
                    color: sel ? Colors.white : textSub,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Featured toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderClr),
          ),
          child: Row(children: [
            const Icon(Icons.star_outline, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feature this article',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain(context))),
                    Text('Shows as a highlighted card at the top',
                        style: TextStyle(color: AppTheme.textSub(context), fontSize: 12)),
                  ]),
            ),
            Switch(
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
              activeColor: AppTheme.primary,
            ),
          ]),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isSubmitting || orgCtrl.organizations.isEmpty) ? null : _submitNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primary.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.newspaper_outlined, size: 20),
            label: Text(
              _isSubmitting ? 'Posting...' : 'Publish News Article',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildEventForm(bool isDark, Color textMain, OrgPostController orgCtrl) {
    final borderClr = AppTheme.borderCol(context);
    final textSub   = AppTheme.textSub(context);
    final inputFill = AppTheme.inputFill(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Organization selector ──────────────────────────────────────────
        _label('Posting as *', textMain),
        const SizedBox(height: 8),
        _buildOrgSelector(orgCtrl, textMain),
        const SizedBox(height: 20),

        _label('Short Name / Acronym *', textMain),
        const SizedBox(height: 8),
        TextFormField(
          controller: _shortNameCtrl,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: textMain),
          decoration: _deco('e.g. BASD, TECH, SPORTS', inputFill, borderClr, textSub),
          maxLength: 20,
        ),
        const SizedBox(height: 16),

        _label('Full Event Name *', textMain),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameCtrl,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: textMain),
          decoration: _deco('e.g. Brigada ng Agham at Sining Dula', inputFill, borderClr, textSub),
        ),
        const SizedBox(height: 16),

        _label('Event Date *', textMain),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderClr),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                _eventDate != null
                    ? DateFormat('MMMM d, yyyy').format(_eventDate!)
                    : 'Select event date',
                style: TextStyle(
                    color: _eventDate != null ? textMain : AppTheme.textSub(context),
                    fontSize: 14),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        _label('Venue *', textMain),
        const SizedBox(height: 8),
        TextFormField(
          controller: _venueCtrl,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: textMain),
          decoration: _deco('e.g. Main Campus Gym', inputFill, borderClr, textSub),
        ),
        const SizedBox(height: 16),

        _label('Category', textMain),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _eventCategories.map((cat) {
            final sel = _eventCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _eventCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppTheme.primary : borderClr),
                ),
                child: Text(cat,
                    style: TextStyle(
                      color: sel ? Colors.white : AppTheme.textSub(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        _label('Description', textMain),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: textMain),
          decoration: _deco('Describe the event for students...', inputFill, borderClr, textSub),
        ),
        const SizedBox(height: 16),

        _label('Event Color', textMain),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: _colorOptions.map((opt) {
            final sel   = _eventColor == opt.hex;
            final color = Color(int.parse('FF${opt.hex.replaceAll('#', '')}', radix: 16));
            return GestureDetector(
              onTap: () => setState(() => _eventColor = opt.hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel ? Colors.black45 : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: sel
                      ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
                      : [],
                ),
                child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isSubmitting || orgCtrl.organizations.isEmpty) ? null : _submitEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primary.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.event_outlined, size: 20),
            label: Text(
              _isSubmitting ? 'Posting...' : 'Publish Event',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color));

  InputDecoration _deco(String hint, Color fill, Color border, Color hintClr) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        hintStyle: TextStyle(color: hintClr, fontSize: 13),
      );
}

class _ColorOpt {
  final String hex, label;
  const _ColorOpt(this.hex, this.label);
}