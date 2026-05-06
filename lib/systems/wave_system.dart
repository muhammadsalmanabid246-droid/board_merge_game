import 'dart:math';
import 'package:flame/components.dart';
import '../components/enemies/enemy_component.dart';
import '../game/game_state.dart';

class WaveSystem extends Component {
  final _rng = Random();
  double _spawnTimer = 0;
  final List<EnemyType> _spawnQueue = [];
  bool _waitingForWaveClear = false;
  double _interWaveDelay = 0;
  static const double _spawnInterval = 1.2;
  static const double _interWaveTime = 5.0;

  @override
  void update(double dt) {
    super.update(dt);
    final gs = GameState();
    if (gs.isGameOver) return;

    if (_waitingForWaveClear) {
      if (!gs.isWaveActive) {
        _waitingForWaveClear = false;
        _interWaveDelay = _interWaveTime;
      }
      return;
    }

    if (_interWaveDelay > 0) {
      _interWaveDelay -= dt;
      return;
    }

    if (_spawnQueue.isEmpty && !gs.isWaveActive) {
      _buildNextWave();
      return;
    }

    if (_spawnQueue.isNotEmpty) {
      _spawnTimer -= dt;
      if (_spawnTimer <= 0) {
        _spawnTimer = _spawnInterval;
        final type = _spawnQueue.removeAt(0);
        parent?.add(EnemyComponent(type: type, waveScale: _waveScale));
      }
    } else {
      _waitingForWaveClear = true;
    }
  }

  void _buildNextWave() {
    final wave = GameState().wave + 1;
    final enemies = _generateEnemies(wave);
    GameState().startWave(enemies.length);
    _spawnQueue.addAll(enemies);
    _spawnTimer = 0;
  }

  double get _waveScale {
    final wave = GameState().wave;
    return 1.0 + (wave - 1) * 0.18;
  }

  List<EnemyType> _generateEnemies(int wave) {
    final list = <EnemyType>[];

    if (wave % 5 == 0) {
      // Boss wave
      list.add(EnemyType.boss);
      for (int i = 0; i < 4 + wave ~/ 5; i++) {
        list.add(EnemyType.basic);
      }
    } else {
      final base = 5 + wave * 2;
      final fastCount = (wave > 2) ? _rng.nextInt(wave.clamp(0, 6)) : 0;
      final tankCount = (wave > 4) ? _rng.nextInt((wave ~/ 3).clamp(0, 5)) : 0;

      for (int i = 0; i < base - fastCount - tankCount; i++) {
        list.add(EnemyType.basic);
      }
      for (int i = 0; i < fastCount; i++) list.add(EnemyType.fast);
      for (int i = 0; i < tankCount; i++) list.add(EnemyType.tank);
      list.shuffle(_rng);
    }
    return list;
  }

  double get interWaveDelay => _interWaveDelay;
}
