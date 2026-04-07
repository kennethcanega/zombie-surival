import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/zombie_survival_game.dart';
import 'game/ui/game_over_overlay.dart';
import 'game/ui/hud_overlay.dart';
import 'game/ui/level_up_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final game = ZombieSurvivalGame();
  runApp(GameApp(game: game));
}

class GameApp extends StatelessWidget {
  const GameApp({required this.game, super.key});

  final ZombieSurvivalGame game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget<ZombieSurvivalGame>(
          game: game,
          overlayBuilderMap: {
            HudOverlay.id: (context, game) => HudOverlay(game: game),
            LevelUpOverlay.id: (context, game) => LevelUpOverlay(game: game),
            GameOverOverlay.id: (context, game) => GameOverOverlay(game: game),
          },
          initialActiveOverlays: const [HudOverlay.id],
        ),
      ),
    );
  }
}
