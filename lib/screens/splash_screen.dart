import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_screen.dart';

// ---------------------------------------------------------------------------
// ENTRY POINT
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ---------------------------------------------------------------------------
// STATE
// ---------------------------------------------------------------------------
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller 1 – background fade-in
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgFade;

  // Controller 2 – icon entrance
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;

  // Controller 3 – text slide-in
  late final AnimationController _textCtrl;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subSlide;
  late final Animation<double> _subFade;

  // Controller 4 – progress bar
  late final AnimationController _progressCtrl;

  // Controller 5 – infinite particle / glow loop
  late final AnimationController _particleCtrl;

  static const Color _accent = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();

    // --- Background ---
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // --- Icon ---
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _iconCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));

    // --- Text ---
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _textCtrl,
                curve:
                    const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _subSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _textCtrl,
                curve:
                    const Interval(0.2, 0.9, curve: Curves.easeOutCubic)));
    _subFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.2, 0.8, curve: Curves.easeIn)));

    // --- Progress bar ---
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));

    // --- Particles (infinite loop) ---
    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();

    _runSequence();
  }

  Future<void> _runSequence() async {
    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _progressCtrl.forward();

    // TODO: Replace this delay with a Firebase Auth current-user check.
    // e.g. final user = FirebaseAuth.instance.currentUser;
    // Navigate to Dashboard if user != null, otherwise stay on Login.
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade =
            CurvedAnimation(parent: animation, curve: Curves.easeIn);
        final slide =
            Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child));
      },
    ));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _iconCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _bgFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 3-stop gradient background ─────────────────────────────────
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.45, 1.0],
                  colors: [
                    Color(0xFF0A3356),
                    Color(0xFF0F4C81),
                    Color(0xFF1976D2),
                  ],
                ),
              ),
            ),

            // ── Decorative background circles ─────────────────────────────
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Floating particle orbs ────────────────────────────────────
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, child) => CustomPaint(
                painter: _ParticlePainter(_particleCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Decorative outer glow ring ────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_iconCtrl, _particleCtrl]),
                builder: (context, child) {
                  final fadeVal = _iconFade.value.clamp(0.0, 1.0);
                  final pulse = 0.88 +
                      0.12 * math.sin(_particleCtrl.value * 2 * math.pi);
                  return Opacity(
                    opacity: (fadeVal * 0.30).clamp(0.0, 1.0),
                    child: Container(
                      width: 280 * pulse,
                      height: 280 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5),
                        gradient: RadialGradient(colors: [
                          Colors.white.withValues(alpha: 0.14),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Main content column ───────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon card ──────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _iconCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: _iconScale.value.clamp(0.0, 1.5),
                      child: Opacity(
                          opacity: _iconFade.value.clamp(0.0, 1.0),
                          child: child),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing halo
                        AnimatedBuilder(
                          animation: _particleCtrl,
                          builder: (context, child) {
                            final pulse = 0.85 +
                                0.15 *
                                    math.sin(
                                        _particleCtrl.value * 2 * math.pi);
                            return Container(
                              width: 150 * pulse,
                              height: 150 * pulse,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  Colors.white
                                      .withValues(alpha: 0.18 * pulse),
                                  Colors.transparent,
                                ]),
                              ),
                            );
                          },
                        ),

                        // Glassmorphism card
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.12),
                              ],
                            ),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.40),
                                blurRadius: 44,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            size: 58,
                            color: Color(0xFF0F4C81),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── App name ─────────────────────────────────────────────
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: const Text(
                        'New Sohail Medical Store',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Subtitle pill ─────────────────────────────────────────
                  SlideTransition(
                    position: _subSlide,
                    child: FadeTransition(
                      opacity: _subFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1),
                        ),
                        child: const Text(
                          'Pharmacy Management System',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 64),

                  // ── Progress bar ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _subFade,
                    child: SizedBox(
                      width: 200,
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (context, child) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressCtrl.value,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── "Initializing…" label ─────────────────────────────────
                  FadeTransition(
                    opacity: _subFade,
                    child: Text(
                      'Initializing…',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom badges ────────────────────────────────────────────
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _subFade,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Powered by TryUnity Solutions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.50),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// CUSTOM PAINTER – floating translucent particle orbs
// ---------------------------------------------------------------------------
class _ParticlePainter extends CustomPainter {
  final double t; // 0..1 looping value from AnimationController

  _ParticlePainter(this.t);

  // [relX, relY, radius, speed, opacity]
  static const List<List<double>> _particles = [
    [0.12, 0.10, 80, 0.30, 0.06],
    [0.85, 0.08, 60, 0.55, 0.05],
    [0.05, 0.75, 100, 0.20, 0.07],
    [0.90, 0.80, 70, 0.40, 0.04],
    [0.50, 0.15, 50, 0.70, 0.06],
    [0.30, 0.90, 90, 0.25, 0.05],
    [0.70, 0.50, 40, 0.80, 0.08],
    [0.20, 0.45, 65, 0.35, 0.04],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final baseX = p[0] * size.width;
      final baseY = p[1] * size.height;
      final radius = p[2];
      final speed = p[3];
      final opacity = p[4];

      final angle = 2 * math.pi * ((t * speed) % 1.0);
      final cx = baseX + math.cos(angle) * 18;
      final cy = baseY + math.sin(angle) * 12;
      final center = Offset(cx, cy);

      final paint = Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 255, 255, opacity),
          const Color(0x00FFFFFF),
        ]).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
