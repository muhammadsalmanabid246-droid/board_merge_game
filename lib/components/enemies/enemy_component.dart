import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/path_data.dart';
import '../../game/game_state.dart';

enum EnemyType { basic, fast, tank, boss }

class EnemyComponent extends PositionComponent {
  final EnemyType type;
  late double maxHp;
  late double hp;
  late double speed;
  late int coinReward;
  late int damage;

  int _waypointIndex = 1;

  // Status effects
  double slowFactor = 1.0; // multiplied with speed
  double slowTimer = 0.0;
  double poisonDps = 0.0;
  double poisonTimer = 0.0;

  bool _isDead = false;
  bool get isDead => _isDead;

  // Visual
  late Color _bodyColor;
  late Color _outlineColor;
  late double _radius;

  static const Map<EnemyType, _EnemyConfig> _configs = {
    EnemyType.basic: _EnemyConfig(hp: 80, speed: 65, coins: 1, damage: 1,
        color: Color(0xFFFF4444), outline: Color(0xFFCC0000), radius: 12),
    EnemyType.fast: _EnemyConfig(hp: 45, speed: 120, coins: 1, damage: 1,
        color: Color(0xFFFF8844), outline: Color(0xFFCC5500), radius: 9),
    EnemyType.tank: _EnemyConfig(hp: 300, speed: 40, coins: 3, damage: 2,
        color: Color(0xFF884422), outline: Color(0xFF442211), radius: 18),
    EnemyType.boss: _EnemyConfig(hp: 1500, speed: 28, coins: 15, damage: 5,
        color: Color(0xFF8822AA), outline: Color(0xFF440066), radius: 26),
  };

  EnemyComponent({required this.type, double waveScale = 1.0})
      : super(anchor: Anchor.center) {
    final cfg = _configs[type]!;
    maxHp = cfg.hp * waveScale;
    hp = maxHp;
    speed = cfg.speed;
    coinReward = cfg.coins;
    damage = cfg.damage;
    _bodyColor = cfg.color;
    _outlineColor = cfg.outline;
    _radius = cfg.radius;
    size = Vector2.all(_radius * 2.2);
  }

  @override
  void onMount() {
    super.onMount();
    // Start at beginning of path
    position = enemyPathWaypoints[0].clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDead) return;

    // Slow effect
    if (slowTimer > 0) {
      slowTimer -= dt;
      if (slowTimer <= 0) slowFactor = 1.0;
    }

    // Poison
    if (poisonTimer > 0) {
      poisonTimer -= dt;
      takeDamage(poisonDps * dt);
    }

    _moveAlongPath(dt);
  }

  void _moveAlongPath(double dt) {
    if (_waypointIndex >= enemyPathWaypoints.length) return;

    double distToMove = speed * slowFactor * dt;

    while (distToMove > 0 && _waypointIndex < enemyPathWaypoints.length) {
      final target = enemyPathWaypoints[_waypointIndex];
      final remaining = target.distanceTo(position);

      if (distToMove >= remaining) {
        position = target.clone();
        distToMove -= remaining;
        _waypointIndex++;
        if (_waypointIndex >= enemyPathWaypoints.length) {
          _reachEnd();
          return;
        }
      } else {
        final dir = (target - position).normalized();
        position += dir * distToMove;
        distToMove = 0;
      }
    }
  }

  void _reachEnd() {
    GameState().enemyLeaked(damage);
    removeFromParent();
  }

  void takeDamage(double amount) {
    if (_isDead) return;
    hp -= amount;
    if (hp <= 0) {
      hp = 0;
      _isDead = true;
      GameState().enemyDefeated(coinReward);
      removeFromParent();
    }
  }

  void applySlow(double factor, double duration) {
    slowFactor = min(slowFactor, factor);
    slowTimer = max(slowTimer, duration);
  }

  void applyPoison(double dps, double duration) {
    poisonDps = max(poisonDps, dps);
    poisonTimer = max(poisonTimer, duration);
  }

  // Progress along path 0..1 (for targeting priority)
  double get pathProgress {
    if (_waypointIndex >= enemyPathWaypoints.length) return 1.0;
    return _waypointIndex / enemyPathWaypoints.length.toDouble();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _outlineColor;
    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), _radius + 2, paint);

    paint.color = _bodyColor;
    if (slowTimer > 0) {
      paint.color = Color.lerp(_bodyColor, const Color(0xFF88CCFF), 0.5)!;
    }
    if (poisonTimer > 0) {
      paint.color = Color.lerp(_bodyColor, const Color(0xFF44FF44), 0.4)!;
    }
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), _radius, paint);

    // Boss crown spikes
    if (type == EnemyType.boss) {
      _drawBossCrown(canvas);
    }

    // Health bar
    _drawHealthBar(canvas);
  }

  void _drawBossCrown(Canvas canvas) {
    final p = Paint()..color = const Color(0xFFFFD700);
    final cx = size.x / 2;
    final cy = size.y / 2;
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (i * 2 * pi / 5);
      final x = cx + cos(angle) * (_radius + 5);
      final y = cy + sin(angle) * (_radius + 5);
      canvas.drawCircle(Offset(x, y), 3, p);
    }
  }

  void _drawHealthBar(Canvas canvas) {
    const barH = 4.0;
    final barW = size.x;
    final barY = size.y - barH;
    final bgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(Rect.fromLTWH(0, barY, barW, barH), bgPaint);
    final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
    final hpColor = hpRatio > 0.5
        ? const Color(0xFF44DD66)
        : hpRatio > 0.25
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF3333);
    final fgPaint = Paint()..color = hpColor;
    canvas.drawRect(Rect.fromLTWH(0, barY, barW * hpRatio, barH), fgPaint);
  }
}

class _EnemyConfig {
  final double hp;
  final double speed;
  final int coins;
  final int damage;
  final Color color;
  final Color outline;
  final double radius;
  const _EnemyConfig({
    required this.hp, required this.speed, required this.coins,
    required this.damage, required this.color, required this.outline,
    required this.radius,
  });
}
