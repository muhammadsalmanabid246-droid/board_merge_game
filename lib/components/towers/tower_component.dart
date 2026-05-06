import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/tower_data.dart';
import '../../game/merge_fortress_game.dart';
import '../../constants.dart';
import '../enemies/enemy_component.dart';
import '../projectiles/projectile_component.dart';

class TowerComponent extends PositionComponent with HasGameReference<MergeFortressGame> {
  final TowerType type;
  int rank;
  late TowerStats stats;

  double _attackCooldown = 0;
  bool _selected = false;
  double _selectPulse = 0;
  double _shootAnim = 0;

  TowerComponent({required this.type, this.rank = 1})
      : super(
          size: Vector2.all(GameConstants.cellSize - GameConstants.cellPadding * 2),
          anchor: Anchor.topLeft,
        ) {
    stats = scaledStats(type, rank);
  }

  void select() {
    _selected = true;
    _selectPulse = 0;
  }

  void deselect() => _selected = false;
  bool get isSelected => _selected;

  @override
  void update(double dt) {
    super.update(dt);
    _attackCooldown -= dt;
    if (_selected) _selectPulse += dt * 4;
    if (_shootAnim > 0) _shootAnim -= dt * 5;

    if (_attackCooldown <= 0) {
      final target = _findTarget();
      if (target != null) {
        _fireAt(target);
        _attackCooldown = stats.attackInterval;
        _shootAnim = 1.0;
      }
    }
  }

  EnemyComponent? _findTarget() {
    if (!isMounted) return null;
    EnemyComponent? best;
    double bestProgress = -1;
    final worldCenter = absolutePosition + size / 2;
    for (final c in game.world.children) {
      if (c is EnemyComponent && !c.isDead) {
        if (c.position.distanceTo(worldCenter) <= stats.range) {
          if (c.pathProgress > bestProgress) {
            bestProgress = c.pathProgress;
            best = c;
          }
        }
      }
    }
    return best;
  }

  void _fireAt(EnemyComponent target) {
    final worldCenter = absolutePosition + size / 2;
    final projectile = ProjectileComponent(
      startPos: worldCenter,
      target: target,
      type: stats.projectileType,
      damage: stats.damage,
      slowFactor: 1.0 - stats.slowFactor,
      slowDuration: stats.slowFactor > 0 ? 2.0 : 0,
      dotDps: stats.dotDps,
      dotDuration: stats.dotDuration,
      isAoe: stats.isAoe,
      aoeRadius: stats.aoeRadius,
    );
    game.world.add(projectile);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2 - 2;

    if (_selected) {
      final pulse = (sin(_selectPulse) * 0.5 + 0.5);
      final selPaint = Paint()
        ..color = GameConstants.cellSelected.withOpacity(0.6 + pulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(cx, cy), r + 6, selPaint);
    }

    switch (type) {
      case TowerType.cannon: _drawCannon(canvas, cx, cy, r);
      case TowerType.ice:    _drawIce(canvas, cx, cy, r);
      case TowerType.poison: _drawPoison(canvas, cx, cy, r);
      case TowerType.laser:  _drawLaser(canvas, cx, cy, r);
      case TowerType.bomb:   _drawBomb(canvas, cx, cy, r);
    }

    _drawRankBadge(canvas, w, h);

    if (_shootAnim > 0) {
      final flashPaint = Paint()
        ..color = stats.color.withOpacity(_shootAnim * 0.5);
      canvas.drawCircle(Offset(cx, cy), r + 4, flashPaint);
    }
  }

  void _drawCannon(Canvas canvas, double cx, double cy, double r) {
    _drawHexagon(canvas, cx, cy, r, const Color(0xFF4A5568));
    final paint = Paint()..color = const Color(0xFF718096);
    canvas.drawCircle(Offset(cx, cy), r * 0.55, paint);
    paint.color = const Color(0xFF2D3748);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - r * 0.25), width: r * 0.35, height: r * 0.85),
        const Radius.circular(3),
      ),
      paint,
    );
    paint.color = const Color(0xFF1A202C);
    canvas.drawCircle(Offset(cx, cy - r * 0.6), r * 0.18, paint);
  }

  void _drawIce(Canvas canvas, double cx, double cy, double r) {
    _drawHexagon(canvas, cx, cy, r, const Color(0xFF1A3A5C));
    final paint = Paint()
      ..color = const Color(0xFF88CCFF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawLine(Offset(cx, cy),
          Offset(cx + cos(angle) * r * 0.65, cy + sin(angle) * r * 0.65), paint);
    }
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFBBEEFF);
    canvas.drawCircle(Offset(cx, cy), r * 0.22, paint);
  }

  void _drawPoison(Canvas canvas, double cx, double cy, double r) {
    _drawHexagon(canvas, cx, cy, r, const Color(0xFF1A3A1A));
    final paint = Paint()..color = const Color(0xFF44AA22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.1), width: r * 1.1, height: r * 1.0), paint);
    paint.color = const Color(0xFF88FF44);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(cx + (i - 1) * r * 0.3, cy + r * 0.05), r * 0.14, paint);
    }
    paint.color = const Color(0xFF66DD22);
    canvas.drawCircle(Offset(cx, cy + r * 0.65), r * 0.12, paint);
  }

  void _drawLaser(Canvas canvas, double cx, double cy, double r) {
    _drawHexagon(canvas, cx, cy, r, const Color(0xFF2A0A3A));
    final p = Paint()..color = const Color(0xFFCC44FF);
    canvas.drawCircle(Offset(cx, cy), r * 0.35, p);
    p.color = const Color(0xFF8822AA);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, p);
    p.strokeWidth = 1.5;
    p.color = const Color(0xFF440066).withOpacity(0.6);
    canvas.drawCircle(Offset(cx, cy), r * 0.7, p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFEE88FF);
    canvas.drawCircle(Offset(cx, cy - r * 0.6), r * 0.14, p);
  }

  void _drawBomb(Canvas canvas, double cx, double cy, double r) {
    _drawHexagon(canvas, cx, cy, r, const Color(0xFF3A2A0A));
    final paint = Paint()..color = const Color(0xFF222222);
    canvas.drawCircle(Offset(cx, cy + r * 0.1), r * 0.65, paint);
    paint.color = const Color(0xFF444444);
    canvas.drawCircle(Offset(cx - r * 0.2, cy - r * 0.1), r * 0.2, paint);
    paint.color = const Color(0xFFAA7722);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    final fusePath = Path()
      ..moveTo(cx, cy - r * 0.45)
      ..quadraticBezierTo(cx + r * 0.3, cy - r * 0.7, cx + r * 0.1, cy - r * 0.85);
    canvas.drawPath(fusePath, paint);
    paint.color = const Color(0xFFFFCC00);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + r * 0.1, cy - r * 0.85), 3, paint);
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3) - pi / 6;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
    paint.color = color.withOpacity(0.5);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawPath(path, paint);
  }

  void _drawRankBadge(Canvas canvas, double w, double h) {
    if (rank <= 1) return;
    final paint = Paint()..color = GameConstants.accentGold;
    final badgeX = w - 8.0;
    const badgeY = 8.0;
    canvas.drawCircle(Offset(badgeX, badgeY), 7, paint);
    final tp = TextPainter(
      text: TextSpan(
        text: '$rank',
        style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(badgeX - tp.width / 2, badgeY - tp.height / 2));
  }
}
