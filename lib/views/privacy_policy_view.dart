// FILE PATH: lib/views/privacy_policy_view.dart

import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  static const _sections = [
    _PpSection(
      title: 'Information We Collect',
      paragraphs: [
        'When you register for Scholife, we collect personal information such as your full name, '
            'student ID, email address, course, year level, and department. This information is '
            'necessary to create and manage your account.',
        'We may also collect information you voluntarily provide when using features of the app, '
            'such as profile photos, contact numbers, marketplace listings, lost and found reports, '
            'and messages sent through the chat feature.',
      ],
    ),
    _PpSection(
      title: 'How We Use Your Information',
      paragraphs: [
        'The information we collect is used to provide, maintain, and improve the Scholife app. '
            'This includes authenticating your identity, displaying your profile, enabling '
            'communication between students, and personalizing your experience.',
        'We may use your email address to send important notifications related to your account '
            'or app updates. We will not send unsolicited marketing emails without your consent.',
        'Your student information may be used to verify eligibility for certain features, such '
            'as organization posting privileges for assigned student officers.',
      ],
    ),
    _PpSection(
      title: 'Data Sharing',
      paragraphs: [
        'We do not sell, trade, or rent your personal information to third parties. Your data '
            'is only accessible to authorized personnel involved in the operation and maintenance '
            'of the Scholife platform.',
        'Certain information you post publicly within the app — such as marketplace listings, '
            'lost and found reports, news articles, and club activity — will be visible to other '
            'registered students of the same institution.',
      ],
    ),
    _PpSection(
      title: 'Data Storage & Security',
      paragraphs: [
        'Your data is stored on secured servers. We implement appropriate technical and '
            'organizational measures to protect your personal information against unauthorized '
            'access, alteration, disclosure, or destruction.',
        'Passwords are stored using industry-standard hashing algorithms and are never stored '
            'in plain text. Authentication is handled via JSON Web Tokens (JWT) with expiration '
            'policies to limit unauthorized access.',
        'While we strive to protect your personal information, no method of transmission over '
            'the internet or method of electronic storage is 100% secure. We cannot guarantee '
            'absolute security.',
      ],
    ),
    _PpSection(
      title: 'Your Rights',
      paragraphs: [
        'You have the right to access, update, or delete your personal information at any time '
            'through the Profile and Settings sections of the app. You may update your contact '
            'number, course, year level, and profile photo directly from your profile page.',
        'If you wish to permanently delete your account and all associated data, please contact '
            'your institution\'s system administrator or reach out through the Report a Problem '
            'feature in Settings.',
      ],
    ),
    _PpSection(
      title: 'Cookies & Local Storage',
      paragraphs: [
        'Scholife uses local device storage (SharedPreferences) to save your session tokens and '
            'app preferences such as dark mode and notification settings. This data is stored '
            'only on your device and is not transmitted to our servers.',
        'No third-party tracking cookies or advertising trackers are used within the app.',
      ],
    ),
    _PpSection(
      title: 'Children\'s Privacy',
      paragraphs: [
        'Scholife is intended for use by enrolled college students. We do not knowingly collect '
            'personal information from individuals under the age of 13. If you believe a minor '
            'has provided us with personal information, please contact us immediately so we can '
            'take appropriate action.',
      ],
    ),
    _PpSection(
      title: 'Changes to This Policy',
      paragraphs: [
        'We reserve the right to update this Privacy Policy at any time. When we do, we will '
            'revise the updated date at the bottom of this page. We encourage you to periodically '
            'review this page to stay informed about how we are protecting your information.',
        'Your continued use of the Scholife app after any changes to this Privacy Policy '
            'constitutes your acceptance of such changes.',
      ],
    ),
    _PpSection(
      title: 'Contact Us',
      paragraphs: [
        'If you have any questions, concerns, or requests regarding this Privacy Policy or the '
            'handling of your personal data, please reach out through the "Report a Problem" '
            'feature found in the Settings section of the app.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2);
    final bodyText = isDark ? Colors.white70 : const Color(0xFF4A4A4A);
    final headingText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Effective date banner ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Effective Date: January 1, 2025',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // ── Intro blurb ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1A1A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF8B1A1A).withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: Color(0xFF8B1A1A), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your privacy matters to us. This policy explains how Scholife '
                          'collects, uses, and protects your personal information.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF5D0000),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sections card ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.map((section) {
                  return _SectionWidget(
                    section: section,
                    headingColor: headingText,
                    bodyColor: bodyText,
                    isLast: section == _sections.last,
                  );
                }).toList(),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Last updated: March 2025',
                style: TextStyle(
                  color: isDark ? Colors.white30 : Colors.grey[400],
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _PpSection {
  final String title;
  final List<String> paragraphs;
  const _PpSection({required this.title, required this.paragraphs});
}

// ── Section widget ─────────────────────────────────────────────────────────────
class _SectionWidget extends StatelessWidget {
  final _PpSection section;
  final Color headingColor;
  final Color bodyColor;
  final bool isLast;

  const _SectionWidget({
    required this.section,
    required this.headingColor,
    required this.bodyColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        ...section.paragraphs.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            p,
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: bodyColor,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        )),
        if (!isLast) ...[
          const SizedBox(height: 4),
          Divider(color: Colors.grey.withOpacity(0.25), thickness: 1),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}