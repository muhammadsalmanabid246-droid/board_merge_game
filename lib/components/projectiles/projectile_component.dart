import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/merge_fortress_game.dart';
import '../enemies/enemy_component.dart';
import '../../game/tower_data.dart';

class ProjectileComponent extends PositionComponent with HasGameReference<MergeFortressGame> {
  final ProjectileType type;
  final double damage;
  final double speed;
  final double slowFactor;
  final double slowDuration;
  final double dotDps;
  final double dotDuration;
  final bool isAoe;
  final double aoeRadius;

  WeakReference<EnemyComponent>? _target;
  bool _hit = false;

  ProjectileComponent({
    required Vector2 startPos,
    required EnemyComponent target,
    required this.type,
    required this.damage,
    this.speed = 320,
    this.slowFactor = 1.0,
    this.slowDuration = 0,
    this.dotDps = 0,
    this.dotDuration = 0,
    this.isAoe = false,
    this.aoeRadius = 0,
  }) : super(position: startPos, anchor: Anchor.center, size: Vector2.all(12)) {
    _target = WeakReference(target);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hit) return;
    final target = _target?.target;
    if (target == null || target.isDead || !target.isMounted) {
      removeFromParent();
      return;
    }
    final dir = target.position - position;
    final dist = dir.length;
    if (dist < 12) {
      _onHit(target);
      return;
    }
    position += dir.normalized() * speed * dt;
  }

  void _onHit(EnemyComponent primary) {
    if (_hit) return;
    _hit = true;

    if (isAoe) {
      for (final c in game.world.children) {
        if (c is EnemyComponent && c.position.distanceTo(position) <= aoeRadius) {
          _applyEffects(c);
        }
      }
      game.world.add(
          _ExplosionEffect(position: position.clone(), radius: aoeRadius, color: _color));
    } else {
      _applyEffects(primary);
    }
    removeFromParent();
  }

  void _applyEffects(EnemyComponent e) {
    e.takeDamage(damage);
    if (slowFactor < 1.0 && slowDuration > 0) e.applySlow(slowFactor, slowDuration);
    if (dotDps > 0 && dotDuration > 0) e.applyPoison(dotDps, dotDuration);
  }

  Color get _color {
    switch (type) {
      case ProjectileType.bullet:     return const Color(0xFFCCCCCC);
      case ProjectileType.iceBolt:    return const Color(0xFF88CCFF);
      case ProjectileType.poisonBlob: return const Color(0xFF66FF44);
      case ProjectileType.laserBeam:  return const Color(0xFFDD44FF);
      case ProjectileType.bombShell:  return const Color(0xFFFF8822);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_hit) return;
    final color = _color;
    final paint = Paint()..color = color;
    const c = Offset(6, 6);

    switch (type) {
      case ProjectileType.bullet:
        canvas.drawCircle(c, 4, paint);
        break;
      case ProjectileType.iceBolt:
        _drawStar(canvas, 6, 6, 5, 3, 6, paint);
        break;
      case ProjectileType.poisonBlob:
        canvas.drawCircle(c, 5, paint);
        break;
      case ProjectileType.laserBeam:
        canvas.drawCircle(c, 4, paint);
        paint.color = color.withOpacity(0.4);
        canvas.drawCircle(c, 7, paint);
        break;
      case ProjectileType.bombShell:
        paint.color = const Color(0xFF222222);
        canvas.drawCircle(c, 5, paint);
        paint.color = const Color(0xFFFF6600);
        canvas.drawCircle(const Offset(6, 3), 2, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double outerR,
      double innerR, int points, Paint paint) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * pi / points) - pi / 2;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

class _ExplosionEffect extends PositionComponent {
  final Color color;
  final double maxRadius;
  double _timer = 0;
  static const double _duration = 0.35;

  _ExplosionEffect({required Vector2 position, required double radius, required this.color})
      : maxRadius = radius,
        super(position: position, anchor: Anchor.center, size: Vector2.all(4));

  @override
  void update(double dt) {
    _timer += dt;
    if (_timer >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _timer / _duration;
    final r = maxRadius * progress;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    var paint = Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset.zero, r, paint);
    paint = Paint()
      ..color = color.withOpacity(opacity * 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, r * 0.6, paint);
  }
}
