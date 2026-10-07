import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const SnakesLaddersApp());

class SnakesLaddersApp extends StatelessWidget {
  const SnakesLaddersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Snakes and Ladders',
      tagline: 'Climb every ladder, dodge every snake — first to 100 wins! 🐍',
      emoji: '🐍',
      slug: 'snakesandladders',
      howToPlay: '• Tap the dice — your token hops forward automatically\n'
          '• 🪜 Land on a ladder foot to ZOOM up\n'
          '• 🐍 Land on a snake head to SLIDE down (yikes!)\n'
          '• You need the EXACT roll to land on 100\n'
          '• First to square 100 wins the crown! 🏆',
      playerOptions: const [1, 2, 3, 4],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => SnakesLaddersScreen(players: players, callbacks: cb),
    );
  }
}
