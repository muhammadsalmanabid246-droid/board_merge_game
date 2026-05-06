import 'package:flame/components.dart';
import '../constants.dart';

// Enemy path waypoints - enemies travel left to right across the top section
// The winding path creates interesting tower placement strategy
final List<Vector2> enemyPathWaypoints = [
  Vector2(-60, GameConstants.pathY1),
  Vector2(80, GameConstants.pathY1),
  Vector2(80, GameConstants.pathY2),
  Vector2(160, GameConstants.pathY2),
  Vector2(160, GameConstants.pathY1),
  Vector2(240, GameConstants.pathY1),
  Vector2(240, GameConstants.pathY2),
  Vector2(320, GameConstants.pathY2),
  Vector2(320, GameConstants.pathY1),
  Vector2(GameConstants.gameWidth + 60, GameConstants.pathY1),
];

double get pathLength {
  double total = 0;
  for (int i = 1; i < enemyPathWaypoints.length; i++) {
    total += enemyPathWaypoints[i].distanceTo(enemyPathWaypoints[i - 1]);
  }
  return total;
}
