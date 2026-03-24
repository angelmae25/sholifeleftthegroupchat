// FILE PATH: lib/views/create_post_view.dart
//
// Opened via FAB in NewsView or EventsView.
// Only visible to students with an org role assignment.
// initialTab: 'news' | 'event'

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/org_post_controller.dart';
import '../services/org_post_service.dart';
import '../theme/app_theme.dart';

class CreatePostView extends StatefulWidget {
  final String initialTab; // 'news' or 'event'
  const CreatePostView({super.key, this.initialTab = 'news'});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── News fields ──────────────────────────────────────────────────────────
  final _newsTitleCtrl = TextEditingController();
  final _newsBodyCtrl  = TextEditingController();
  String _newsCategory  = 'campus';
  bool   _isFeatured    = false;

  // ── Event fields ─────────────────────────────────────────────────────────
  final _shortNameCtrl  = TextEditingController();
  final _fullNameCtrl   = TextEditingController();
  final _venueCtrl      = TextEditingController();
  final _descCtrl       = TextEditingController();
  String   _eventCategory = 'General';
  DateTime? _eventDate;
  String   _eventColor    = '#8B1A1A';

  bool _isSubmitting = false;

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
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'event' ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _newsTitleCtrl.dispose();
    _newsBodyCtrl.dispose();
    _shortNameCtrl.dispose();
    _fullNameCtrl.dispose();
    _venueCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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

  // ── Submit News ───────────────────────────────────────────────────────────
  Future<void> _submitNews() async {
    final title = _newsTitleCtrl.text.trim();
    final body  = _newsBodyCtrl.text.trim();

    if (title.isEmpty) { _showError('Title is required.'); return; }
    if (body.isEmpty)  { _showError('Content is required.'); return; }
    if (_selectedOrg == null) {
      _showError('No organization selected.'); return;
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

  // ── Submit Event ──────────────────────────────────────────────────────────
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
      _showError('No organization selected.'); return;
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

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<OrgPostController>(
      builder: (_, orgCtrl, __) {
        final orgs = orgCtrl.organizations;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            title: const Text('Create Post',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.accentLight,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(icon: Icon(Icons.newspaper_outlined), text: 'News'),
                Tab(icon: Icon(Icons.event_outlined),     text: 'Event'),
              ],
            ),
          ),
          body: Column(children: [
            // ── Org selector banner ──────────────────────────────────────
            if (orgs.length > 1)
              Container(
                color: AppTheme.primary.withOpacity(0.06),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.verified_outlined,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Posting as:',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OrgAssignment>(
                        value: orgCtrl.selectedOrg,
                        isDense: true,
                        items: orgs.map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(
                            '${o.roleName} · ${o.acronym.isNotEmpty ? o.acronym : o.organizationName}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary),
                          ),
                        )).toList(),
                        onChanged: (o) {
                          if (o != null) orgCtrl.selectOrg(o);
                        },
                      ),
                    ),
                  ),
                ]),
              )
            else if (orgs.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: AppTheme.primary.withOpacity(0.06),
                child: Row(children: [
                  const Icon(Icons.verified_outlined,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Posting as ${orgs.first.roleName} · '
                        '${orgs.first.acronym.isNotEmpty ? orgs.first.acronym : orgs.first.organizationName}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),

            // ── Tab content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _NewsForm(),
                  _EventForm(),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEWS FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _NewsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Title
        _label('Title *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newsTitleCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: _deco('Enter news headline'),
          maxLength: 255,
        ),
        const SizedBox(height: 16),

        // Body
        _label('Content *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newsBodyCtrl,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: _deco('Write the full news article...'),
        ),
        const SizedBox(height: 16),

        // Category
        _label('Category'),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? AppTheme.primary : AppTheme.divider),
                ),
                child: Text(
                  cat[0].toUpperCase() + cat.substring(1),
                  style: TextStyle(
                    color: sel ? Colors.white : AppTheme.textSecondary,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.inputBorder),
          ),
          child: Row(children: [
            const Icon(Icons.star_outline,
                color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feature this article',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('Shows as a highlighted card at the top',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
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

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.newspaper_outlined, size: 20),
            label: Text(
              _isSubmitting ? 'Posting...' : 'Publish News Article',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EVENT FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _EventForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Short name
        _label('Short Name / Acronym *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _shortNameCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: _deco('e.g. BASD, TECH, SPORTS'),
          maxLength: 20,
        ),
        const SizedBox(height: 16),

        // Full name
        _label('Full Event Name *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: _deco('e.g. Brigada ng Agham at Sining Dula'),
        ),
        const SizedBox(height: 16),

        // Date
        _label('Event Date *'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.inputBorder),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                _eventDate != null
                    ? DateFormat('MMMM d, yyyy').format(_eventDate!)
                    : 'Select event date',
                style: TextStyle(
                    color: _eventDate != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 14),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Venue
        _label('Venue *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _venueCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: _deco('e.g. Main Campus Gym'),
        ),
        const SizedBox(height: 16),

        // Category
        _label('Category'),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? AppTheme.primary : AppTheme.divider),
                ),
                child: Text(cat,
                    style: TextStyle(
                      color: sel
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Description
        _label('Description'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: _deco('Describe the event for students...'),
        ),
        const SizedBox(height: 16),

        // Color picker
        _label('Event Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: _colorOptions.map((opt) {
            final sel = _eventColor == opt.hex;
            final color = Color(
                int.parse('FF${opt.hex.replaceAll('#', '')}', radix: 16));
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
                      ? [BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8)]
                      : [],
                ),
                child: sel
                    ? const Icon(Icons.check,
                    color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.event_outlined, size: 20),
            label: Text(
              _isSubmitting ? 'Posting...' : 'Publish Event',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.inputBorder)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.inputBorder)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    hintStyle: const TextStyle(
        color: AppTheme.textSecondary, fontSize: 13),
  );
}

// ── Color option data class ────────────────────────────────────────────────
class _ColorOpt {
  final String hex, label;
  const _ColorOpt(this.hex, this.label);
}