import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/merge_fortress_game.dart';
import '../game/game_state.dart';
import '../ui/game_hud.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MergeFortressGame _game;

  @override
  void initState() {
    super.initState();
    GameState().reset();
    _game = MergeFortressGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, game) =>
              GameHud(game: game as MergeFortressGame),
          'pause': (context, game) =>
              PauseOverlay(game: game as MergeFortressGame),
          'gameOver': (context, game) =>
              GameOverOverlay(game: game as MergeFortressGame),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }
}
