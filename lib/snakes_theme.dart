import 'dart:math';
import 'package:flutter/material.dart';

/// "Parchment & Brass Storybook Board" design system for Snakes & Ladders
/// (Stitch project 14049530433125792394). Vintage storybook: hand-painted
/// parchment, carved wood, brass fittings, ivory die. Pseudo-3D physical
/// materials only — no neon, no flat Material chrome.
abstract final class StTheme {
  // ---- Palette (DESIGN.md) ----
  static const parchment = Color(0xFFF1E3C3);
  static const parchmentDeep = Color(0xFFE3CFA4);
  static const ochre = Color(0xFFC89B5A);
  static const walnut = Color(0xFF6B4A2F);
  static const oak = Color(0xFFA4713F);
  static const pineLight = Color(0xFFC99A63);
  static const brass = Color(0xFFB08D3E);
  static const inkBrown = Color(0xFF4A3220);
  static const inkSoft = Color(0xFF7A5C3E);
  static const goldLeaf = Color(0xFFD4A93C);
  static const pawnRed = Color(0xFFB3402E);
  static const pawnBlue = Color(0xFF2E5F8A);
  static const pawnGreen = Color(0xFF3E7A3E);
  static const pawnYellow = Color(0xFFD9A62E);
  static const snakeGreen = Color(0xFF4E6B34);
  static const leaf = Color(0xFF6E8B4A);
  static const mahogany = Color(0xFF5C3A22); // table / backdrop wood
  static const mahoganyDeep = Color(0xFF3E2413);

  static const pawnColors = [pawnRed, pawnBlue, pawnGreen, pawnYellow];
  static const pawnNames = ['Lady Beatrice', 'Master Edwin', 'Captain Algernon', 'Miss Penelope'];

  // ---- Typography ----
  static const displayFamily = 'EBGaramond';
  static const bodyFamily = 'Newsreader';

  static TextStyle get title => const TextStyle(
        fontFamily: displayFamily,
        fontSize: 46,
        fontWeight: FontWeight.w800,
        color: inkBrown,
        letterSpacing: 0.5,
        shadows: [
          Shadow(color: Color(0x55D4A93C), offset: Offset(0, 2), blurRadius: 1),
          Shadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 6),
        ],
      );

  static TextStyle get titleSmall => const TextStyle(
        fontFamily: displayFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: inkBrown,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        color: inkBrown,
        height: 1.4,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12.5,
        fontStyle: FontStyle.italic,
        color: inkSoft,
      );

  static TextStyle get buttonLabel => const TextStyle(
        fontFamily: displayFamily,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: parchment,
        letterSpacing: 1.2,
        shadows: [
          Shadow(color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 2),
        ],
      );

  static TextStyle get numeral => const TextStyle(
        fontFamily: displayFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: inkBrown,
      );

  // ---- Pseudo-3D material helpers ----
  /// Carved-wood bevel: warm top-left light, dark bottom occlusion.
  static List<BoxShadow> get woodShadow => const [
        BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
        BoxShadow(color: Color(0x33FFFFFF), blurRadius: 1, offset: Offset(0, -1)),
      ];

  static List<BoxShadow> get paperShadow => const [
        BoxShadow(color: Color(0x4D2C1810), blurRadius: 12, offset: Offset(0, 6)),
        BoxShadow(color: Color(0x1A2C1810), blurRadius: 3, offset: Offset(0, 1)),
      ];

  static List<BoxShadow> get brassShadow => const [
        BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3)),
        BoxShadow(color: Color(0x66FFF3C4), blurRadius: 1, offset: Offset(0, -1)),
      ];

  /// Soft drop shadow under a token standing on the board.
  static List<BoxShadow> get tokenShadow => const [
        BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 4)),
        BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
      ];
}

/// Aged parchment backdrop with subtle mottling, fibres and worn edges.
class ParchmentBackdrop extends StatelessWidget {
  final Widget child;
  const ParchmentBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StTheme.parchment,
      child: CustomPaint(
        painter: _ParchmentPainter(),
        child: child,
      ),
    );
  }
}

class _ParchmentPainter extends CustomPainter {
  final _rnd = Random(7);
  @override
  void paint(Canvas canvas, Size size) {
    // gentle mottling blotches
    for (int i = 0; i < 26; i++) {
      final x = _rnd.nextDouble() * size.width;
      final y = _rnd.nextDouble() * size.height;
      final r = 24 + _rnd.nextDouble() * 90;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = const Color(0x0AD49B5A)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
    // fibre specks
    final p = Paint()..color = const Color(0x147A5C3E);
    for (int i = 0; i < 140; i++) {
      canvas.drawCircle(
        Offset(_rnd.nextDouble() * size.width, _rnd.nextDouble() * size.height),
        0.7,
        p,
      );
    }
    // worn darker edges (vignette)
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.35,
          colors: const [Color(0x00000000), Color(0x2E6B4A2F)],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Carved-wood panel with grain, bevelled edges and brass corner studs.
class WoodPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const WoodPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: StTheme.woodShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _WoodPainter(base: StTheme.walnut, dark: const Color(0xFF4E331F)),
          child: child,
        ),
      ),
    );
  }
}

class _WoodPainter extends CustomPainter {
  final Color base;
  final Color dark;
  final _rnd = Random(11);
  _WoodPainter({required this.base, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    // grain streaks
    for (int i = 0; i < 22; i++) {
      final y = _rnd.nextDouble() * size.height;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        path.lineTo(x, y + sin(x / 40 + i) * 3 + _rnd.nextDouble() * 2);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = dark.withValues(alpha: 0.16 + _rnd.nextDouble() * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + _rnd.nextDouble() * 1.6,
      );
    }
    // top-left light bevel
    canvas.drawRect(
      Offset.zero & Size(size.width, 3),
      Paint()..color = const Color(0x55C99A63),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, size.height),
      Paint()..color = const Color(0x44C99A63),
    );
    // bottom occlusion
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 4, size.width, 4),
      Paint()..color = const Color(0x66000000),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Carved-wood button with brass rim and pressed state.
class WoodButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  const WoodButton({super.key, required this.label, required this.onTap, this.fontSize = 21, this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 14)});

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: widget.padding,
        transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0.0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StTheme.brass, width: 2.5),
          boxShadow: _pressed
              ? const [BoxShadow(color: Color(0x44000000), blurRadius: 3, offset: Offset(0, 1))]
              : StTheme.woodShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: CustomPaint(
            painter: _WoodPainter(base: enabled ? StTheme.oak : const Color(0xFF8A6A4E), dark: StTheme.walnut),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: StTheme.buttonLabel.copyWith(fontSize: widget.fontSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round brass button (pause, settings, back) with engraved glyph.
class BrassRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const BrassRoundButton({super.key, required this.icon, required this.onTap, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD9B45C), StTheme.brass, Color(0xFF8A6B2A)],
          ),
          boxShadow: StTheme.brassShadow,
          border: Border.all(color: const Color(0xFF6E5220), width: 1.5),
        ),
        child: Icon(icon, color: StTheme.inkBrown, size: size * 0.5),
      ),
    );
  }
}

/// Wooden toggle switch on a brass mounting plate.
class WoodToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const WoodToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 64,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: value ? StTheme.pineLight : const Color(0xFF9A7A56),
          border: Border.all(color: StTheme.brass, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2)),
            BoxShadow(color: Color(0x44FFF3C4), blurRadius: 1, offset: Offset(0, -1)),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD9B45C), StTheme.brass, Color(0xFF8A6B2A)],
                  ),
                  border: Border.all(color: const Color(0xFF6E5220), width: 1.2),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carved wooden volume slider with a turned brass knob.
class WoodSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const WoodSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 12,
        thumbShape: const _BrassKnobShape(),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: StTheme.oak,
        inactiveTrackColor: const Color(0xFF9A7A56),
      ),
      child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
    );
  }
}

class _BrassKnobShape extends SliderComponentShape {
  const _BrassKnobShape();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(30, 30);

  @override
  void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {
    final c = context.canvas;
    c.drawCircle(
      center,
      15,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD9B45C), StTheme.brass, Color(0xFF8A6B2A)],
        ).createShader(Rect.fromCircle(center: center, radius: 15)),
    );
    c.drawCircle(center, 15, Paint()..style = PaintingStyle.stroke..color = const Color(0xFF6E5220)..strokeWidth = 1.5);
    c.drawCircle(center + const Offset(-4, -4), 4, Paint()..color = const Color(0xAAFFF3C4));
    c.drawCircle(center, 4, Paint()..color = const Color(0xFF6E5220));
  }
}

/// Hand-carved wooden pawn with painted coat, bevel and soft shadow.
class WoodenPawn extends StatelessWidget {
  final Color color;
  final double size;
  final bool crowned;
  const WoodenPawn({super.key, required this.color, this.size = 40, this.crowned = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.35,
      child: CustomPaint(painter: _PawnPainter(color: color, crowned: crowned)),
    );
  }
}

class _PawnPainter extends CustomPainter {
  final Color color;
  final bool crowned;
  _PawnPainter({required this.color, required this.crowned});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - w * 0.08), width: w * 0.9, height: w * 0.22),
      Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // body profile: classic pawn silhouette
    final body = Path()
      ..moveTo(w * 0.5 - w * 0.30, h - w * 0.10)
      ..cubicTo(w * 0.5 - w * 0.34, h * 0.62, w * 0.5 - w * 0.13, h * 0.58, w * 0.5 - w * 0.12, h * 0.44)
      ..cubicTo(w * 0.5 - w * 0.11, h * 0.34, w * 0.5 - w * 0.05, h * 0.32, w * 0.5, h * 0.32)
      ..cubicTo(w * 0.5 + w * 0.05, h * 0.32, w * 0.5 + w * 0.11, h * 0.34, w * 0.5 + w * 0.12, h * 0.44)
      ..cubicTo(w * 0.5 + w * 0.13, h * 0.58, w * 0.5 + w * 0.34, h * 0.62, w * 0.5 + w * 0.30, h - w * 0.10)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    // wood-grain sheen on the left
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0x55FFFFFF), const Color(0x00000000), const Color(0x44000000)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(body.getBounds()),
    );
    // head
    final headR = w * 0.20;
    final headC = Offset(w * 0.5, h * 0.20);
    canvas.drawCircle(headC, headR, Paint()..color = color);
    canvas.drawCircle(
      headC + Offset(-headR * 0.3, -headR * 0.3),
      headR * 0.45,
      Paint()..color = const Color(0x44FFFFFF),
    );
    // base ring (brass-ish painted band)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h - w * 0.16, w * 0.60, w * 0.07), const Radius.circular(4)),
      Paint()..color = StTheme.brass,
    );
    if (crowned) {
      // tiny gold crown on the head
      final cw = w * 0.34, cy = h * 0.06;
      final crown = Path()
        ..moveTo(w * 0.5 - cw / 2, cy + h * 0.06)
        ..lineTo(w * 0.5 - cw / 2, cy - h * 0.02)
        ..lineTo(w * 0.5 - cw * 0.25, cy + h * 0.015)
        ..lineTo(w * 0.5, cy - h * 0.045)
        ..lineTo(w * 0.5 + cw * 0.25, cy + h * 0.015)
        ..lineTo(w * 0.5 + cw / 2, cy - h * 0.02)
        ..lineTo(w * 0.5 + cw / 2, cy + h * 0.06)
        ..close();
      canvas.drawPath(crown, Paint()..color = StTheme.goldLeaf);
      canvas.drawPath(crown, Paint()..style = PaintingStyle.stroke..color = const Color(0xFF8A6B2A)..strokeWidth = 1.2);
      for (final dx in [-0.25, 0.0, 0.25]) {
        canvas.drawCircle(Offset(w * 0.5 + cw * dx, cy - (dx == 0 ? h * 0.045 : h * 0.02)), 2.2, Paint()..color = const Color(0xFFB3402E));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PawnPainter old) => old.color != color || old.crowned != crowned;
}

/// Ivory die with burned-in pips, rounded like real bone.
class IvoryDie extends StatelessWidget {
  final int value; // 1..6, 0 = blank
  final double size;
  const IvoryDie({super.key, required this.value, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DiePainter(value: value)),
    );
  }
}

class _DiePainter extends CustomPainter {
  final int value;
  _DiePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s / 2 + 3, s - 4), width: s * 0.8, height: 10),
      Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final rect = RRect.fromRectAndRadius(Offset.zero & Size(s, s), Radius.circular(s * 0.18));
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFF7EFDC));
    // aged ivory mottling
    final rnd = Random(value * 13 + 5);
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * s, rnd.nextDouble() * s),
        2 + rnd.nextDouble() * 4,
        Paint()..color = const Color(0x14000000),
      );
    }
    // bevel
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFC9B98F),
    );
    canvas.drawLine(
      Offset(s * 0.14, s * 0.08), Offset(s * 0.86, s * 0.08),
      Paint()..color = const Color(0x88FFFFFF)..strokeWidth = 3,
    );
    // burned-in pips
    const layouts = {
      1: [Offset(0.5, 0.5)],
      2: [Offset(0.3, 0.3), Offset(0.7, 0.7)],
      3: [Offset(0.28, 0.28), Offset(0.5, 0.5), Offset(0.72, 0.72)],
      4: [Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.3, 0.7), Offset(0.7, 0.7)],
      5: [Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.5, 0.5), Offset(0.3, 0.7), Offset(0.7, 0.7)],
      6: [Offset(0.3, 0.28), Offset(0.7, 0.28), Offset(0.3, 0.5), Offset(0.7, 0.5), Offset(0.3, 0.72), Offset(0.7, 0.72)],
    };
    final pips = layouts[value] ?? const <Offset>[];
    for (final o in pips) {
      final c = Offset(o.dx * s, o.dy * s);
      canvas.drawCircle(c, s * 0.075, Paint()..color = StTheme.inkBrown);
      canvas.drawCircle(c + const Offset(-1, -1), s * 0.028, Paint()..color = const Color(0x337A5C3E));
    }
  }

  @override
  bool shouldRepaint(covariant _DiePainter old) => old.value != value;
}

/// Hand-painted serpent: tapered body, scale arcs, head with forked tongue.
class SnakePainter extends CustomPainter {
  final Offset from; // head
  final Offset to; // tail
  final double scale;
  final Random _rnd = Random(23);
  SnakePainter({required this.from, required this.to, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final dir = to - from;
    final len = dir.distance;
    if (len < 1) return;
    final n = dir / len;
    final normal = Offset(-n.dy, n.dx);
    // slither control points — organic S-curve
    final bends = 3;
    final pts = <Offset>[];
    for (int i = 0; i <= 12; i++) {
      final tt = i / 12;
      final sway = sin(tt * pi * bends) * len * 0.09 * (i == 0 || i == 12 ? 0.15 : 1.0);
      pts.add(from + dir * tt + normal * sway);
    }
    final spine = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      spine.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    spine.lineTo(pts.last.dx, pts.last.dy);

    // tapered body: draw as series of overlapping circles, thick at head
    for (int i = 0; i < pts.length; i++) {
      final tt = i / (pts.length - 1);
      final r = (10 - tt * 8.5) * scale;
      final shade = Color.lerp(const Color(0xFF5E7A40), const Color(0xFF3A5226), tt)!;
      canvas.drawCircle(pts[i], r, Paint()..color = shade);
    }
    // belly highlight
    for (int i = 2; i < pts.length - 2; i += 2) {
      final tt = i / (pts.length - 1);
      canvas.drawCircle(pts[i] + normal * -2 * scale, (10 - tt * 8.5) * scale * 0.45, Paint()..color = const Color(0x3398B06A));
    }
    // scale arcs
    final scalePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x662E4218);
    for (int i = 1; i < pts.length - 1; i++) {
      final tt = i / (pts.length - 1);
      final r = (10 - tt * 8.5) * scale * 0.7;
      canvas.drawArc(Rect.fromCircle(center: pts[i], radius: r), 0.4, 2.2, false, scalePaint);
    }
    // speckles
    for (int i = 0; i < 40; i++) {
      final tt = _rnd.nextDouble() * 0.8;
      final idx = (tt * (pts.length - 1)).floor();
      final r = (10 - tt * 8.5) * scale * 0.5;
      canvas.drawCircle(
        pts[idx] + Offset((_rnd.nextDouble() - 0.5) * r * 2, (_rnd.nextDouble() - 0.5) * r * 2),
        1.2,
        Paint()..color = const Color(0x552A3F16),
      );
    }
    // head: slightly flattened ellipse with eyes + forked tongue
    final headR = 11 * scale;
    canvas.drawOval(
      Rect.fromCenter(center: pts.first, width: headR * 2.1, height: headR * 1.7),
      Paint()..color = const Color(0xFF5E7A40),
    );
    final look = n;
    final eyeBase = pts.first + look * headR * 0.45;
    for (final s in [-1.0, 1.0]) {
      final e = eyeBase + normal * s * headR * 0.45;
      canvas.drawCircle(e, headR * 0.28, Paint()..color = const Color(0xFFF3E6C8));
      canvas.drawCircle(e + look * 1.2, headR * 0.13, Paint()..color = const Color(0xFF1A1408));
    }
    // forked tongue
    final tp = pts.first + look * headR * 1.05;
    final tongue = Path()
      ..moveTo(tp.dx, tp.dy)
      ..lineTo((tp + look * 10 * scale + normal * 4 * scale).dx, (tp + look * 10 * scale + normal * 4 * scale).dy)
      ..moveTo(tp.dx, tp.dy)
      ..lineTo((tp + look * 10 * scale - normal * 4 * scale).dx, (tp + look * 10 * scale - normal * 4 * scale).dy);
    canvas.drawPath(tongue, Paint()..style = PaintingStyle.stroke..strokeWidth = 2 * scale..color = const Color(0xFFB3402E)..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant SnakePainter old) => old.from != from || old.to != to;
}

/// Wooden ladder with rope sides and timber rungs.
class LadderPainter extends CustomPainter {
  final Offset from; // foot
  final Offset to; // top
  final double scale;
  LadderPainter({required this.from, required this.to, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final delta = to - from;
    final len = delta.distance;
    if (len < 1) return;
    final n = delta / len;
    final normal = Offset(-n.dy, n.dx);
    final halfW = 9 * scale;
    // rope sides (twisted look via dashes)
    final rope = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * scale
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8A6A45);
    canvas.drawLine(from + normal * halfW, to + normal * halfW, rope);
    canvas.drawLine(from - normal * halfW, to - normal * halfW, rope);
    final ropeHi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale
      ..color = const Color(0xFFB99868);
    canvas.drawLine(from + normal * halfW + normal * -1.2, to + normal * halfW + normal * -1.2, ropeHi);
    canvas.drawLine(from - normal * halfW + normal * -1.2, to - normal * halfW + normal * -1.2, ropeHi);
    // timber rungs
    final rungs = (len / (26 * scale)).floor().clamp(2, 9);
    for (int i = 0; i <= rungs; i++) {
      final p = from + delta * (i / rungs);
      final a = p + normal * halfW;
      final b = p - normal * halfW;
      canvas.drawLine(a, b, Paint()..style = PaintingStyle.stroke..strokeWidth = 5 * scale..strokeCap = StrokeCap.round..color = const Color(0xFFA4713F));
      canvas.drawLine(a + n * -1.2, b + n * -1.2, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6 * scale..color = const Color(0xFFC99A63));
    }
  }

  @override
  bool shouldRepaint(covariant LadderPainter old) => old.from != from || old.to != to;
}
