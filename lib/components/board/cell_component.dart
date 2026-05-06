import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../towers/tower_component.dart';

class CellComponent extends PositionComponent {
  final int col;
  final int row;
  TowerComponent? tower;

  bool isDragging = false;   // source cell being dragged from
  bool isDropTarget = false; // valid drop destination during drag

  bool _highlighted = false;
  double _highlightTimer = 0;

  CellComponent({required this.col, required this.row})
      : super(
          size: Vector2.all(GameConstants.cellSize),
          anchor: Anchor.topLeft,
        );

  void setHighlight(bool v) {
    _highlighted = v;
    _highlightTimer = v ? 0.5 : 0;
  }

  bool get hasTower => tower != null;

  void placeTower(TowerComponent t) {
    tower?.removeFromParent();
    tower = t;
    t.position = Vector2(GameConstants.cellPadding, GameConstants.cellPadding);
    add(t);
  }

  TowerComponent? removeTower() {
    final t = tower;
    tower?.removeFromParent();
    tower = null;
    return t;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_highlightTimer > 0) {
      _highlightTimer -= dt;
      if (_highlightTimer <= 0) _highlighted = false;
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // Background fill
    final Color bg;
    if (isDropTarget) {
      bg = GameConstants.dropTargetColor.withOpacity(0.25);
    } else if (isDragging) {
      bg = GameConstants.cellEmpty.withOpacity(0.5);
    } else if (_highlighted) {
      bg = GameConstants.cellHighlight;
    } else {
      bg = GameConstants.cellEmpty;
    }
    canvas.drawRRect(rr, Paint()..color = bg);

    // Border
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDropTarget ? 2.0 : 1.5;
    if (isDropTarget) {
      borderPaint.color = GameConstants.dropTargetColor;
    } else if (_highlighted) {
      borderPaint.color = GameConstants.accent.withOpacity(0.7);
    } else {
      borderPaint.color = const Color(0xFF2A3D5A);
    }
    canvas.drawRRect(rr, borderPaint);

    // Drop-target inner glow
    if (isDropTarget) {
      canvas.drawRRect(
        rr,
        Paint()
          ..color = GameConstants.dropTargetColor.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );
    }

    // Empty cell dot
    if (!hasTower && !isDragging) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        3.5,
        Paint()..color = const Color(0xFF2A3D5A).withOpacity(0.5),
      );
    }

    // Dim overlay when this cell is the drag source
    if (isDragging && hasTower) {
      canvas.drawRRect(
        rr,
        Paint()..color = Colors.black.withOpacity(0.45),
      );
    }
  }
}
