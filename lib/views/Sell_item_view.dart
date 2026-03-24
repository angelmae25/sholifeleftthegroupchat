// FILE PATH: lib/views/sell_item_view.dart
//
// Full-screen form for posting a marketplace item.
// Image is picked from gallery/camera, converted to base64,
// and sent to Flask → stored as base64 string in the DB.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/controllers.dart';
import '../theme/app_theme.dart';

class SellItemView extends StatefulWidget {
  const SellItemView({super.key});

  @override
  State<SellItemView> createState() => _SellItemViewState();
}

class _SellItemViewState extends State<SellItemView> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _priceCtrl   = TextEditingController();

  String  _condition    = 'Good condition';
  File?   _imageFile;
  String? _base64Image;
  bool    _isSubmitting = false;

  static const _conditions = [
    'Brand new',
    'Like new',
    'Good condition',
    'Fair condition',
    'For parts',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Pick image from gallery or camera ────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth:  480,
      maxHeight: 480,
      imageQuality: 40,
    );
    if (picked == null) return;
    final bytes  = await picked.readAsBytes();
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
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
            title: const Text('Choose from Gallery'),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
            title: const Text('Take a Photo'),
            onTap: () => _pickImage(ImageSource.camera),
          ),
          if (_imageFile != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
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

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ctrl = context.read<MarketplaceController>();

      // Warn if image is still suspiciously large after compression
      if (_base64Image != null && _base64Image!.length > 3000000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Image is too large. Please pick a smaller photo.'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ));
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final ok   = await ctrl.createItem(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        condition:   _condition,
        price:       double.tryParse(_priceCtrl.text.trim()) ?? 0,
        base64Image: _base64Image,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Item posted successfully!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(ctrl.error ?? 'Failed to post item.',
                style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Sell an Item',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Image picker ───────────────────────────────────────────────
            _SectionLabel('Item Photo'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _imageFile != null
                          ? AppTheme.primary
                          : AppTheme.inputBorder,
                      width: _imageFile != null ? 2 : 1),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)],
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
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_outlined,
                          size: 30, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tap to add a photo',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Gallery or Camera',
                        style: TextStyle(
                            color: AppTheme.textSecondary
                                .withOpacity(0.7),
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.edit, size: 14, color: AppTheme.primary),
                  label: const Text('Change photo',
                      style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Item name ──────────────────────────────────────────────────
            _SectionLabel('Item Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco('e.g. Calculus Textbook 7th Edition'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ────────────────────────────────────────────────
            _SectionLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco('Describe your item — brand, size, included accessories...'),
            ),
            const SizedBox(height: 16),

            // ── Condition ──────────────────────────────────────────────────
            _SectionLabel('Condition *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _conditions.map((c) {
                final selected = _condition == c;
                return GestureDetector(
                  onTap: () => setState(() => _condition = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.divider),
                    ),
                    child: Text(c,
                        style: TextStyle(
                          color: selected
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

            // ── Price ──────────────────────────────────────────────────────
            _SectionLabel('Price (₱) *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco('e.g. 150.00'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Submit button ──────────────────────────────────────────────
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
                    : const Icon(Icons.storefront_outlined, size: 20),
                label: Text(
                  _isSubmitting ? 'Posting...' : 'Post Item for Sale',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Widget _SectionLabel(String text) => Text(text,
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