import 'package:flutter/material.dart';

class GameConstants {
  static const double gameWidth = 400.0;
  static const double gameHeight = 760.0;

  // Board — fills full width with a 5px margin each side
  static const int boardCols = 5;
  static const int boardRows = 5;
  static const double cellSize = 76.0; // (400 - 10*2) / 5
  static const double cellPadding = 3.0;
  static const double boardLeft = 10.0;  // (400 - 5*76) / 2 = 10
  static const double boardTop = 285.0;

  // Path (enemies travel above the board)
  static const double pathY1 = 218.0;
  static const double pathY2 = 155.0;

  // Player
  static const int maxHealth = 20;
  static const int startMana = 30;
  static const int maxMana = 100;
  static const double manaRegen = 4.0;
  static const int summonCost = 12;

  // Merging
  static const int maxRank = 5;

  // Colors
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgMid = Color(0xFF121929);
  static const Color bgLight = Color(0xFF1A2540);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentRed = Color(0xFFFF4444);
  static const Color manaBlue = Color(0xFF4A90E2);
  static const Color healthGreen = Color(0xFF44DD66);
  static const Color pathColor = Color(0xFF2A3A28);
  static const Color cellEmpty = Color(0xFF1E2D45);
  static const Color cellHighlight = Color(0xFF2A4A6A);
  static const Color cellSelected = Color(0xFF3A7ABB);
  static const Color dropTargetColor = Color(0xFF44BB88);

  // Tower colors
  static const Color cannonColor = Color(0xFF8B9DC3);
  static const Color iceColor = Color(0xFF88CCFF);
  static const Color poisonColor = Color(0xFF66DD44);
  static const Color laserColor = Color(0xFFCC44FF);
  static const Color bombColor = Color(0xFFFF8822);
}
