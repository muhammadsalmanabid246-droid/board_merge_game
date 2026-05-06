import 'package:flutter/material.dart';
import '../constants.dart';

enum TowerType { cannon, ice, poison, laser, bomb }

enum ProjectileType { bullet, iceBolt, poisonBlob, laserBeam, bombShell }

class TowerStats {
  final double damage;
  final double attackInterval; // seconds
  final double range;
  final ProjectileType projectileType;
  final bool isAoe;
  final double aoeRadius;
  final double slowFactor; // 0=no slow, 0.5=50% speed
  final double dotDps; // damage over time per second
  final double dotDuration;
  final Color color;
  final String label;

  const TowerStats({
    required this.damage,
    required this.attackInterval,
    required this.range,
    required this.projectileType,
    this.isAoe = false,
    this.aoeRadius = 0,
    this.slowFactor = 0,
    this.dotDps = 0,
    this.dotDuration = 0,
    required this.color,
    required this.label,
  });
}

const Map<TowerType, TowerStats> baseTowerStats = {
  TowerType.cannon: TowerStats(
    damage: 22,
    attackInterval: 1.1,
    range: 280,
    projectileType: ProjectileType.bullet,
    color: GameConstants.cannonColor,
    label: 'Cannon',
  ),
  TowerType.ice: TowerStats(
    damage: 10,
    attackInterval: 1.4,
    range: 260,
    projectileType: ProjectileType.iceBolt,
    slowFactor: 0.45,
    color: GameConstants.iceColor,
    label: 'Ice',
  ),
  TowerType.poison: TowerStats(
    damage: 5,
    attackInterval: 1.0,
    range: 240,
    projectileType: ProjectileType.poisonBlob,
    isAoe: true,
    aoeRadius: 45,
    dotDps: 8,
    dotDuration: 3.0,
    color: GameConstants.poisonColor,
    label: 'Poison',
  ),
  TowerType.laser: TowerStats(
    damage: 12,
    attackInterval: 0.18,
    range: 310,
    projectileType: ProjectileType.laserBeam,
    color: GameConstants.laserColor,
    label: 'Laser',
  ),
  TowerType.bomb: TowerStats(
    damage: 55,
    attackInterval: 2.4,
    range: 250,
    projectileType: ProjectileType.bombShell,
    isAoe: true,
    aoeRadius: 70,
    color: GameConstants.bombColor,
    label: 'Bomb',
  ),
};

// Rank multipliers [rank1, rank2, rank3, rank4, rank5]
const List<double> rankDamageMultiplier = [1.0, 1.7, 2.8, 4.5, 7.0];
const List<double> rankRangeMultiplier = [1.0, 1.1, 1.22, 1.36, 1.5];
const List<double> rankIntervalMultiplier = [1.0, 0.9, 0.8, 0.7, 0.6];

TowerStats scaledStats(TowerType type, int rank) {
  final base = baseTowerStats[type]!;
  final i = rank - 1;
  return TowerStats(
    damage: base.damage * rankDamageMultiplier[i],
    attackInterval: base.attackInterval * rankIntervalMultiplier[i],
    range: base.range * rankRangeMultiplier[i],
    projectileType: base.projectileType,
    isAoe: base.isAoe,
    aoeRadius: base.aoeRadius * rankRangeMultiplier[i],
    slowFactor: base.slowFactor,
    dotDps: base.dotDps * rankDamageMultiplier[i],
    dotDuration: base.dotDuration,
    color: base.color,
    label: base.label,
  );
}

TowerType randomTowerType() {
  final types = TowerType.values;
  return types[(DateTime.now().millisecondsSinceEpoch % types.length)];
}
