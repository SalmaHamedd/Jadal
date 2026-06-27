import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/features/splash/presentation/screens/permission_settings_dialog.dart';
import 'package:jadal_app/features/temp_home/presentation/screens/temp_home_screen.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../live_debate/presentation/pages/debate_list_screen.dart';
import '../cubit/splash_cubit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SplashView();
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView> with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Background fade-in
  late final Animation<double> _bgFade;
  // Orb travel (0 = at edges, 1 = at center)
  late final Animation<double> _orbProgress;
  // Orbs fade out as they collide
  late final Animation<double> _orbFade;
  // Logo appears at collision
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  // App name slide + fade
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  // Slogan slide + fade
  late final Animation<double> _sloganFade;
  late final Animation<Offset> _sloganSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();

    _bgFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.08, curve: Curves.easeIn),
    );

    _orbProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.36, curve: Curves.easeInOut),
    );

    _orbFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.32, 0.42)),
    );

    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.36, 0.52, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.36, 0.50, curve: Curves.easeOutBack)),
    );

    _nameFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.46, 0.60, curve: Curves.easeOut),
    );

    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.46, 0.62, curve: Curves.easeOutCubic)));

    _sloganFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.57, 0.72, curve: Curves.easeOut),
    );

    _sloganSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.57, 0.73, curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigate(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;

    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToLogin) _navigate(const LoginScreen());
        if (state is SplashNavigateToHome)  _navigate(const DebateListScreen());
        if (state is SplashNavigateToPermissions) {
          PermissionSettingsDialog.show(
            context,
            denied: state.deniedPermissions, 
          );
        }
      },

      child: Scaffold(
        backgroundColor: JadalColors.darkBackground,
        body: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final halfW = size.width / 2;
            final blueX  = -halfW * (1 - _orbProgress.value);
            final orangeX = halfW * (1 - _orbProgress.value);

            return Stack(
              fit: StackFit.expand,
              children: [
                // Node-network background pattern
                Opacity(
                  opacity: _bgFade.value,
                  child: CustomPaint(
                    painter: _NodeNetworkPainter(),
                    size: size,
                  ),
                ),

                // Decorative blue glow (top-left)
                Positioned(
                  top: -80,
                  left: -80,
                  child: Opacity(
                    opacity: _bgFade.value * 0.6,
                    child: _blur(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: JadalColors.primaryBlue.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                ),

                // Decorative orange glow (bottom-right)
                Positioned(
                  bottom: -80,
                  right: -80,
                  child: Opacity(
                    opacity: _bgFade.value * 0.6,
                    child: _blur(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: JadalColors.primaryOrange.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),

                // Animated orbs
                Opacity(
                  opacity: _orbFade.value,
                  child: Center(
                    child: Stack(
                      children: [
                        // Blue orb — travels from left
                        Transform.translate(
                          offset: Offset(blueX, 0),
                          child: const _GlowOrb(color: JadalColors.primaryBlue, radius: 40),
                        ),
                        // Orange orb — travels from right
                        Transform.translate(
                          offset: Offset(orangeX, 0),
                          child: const _GlowOrb(color: JadalColors.primaryOrange, radius: 40),
                        ),
                      ],
                    ),
                  ),
                ),

                // Logo + text (fade in after collision)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with glow
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: JadalColors.primaryBlue.withValues(alpha: 0.30),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: JadalColors.primaryOrange.withValues(alpha: 0.22),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/images/Jadal-logo.jpg',
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // App name
                      FadeTransition(
                        opacity: _nameFade,
                        child: SlideTransition(
                          position: _nameSlide,
                          child: Text(
                            'JADAL',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: JadalColors.darkTextPrimary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Slogan
                      FadeTransition(
                        opacity: _sloganFade,
                        child: SlideTransition(
                          position: _sloganSlide,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'حيث تلتقي الكلمة بالتقنية',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: JadalColors.darkTextSecondary,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _blur({required Widget child}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: child,
    );
  }
}

// ── Glow orb ─────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double radius;

  const _GlowOrb({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.30, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}

// ── Node network background painter ──────────────────────────────────────────

class _NodeNetworkPainter extends CustomPainter {
  static const int _count = 32;
  static List<Offset>? _nodes;

  List<Offset> _getNodes(Size size) {
    if (_nodes != null) return _nodes!;
    final rng = Random(42);
    _nodes = List.generate(
      _count,
      (_) => Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
    );
    return _nodes!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _getNodes(size);
    const maxDist = 145.0;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < maxDist) {
          final alpha = (1 - dist / maxDist) * 0.10;
          canvas.drawLine(
            nodes[i],
            nodes[j],
            Paint()
              ..color = const Color(0xFF4A6A9A).withValues(alpha: alpha)
              ..strokeWidth = 0.8,
          );
        }
      }
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF6080A8).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    for (final node in nodes) {
      canvas.drawCircle(node, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_NodeNetworkPainter _) => false;
}
