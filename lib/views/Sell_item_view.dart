// FILE PATH: lib/views/sell_item_view.dart

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
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();

  String   _condition    = 'Good condition';
  File?    _imageFile;
  String?  _base64Image;
  bool     _isSubmitting = false;

  static const _conditions = [
    'Brand new', 'Like new', 'Good condition', 'Fair condition', 'For parts',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Image helpers ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source, maxWidth: 800, maxHeight: 800, imageQuality: 75,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final mimeType = picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    setState(() {
      _imageFile   = File(picked.path);
      _base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';
    });
  }

  void _showImageSourceSheet() {
    final isDark = AppTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: isDark ? AppTheme.fbDarkInput : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
            title: Text('Choose from Gallery',
                style: TextStyle(color: AppTheme.textMain(context))),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
            title: Text('Take a Photo',
                style: TextStyle(color: AppTheme.textMain(context))),
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

  /// Opens a full-screen image viewer when the posted photo is tapped.
  void _openImagePreview() {
    if (_imageFile == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenImageView(file: _imageFile!),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ctrl = context.read<MarketplaceController>();

      // Check raw base64 size (strip the data URI prefix for size calculation)
      final rawBase64 = _base64Image != null && _base64Image!.contains(',')
          ? _base64Image!.split(',').last
          : _base64Image;

      if (rawBase64 != null && rawBase64.length > 3000000) {
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

      final ok = await ctrl.createItem(
        name:          _nameCtrl.text.trim(),
        description:   _descCtrl.text.trim(),
        condition:     _condition,
        price:         double.tryParse(_priceCtrl.text.trim()) ?? 0,
        base64Image:   _base64Image,
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
        _showError(ctrl.error ?? 'Failed to post item.');
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pageBg    = AppTheme.pageColor(context);
    final inputFill = AppTheme.inputFill(context);
    final borderClr = AppTheme.borderCol(context);
    final textMain  = AppTheme.textMain(context);
    final textSub   = AppTheme.textSub(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Post Pre-Loved Item',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Item Photo ─────────────────────────────────────────────────
            _SectionLabel('Item Photo', textMain),
            const SizedBox(height: 8),

            if (_imageFile != null) ...[
              // ── Posted photo (tappable → full-screen) ───────────────────
              GestureDetector(
                onTap: _openImagePreview,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Subtle "tap to expand" badge
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.zoom_out_map_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Tap to expand',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ),
                    // Primary border overlay
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.6),
                                width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            ] else ...[
              // ── Empty picker placeholder ─────────────────────────────────
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderClr),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: Column(
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
                          style: TextStyle(color: textSub, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Item Name ──────────────────────────────────────────────────
            _SectionLabel('Item Name *', textMain),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: textMain),
              decoration: _inputDeco('e.g. Calculus Textbook 7th Edition',
                  inputFill, borderClr, textSub),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Description (now required) ─────────────────────────────────
            _SectionLabel('Description *', textMain),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: textMain),
              decoration: _inputDeco(
                  'Describe your item — brand, size, included accessories...',
                  inputFill, borderClr, textSub),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Condition ──────────────────────────────────────────────────
            _SectionLabel('Condition *', textMain),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : inputFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? AppTheme.primary : borderClr),
                    ),
                    child: Text(c,
                        style: TextStyle(
                          color: selected ? Colors.white : textSub,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Price ──────────────────────────────────────────────────────
            _SectionLabel('Price (₱) *', textMain),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textMain),
              decoration: _inputDeco('e.g. 150.00', inputFill, borderClr, textSub),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────────────
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
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.storefront_outlined, size: 20),
                label: Text(
                  _isSubmitting ? 'Posting...' : 'Post Pre-Loved Item',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

// ── Full-screen image viewer ───────────────────────────────────────────────────
class _FullScreenImageView extends StatelessWidget {
  final File file;
  const _FullScreenImageView({required this.file});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Dim background
            const SizedBox.expand(
              child: ColoredBox(color: Colors.black87),
            ),
            // Pinch-to-zoom image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            // Close button
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────
Widget _SectionLabel(String text, Color color) => Text(text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color));

InputDecoration _inputDeco(
    String hint, Color fill, Color border, Color hintClr) =>
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