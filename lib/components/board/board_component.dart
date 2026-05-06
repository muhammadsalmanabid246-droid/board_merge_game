import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../game/tower_data.dart';
import '../../game/game_state.dart';
import '../towers/tower_component.dart';
import 'cell_component.dart';

class BoardComponent extends PositionComponent with DragCallbacks {
  final List<List<CellComponent>> _cells = [];

  // Drag state
  CellComponent? _dragSource;
  _DragGhost? _ghost;
  Vector2 _lastDragLocal = Vector2.zero();

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

  // ── Summon ───────────────────────────────────────────────────────────────────

  bool summonTower() {
    if (!GameState().spendMana(GameConstants.summonCost)) return false;
    final freeCells = [
      for (final row in _cells)
        for (final cell in row)
          if (!cell.hasTower) cell
    ];
    if (freeCells.isEmpty) {
      GameState().addMana(GameConstants.summonCost.toDouble());
      return false;
    }
    final rng = Random();
    final cell = freeCells[rng.nextInt(freeCells.length)];
    final type = TowerType.values[rng.nextInt(TowerType.values.length)];
    cell.placeTower(TowerComponent(type: type, rank: 1));
    return true;
  }

  // ── Drag callbacks ────────────────────────────────────────────────────────────

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = _cellAt(event.localPosition);
    if (cell?.hasTower != true) return;

    _dragSource = cell;
    _lastDragLocal = event.localPosition.clone();
    cell!.isDragging = true;

    _ghost = _DragGhost(type: cell.tower!.type, rank: cell.tower!.rank);
    _ghost!.position = absolutePosition + _lastDragLocal;
    parent?.add(_ghost!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragSource == null) return;
    // localEndPosition is already in this component's local coordinate space.
    _lastDragLocal = event.localEndPosition.clone();
    _ghost?.position = absolutePosition + _lastDragLocal;
    _refreshDropHighlights(_lastDragLocal);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finalizeDrag();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _finalizeDrag();
  }

  void _finalizeDrag() {
    if (_dragSource == null) return;

    _dragSource!.isDragging = false;
    _clearDropHighlights();

    final target = _cellAt(_lastDragLocal);
    if (target != null && target != _dragSource && _dragSource!.hasTower) {
      if (!target.hasTower) {
        _moveTower(_dragSource!, target);
      } else if (_canMerge(_dragSource!, target)) {
        _mergeTowers(_dragSource!, target);
      }
    }

    _ghost?.removeFromParent();
    _ghost = null;
    _dragSource = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  CellComponent? _cellAt(Vector2 localPos) {
    if (localPos.x < 0 || localPos.y < 0 ||
        localPos.x >= size.x || localPos.y >= size.y) return null;
    final col = (localPos.x / GameConstants.cellSize)
        .floor()
        .clamp(0, GameConstants.boardCols - 1);
    final row = (localPos.y / GameConstants.cellSize)
        .floor()
        .clamp(0, GameConstants.boardRows - 1);
    return _cells[row][col];
  }

  bool _canMerge(CellComponent a, CellComponent b) =>
      a.hasTower &&
      b.hasTower &&
      a.tower!.type == b.tower!.type &&
      a.tower!.rank == b.tower!.rank &&
      a.tower!.rank < GameConstants.maxRank;

  void _refreshDropHighlights(Vector2 localPos) {
    _clearDropHighlights();
    final hover = _cellAt(localPos);
    if (hover != null && hover != _dragSource && _dragSource?.hasTower == true) {
      hover.isDropTarget = !hover.hasTower || _canMerge(_dragSource!, hover);
    }
  }

  void _clearDropHighlights() {
    for (final row in _cells) {
      for (final cell in row) {
        cell.isDropTarget = false;
      }
    }
  }

  void _mergeTowers(CellComponent from, CellComponent into) {
    final type = from.tower!.type;
    final newRank = from.tower!.rank + 1;
    from.removeTower();
    into.removeTower();
    into.placeTower(TowerComponent(type: type, rank: newRank));
    into.setHighlight(true);
    parent?.add(_MergeFlash(position: into.absolutePosition + into.size / 2));
  }

  void _moveTower(CellComponent from, CellComponent to) {
    to.placeTower(from.removeTower()!);
  }

  // ── Board render ──────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, size.x + 8, size.y + 8),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFF0D1B2E),
    );
    super.render(canvas);
  }
}

// ── Drag ghost ────────────────────────────────────────────────────────────────

class _DragGhost extends PositionComponent {
  final TowerType type;
  final int rank;
  static const double _s = GameConstants.cellSize * 1.08;
  double _pulse = 0;

  _DragGhost({required this.type, required this.rank})
      : super(size: Vector2.all(_s), anchor: Anchor.center);

  @override
  void update(double dt) => _pulse += dt * 5;

  @override
  void render(Canvas canvas) {
    final r = _s / 2;
    final scale = 1.0 + sin(_pulse) * 0.04;

    canvas.save();
    canvas.translate(r, r);
    canvas.scale(scale, scale);
    canvas.translate(-r, -r);

    // Soft glow
    canvas.drawCircle(
      Offset(r, r),
      r + 6,
      Paint()
        ..color = _color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Hex body
    _drawHex(canvas, r, r, r - 4, _color.withOpacity(0.88));

    // Rank badge
    if (rank > 1) {
      canvas.drawCircle(
        Offset(_s - 9, 9),
        8,
        Paint()..color = GameConstants.accentGold,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '$rank',
          style: const TextStyle(
              color: Color(0xFF1A1A1A), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_s - 9 - tp.width / 2, 9 - tp.height / 2));
    }

    canvas.restore();
  }

  Color get _color => switch (type) {
        TowerType.cannon => GameConstants.cannonColor,
        TowerType.ice    => GameConstants.iceColor,
        TowerType.poison => GameConstants.poisonColor,
        TowerType.laser  => GameConstants.laserColor,
        TowerType.bomb   => GameConstants.bombColor,
      };

  void _drawHex(Canvas canvas, double cx, double cy, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * pi / 3) - pi / 6;
      final x = cx + cos(a) * r;
      final y = cy + sin(a) * r;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }
}

// ── Merge flash ───────────────────────────────────────────────────────────────

class _MergeFlash extends PositionComponent {
  double _timer = 0;
  static const double _dur = 0.5;
  _MergeFlash({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _timer += dt;
    if (_timer >= _dur) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_timer / _dur).clamp(0.0, 1.0);
    final op = (1 - p).clamp(0.0, 1.0);
    canvas.drawCircle(Offset.zero, 40.0 * p,
        Paint()
          ..color = GameConstants.accentGold.withOpacity(op)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(Offset.zero, 16.0 * p,
        Paint()..color = Colors.white.withOpacity(op * 0.5));
  }
}
