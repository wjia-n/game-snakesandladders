import 'package:flutter/material.dart';
import 'audio.dart';
import 'settings.dart';
import 'snakes_theme.dart';

/// Settings: parchment panel on a wooden parlour table — wooden toggles with
/// brass bases for Music and SFX, carved wooden volume slider with brass knob,
/// brass back arrow, and the parlour records ledger.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _audio = SlAudio.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: StTheme.mahoganyDeep,
        child: CustomPaint(
          painter: _TablePainter(),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      BrassRoundButton(
                        icon: Icons.arrow_back,
                        size: 44,
                        onTap: () {
                          _audio.click();
                          Navigator.of(context).pop();
                        },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Settings', style: StTheme.titleSmall.copyWith(color: StTheme.parchment)),
                            Text('Parlour Preferences & Audio',
                                style: StTheme.caption.copyWith(color: StTheme.parchmentDeep)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                      decoration: BoxDecoration(
                        color: StTheme.parchment,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: StTheme.brass, width: 2),
                        boxShadow: StTheme.paperShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row(
                            title: 'Victorian Melodies',
                            subtitle: 'Pianoforte & parlour strings',
                            control: WoodToggle(
                              value: _audio.musicOn,
                              onChanged: (v) async {
                                _audio.click();
                                await _audio.setMusic(v);
                                if (v) _audio.playMusic('audio/music_menu.wav');
                                setState(() {});
                              },
                            ),
                          ),
                          const _Rule(),
                          _row(
                            title: 'Dice & Token Clicks',
                            subtitle: 'Carved wood & brass clatter',
                            control: WoodToggle(
                              value: _audio.sfxOn,
                              onChanged: (v) async {
                                await _audio.setSfx(v);
                                _audio.click();
                                setState(() {});
                              },
                            ),
                          ),
                          const _Rule(),
                          Text('Gramophone Volume', style: StTheme.titleSmall.copyWith(fontSize: 20)),
                          Text('How loudly the parlour sings',
                              style: StTheme.caption),
                          const SizedBox(height: 4),
                          WoodSlider(
                            value: _audio.volume,
                            onChanged: (v) async {
                              await _audio.setVolume(v);
                              setState(() {});
                            },
                          ),
                          const _Rule(),
                          Text('Parlour Records', style: StTheme.titleSmall.copyWith(fontSize: 20)),
                          const SizedBox(height: 8),
                          for (int i = 0; i < 4; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  WoodenPawn(color: StTheme.pawnColors[i], size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(StTheme.pawnNames[i], style: StTheme.body)),
                                  Text('${SlSettings.instance.wins[i]} crowns',
                                      style: StTheme.body.copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'Largest climb: ${SlSettings.instance.biggestClimb} squares\n'
                            'Longest slide: ${SlSettings.instance.longestSlide} squares\n'
                            'Tales completed: ${SlSettings.instance.gamesPlayed}',
                            style: StTheme.caption.copyWith(fontStyle: FontStyle.normal, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row({required String title, required String subtitle, required Widget control}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: StTheme.titleSmall.copyWith(fontSize: 20)),
              Text(subtitle, style: StTheme.caption),
            ],
          ),
        ),
        control,
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1.5,
      color: StTheme.brass.withValues(alpha: 0.5),
    );
  }
}

/// Dark mahogany parlour table with grain.
class _TablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = StTheme.mahoganyDeep);
    // soft warm pool of daylight
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.3,
          colors: [const Color(0xFF6B4A2F).withValues(alpha: 0.55), const Color(0x00000000)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
