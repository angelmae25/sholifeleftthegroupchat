// FILE PATH: lib/views/edit_profile_view.dart
//
// Opens when student taps the pen/edit button on the profile page.
// Editable fields: avatar, contact/phone, course, year level
// Read-only fields: full name, student ID, email (shown but not editable)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/controllers.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class EditProfileView extends StatefulWidget {
  final UserModel user;
  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey      = GlobalKey<FormState>();
  final _contactCtrl  = TextEditingController();
  final _courseCtrl   = TextEditingController();

  String? _selectedYearLevel;
  File?   _imageFile;
  String? _base64Avatar;
  bool    _isSubmitting = false;

  static const _yearLevels = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with current values
    _contactCtrl.text      = widget.user.phone ?? '';
    _courseCtrl.text       = widget.user.course;
    _selectedYearLevel     = _yearLevels.contains(widget.user.yearLevel)
        ? widget.user.yearLevel
        : '1st Year';
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  // ── Avatar picker ───────────────────────────────────────────────────────────
  Future<void> _pickAvatar(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source:       source,
      maxWidth:     400,
      maxHeight:    400,
      imageQuality: 60,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageFile   = File(picked.path);
      _base64Avatar = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  void _showAvatarSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text('Change Profile Photo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppTheme.primary),
            title: const Text('Choose from Gallery'),
            onTap: () => _pickAvatar(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined,
                color: AppTheme.primary),
            title: const Text('Take a Photo'),
            onTap: () => _pickAvatar(ImageSource.camera),
          ),
          if (_imageFile != null || widget.user.avatarUrl != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Photo',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _imageFile    = null;
                  _base64Avatar = '';  // empty string = remove avatar
                });
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final updated = widget.user.copyWith(
        phone:      _contactCtrl.text.trim(),
        course:     _courseCtrl.text.trim(),
        yearLevel:  _selectedYearLevel,
        avatarUrl:  _base64Avatar ?? widget.user.avatarUrl,
      );

      final ctrl = context.read<ProfileController>();
      await ctrl.updateProfile(updated);

      if (!mounted) return;

      if (ctrl.error == null) {
        // Also update AuthController so drawer/header reflects new info
        // ignore: use_build_context_synchronously
        context.read<AuthController>().refreshUser(updated);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Profile updated successfully!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      } else {
        _showError(ctrl.error!);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Avatar widget ────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    Widget avatarChild;

    if (_imageFile != null) {
      avatarChild = ClipOval(
          child: Image.file(_imageFile!,
              width: 96, height: 96, fit: BoxFit.cover));
    } else if (_base64Avatar == '') {
      // removed
      avatarChild = const CircleAvatar(
          radius: 48,
          backgroundColor: AppTheme.accentLight,
          child: Icon(Icons.person, size: 52, color: AppTheme.primaryDark));
    } else if (widget.user.avatarUrl != null &&
        widget.user.avatarUrl!.isNotEmpty) {
      final url = widget.user.avatarUrl!;
      if (url.startsWith('data:image')) {
        try {
          final bytes = base64Decode(url.split(',').last);
          avatarChild = ClipOval(
              child: Image.memory(bytes,
                  width: 96, height: 96, fit: BoxFit.cover));
        } catch (_) {
          avatarChild = _defaultAvatar();
        }
      } else {
        avatarChild = ClipOval(
            child: Image.network(url,
                width: 96, height: 96, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar()));
      }
    } else {
      avatarChild = _defaultAvatar();
    }

    return GestureDetector(
      onTap: _showAvatarSheet,
      child: Stack(children: [
        SizedBox(width: 96, height: 96, child: avatarChild),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
                color: AppTheme.accent, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  Widget _defaultAvatar() => const CircleAvatar(
      radius: 48,
      backgroundColor: AppTheme.accentLight,
      child: Icon(Icons.person, size: 52, color: AppTheme.primaryDark));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Avatar ────────────────────────────────────────────────────
              Center(child: _buildAvatar()),
              const SizedBox(height: 6),
              const Center(
                child: Text('Tap photo to change',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 24),

              // ── Read-only section ─────────────────────────────────────────
              _SectionHeader('Account Info'),
              const SizedBox(height: 10),
              _ReadOnlyField(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: widget.user.fullName),
              const SizedBox(height: 10),
              _ReadOnlyField(
                  icon: Icons.badge_outlined,
                  label: 'Student ID',
                  value: widget.user.studentId),
              const SizedBox(height: 10),
              _ReadOnlyField(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: widget.user.email),
              const SizedBox(height: 24),

              // ── Editable section ──────────────────────────────────────────
              _SectionHeader('Edit Information'),
              const SizedBox(height: 10),

              // Contact
              _FieldLabel('Contact Number'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco(
                    'e.g. +63 912 345 6789',
                    Icons.phone_outlined),
              ),
              const SizedBox(height: 16),

              // Course
              _FieldLabel('Course'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _courseCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco(
                    'e.g. BS Information Technology',
                    Icons.school_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Course is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Year Level
              _FieldLabel('Year Level'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.inputBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedYearLevel,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppTheme.textSecondary),
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14),
                    items: _yearLevels.map((y) => DropdownMenuItem(
                      value: y,
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Text(y),
                      ]),
                    )).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedYearLevel = v),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
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
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(
                    _isSubmitting ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _SectionHeader(String text) => Text(text,
    style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppTheme.primary,
        letterSpacing: 0.3));

Widget _FieldLabel(String text) => Text(text,
    style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary));

class _ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _ReadOnlyField(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSecondary),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ]),
      const Spacer(),
      const Icon(Icons.lock_outline, size: 14, color: AppTheme.textSecondary),
    ]),
  );
}

InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
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
      borderSide:
      const BorderSide(color: AppTheme.primary, width: 2)),
  hintStyle: const TextStyle(
      color: AppTheme.textSecondary, fontSize: 13),
);