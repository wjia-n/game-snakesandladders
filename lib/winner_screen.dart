import 'dart:math';
import 'package:flutter/material.dart';
import 'audio.dart';
import 'engine.dart';
import 'game_screen.dart';
import 'snakes_theme.dart';

/// Winner celebration: storybook podium of stacked books, crowned pawn,
/// laurel wreath, paper-petal confetti, standings ledger.
class WinnerScreen extends StatefulWidget {
  final SlEngine engine;
  final int winner;
  final GameConfig config;
  const WinnerScreen({super.key, required this.engine, required this.winner, required this.config});

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _petalCtrl;
  final _rnd = Random(99);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _petalCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    SlAudio.instance.playMusic('audio/music_menu.wav');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _petalCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) SlAudio.instance.stopMusic();
    if (state == AppLifecycleState.resumed && mounted) {
      SlAudio.instance.playMusic('audio/music_menu.wav');
    }
  }

  String _ordinal(int i) {
    if (i == 0) return '1st';
    if (i == 1) return '2nd';
    if (i == 2) return '3rd';
    return '4th';
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.engine.players[widget.winner];
    final standings = widget.engine.standings(widget.winner);
    return Scaffold(
      body: ParchmentBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              // paper-petal confetti
              AnimatedBuilder(
                animation: _petalCtrl,
                builder: (_, _) => CustomPaint(
                  painter: _PetalPainter(progress: _petalCtrl.value, rnd: _rnd),
                  size: Size.infinite,
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 26),
                    // laurel + crowned pawn on book podium
                    SizedBox(
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            painter: _LaurelPainter(),
                            size: const Size(260, 250),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WoodenPawn(
                                color: StTheme.pawnColors[winner.colorIndex],
                                size: 56,
                                crowned: true,
                              ),
                              const SizedBox(height: 6),
                              _book(150, const Color(0xFF7E301E), 'TALES'),
                              _book(170, const Color(0xFF2E5F8A), 'FABLES'),
                              _book(190, const Color(0xFF4E6B34), 'LEGENDS'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Crowned Victor!', style: StTheme.title.copyWith(fontSize: 38)),
                    const SizedBox(height: 4),
                    Text('${winner.name} reaches square 100',
                        style: StTheme.body.copyWith(fontStyle: FontStyle.italic, fontSize: 16)),
                    const SizedBox(height: 18),
                    // standings ledger
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: StTheme.parchmentDeep.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: StTheme.brass, width: 1.5),
                        boxShadow: StTheme.paperShadow,
                      ),
                      child: Column(
                        children: [
                          Text('The Final Ledger', style: StTheme.titleSmall.copyWith(fontSize: 20)),
                          const SizedBox(height: 8),
                          for (int r = 0; r < standings.length; r++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: Text(_ordinal(r),
                                        style: StTheme.body.copyWith(fontWeight: FontWeight.w700)),
                                  ),
                                  WoodenPawn(
                                    color: StTheme.pawnColors[widget.engine.players[standings[r]].colorIndex],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(widget.engine.players[standings[r]].name,
                                        style: StTheme.body),
                                  ),
                                  Text('sq ${widget.engine.pos[standings[r]]}',
                                      style: StTheme.caption.copyWith(fontStyle: FontStyle.normal)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    WoodButton(
                      label: 'Play Again',
                      onTap: () {
                        SlAudio.instance.click();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => SnakesGameScreen(config: widget.config),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    WoodButton(
                      label: 'Main Menu',
                      fontSize: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      onTap: () {
                        SlAudio.instance.click();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _book(double w, Color color, String title) {
    return Container(
      width: w,
      height: 30,
      margin: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3A2413), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
      ),
      alignment: Alignment.center,
      child: Text(title,
          style: StTheme.caption.copyWith(
              color: StTheme.parchment, fontStyle: FontStyle.normal, letterSpacing: 3, fontSize: 11)),
    );
  }
}

/// Falling paper petals + gold-foil flecks.
class _PetalPainter extends CustomPainter {
  final double progress;
  final Random rnd;
  _PetalPainter({required this.progress, required this.rnd});

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      StTheme.pawnRed, StTheme.pawnYellow, StTheme.goldLeaf,
      StTheme.leaf, StTheme.pawnBlue, StTheme.parchmentDeep,
    ];
    final r = Random(99);
    for (int i = 0; i < 46; i++) {
      final seed = r.nextDouble();
      final speed = 0.25 + r.nextDouble() * 0.5;
      final y = ((progress * speed + seed) % 1.0) * (size.height + 40) - 20;
      final x = r.nextDouble() * size.width + sin((progress * 4 + seed * 9)) * 26;
      final rot = progress * 6 * (r.nextBool() ? 1 : -1) + seed * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final petal = r.nextDouble() < 0.75;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: petal ? 12 : 7, height: petal ? 8 : 7),
        Paint()..color = colors[i % colors.length].withValues(alpha: 0.75),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter old) => old.progress != progress;
}

/// Hand-painted laurel wreath behind the podium.
class _LaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;
    final rx = size.width * 0.40;
    final ry = size.height * 0.40;
    final leafPaint = Paint()..color = StTheme.leaf;
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF4E6B34);
    for (final side in [-1.0, 1.0]) {
      for (int i = 0; i < 9; i++) {
        final a = pi * (0.08 + 0.84 * i / 8);
        final px = cx + side * cos(a) * rx;
        final py = cy - sin(a) * ry;
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(side * (a - pi / 2) + side * 0.5);
        final leaf = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(9, -7, 20, 0)
          ..quadraticBezierTo(9, 7, 0, 0)
          ..close();
        canvas.drawPath(leaf, leafPaint);
        canvas.drawLine(const Offset(2, 0), const Offset(18, 0), veinPaint);
        canvas.restore();
      }
      // berries
      for (int i = 0; i < 5; i++) {
        final a = pi * (0.15 + 0.7 * i / 4);
        canvas.drawCircle(
          Offset(cx + side * cos(a) * (rx - 12), cy - sin(a) * (ry - 12)),
          3.4,
          Paint()..color = StTheme.pawnRed,
        );
      }
    }
    // bow at the bottom
    canvas.drawCircle(Offset(cx, cy + ry + 6), 6, Paint()..color = StTheme.goldLeaf);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
