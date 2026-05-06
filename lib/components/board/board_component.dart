import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../game/tower_data.dart';
import '../../game/game_state.dart';
import '../towers/tower_component.dart';
import 'cell_component.dart';

class BoardComponent extends PositionComponent with TapCallbacks {
  final List<List<CellComponent>> _cells = [];
  CellComponent? _selectedCell;

  BoardComponent()
      : super(
          position: Vector2(GameConstants.boardLeft, GameConstants.boardTop),
          size: Vector2(
            GameConstants.boardCols * GameConstants.cellSize,
            GameConstants.boardRows * GameConstants.cellSize,
          ),
        );

  @override
  Future<void> onLoad() async {
    for (int row = 0; row < GameConstants.boardRows; row++) {
      final rowList = <CellComponent>[];
      for (int col = 0; col < GameConstants.boardCols; col++) {
        final cell = CellComponent(col: col, row: row)
          ..position = Vector2(
            col * GameConstants.cellSize,
            row * GameConstants.cellSize,
          );
        add(cell);
        rowList.add(cell);
      }
      _cells.add(rowList);
    }
  }

  /// Try to summon a random tower in a free cell. Returns false if no free cells.
  bool summonTower() {
    if (!GameState().spendMana(GameConstants.summonCost)) return false;

    final freeCells = <CellComponent>[];
    for (final row in _cells) {
      for (final cell in row) {
        if (!cell.hasTower) freeCells.add(cell);
      }
    }
    if (freeCells.isEmpty) {
      // Refund mana
      GameState().addMana(GameConstants.summonCost.toDouble());
      return false;
    }

    final rng = Random();
    final cell = freeCells[rng.nextInt(freeCells.length)];
    final type = TowerType.values[rng.nextInt(TowerType.values.length)];
    cell.placeTower(TowerComponent(type: type, rank: 1));
    return true;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final localPos = event.localPosition;
    final col = (localPos.x / GameConstants.cellSize).floor()
        .clamp(0, GameConstants.boardCols - 1);
    final row = (localPos.y / GameConstants.cellSize).floor()
        .clamp(0, GameConstants.boardRows - 1);
    final tapped = _cells[row][col];

    if (_selectedCell == null) {
      // Select a tower
      if (tapped.hasTower) {
        _selectedCell = tapped;
        tapped.tower!.select();
      }
    } else {
      if (tapped == _selectedCell) {
        // Deselect
        _deselect();
      } else if (tapped.hasTower &&
          tapped.tower!.type == _selectedCell!.tower!.type &&
          tapped.tower!.rank == _selectedCell!.tower!.rank &&
          _selectedCell!.tower!.rank < GameConstants.maxRank) {
        // Merge
        _mergeTowers(_selectedCell!, tapped);
      } else if (!tapped.hasTower) {
        // Move tower to empty cell
        _moveTower(_selectedCell!, tapped);
      } else {
        // Switch selection
        _deselect();
        if (tapped.hasTower) {
          _selectedCell = tapped;
          tapped.tower!.select();
        }
      }
    }
  }

  void _mergeTowers(CellComponent from, CellComponent into) {
    final fromType = from.tower!.type;
    final newRank = from.tower!.rank + 1;
    from.removeTower();
    into.removeTower();
    into.placeTower(TowerComponent(type: fromType, rank: newRank));
    into.setHighlight(true);
    _selectedCell = null;
    // Spawn merge particles
    parent?.add(_MergeFlash(position: into.absolutePosition + into.size / 2));
  }

  void _moveTower(CellComponent from, CellComponent to) {
    final t = from.removeTower()!;
    to.placeTower(t);
    t.deselect();
    _selectedCell = null;
  }

  void _deselect() {
    _selectedCell?.tower?.deselect();
    _selectedCell = null;
  }

  bool get isFull {
    for (final row in _cells) {
      for (final cell in row) {
        if (!cell.hasTower) return false;
      }
    }
    return true;
  }

  @override
  void render(Canvas canvas) {
    // Board background
    final bgPaint = Paint()..color = const Color(0xFF0D1B2E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, size.x + 8, size.y + 8),
        const Radius.circular(12),
      ),
      bgPaint,
    );
    super.render(canvas);
  }
}

class _MergeFlash extends PositionComponent {
  double _timer = 0;
  static const double _duration = 0.5;

  _MergeFlash({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _timer += dt;
    if (_timer >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_timer / _duration).clamp(0.0, 1.0);
    final r = 40.0 * progress;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = GameConstants.accentGold.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset.zero, r, paint);
    paint.color = const Color(0xFFFFFFFF).withOpacity(opacity * 0.5);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, r * 0.4, paint);
  }
}
