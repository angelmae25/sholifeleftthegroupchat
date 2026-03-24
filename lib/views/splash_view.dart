// =============================================================================
// VIEW: splash_view.dart  &  onboarding_view.dart
// Splash matches the exact design: warm orange radial gradient background
// with the combined Scholife logo (book + wordmark) animated in the center.
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPLASH VIEW
// ─────────────────────────────────────────────────────────────────────────────
class SplashView extends StatefulWidget {
  const SplashView({super.key});
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {

  // Background pulse
  late AnimationController _bgCtrl;
  late Animation<double>    _bgScale;

  // Logo entrance
  late AnimationController _logoCtrl;
  late Animation<double>    _logoScale;
  late Animation<double>    _logoFade;
  late Animation<double>    _logoY;

  // Shimmer
  late AnimationController _shimmerCtrl;
  late Animation<double>    _shimmerAnim;

  // Loading dots
  late AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();

    // Background gentle breathe
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _bgScale  = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut));

    // Logo spring entrance
    _logoCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.35)));
    _logoY     = Tween<double>(begin: 60.0, end: 0.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    // Shimmer sweep across logo
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.0)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Pulsing dots
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Short pause, then logo bounces in
    await Future.delayed(const Duration(milliseconds: 300));
    await _logoCtrl.forward();
    // Shimmer sweep
    await Future.delayed(const Duration(milliseconds: 100));
    await _shimmerCtrl.forward();
    // Hold, then navigate
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) context.go('/onboarding');
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _shimmerCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _logoCtrl, _shimmerCtrl, _dotsCtrl]),
        builder: (_, __) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              // Deep maroon gradient — logo has transparent bg now
              gradient: RadialGradient(
                center: Alignment.center,
                radius: _bgScale.value,
                colors: const [
                  Color(0xFF3D0505), // maroon center
                  Color(0xFF6B0F0F), // deep maroon mid
                  Color(0xFF0D0000), // near-black edge
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(children: [

              // ── Soft radial highlight top-center ────────────────────────
              Positioned(
                top: -60, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFE8A000).withOpacity(0.15),
                          Colors.transparent,
                        ])),
                  ),
                ),
              ),

              // ── Main content ─────────────────────────────────────────────
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [

                  // ── Animated logo ────────────────────────────────────────
                  Transform.translate(
                    offset: Offset(0, _logoY.value),
                    child: Opacity(
                      opacity: _logoFade.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _LogoWithShimmer(shimmerValue: _shimmerAnim.value),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Pulsing dots ─────────────────────────────────────────
                  Opacity(
                    opacity: _logoFade.value.clamp(0.0, 1.0),
                    child: _PulsingDots(controller: _dotsCtrl),
                  ),
                ]),
              ),

              // ── Bottom tagline ────────────────────────────────────────────
              Positioned(
                bottom: 48, left: 0, right: 0,
                child: Opacity(
                  opacity: _logoFade.value.clamp(0.0, 1.0),
                  child: const Text(
                    'Your school, your community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ── Logo image with shimmer overlay ──────────────────────────────────────────
class _LogoWithShimmer extends StatelessWidget {
  final double shimmerValue;
  const _LogoWithShimmer({required this.shimmerValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Drop shadow behind logo
        Container(
          width: 290, height: 290,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),

        // The combined splash logo (icon + wordmark on orange bg)
        Image.asset(
          'assets/images/splash_logo.png',
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _FallbackLogo(),
        ),

        // Shimmer sweep
        if (shimmerValue > -1.0 && shimmerValue < 1.8)
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(shimmerValue * 200, -30),
                  child: Transform.rotate(
                    angle: 0.35,
                    child: Container(
                      width: 55,
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.28),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Fallback if image asset is missing ───────────────────────────────────────
class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 160, height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
              colors: [Color(0xFFFF8C00), Color(0xFF8B0000)]),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.2), blurRadius: 20)],
        ),
        child: const Icon(Icons.menu_book, size: 80, color: Colors.white),
      ),
      const SizedBox(height: 20),
      RichText(text: const TextSpan(children: [
        TextSpan(text: 'Scho', style: TextStyle(color: Color(0xFF7B1A1A), fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
        TextSpan(text: 'O',    style: TextStyle(color: Color(0xFFFFB830), fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
        TextSpan(text: 'life', style: TextStyle(color: Color(0xFF7B1A1A), fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
      ])),
    ]);
  }
}

// ── Pulsing dots ──────────────────────────────────────────────────────────────
class _PulsingDots extends StatelessWidget {
  final AnimationController controller;
  const _PulsingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase   = i * 0.33;
          final t       = ((controller.value - phase + 1.0) % 1.0);
          final opacity = math.sin(t * math.pi).clamp(0.2, 1.0);
          final size    = 7.0 + (math.sin(t * math.pi) * 3.5);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(opacity),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING VIEW
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(icon: Icons.newspaper_outlined,       title: 'Stay Informed',     sub: 'Get the latest news and announcements from your school community.'),
    _PageData(icon: Icons.event_available_outlined, title: 'Never Miss Events', sub: 'Discover and join exciting school events, fairs, and activities.'),
    _PageData(icon: Icons.groups_outlined,          title: 'Connect & Belong',  sub: 'Join clubs, find pre-loved items, and chat with fellow students.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, Color(0xFF3D0000)],
        ),
      ),
      child: SafeArea(child: Column(children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Image.asset(
              'assets/images/splash_logo.png',
              height: 36,
              errorBuilder: (_, __, ___) => RichText(
                text: const TextSpan(children: [
                  TextSpan(text: 'Scho', style: TextStyle(color: Color(0xFFB22222), fontSize: 22, fontWeight: FontWeight.w900)),
                  TextSpan(text: 'O',    style: TextStyle(color: AppTheme.accentLight, fontSize: 22, fontWeight: FontWeight.w900)),
                  TextSpan(text: 'life', style: TextStyle(color: Color(0xFFB22222), fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
            const Spacer(),
            TextButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('Skip', style: TextStyle(color: AppTheme.textOnDarkMuted))),
          ]),
        ),

        // Pages
        Expanded(
          child: PageView.builder(
            controller: _ctrl, itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
          ),
        ),

        SmoothPageIndicator(
            controller: _ctrl, count: _pages.length,
            effect: const ExpandingDotsEffect(
                activeDotColor: AppTheme.accent, dotColor: Colors.white30,
                dotHeight: 8, dotWidth: 8, expansionFactor: 3)),
        const SizedBox(height: 32),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (_page < _pages.length - 1) {
                  _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
                } else {
                  context.go('/sign-in');
                }
              },
              child: Text(
                  _page < _pages.length - 1 ? 'Next' : 'Get Started',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ])),
    ),
  );
}

class _PageData {
  final IconData icon; final String title, sub;
  const _PageData({required this.icon, required this.title, required this.sub});
}

class _OnboardPage extends StatelessWidget {
  final _PageData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 160, height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFFFF8C00), AppTheme.primary]),
          boxShadow: [BoxShadow(
              color: AppTheme.accent.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
        ),
        child: Icon(data.icon, size: 70, color: Colors.white),
      ),
      const SizedBox(height: 40),
      Text(data.title,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text(data.sub,
          style: const TextStyle(color: AppTheme.textOnDarkMuted, fontSize: 15, height: 1.6),
          textAlign: TextAlign.center),
    ]),
  );
}