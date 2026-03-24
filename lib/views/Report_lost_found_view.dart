// FILE PATH: lib/views/report_lost_found_view.dart
//
// Opened via FAB in LostFoundView.
// Pass status: 'lost' or 'found' to pre-select the type.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/controllers.dart';
import '../theme/app_theme.dart';

class ReportLostFoundView extends StatefulWidget {
  final String initialStatus; // 'lost' or 'found'
  const ReportLostFoundView({super.key, this.initialStatus = 'lost'});

  @override
  State<ReportLostFoundView> createState() => _ReportLostFoundViewState();
}

class _ReportLostFoundViewState extends State<ReportLostFoundView> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _locCtrl    = TextEditingController();

  late String _status;
  DateTime?   _selectedDate;
  File?       _imageFile;
  String?     _base64Image;
  bool        _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth:  480,
      maxHeight: 480,
      imageQuality: 40,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageFile   = File(picked.path);
      _base64Image = base64Encode(bytes);
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppTheme.primary),
            title: const Text('Choose from Gallery'),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined,
                color: AppTheme.primary),
            title: const Text('Take a Photo'),
            onTap: () => _pickImage(ImageSource.camera),
          ),
          if (_imageFile != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Photo',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() { _imageFile = null; _base64Image = null; });
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Date picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Submit ───────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select the date.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ctrl = context.read<LostFoundController>();
      final ok   = await ctrl.reportItem(
        title:       _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location:    _locCtrl.text.trim(),
        date:        DateFormat('yyyy-MM-dd').format(_selectedDate!),
        status:      _status,
        base64Image: _base64Image,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text('Item reported as ${_status.toUpperCase()} successfully!',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      } else {
        _showError(ctrl.error ?? 'Failed to submit report.');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _status == 'lost';
    final statusColor = isLost
        ? const Color(0xFFB71C1C)
        : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          isLost ? 'Report Lost Item' : 'Report Found Item',
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Status toggle ──────────────────────────────────────────────
              _SLabel('Report Type *'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.inputBorder)),
                child: Row(children: [
                  _StatusBtn('Lost',  'lost',  _status,
                      const Color(0xFFB71C1C),
                          (v) => setState(() => _status = v)),
                  _StatusBtn('Found', 'found', _status,
                      const Color(0xFF2E7D32),
                          (v) => setState(() => _status = v)),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Photo ──────────────────────────────────────────────────────
              _SLabel('Photo (Optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _imageFile != null
                            ? statusColor
                            : AppTheme.inputBorder,
                        width: _imageFile != null ? 2 : 1),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            shape: BoxShape.circle),
                        child: Icon(Icons.add_a_photo_outlined,
                            size: 28, color: statusColor),
                      ),
                      const SizedBox(height: 10),
                      Text('Tap to add a photo',
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Optional — helps identify the item',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
              if (_imageFile != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: Icon(Icons.edit, size: 13, color: statusColor),
                    label: Text('Change photo',
                        style: TextStyle(
                            color: statusColor, fontSize: 12)),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Title ──────────────────────────────────────────────────────
              _SLabel('Item Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco('e.g. Black Wallet, ID Card, Umbrella'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Item name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Description ────────────────────────────────────────────────
              _SLabel('Description *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDeco(
                    'Describe the item — color, brand, markings...'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Location ───────────────────────────────────────────────────
              _SLabel('Location *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco(
                    isLost
                        ? 'Where did you last see it?'
                        : 'Where did you find it?'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Date ───────────────────────────────────────────────────────
              _SLabel(isLost ? 'Date Lost *' : 'Date Found *'),
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
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: statusColor),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate != null
                          ? DateFormat('MMMM d, yyyy')
                          .format(_selectedDate!)
                          : 'Select a date',
                      style: TextStyle(
                          color: _selectedDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontSize: 14),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ─────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
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
                      : Icon(isLost
                      ? Icons.search_outlined
                      : Icons.check_circle_outline,
                      size: 20),
                  label: Text(
                    _isSubmitting
                        ? 'Submitting...'
                        : isLost
                        ? 'Submit Lost Report'
                        : 'Submit Found Report',
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

// ── Status toggle button ───────────────────────────────────────────────────────
class _StatusBtn extends StatelessWidget {
  final String label, value, current;
  final Color  color;
  final ValueChanged<String> onTap;
  const _StatusBtn(this.label, this.value, this.current,
      this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Widget _SLabel(String text) => Text(text,
    style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary));

InputDecoration _inputDeco(String hint) => InputDecoration(
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
      borderSide:
      const BorderSide(color: AppTheme.primary, width: 2)),
  hintStyle: const TextStyle(
      color: AppTheme.textSecondary, fontSize: 13),
);