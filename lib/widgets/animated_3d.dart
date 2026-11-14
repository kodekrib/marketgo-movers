// Animated 3D-style visuals built with pure Flutter.
//
// No image assets or extra packages are used — the "3D images" are drawn with
// real perspective matrices (Matrix4) and Canvas isometric geometry, then
// animated on a loop. This keeps the app lightweight while giving the Login
// and Home screens a lively, tactile hero.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';

/// Global switch so widget tests can keep frames stable. Set to false in tests
/// to avoid never-ending `pumpAndSettle` loops from the looping heroes.
bool kHeroAnimationsEnabled = true;

// ---------------------------------------------------------------------------
// Motion wrappers
// ---------------------------------------------------------------------------

/// Gently swings [child] in 3D space using a perspective matrix while floating
/// it up and down. This is the core "animated 3D image" wrapper.
class Showcase3D extends StatefulWidget {
  const Showcase3D({
    super.key,
    required this.child,
    this.tilt = 0.16,
    this.float = 10,
    this.period = const Duration(seconds: 6),
    this.perspective = 0.0014,
  });

  final Widget child;

  /// Max Y-axis swing (radians) applied by the loop.
  final double tilt;

  /// Vertical float distance in logical pixels.
  final double float;

  final Duration period;

  /// Strength of the perspective divide (bigger = more dramatic depth).
  final double perspective;

  @override
  State<Showcase3D> createState() => _Showcase3DState();
}

class _Showcase3DState extends State<Showcase3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
    if (kHeroAnimationsEnabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 * math.pi;
        final swing = math.sin(t) * widget.tilt;
        final bob = math.cos(t) * widget.float;
        final m = Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(swing * 0.5)
          ..rotateY(swing);
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform(
            alignment: Alignment.center,
            transform: m,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Fades and slides [child] into place once, used to stage sections.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 18),
    this.duration = const Duration(milliseconds: 520),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = curve;
    _slide =
        Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curve);
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delay = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Glow helpers
// ---------------------------------------------------------------------------

/// Static soft radial glow used to add depth behind hero content.
class GlowOrb extends StatelessWidget {
  const GlowOrb({super.key, required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

/// Slowly pulsing glow for ambient movement in the hero.
class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.diameter,
    required this.color,
    this.period = const Duration(seconds: 5),
  });

  final double diameter;
  final Color color;
  final Duration period;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
    if (kHeroAnimationsEnabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final s = 0.85 + 0.15 * math.sin(_c.value * 2 * math.pi);
        return Transform.scale(
          scale: s,
          child: GlowOrb(diameter: widget.diameter, color: widget.color),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// The moving truck "3D image"
// ---------------------------------------------------------------------------

/// A crisp isometric (2.5D) moving-truck illustration, drawn in the brand
/// palette and wrapped in a looping [Showcase3D] swing so it reads as a live
/// animated 3D image.
class MovingTruck3D extends StatelessWidget {
  const MovingTruck3D({
    super.key,
    this.size = 220,
    this.speed = const Duration(seconds: 6),
    this.motionLines = true,
  });

  final double size;
  final Duration speed;
  final bool motionLines;

  @override
  Widget build(BuildContext context) {
    return Showcase3D(
      period: speed,
      tilt: 0.14,
      float: size * 0.045,
      child: SizedBox(
        width: size,
        height: size * 0.9,
        child: CustomPaint(
          painter: _TruckPainter(
            brand: MoversApp.brandOrange,
            brandDark: MoversApp.brandOrangeDark,
            brandLight: MoversApp.brandOrangeLight,
            motionLines: motionLines,
          ),
        ),
      ),
    );
  }
}

class _BoxSpec {
  const _BoxSpec(this.x, this.y, this.z, this.w, this.d, this.h, this.base);

  final double x, y, z, w, d, h;
  final Color base;
}

class _TruckPainter extends CustomPainter {
  _TruckPainter({
    required this.brand,
    required this.brandDark,
    required this.brandLight,
    required this.motionLines,
  });

  final Color brand;
  final Color brandDark;
  final Color brandLight;
  final bool motionLines;

  static const double _c30 = 0.8660254038; // cos(30°)
  static const Color _chassis = Color(0xFF2B3038);
  static const Color _tyre = Color(0xFF1B1F25);
  static const Color _hub = Color(0xFF9AA1AA);
  static const Color _glass = Color(0xFFBFE3F5);

  @override
  void paint(Canvas canvas, Size size) {
    final boxes = <_BoxSpec>[
      const _BoxSpec(0.0, 0.0, 0.30, 3.35, 1.45, 0.16, _chassis),
      _BoxSpec(0.10, 0.08, 0.46, 1.90, 1.30, 1.28, brand),
      _BoxSpec(2.06, 0.12, 0.30, 1.16, 1.24, 0.92, brandDark),
      _BoxSpec(2.22, 0.20, 1.22, 0.50, 0.50, 0.14, brandLight),
      const _BoxSpec(3.22, 0.12, 0.34, 0.14, 1.24, 0.34, Color(0xFF15181D)),
    ];

    Offset project(double x, double y, double z) =>
        Offset((x - y) * _c30, (x + y) * 0.5 - z);

    // Fit the geometry into the canvas with a small breathing margin.
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    void consider(Offset p) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    for (final b in boxes) {
      for (final x in [b.x, b.x + b.w]) {
        for (final y in [b.y, b.y + b.d]) {
          for (final z in [b.z, b.z + b.h]) {
            consider(project(x, y, z));
          }
        }
      }
    }
    consider(project(0.85, 1.55, -0.06));
    consider(project(2.80, 1.55, -0.06));

    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final scale = math.min(
      size.width / (spanX + 0.7),
      size.height / (spanY + 0.7),
    );
    final ox = (size.width - spanX * scale) / 2 - minX * scale;
    final oy = (size.height - spanY * scale) / 2 - minY * scale;

    Offset iso(double x, double y, double z) {
      final p = project(x, y, z);
      return Offset(p.dx * scale + ox, p.dy * scale + oy);
    }

    // Soft contact shadow on the ground plane.
    final shadowCenter = iso(1.7, 0.72, 0.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowCenter.dx, shadowCenter.dy + scale * 0.06),
        width: scale * 4.6,
        height: scale * 1.5,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale * 0.35),
    );

    // Speed lines (drawn behind the body).
    if (motionLines) {
      final base = iso(0.0, 0.9, 0.9);
      for (var i = 0; i < 3; i++) {
        final y = base.dy + i * scale * 0.34 - scale * 0.12;
        final w = scale * (0.9 - i * 0.16);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(base.dx - scale * 1.35 - w, y, w, scale * 0.075),
            Radius.circular(scale * 0.05),
          ),
          Paint()..color = brandLight.withOpacity(0.35 - i * 0.08),
        );
      }
    }

    // Wheels — far side first so near-side tyres sit on top.
    void wheel(double x, double y, double alpha) {
      final c = iso(x, y, 0.32);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: scale * 0.8, height: scale * 0.88),
        Paint()..color = _tyre.withOpacity(alpha),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: scale * 0.34, height: scale * 0.38),
        Paint()..color = _hub.withOpacity(alpha),
      );
    }

    wheel(0.85, -0.02, 0.55);
    wheel(2.80, -0.02, 0.55);
    wheel(0.85, 1.50, 1.0);
    wheel(2.80, 1.50, 1.0);

    // Solid boxes, painted back-to-front.
    final ordered = [...boxes]
      ..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    for (final b in ordered) {
      _paintBox(canvas, iso, b);
    }

    // Windshield on the cabin's visible front face.
    _paintQuad(
      canvas,
      [
        iso(2.20, 1.36, 1.12),
        iso(3.02, 1.36, 1.12),
        iso(3.02, 1.36, 0.72),
        iso(2.20, 1.36, 0.72),
      ],
      _glass.withOpacity(0.92),
    );

    // Cargo door seam + brand stripe.
    _paintQuad(
      canvas,
      [
        iso(0.96, 1.38, 1.72),
        iso(0.96, 1.38, 0.50),
        iso(1.02, 1.38, 0.50),
        iso(1.02, 1.38, 1.72),
      ],
      _shade(brand, -0.28),
    );
    _paintQuad(
      canvas,
      [
        iso(0.14, 1.38, 0.72),
        iso(1.96, 1.38, 0.72),
        iso(1.96, 1.38, 0.60),
        iso(0.14, 1.38, 0.60),
      ],
      _shade(brandLight, 0.02),
    );
  }

  void _paintBox(
      Canvas canvas, Offset Function(double, double, double) iso, _BoxSpec b) {
    final x0 = b.x, x1 = b.x + b.w;
    final y0 = b.y, y1 = b.y + b.d;
    final z0 = b.z, z1 = b.z + b.h;

    // Top face (lightest).
    _paintQuad(
        canvas,
        [
          iso(x0, y0, z1),
          iso(x1, y0, z1),
          iso(x1, y1, z1),
          iso(x0, y1, z1),
        ],
        _shade(b.base, 0.22));

    // Right face (x = max).
    _paintQuad(
        canvas,
        [
          iso(x1, y0, z0),
          iso(x1, y1, z0),
          iso(x1, y1, z1),
          iso(x1, y0, z1),
        ],
        _shade(b.base, -0.02));

    // Front face (y = max, toward viewer-left).
    _paintQuad(
        canvas,
        [
          iso(x0, y1, z0),
          iso(x1, y1, z0),
          iso(x1, y1, z1),
          iso(x0, y1, z1),
        ],
        _shade(b.base, -0.18));
  }

  void _paintQuad(Canvas canvas, List<Offset> pts, Color color) {
    if (pts.length < 3) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  Color _shade(Color c, double t) => t >= 0
      ? Color.lerp(c, Colors.white, t)!
      : Color.lerp(c, Colors.black, -t)!;

  @override
  bool shouldRepaint(covariant _TruckPainter old) =>
      old.brand != brand ||
      old.brandDark != brandDark ||
      old.brandLight != brandLight;
}
