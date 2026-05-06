import 'package:flutter/foundation.dart';
import '../constants.dart';

class GameState extends ChangeNotifier {
  static final GameState _instance = GameState._internal();
  factory GameState() => _instance;
  GameState._internal();

  int health = GameConstants.maxHealth;
  int maxHealth = GameConstants.maxHealth;
  double mana = GameConstants.startMana.toDouble();
  int coins = 0;
  int wave = 0;
  int score = 0;
  bool isGameOver = false;
  bool isWaveActive = false;
  int enemiesRemainingInWave = 0;

  void reset() {
    health = GameConstants.maxHealth;
    maxHealth = GameConstants.maxHealth;
    mana = GameConstants.startMana.toDouble();
    coins = 0;
    wave = 0;
    score = 0;
    isGameOver = false;
    isWaveActive = false;
    enemiesRemainingInWave = 0;
    notifyListeners();
  }

  bool spendMana(int amount) {
    if (mana >= amount) {
      mana -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }

  void addMana(double amount) {
    mana = (mana + amount).clamp(0, GameConstants.maxMana.toDouble());
    notifyListeners();
  }

  void addCoins(int amount) {
    coins += amount;
    score += amount * 10;
    notifyListeners();
  }

  void takeDamage(int amount) {
    health = (health - amount).clamp(0, maxHealth);
    if (health <= 0) {
      isGameOver = true;
    }
    notifyListeners();
  }

  void startWave(int enemyCount) {
    wave++;
    isWaveActive = true;
    enemiesRemainingInWave = enemyCount;
    notifyListeners();
  }

  void enemyDefeated(int coinReward) {
    enemiesRemainingInWave--;
    addCoins(coinReward);
    if (enemiesRemainingInWave <= 0) {
      isWaveActive = false;
      notifyListeners();
    }
  }

  void enemyLeaked(int damage) {
    enemiesRemainingInWave--;
    takeDamage(damage);
    if (enemiesRemainingInWave <= 0) {
      isWaveActive = false;
    }
    notifyListeners();
  }

  bool get isBossWave => wave % 5 == 0 && wave > 0;
}
