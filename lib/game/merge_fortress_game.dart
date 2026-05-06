import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../components/board/board_component.dart';
import '../systems/wave_system.dart';
import 'game_state.dart';
import 'path_data.dart';

class MergeFortressGame extends FlameGame with TapCallbacks {
  late BoardComponent _board;
  late WaveSystem _waveSystem;
  final GameState _gs = GameState();

  BoardComponent get board => _board;
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void togglePause() {
    if (_isPaused) {
      _isPaused = false;
      overlays.remove('pause');
      resumeEngine();
    } else {
      _isPaused = true;
      overlays.add('pause');
      pauseEngine();
    }
  }

  @override
  Color backgroundColor() => GameConstants.bgDark;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize =
        Vector2(GameConstants.gameWidth, GameConstants.gameHeight);
    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(PathRenderer());
    world.add(BackgroundRenderer());

    _board = BoardComponent();
    world.add(_board);

    _waveSystem = WaveSystem();
    world.add(_waveSystem);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gs.isGameOver) {
      overlays.add('gameOver');
      pauseEngine();
      return;
    }
    _gs.addMana(GameConstants.manaRegen * dt);
    _spawnManaParticle(dt);
  }

  void summonTower() {
    if (_gs.isGameOver) return;
    _board.summonTower();
  }

  void restartGame() {
    _isPaused = false;
    _gs.reset();
    world.children.whereType<_ManaOrb>().toList().forEach((c) => c.removeFromParent());
    _board.removeFromParent();
    _waveSystem.removeFromParent();
    _board = BoardComponent();
    _waveSystem = WaveSystem();
    world.add(_board);
    world.add(_waveSystem);
    overlays.remove('gameOver');
    overlays.remove('pause');
    resumeEngine();
  }

  double _manaParticleTimer = 0;
  void _spawnManaParticle(double dt) {
    _manaParticleTimer += dt;
    if (_manaParticleTimer > 1.2) {
      _manaParticleTimer = 0;
      world.add(_ManaOrb());
    }
  }
}

class BackgroundRenderer extends Component {
  @override
  int get priority => -10;

  @override
  void render(Canvas canvas) {
    // Top section gradient (enemy area)
    final topRect =
        Rect.fromLTWH(0, 60, GameConstants.gameWidth, GameConstants.boardTop - 60);
    canvas.drawRect(topRect, Paint()..color = const Color(0xFF0C1520));

    // Bottom section (board area)
    final bottomRect = Rect.fromLTWH(
      0, GameConstants.boardTop - 10,
      GameConstants.gameWidth,
      GameConstants.gameHeight - GameConstants.boardTop + 10,
    );
    canvas.drawRect(bottomRect, Paint()..color = const Color(0xFF08111E));

    // Divider line
    final divPaint = Paint()
      ..color = GameConstants.accent.withOpacity(0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, GameConstants.boardTop - 10),
      Offset(GameConstants.gameWidth, GameConstants.boardTop - 10),
      divPaint,
    );
  }
}

class PathRenderer extends Component {
  @override
  int get priority => -5;

  @override
  void render(Canvas canvas) {
    // Road shadow
    final roadShadow = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_buildPath(), roadShadow);

    // Road surface
    final roadPaint = Paint()
      ..color = const Color(0xFF1E2E1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_buildPath(), roadPaint);

    // Road border
    final borderPaint = Paint()
      ..color = const Color(0xFF2A3E28).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_buildPath(), borderPaint);

    // Road surface (on top)
    canvas.drawPath(_buildPath(), roadPaint);

    // Center dashes
    final dashPaint = Paint()
      ..color = const Color(0xFF3A5A38).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_buildPath(), dashPaint);

    // Entry/exit markers
    _drawEntryArrow(canvas);
    _drawExitCastle(canvas);
  }

  Path _buildPath() {
    final path = Path();
    final pts = enemyPathWaypoints;
    path.moveTo(pts[0].x, pts[0].y);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }
    return path;
  }

  void _drawEntryArrow(Canvas canvas) {
    final paint = Paint()..color = GameConstants.accent.withOpacity(0.7);
    final p = enemyPathWaypoints[0];
    final path = Path()
      ..moveTo(p.x + 8, p.y - 8)
      ..lineTo(p.x + 20, p.y)
      ..lineTo(p.x + 8, p.y + 8)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawExitCastle(Canvas canvas) {
    final last = enemyPathWaypoints.last;
    final cx = last.x - 20;
    final cy = last.y;

    // Castle body
    var paint = Paint()..color = const Color(0xFF2A3A5A);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 2), width: 24, height: 28), paint);

    // Battlements
    paint.color = const Color(0xFF3A4A6A);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
          Rect.fromLTWH(cx - 10 + i * 9, cy - 16, 6, 8), paint);
    }

    // Gate
    paint.color = const Color(0xFF1A2A44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 6), width: 8, height: 12),
          const Radius.circular(4)),
      paint,
    );

    // Health indicator
    paint.color = GameConstants.healthGreen;
    final healthFrac = GameState().health / GameConstants.maxHealth;
    canvas.drawRect(
      Rect.fromLTWH(cx - 12, cy - 28, 24 * healthFrac, 4),
      paint,
    );
    paint.color = const Color(0xFF333333);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(cx - 12, cy - 28, 24, 4), paint);
  }
}

class _ManaOrb extends PositionComponent {
  static final _rng = Random();
  double _life = 0;
  final double _duration;
  final double _startX;
  final double _startY;
  final double _drift;

  _ManaOrb()
      : _duration = 1.2 + _rng.nextDouble() * 0.8,
        _startX = GameConstants.boardLeft +
            _rng.nextDouble() * GameConstants.boardCols * GameConstants.cellSize,
        _startY = GameConstants.boardTop +
            _rng.nextDouble() * GameConstants.boardRows * GameConstants.cellSize,
        _drift = (_rng.nextDouble() - 0.5) * 24,
        super(anchor: Anchor.center) {
    position = Vector2(
      GameConstants.boardLeft +
          _rng.nextDouble() * GameConstants.boardCols * GameConstants.cellSize,
      GameConstants.boardTop +
          _rng.nextDouble() * GameConstants.boardRows * GameConstants.cellSize,
    );
  }

  @override
  void update(double dt) {
    _life += dt;
    if (_life >= _duration) {
      removeFromParent();
      return;
    }
    final progress = _life / _duration;
    position = Vector2(_startX + _drift * progress, _startY - 50 * progress);
  }

  @override
  void render(Canvas canvas) {
    final progress = (_life / _duration).clamp(0.0, 1.0);
    final opacity = sin(progress * pi).clamp(0.0, 1.0);
    final paint = Paint()..color = GameConstants.manaBlue.withOpacity(opacity * 0.6);
    canvas.drawCircle(Offset.zero, 3, paint);
    paint.color = const Color(0xFFAADDFF).withOpacity(opacity * 0.3);
    canvas.drawCircle(Offset.zero, 5, paint);
  }
}
