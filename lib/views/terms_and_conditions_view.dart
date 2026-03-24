// FILE PATH: lib/views/terms_and_conditions_view.dart

import 'package:flutter/material.dart';

class TermsAndConditionsView extends StatelessWidget {
  const TermsAndConditionsView({super.key});

  static const _accentBlue = Color(0xFF2979FF);

  static const _sections = [
    _TcSection(
      title: 'General Conditions',
      paragraphs: [
        'We reserve the right to refuse service to anyone, at any time, for any reason. '
            'We reserve the right to make any modifications to the website, including terminating, '
            'changing, suspending or discontinuing any aspect of the website at any time, without notice. '
            'We may impose additional rules or limits on the use of our website. You agree to review '
            'the Terms regularly and your continued access or use of our website will mean that you '
            'agree to any changes.',
        'You agree that we will not be liable to you or any third party for any modification, '
            'suspension or discontinuance of our website or for any service, content, feature or '
            'product offered through our website.',
      ],
    ),
    _TcSection(
      title: 'Products or Services',
      paragraphs: [
        'All purchases through our app are subject to product availability. We may, in our sole '
            'discretion, limit or cancel the quantities offered on our app or limit the sales of our '
            'products or services to any person, household, geographic region or jurisdiction.',
        'Prices for our products are subject to change, without notice. Unless otherwise indicated, '
            'prices displayed on our app are quoted in Philippine Peso.',
        'We reserve the right, in our sole discretion, to refuse orders, including without limitation, '
            'orders that appear to be placed by distributors or resellers. If we believe that you have '
            'made a false or fraudulent order, we will be entitled to cancel the order and inform the '
            'relevant authorities.',
        'We do not guarantee the accuracy of the colour or design of the products on our app. '
            'We have made efforts to ensure the colour and design of our products are displayed as '
            'accurately as possible on our website.',
      ],
    ),
    _TcSection(
      title: 'Accuracy of Information',
      paragraphs: [
        'We occasionally may present information on our app that contains typographical errors, '
            'inaccuracies or omissions that may relate to product descriptions, pricing, promotions, '
            'offers and availability. We reserve the right to correct any errors, inaccuracies or '
            'omissions and to change or update information at any time, without prior notice.',
      ],
    ),
    _TcSection(
      title: 'Third-Party Links',
      paragraphs: [
        'Certain content available via our app may include links to other websites. We are not '
            'responsible for examining or evaluating the content or accuracy of third-party websites '
            'and do not warrant and will not have any liability or responsibility for any third-party '
            'materials or services.',
        'We are not liable for any harm or damages related to the purchase or use of goods, '
            'services, resources, content, or any other transactions made in connection with any '
            'third-party websites.',
      ],
    ),
    _TcSection(
      title: 'User Comments & Feedback',
      paragraphs: [
        'If you send certain submissions or post content on our app, you grant us a non-exclusive, '
            'royalty-free, perpetual, irrevocable and fully sub-licensable right to use, reproduce, '
            'modify, adapt, publish, translate and distribute such content.',
        'You agree that your comments will not violate any right of any third-party, including '
            'copyright, trademark, privacy, personality or other personal or proprietary right. '
            'You further agree that your comments will not contain libelous or otherwise unlawful, '
            'abusive or obscene material.',
      ],
    ),
    _TcSection(
      title: 'Personal Information',
      paragraphs: [
        'Your submission of personal information through the app is governed by our Privacy Policy. '
            'Please review our Privacy Policy, which is incorporated into these Terms and Conditions '
            'by this reference.',
      ],
    ),
    _TcSection(
      title: 'Changes to Terms',
      paragraphs: [
        'We reserve the right, at our sole discretion, to update, change or replace any part of '
            'these Terms and Conditions by posting updates and changes to our app. It is your '
            'responsibility to check our app periodically for changes. Your continued use of or '
            'access to our app following the posting of any changes constitutes acceptance of '
            'those changes.',
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
          'Terms and Condition',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Container(
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
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _TcSection {
  final String title;
  final List<String> paragraphs;
  const _TcSection({required this.title, required this.paragraphs});
}

// ── Section widget ─────────────────────────────────────────────────────────────
class _SectionWidget extends StatelessWidget {
  final _TcSection section;
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
        // ── Section title ──────────────────────────────────────────────────
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

        // ── Paragraphs ─────────────────────────────────────────────────────
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

        // ── Divider between sections ───────────────────────────────────────
        if (!isLast) ...[
          const SizedBox(height: 4),
          Divider(color: Colors.grey.withOpacity(0.25), thickness: 1),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}