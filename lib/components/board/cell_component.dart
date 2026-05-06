import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../towers/tower_component.dart';

class CellComponent extends PositionComponent {
  final int col;
  final int row;
  TowerComponent? tower;

  bool _highlighted = false;
  double _highlightTimer = 0;

  CellComponent({required this.col, required this.row})
      : super(
          size: Vector2.all(GameConstants.cellSize),
          anchor: Anchor.topLeft,
        );

  void setHighlight(bool v) {
    _highlighted = v;
    _highlightTimer = v ? 0.4 : 0;
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
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Background
    Color bg;
    if (tower != null && tower!.isSelected) {
      bg = GameConstants.cellSelected.withOpacity(0.6);
    } else if (_highlighted) {
      bg = GameConstants.cellHighlight;
    } else {
      bg = GameConstants.cellEmpty;
    }

    final paint = Paint()..color = bg;
    canvas.drawRRect(rr, paint);

    // Border
    paint.color = _highlighted
        ? GameConstants.accent.withOpacity(0.7)
        : const Color(0xFF2A3D5A);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawRRect(rr, paint);

    // Empty cell indicator
    if (!hasTower) {
      paint.color = const Color(0xFF2A3D5A).withOpacity(0.4);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), 4, paint);
    }
  }
}
