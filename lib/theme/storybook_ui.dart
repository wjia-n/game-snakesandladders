import 'dart:math';
import 'package:flutter/material.dart';
import 'storybook_themes.dart';

/// "Parchment & Brass Storybook Board" design system for Snakes & Ladders.
/// Vintage storybook: hand-painted parchment, carved wood, brass fittings,
/// ivory die. Pseudo-3D physical materials only — no neon, no flat Material
/// chrome. Every widget takes the active [StoryThemeDef] so the whole look
/// re-skins with the theme picker.
class Story {
  static const displayFamily = 'EBGaramond';
  static const bodyFamily = 'Newsreader';

  static TextStyle title(double size, {required StoryThemeDef t}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: t.ink,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
              color: t.goldLeaf.withValues(alpha: 0.35),
              offset: const Offset(0, 2),
              blurRadius: 1),
          const Shadow(
              color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 6),
        ],
      );

  static TextStyle titleSmall(double size, {required StoryThemeDef t}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: t.ink,
      );

  static TextStyle body(double size, {required StoryThemeDef t, Color? color}) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        color: color ?? t.ink,
        height: 1.4,
      );

  static TextStyle caption(double size, {required StoryThemeDef t}) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: t.inkSoft,
      );

  static TextStyle label(double size,
          {required StoryThemeDef t, Color? color}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? t.accentLight,
        letterSpacing: 0.8,
      );

  static TextStyle buttonLabel(double size, {required StoryThemeDef t}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: t.parchment,
        letterSpacing: 1.2,
        shadows: const [
          Shadow(
              color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 2),
        ],
      );

  static TextStyle numeral(double size, {required StoryThemeDef t}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: t.ink,
      );

  static List<BoxShadow> get woodShadow => const [
        BoxShadow(
            color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
        BoxShadow(
            color: Color(0x33FFFFFF), blurRadius: 1, offset: Offset(0, -1)),
      ];

  static List<BoxShadow> get paperShadow => const [
        BoxShadow(
            color: Color(0x4D2C1810), blurRadius: 12, offset: Offset(0, 6)),
        BoxShadow(
            color: Color(0x1A2C1810), blurRadius: 3, offset: Offset(0, 1)),
      ];

  static List<BoxShadow> brassShadow(StoryThemeDef t) => [
        const BoxShadow(
            color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3)),
        BoxShadow(
            color: t.accentLight.withValues(alpha: 0.4),
            blurRadius: 1,
            offset: const Offset(0, -1)),
      ];
}

/// Aged parchment backdrop with subtle mottling, fibres and worn edges.
class ParchmentBackdrop extends StatelessWidget {
  final Widget child;
  final StoryThemeDef t;
  const ParchmentBackdrop({super.key, required this.child, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: t.parchment,
      child: CustomPaint(
        painter: _ParchmentPainter(t),
        child: child,
      ),
    );
  }
}

class _ParchmentPainter extends CustomPainter {
  final StoryThemeDef t;
  final _rnd = Random(7);
  _ParchmentPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 26; i++) {
      final x = _rnd.nextDouble() * size.width;
      final y = _rnd.nextDouble() * size.height;
      final r = 24 + _rnd.nextDouble() * 90;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = t.woodMid.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
    final p = Paint()..color = t.inkSoft.withValues(alpha: 0.08);
    for (int i = 0; i < 140; i++) {
      canvas.drawCircle(
        Offset(_rnd.nextDouble() * size.width,
            _rnd.nextDouble() * size.height),
        0.7,
        p,
      );
    }
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.35,
          colors: [const Color(0x00000000), t.woodDark.withValues(alpha: 0.22)],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Carved-wood panel with grain, bevelled edges and theme tint.
class WoodPanel extends StatelessWidget {
  final Widget child;
  final StoryThemeDef t;
  final EdgeInsetsGeometry padding;
  final double radius;
  const WoodPanel(
      {super.key,
      required this.child,
      required this.t,
      this.padding = const EdgeInsets.all(16),
      this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: Story.woodShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _WoodPainter(base: t.woodDark, dark: t.ink, light: t.woodMid),
          child: child,
        ),
      ),
    );
  }
}

class _WoodPainter extends CustomPainter {
  final Color base;
  final Color dark;
  final Color light;
  final _rnd = Random(11);
  _WoodPainter({required this.base, required this.dark, required this.light});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
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
    canvas.drawRect(
      Offset.zero & Size(size.width, 3),
      Paint()..color = light.withValues(alpha: 0.35),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, size.height),
      Paint()..color = light.withValues(alpha: 0.28),
    );
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
  final StoryThemeDef t;
  final double fontSize;
  final double width;
  final EdgeInsetsGeometry padding;
  const WoodButton(
      {super.key,
      required this.label,
      required this.onTap,
      required this.t,
      this.fontSize = 21,
      this.width = 240,
      this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14)});

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
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: widget.padding,
        transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0.0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.t.accent, width: 2.5),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 3,
                      offset: Offset(0, 1))
                ]
              : Story.woodShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: CustomPaint(
            painter: _WoodPainter(
                base: enabled ? widget.t.woodMid : widget.t.woodDark,
                dark: widget.t.ink,
                light: widget.t.accentLight),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: Story.buttonLabel(widget.fontSize, t: widget.t),
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
  final StoryThemeDef t;
  final double size;
  const BrassRoundButton(
      {super.key,
      required this.icon,
      required this.onTap,
      required this.t,
      this.size = 46});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.accentLight, t.accent, t.accentDark],
          ),
          boxShadow: Story.brassShadow(t),
          border: Border.all(color: t.accentDark, width: 1.5),
        ),
        child: Icon(icon, color: t.ink, size: size * 0.5),
      ),
    );
  }
}

/// Wooden toggle switch on a brass mounting plate.
class StoryToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final StoryThemeDef t;
  const StoryToggle(
      {super.key, required this.value, required this.onChanged, required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 64,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: value ? t.woodMid : t.parchmentDeep,
          border: Border.all(color: t.accent, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55000000),
                blurRadius: 4,
                offset: Offset(0, 2)),
            BoxShadow(
                color: Color(0x44FFF3C4),
                blurRadius: 1,
                offset: Offset(0, -1)),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              border: Border.all(color: t.accentDark, width: 1.2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 3,
                    offset: Offset(0, 2))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carved wooden volume slider with a turned brass knob.
class StorySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final StoryThemeDef t;
  const StorySlider(
      {super.key, required this.value, required this.onChanged, required this.t});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 12,
        thumbShape: _BrassKnobShape(t),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: t.woodMid,
        inactiveTrackColor: t.parchmentDeep,
      ),
      child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
    );
  }
}

class _BrassKnobShape extends SliderComponentShape {
  final StoryThemeDef t;
  const _BrassKnobShape(this.t);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(30, 30);

  @override
  void paint(
      PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final c = context.canvas;
    c.drawCircle(
      center,
      15,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.accentLight, t.accent, t.accentDark],
        ).createShader(Rect.fromCircle(center: center, radius: 15)),
    );
    c.drawCircle(
        center,
        15,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = t.accentDark
          ..strokeWidth = 1.5);
    c.drawCircle(center + const Offset(-4, -4), 4,
        Paint()..color = const Color(0xAAFFF3C4));
    c.drawCircle(center, 4, Paint()..color = t.accentDark);
  }
}

/// Small helper: a labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final StoryThemeDef t;
  const SettingRow(
      {super.key, required this.label, required this.control, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: t.parchmentDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Story.body(16, t: t))),
          control,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Token pawn: 12 hand-painted styles, each a real physical object.
// ---------------------------------------------------------------------------
class TokenPawn extends StatelessWidget {
  final Color color;
  final double size;
  final int shape; // 0..11, see TokenShapes
  final bool crowned;
  const TokenPawn(
      {super.key,
      required this.color,
      this.size = 40,
      this.shape = 0,
      this.crowned = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.35,
      child: CustomPaint(
          painter: _PawnPainter(color: color, shape: shape, crowned: crowned)),
    );
  }
}

class _PawnPainter extends CustomPainter {
  final Color color;
  final int shape;
  final bool crowned;
  _PawnPainter(
      {required this.color, required this.shape, required this.crowned});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // soft drop shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h - w * 0.08),
          width: w * 0.9,
          height: w * 0.22),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    switch (shape) {
      case 0:
        _classicPawn(canvas, w, h);
      case 1:
        _orb(canvas, w, h);
      case 2:
        _gem(canvas, w, h);
      case 3:
        _marble(canvas, w, h);
      case 4:
        _star(canvas, w, h);
      case 5:
        _crownToken(canvas, w, h);
      case 6:
        _shield(canvas, w, h);
      case 7:
        _acorn(canvas, w, h);
      case 8:
        _leaf(canvas, w, h);
      case 9:
        _coin(canvas, w, h);
      case 10:
        _shell(canvas, w, h);
      default:
        _mushroom(canvas, w, h);
    }
    if (crowned) _crown(canvas, w, h);
  }

  void _sheen(Canvas canvas, Path body) {
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0x55FFFFFF),
            Color(0x00000000),
            Color(0x44000000)
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(body.getBounds()),
    );
  }

  void _baseRing(Canvas canvas, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.20, h - w * 0.16, w * 0.60, w * 0.07),
          const Radius.circular(4)),
      Paint()..color = const Color(0xFFB08D3E),
    );
  }

  void _classicPawn(Canvas canvas, double w, double h) {
    final body = Path()
      ..moveTo(w * 0.5 - w * 0.30, h - w * 0.10)
      ..cubicTo(w * 0.5 - w * 0.34, h * 0.62, w * 0.5 - w * 0.13, h * 0.58,
          w * 0.5 - w * 0.12, h * 0.44)
      ..cubicTo(w * 0.5 - w * 0.11, h * 0.34, w * 0.5 - w * 0.05, h * 0.32,
          w * 0.5, h * 0.32)
      ..cubicTo(w * 0.5 + w * 0.05, h * 0.32, w * 0.5 + w * 0.11, h * 0.34,
          w * 0.5 + w * 0.12, h * 0.44)
      ..cubicTo(w * 0.5 + w * 0.13, h * 0.58, w * 0.5 + w * 0.34, h * 0.62,
          w * 0.5 + w * 0.30, h - w * 0.10)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    _sheen(canvas, body);
    final headR = w * 0.20;
    final headC = Offset(w * 0.5, h * 0.20);
    canvas.drawCircle(headC, headR, Paint()..color = color);
    canvas.drawCircle(
      headC + Offset(-headR * 0.3, -headR * 0.3),
      headR * 0.45,
      Paint()..color = const Color(0x44FFFFFF),
    );
    _baseRing(canvas, w, h);
  }

  void _orb(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.42);
    final r = w * 0.38;
    canvas.drawCircle(c, r,
        Paint()..color = HSLColor.fromColor(color).withLightness(0.45).toColor());
    // wood grain rings
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
          c,
          r * i / 3.4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0x44000000));
    }
    canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.35), r * 0.4,
        Paint()..color = const Color(0x55FFFFFF));
    _baseRing(canvas, w, h);
  }

  void _gem(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.42);
    final r = w * 0.36;
    final gem = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.85, c.dy - r * 0.2)
      ..lineTo(c.dx + r * 0.5, c.dy + r * 0.8)
      ..lineTo(c.dx - r * 0.5, c.dy + r * 0.8)
      ..lineTo(c.dx - r * 0.85, c.dy - r * 0.2)
      ..close();
    canvas.drawPath(gem, Paint()..color = color);
    canvas.drawPath(
        gem,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0x66000000));
    // facets
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r * 0.8),
        Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1.4);
    canvas.drawLine(Offset(c.dx - r * 0.85, c.dy - r * 0.2),
        Offset(c.dx + r * 0.85, c.dy - r * 0.2),
        Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1.2);
    _sheen(canvas, gem);
    _baseRing(canvas, w, h);
  }

  void _marble(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.42);
    final r = w * 0.36;
    canvas.drawCircle(c, r, Paint()..color = color);
    final rnd = Random(color.toARGB32());
    for (int i = 0; i < 3; i++) {
      final a = rnd.nextDouble() * pi * 2;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * (0.3 + rnd.nextDouble() * 0.5)),
          a,
          1.6,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = const Color(0x66FFFFFF));
    }
    canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.35), r * 0.32,
        Paint()..color = const Color(0x66FFFFFF));
    _baseRing(canvas, w, h);
  }

  Path _starPath(Offset c, double r) {
    final p = Path();
    for (int i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final pt = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  void _star(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.42);
    final star = _starPath(c, w * 0.40);
    canvas.drawPath(star, Paint()..color = color);
    canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF8A6B2A));
    canvas.drawCircle(
        c + const Offset(-6, -6), 5, Paint()..color = const Color(0x66FFFFFF));
    _baseRing(canvas, w, h);
  }

  void _crownToken(Canvas canvas, double w, double h) {
    final cw = w * 0.72, cy = h * 0.30;
    final crown = Path()
      ..moveTo(w * 0.5 - cw / 2, cy + h * 0.22)
      ..lineTo(w * 0.5 - cw / 2, cy)
      ..lineTo(w * 0.5 - cw * 0.25, cy + h * 0.06)
      ..lineTo(w * 0.5, cy - h * 0.08)
      ..lineTo(w * 0.5 + cw * 0.25, cy + h * 0.06)
      ..lineTo(w * 0.5 + cw / 2, cy)
      ..lineTo(w * 0.5 + cw / 2, cy + h * 0.22)
      ..close();
    canvas.drawPath(crown, Paint()..color = color);
    canvas.drawPath(
        crown,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF8A6B2A)
          ..strokeWidth = 1.6);
    for (final dx in [-0.25, 0.0, 0.25]) {
      canvas.drawCircle(
          Offset(w * 0.5 + cw * dx, cy - (dx == 0 ? h * 0.08 : 0)), 3,
          Paint()..color = const Color(0xFFB3402E));
    }
    _sheen(canvas, crown);
    _baseRing(canvas, w, h);
  }

  void _shield(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.30);
    final r = w * 0.36;
    final shield = Path()
      ..moveTo(c.dx - r, c.dy - r * 0.5)
      ..lineTo(c.dx + r, c.dy - r * 0.5)
      ..lineTo(c.dx + r, c.dy + r * 0.3)
      ..quadraticBezierTo(c.dx + r, c.dy + r * 1.1, c.dx, c.dy + r * 1.5)
      ..quadraticBezierTo(c.dx - r, c.dy + r * 1.1, c.dx - r, c.dy + r * 0.3)
      ..close();
    canvas.drawPath(shield, Paint()..color = color);
    canvas.drawPath(
        shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFB08D3E));
    // enamel cross
    canvas.drawLine(Offset(c.dx, c.dy - r * 0.3), Offset(c.dx, c.dy + r * 0.9),
        Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 4);
    _baseRing(canvas, w, h);
  }

  void _acorn(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.48);
    final nut = Path()
      ..moveTo(c.dx, c.dy + w * 0.36)
      ..quadraticBezierTo(
          c.dx - w * 0.38, c.dy + w * 0.1, c.dx - w * 0.30, c.dy - w * 0.18)
      ..quadraticBezierTo(c.dx, c.dy - w * 0.28, c.dx + w * 0.30, c.dy - w * 0.18)
      ..quadraticBezierTo(
          c.dx + w * 0.38, c.dy + w * 0.1, c.dx, c.dy + w * 0.36)
      ..close();
    canvas.drawPath(nut, Paint()..color = color);
    _sheen(canvas, nut);
    // cap
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy - w * 0.20),
            width: w * 0.66,
            height: w * 0.22),
        Paint()..color = const Color(0xFF6B4A2F));
    canvas.drawLine(Offset(c.dx, c.dy - w * 0.30), Offset(c.dx, c.dy - w * 0.42),
        Paint()..color = const Color(0xFF4A3220)..strokeWidth = 3);
    _baseRing(canvas, w, h);
  }

  void _leaf(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.42);
    final leaf = Path()
      ..moveTo(c.dx, c.dy - w * 0.38)
      ..quadraticBezierTo(c.dx + w * 0.36, c.dy - w * 0.1, c.dx + w * 0.10,
          c.dy + w * 0.34)
      ..quadraticBezierTo(c.dx - w * 0.10, c.dy + w * 0.38, c.dx - w * 0.30,
          c.dy + w * 0.10)
      ..quadraticBezierTo(
          c.dx - w * 0.34, c.dy - w * 0.12, c.dx, c.dy - w * 0.38)
      ..close();
    canvas.drawPath(leaf, Paint()..color = color);
    canvas.drawLine(Offset(c.dx, c.dy - w * 0.34), Offset(c.dx, c.dy + w * 0.34),
        Paint()..color = const Color(0x552A3F16)..strokeWidth = 2);
    _sheen(canvas, leaf);
    _baseRing(canvas, w, h);
  }

  void _coin(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.42);
    final r = w * 0.36;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [Color(0xFFD9B45C), Color(0xFFB08D3E), Color(0xFF8A6B2A)],
          ).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
        c,
        r * 0.72,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF8A6B2A));
    // embossed initial of the paint color — draw a simple knot instead
    canvas.drawCircle(c, r * 0.3,
        Paint()..color = color.withValues(alpha: 0.85));
    _baseRing(canvas, w, h);
  }

  void _shell(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.48);
    final r = w * 0.36;
    for (int i = 0; i < 7; i++) {
      final a = pi * (0.15 + 0.7 * i / 6);
      final dir = Offset(cos(a + pi / 2), -sin(a + pi / 2));
      canvas.drawLine(
          c + dir * r * 0.15,
          c + dir * r,
          Paint()
            ..color = color
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
    }
    canvas.drawArc(
        Rect.fromCircle(center: c + Offset(0, r * 0.1), radius: r * 0.9),
        pi * 1.15,
        pi * 0.7,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0x66000000));
    _baseRing(canvas, w, h);
  }

  void _mushroom(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h * 0.40);
    // stem
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(c.dx - w * 0.10, c.dy - w * 0.05, w * 0.20, w * 0.42),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFFF1E3C3));
    // cap
    final cap = Path()
      ..moveTo(c.dx - w * 0.40, c.dy + w * 0.02)
      ..quadraticBezierTo(
          c.dx - w * 0.36, c.dy - w * 0.38, c.dx, c.dy - w * 0.40)
      ..quadraticBezierTo(
          c.dx + w * 0.36, c.dy - w * 0.38, c.dx + w * 0.40, c.dy + w * 0.02)
      ..quadraticBezierTo(c.dx, c.dy + w * 0.12, c.dx - w * 0.40, c.dy + w * 0.02)
      ..close();
    canvas.drawPath(cap, Paint()..color = color);
    // spots
    final rnd = Random(5);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
          Offset(c.dx + (rnd.nextDouble() - 0.5) * w * 0.5,
              c.dy - rnd.nextDouble() * w * 0.3),
          3.2,
          Paint()..color = const Color(0xDDF1E3C3));
    }
    _baseRing(canvas, w, h);
  }

  void _crown(Canvas canvas, double w, double h) {
    final cw = w * 0.34, cy = h * 0.04;
    final crown = Path()
      ..moveTo(w * 0.5 - cw / 2, cy + h * 0.06)
      ..lineTo(w * 0.5 - cw / 2, cy - h * 0.02)
      ..lineTo(w * 0.5 - cw * 0.25, cy + h * 0.015)
      ..lineTo(w * 0.5, cy - h * 0.045)
      ..lineTo(w * 0.5 + cw * 0.25, cy + h * 0.015)
      ..lineTo(w * 0.5 + cw / 2, cy - h * 0.02)
      ..lineTo(w * 0.5 + cw / 2, cy + h * 0.06)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFFD4A93C));
    canvas.drawPath(
        crown,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF8A6B2A)
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _PawnPainter old) =>
      old.color != color || old.shape != shape || old.crowned != crowned;
}

// ---------------------------------------------------------------------------
// Ivory die, 6 styles: body + pip colors vary, pips always burned in.
// ---------------------------------------------------------------------------
class StoryDie extends StatelessWidget {
  final int value; // 1..6, 0 = blank
  final double size;
  final int style; // 0..5, see DiceStyles
  const StoryDie(
      {super.key, required this.value, this.size = 64, this.style = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DiePainter(value: value, style: style)),
    );
  }
}

class _DiePainter extends CustomPainter {
  final int value;
  final int style;
  _DiePainter({required this.value, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(s / 2 + 3, s - 4), width: s * 0.8, height: 10),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    Color body, pip, edge;
    switch (style) {
      case 1: // Brass Noble
        body = const Color(0xFF6E5220);
        pip = const Color(0xFFF3DC8E);
        edge = const Color(0xFF8A6B2A);
      case 2: // Oak
        body = const Color(0xFFA4713F);
        pip = const Color(0xFF3A2513);
        edge = const Color(0xFF6B4A2F);
      case 3: // Marble Vein
        body = const Color(0xFFF5F2E8);
        pip = const Color(0xFF4A5A6A);
        edge = const Color(0xFFB8BCC4);
      case 4: // Obsidian
        body = const Color(0xFF1E1E24);
        pip = const Color(0xFFE8ECF5);
        edge = const Color(0xFF0C0C0E);
      case 5: // Copper Rose
        body = const Color(0xFFB87333);
        pip = const Color(0xFF3E2413);
        edge = const Color(0xFF7E4F22);
      default: // Ivory Classic
        body = const Color(0xFFF7EFDC);
        pip = const Color(0xFF4A3220);
        edge = const Color(0xFFC9B98F);
    }
    final rect =
        RRect.fromRectAndRadius(Offset.zero & Size(s, s), Radius.circular(s * 0.18));
    canvas.drawRRect(rect, Paint()..color = body);
    if (style == 0 || style == 3) {
      // aged mottling / marble veins
      final rnd = Random(value * 13 + 5);
      for (int i = 0; i < 8; i++) {
        canvas.drawCircle(
          Offset(rnd.nextDouble() * s, rnd.nextDouble() * s),
          2 + rnd.nextDouble() * 4,
          Paint()..color = const Color(0x14000000),
        );
      }
    }
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = edge,
    );
    canvas.drawLine(
      Offset(s * 0.14, s * 0.08),
      Offset(s * 0.86, s * 0.08),
      Paint()..color = const Color(0x88FFFFFF)..strokeWidth = 3,
    );
    const layouts = {
      1: [Offset(0.5, 0.5)],
      2: [Offset(0.3, 0.3), Offset(0.7, 0.7)],
      3: [
        Offset(0.28, 0.28),
        Offset(0.5, 0.5),
        Offset(0.72, 0.72)
      ],
      4: [
        Offset(0.3, 0.3),
        Offset(0.7, 0.3),
        Offset(0.3, 0.7),
        Offset(0.7, 0.7)
      ],
      5: [
        Offset(0.3, 0.3),
        Offset(0.7, 0.3),
        Offset(0.5, 0.5),
        Offset(0.3, 0.7),
        Offset(0.7, 0.7)
      ],
      6: [
        Offset(0.3, 0.28),
        Offset(0.7, 0.28),
        Offset(0.3, 0.5),
        Offset(0.7, 0.5),
        Offset(0.3, 0.72),
        Offset(0.7, 0.72)
      ],
    };
    final pips = layouts[value] ?? const <Offset>[];
    for (final o in pips) {
      final c = Offset(o.dx * s, o.dy * s);
      canvas.drawCircle(c, s * 0.075, Paint()..color = pip);
      canvas.drawCircle(c + const Offset(-1, -1), s * 0.028,
          Paint()..color = const Color(0x337A5C3E));
    }
  }

  @override
  bool shouldRepaint(covariant _DiePainter old) =>
      old.value != value || old.style != style;
}

// ---------------------------------------------------------------------------
// Hand-painted serpent and wooden ladder (theme-tinted).
// ---------------------------------------------------------------------------

/// Point along a serpent's S-curve (mirrors SnakePainter's sway) — used for
/// the slide animation path.
Offset snakePathPoint(Offset from, Offset to, double t) {
  final dir = to - from;
  final len = dir.distance;
  if (len < 1) return from;
  final n = dir / len;
  final normal = Offset(-n.dy, n.dx);
  final edge = (t == 0 || t == 1) ? 0.15 : 1.0;
  final sway = sin(t * pi * 3) * len * 0.09 * edge;
  return from + dir * t + normal * sway;
}

class SnakePainter extends CustomPainter {
  final Offset from; // head
  final Offset to; // tail
  final double scale;
  final Color base;
  final Color dark;
  final Random _rnd = Random(23);
  SnakePainter(
      {required this.from,
      required this.to,
      this.scale = 1.0,
      this.base = const Color(0xFF5E7A40),
      this.dark = const Color(0xFF3A5226)});

  @override
  void paint(Canvas canvas, Size size) {
    final dir = to - from;
    final len = dir.distance;
    if (len < 1) return;
    final n = dir / len;
    final normal = Offset(-n.dy, n.dx);
    final pts = <Offset>[];
    for (int i = 0; i <= 12; i++) {
      final tt = i / 12;
      final sway = sin(tt * pi * 3) * len * 0.09 * (i == 0 || i == 12 ? 0.15 : 1.0);
      pts.add(from + dir * tt + normal * sway);
    }
    for (int i = 0; i < pts.length; i++) {
      final tt = i / (pts.length - 1);
      final r = (10 - tt * 8.5) * scale;
      final shade = Color.lerp(base, dark, tt)!;
      canvas.drawCircle(pts[i], r, Paint()..color = shade);
    }
    for (int i = 2; i < pts.length - 2; i += 2) {
      final tt = i / (pts.length - 1);
      canvas.drawCircle(pts[i] + normal * -2 * scale,
          (10 - tt * 8.5) * scale * 0.45, Paint()..color = const Color(0x3398B06A));
    }
    final scalePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x662E4218);
    for (int i = 1; i < pts.length - 1; i++) {
      final tt = i / (pts.length - 1);
      final r = (10 - tt * 8.5) * scale * 0.7;
      canvas.drawArc(
          Rect.fromCircle(center: pts[i], radius: r), 0.4, 2.2, false, scalePaint);
    }
    for (int i = 0; i < 40; i++) {
      final tt = _rnd.nextDouble() * 0.8;
      final idx = (tt * (pts.length - 1)).floor();
      final r = (10 - tt * 8.5) * scale * 0.5;
      canvas.drawCircle(
        pts[idx] +
            Offset((_rnd.nextDouble() - 0.5) * r * 2,
                (_rnd.nextDouble() - 0.5) * r * 2),
        1.2,
        Paint()..color = const Color(0x552A3F16),
      );
    }
    final headR = 11 * scale;
    canvas.drawOval(
      Rect.fromCenter(
          center: pts.first, width: headR * 2.1, height: headR * 1.7),
      Paint()..color = base,
    );
    final eyeBase = pts.first + n * headR * 0.45;
    for (final s in [-1.0, 1.0]) {
      final e = eyeBase + normal * s * headR * 0.45;
      canvas.drawCircle(e, headR * 0.28, Paint()..color = const Color(0xFFF3E6C8));
      canvas.drawCircle(e + n * 1.2, headR * 0.13,
          Paint()..color = const Color(0xFF1A1408));
    }
    final tp = pts.first + n * headR * 1.05;
    final tongue = Path()
      ..moveTo(tp.dx, tp.dy)
      ..lineTo((tp + n * 10 * scale + normal * 4 * scale).dx,
          (tp + n * 10 * scale + normal * 4 * scale).dy)
      ..moveTo(tp.dx, tp.dy)
      ..lineTo((tp + n * 10 * scale - normal * 4 * scale).dx,
          (tp + n * 10 * scale - normal * 4 * scale).dy);
    canvas.drawPath(
        tongue,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale
          ..color = const Color(0xFFB3402E)
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant SnakePainter old) =>
      old.from != from || old.to != to || old.base != base;
}

class LadderPainter extends CustomPainter {
  final Offset from; // foot
  final Offset to; // top
  final double scale;
  final Color wood;
  final Color rope;
  LadderPainter(
      {required this.from,
      required this.to,
      this.scale = 1.0,
      this.wood = const Color(0xFFA4713F),
      this.rope = const Color(0xFF8A6A45)});

  @override
  void paint(Canvas canvas, Size size) {
    final delta = to - from;
    final len = delta.distance;
    if (len < 1) return;
    final n = delta / len;
    final normal = Offset(-n.dy, n.dx);
    final halfW = 9 * scale;
    final ropePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * scale
      ..strokeCap = StrokeCap.round
      ..color = rope;
    canvas.drawLine(from + normal * halfW, to + normal * halfW, ropePaint);
    canvas.drawLine(from - normal * halfW, to - normal * halfW, ropePaint);
    final ropeHi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale
      ..color = const Color(0xFFB99868);
    canvas.drawLine(from + normal * halfW + normal * -1.2,
        to + normal * halfW + normal * -1.2, ropeHi);
    canvas.drawLine(from - normal * halfW + normal * -1.2,
        to - normal * halfW + normal * -1.2, ropeHi);
    final rungs = (len / (26 * scale)).floor().clamp(2, 9);
    for (int i = 0; i <= rungs; i++) {
      final p = from + delta * (i / rungs);
      final a = p + normal * halfW;
      final b = p - normal * halfW;
      canvas.drawLine(
          a,
          b,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * scale
            ..strokeCap = StrokeCap.round
            ..color = wood);
      canvas.drawLine(
          a + n * -1.2,
          b + n * -1.2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 * scale
            ..color = const Color(0xFFC99A63));
    }
  }

  @override
  bool shouldRepaint(covariant LadderPainter old) =>
      old.from != from || old.to != to;
}
