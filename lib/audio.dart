import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central audio for Snakes & Ladders: SFX + looping parlour music,
/// with persisted toggles and volume. All sounds are synthesized WAVs
/// matching the game's physical identity (ivory die, wood, rope, brass).
class SlAudio {
  SlAudio._();
  static final SlAudio instance = SlAudio._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  bool _ready = false;
  String? _currentTrack;

  Future<void> init() async {
    if (_ready) return;
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool('sl_music') ?? true;
    sfxOn = p.getBool('sl_sfx') ?? true;
    volume = p.getDouble('sl_vol') ?? 0.8;
    await _music.setReleaseMode(ReleaseMode.loop);
    _ready = true;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('sl_music', musicOn);
    await p.setBool('sl_sfx', sfxOn);
    await p.setDouble('sl_vol', volume);
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    await _save();
    if (!v) {
      await _music.stop();
      _currentTrack = null;
    }
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    await _save();
    await _music.setVolume(volume * 0.55);
  }

  Future<void> playMusic(String asset) async {
    if (!musicOn) return;
    if (_currentTrack == asset) return;
    _currentTrack = asset;
    try {
      await _music.setVolume(volume * 0.55);
      await _music.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    try {
      await _music.stop();
    } catch (_) {}
  }

  Future<void> _play(String asset, {double vol = 1.0}) async {
    if (!sfxOn) return;
    try {
      await _sfx.setVolume((volume * vol).clamp(0.0, 1.0));
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  // ---- Game vocabulary (fire-and-forget; safe in async contexts) ----
  void click() => unawaited(_play('audio/click.wav'));
  void dice() => unawaited(_play('audio/dice.wav'));
  void hop() => unawaited(_play('audio/hop.wav', vol: 0.8));
  void ladder() => unawaited(_play('audio/ladder.wav'));
  void snake() => unawaited(_play('audio/snake.wav'));
  void invalid() => unawaited(_play('audio/invalid.wav', vol: 0.8));
  void start() => unawaited(_play('audio/start.wav'));
  void win() => unawaited(_play('audio/win.wav'));
  void lose() => unawaited(_play('audio/lose.wav'));

  void dispose() {
    _sfx.dispose();
    _music.dispose();
  }
}
