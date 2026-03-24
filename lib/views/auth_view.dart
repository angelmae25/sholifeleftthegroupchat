// =============================================================================
// VIEW: auth_view.dart  (Sign In + Create Account)
// Full-screen grid background — no gaps, no white areas.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SIGN IN VIEW
// ─────────────────────────────────────────────────────────────────────────────
class SignInView extends StatefulWidget {
  const SignInView({super.key});
  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final ok = await context.read<AuthController>().signIn(
      _emailCtrl.text.trim(), _passCtrl.text,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D0000),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF3D0000)),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.30)),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      MediaQuery.of(context).padding.top + 24,
                      28,
                      MediaQuery.of(context).padding.bottom + 32,
                    ),
                    child: Consumer<AuthController>(
                      builder: (_, ctrl, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/splash_logo.png',
                              height: 120,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.menu_book, size: 80, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 32),

                          const Text('Sign In',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 30,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Text('Welcome back! Please sign in to continue.',
                              style: TextStyle(
                                  color: AppTheme.textOnDarkMuted, fontSize: 13)),
                          const SizedBox(height: 28),

                          if (ctrl.errorMessage != null) ...[
                            _ErrorBanner(ctrl.errorMessage!),
                            const SizedBox(height: 16),
                          ],

                          _FieldLabel('Email Address'),
                          const SizedBox(height: 8),
                          _GlassField(
                            controller: _emailCtrl,
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),

                          _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          _GlassField(
                            controller: _passCtrl,
                            hint: 'Enter your password',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            toggleObscure: () => setState(() => _obscure = !_obscure),
                          ),

                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Forgot Password?',
                                      style: TextStyle(
                                          color: AppTheme.accentLight, fontSize: 13,
                                          fontWeight: FontWeight.w500)))),
                          const SizedBox(height: 8),

                          _PrimaryButton(
                            label: 'Sign In',
                            isLoading: ctrl.isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 28),

                          _OrDivider(),
                          const SizedBox(height: 28),

                          _OutlineButton(
                            label: 'Create Account',
                            onPressed: () => context.go('/create-account'),
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// CREATE ACCOUNT VIEW
// ─────────────────────────────────────────────────────────────────────────────
class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});
  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final _nameCtrl         = TextEditingController();
  final _idCtrl           = TextEditingController();
  final _emailCtrl        = TextEditingController();
  final _passCtrl         = TextEditingController();
  final _confCtrl         = TextEditingController();
  final _customCourseCtrl = TextEditingController();

  bool _obscure = true, _obscureConf = true;

  // ── Dropdown selections ────────────────────────────────────────────────────
  String? _selectedDepartment;
  String? _selectedCourse;
  String? _selectedYearLevel;
  bool    _isCustomCourse = false;

  // ── Department → Courses map ───────────────────────────────────────────────
  static const Map<String, List<String>> _departmentCourses = {
    'Basic Arts and Sciences Department': [
      'Bachelor of Science in Information Technology',
      'Other',
    ],
    'Electrical and Allied Department': [
      'Bachelor of Science in Electronics Engineering',
      'Bachelor of Science in Electrical Engineering',
      'Other',
    ],
    'Civil and Allied Department': [
      'Other',
    ],
    'Mechanical and Allied Department': [
      'Other',
    ],
  };

  static const List<String> _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  List<String> get _courses =>
      _selectedDepartment != null ? _departmentCourses[_selectedDepartment!] ?? [] : [];

  @override
  void dispose() {
    _nameCtrl.dispose(); _idCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    _customCourseCtrl.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (_passCtrl.text != _confCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.red));
      return;
    }
    final courseValue = _isCustomCourse
        ? _customCourseCtrl.text.trim()
        : _selectedCourse;

    if (_selectedDepartment == null || courseValue == null || courseValue.isEmpty || _selectedYearLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill in all fields'),
              backgroundColor: Colors.red));
      return;
    }
    final ok = await context.read<AuthController>().register(
      fullName:   _nameCtrl.text.trim(),
      studentId:  _idCtrl.text.trim(),
      email:      _emailCtrl.text.trim(),
      password:   _passCtrl.text,
      course:     courseValue,
      yearLevel:  _selectedYearLevel!,
      department: _selectedDepartment!,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D0000),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF3D0000)),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.30)),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      MediaQuery.of(context).padding.top + 16,
                      28,
                      MediaQuery.of(context).padding.bottom + 32,
                    ),
                    child: Consumer<AuthController>(
                      builder: (_, ctrl, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 20),
                            onPressed: () => context.go('/sign-in'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(height: 12),

                          // Logo
                          Center(
                            child: Image.asset(
                              'assets/images/splash_logo.png',
                              height: 100,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.menu_book, size: 60, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text('Create Account',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 28,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Text('Join the Scholife community today!',
                              style: TextStyle(
                                  color: AppTheme.textOnDarkMuted, fontSize: 13)),
                          const SizedBox(height: 24),

                          // Error
                          if (ctrl.errorMessage != null) ...[
                            _ErrorBanner(ctrl.errorMessage!),
                            const SizedBox(height: 16),
                          ],

                          // Full Name
                          _FieldLabel('Full Name'),
                          const SizedBox(height: 8),
                          _GlassField(
                              controller: _nameCtrl,
                              hint: 'Enter your full name',
                              icon: Icons.person_outline),
                          const SizedBox(height: 16),

                          // Student ID
                          _FieldLabel('Student ID'),
                          const SizedBox(height: 8),
                          _GlassField(
                              controller: _idCtrl,
                              hint: 'Enter your student ID',
                              icon: Icons.badge_outlined),
                          const SizedBox(height: 16),

                          // Email
                          _FieldLabel('Email'),
                          const SizedBox(height: 8),
                          _GlassField(
                              controller: _emailCtrl,
                              hint: 'Enter your school email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),

                          // Department
                          _FieldLabel('Department'),
                          const SizedBox(height: 8),
                          _GlassDropdown(
                            hint: 'Select your department',
                            icon: Icons.account_balance_outlined,
                            value: _selectedDepartment,
                            items: _departmentCourses.keys.toList(),
                            onChanged: (val) => setState(() {
                              _selectedDepartment = val;
                              _selectedCourse = null;
                              _isCustomCourse = false;
                              _customCourseCtrl.clear();
                            }),
                          ),
                          const SizedBox(height: 16),

                          // Course
                          _FieldLabel('Course'),
                          const SizedBox(height: 8),
                          _GlassDropdown(
                            hint: _selectedDepartment == null
                                ? 'Select department first'
                                : 'Select your course',
                            icon: Icons.school_outlined,
                            value: _isCustomCourse ? 'Other' : _selectedCourse,
                            items: _courses,
                            onChanged: _courses.isEmpty
                                ? null
                                : (val) => setState(() {
                              if (val == 'Other') {
                                _isCustomCourse = true;
                                _selectedCourse = 'Other';
                              } else {
                                _isCustomCourse = false;
                                _selectedCourse = val;
                                _customCourseCtrl.clear();
                              }
                            }),
                          ),
                          // "Other" → show text field to type custom course
                          if (_isCustomCourse) ...[
                            const SizedBox(height: 10),
                            _GlassField(
                              controller: _customCourseCtrl,
                              hint: 'Type your course name',
                              icon: Icons.edit_outlined,
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Year Level
                          _FieldLabel('Year Level'),
                          const SizedBox(height: 8),
                          _GlassDropdown(
                            hint: 'Select your year level',
                            icon: Icons.calendar_today_outlined,
                            value: _selectedYearLevel,
                            items: _yearLevels,
                            onChanged: (val) => setState(() => _selectedYearLevel = val),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          _GlassField(
                              controller: _passCtrl,
                              hint: 'Create a password',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              toggleObscure: () => setState(() => _obscure = !_obscure)),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _FieldLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          _GlassField(
                              controller: _confCtrl,
                              hint: 'Confirm your password',
                              icon: Icons.lock_outline,
                              obscure: _obscureConf,
                              toggleObscure: () => setState(() => _obscureConf = !_obscureConf)),
                          const SizedBox(height: 28),

                          _PrimaryButton(
                            label: 'Create Account',
                            isLoading: ctrl.isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 24),

                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/sign-in'),
                              child: const Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                        color: AppTheme.textOnDarkMuted, fontSize: 13)),
                                TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                        color: AppTheme.accentLight,
                                        fontWeight: FontWeight.w700, fontSize: 13)),
                              ])),
                            ),
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppTheme.textOnDarkMuted, fontSize: 13, fontWeight: FontWeight.w500));
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool? obscure;
  final VoidCallback? toggleObscure;
  final TextInputType? keyboardType;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure,
    this.toggleObscure,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure ?? false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.55), size: 20),
          suffixIcon: toggleObscure != null
              ? IconButton(
              icon: Icon(
                  obscure! ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.45), size: 20),
              onPressed: toggleObscure)
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

// ── Glass-styled Dropdown ─────────────────────────────────────────────────────
class _GlassDropdown extends StatelessWidget {
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const _GlassDropdown({
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF5A0000),
          hint: Row(children: [
            Icon(icon, color: Colors.white.withOpacity(0.55), size: 20),
            const SizedBox(width: 10),
            Text(hint, style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13)),
          ]),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.55)),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
          selectedItemBuilder: (context) => items.map((item) => Row(children: [
            Icon(icon, color: Colors.white.withOpacity(0.55), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
          ])).toList(),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: AppTheme.primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(height: 20, width: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryDark))
          : Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _OutlineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.40)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: onPressed,
      child: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: Colors.white.withOpacity(0.20))),
    Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('or', style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13))),
    Expanded(child: Divider(color: Colors.white.withOpacity(0.20))),
  ]);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
    ]),
  );
}