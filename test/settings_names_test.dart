import 'package:flutter_test/flutter_test.dart';
import 'package:snakesandladders/engine/sl_engine.dart';
import 'package:snakesandladders/services/settings_service.dart';

/// Regression tests for the player-name persistence bug (2026-10-09):
///
/// Player names were stored with SharedPreferences.setStringList, which on
/// Android is backed by an UNORDERED StringSet — so after an app restart the
/// four names came back in arbitrary order and renames appeared "not saved".
/// Names are now stored as one order-preserving JSON string
/// (snakesandladders_player_names_json). These tests cover the encode/decode
/// round-trip plus the engine reload path, without needing platform channels.
void main() {
  test('names survive an encode/decode round-trip in exact slot order', () {
    const names = ['Wajiha', 'Zara', 'Ali', 'Bot Bob'];
    final decoded = StorySettings.decodePlayerNames(
      StorySettings.encodePlayerNames(names),
    );
    expect(decoded, names);
    // Slot order is what matters: each index must map to the same player.
    for (int i = 0; i < 4; i++) {
      expect(decoded[i], names[i]);
    }
  });

  test('decode falls back to defaults on missing or corrupt data', () {
    expect(
      StorySettings.decodePlayerNames(null),
      StorySettings.defaultNames,
    );
    expect(
      StorySettings.decodePlayerNames('definitely not json'),
      StorySettings.defaultNames,
    );
    expect(
      StorySettings.decodePlayerNames('["only","two"]'),
      StorySettings.defaultNames,
    );
    expect(
      StorySettings.decodePlayerNames('{"a":1}'),
      StorySettings.defaultNames,
    );
  });

  test('blank entries fall back to that slot\'s default name', () {
    final decoded = StorySettings.decodePlayerNames(
        '["Wajiha","","  ","Miss Penelope"]');
    expect(decoded, ['Wajiha', 'Master Edwin', 'Captain Algernon',
      'Miss Penelope']);
  });

  test('engine rebuilt after "restart" shows the persisted names', () {
    // Simulate: user renamed slot 0, app restarted, setup screen + engine
    // rebuilt from the persisted value.
    const renamed = ['Wajiha', 'Master Edwin', 'Captain Algernon',
      'Miss Penelope'];
    final persisted = StorySettings.decodePlayerNames(
      StorySettings.encodePlayerNames(renamed),
    );
    final engine = SlEngine(
      players: [
        for (int i = 0; i < persisted.length; i++)
          SlPlayer(name: persisted[i], colorIndex: i, isBot: i == 3),
      ],
      testMode: true,
    )..drainTest(); // complete the roll-off synchronously
    addTearDown(engine.dispose);
    expect(engine.players[0].name, 'Wajiha');
    expect(engine.players[1].name, 'Master Edwin');
    expect(engine.players[2].name, 'Captain Algernon');
    expect(engine.players[3].name, 'Miss Penelope');
    // The rename also reaches turn narration (roll-off winner banner).
    expect(engine.banner, contains(engine.players[engine.turn].name));
  });
}
