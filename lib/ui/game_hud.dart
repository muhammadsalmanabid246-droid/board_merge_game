import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../game/merge_fortress_game.dart';
import '../constants.dart';

class GameHud extends StatefulWidget {
  final MergeFortressGame game;
  const GameHud({super.key, required this.game});

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> {
  final _gs = GameState();

  @override
  void initState() {
    super.initState();
    _gs.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _gs.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _TopBar(gs: _gs, game: widget.game),
          const Spacer(),
          _BottomBar(gs: _gs, game: widget.game),
        ],
      ),
    );
  }
}

// ─── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GameState gs;
  final MergeFortressGame game;
  const _TopBar({required this.gs, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameConstants.bgDark.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(color: GameConstants.accent.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Health
          _StatChip(
            icon: Icons.favorite,
            iconColor: GameConstants.accentRed,
            value: '${gs.health}/${gs.maxHealth}',
            barValue: gs.health / gs.maxHealth,
            barColor: GameConstants.healthGreen,
          ),
          const SizedBox(width: 8),
          // Wave badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GameConstants.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameConstants.accent.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gs.wave == 0 ? 'READY' : 'WAVE ${gs.wave}',
                  style: TextStyle(
                    color: gs.isBossWave
                        ? GameConstants.accentGold
                        : GameConstants.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (gs.isBossWave)
                  const Text(
                    'BOSS',
                    style: TextStyle(
                        color: Color(0xFFFF4444),
                        fontSize: 8,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          const Spacer(),
          // Coins
          Row(
            children: [
              const Icon(Icons.monetization_on,
                  color: GameConstants.accentGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '${gs.coins}',
                style: const TextStyle(
                    color: GameConstants.accentGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Pause button
          GestureDetector(
            onTap: () => game.togglePause(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GameConstants.bgLight,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: GameConstants.accent.withOpacity(0.25)),
              ),
              child: const Icon(Icons.pause_rounded,
                  color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final double barValue;
  final Color barColor;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.barValue,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GameConstants.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              SizedBox(
                width: 50,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: barValue.clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFF333333),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final GameState gs;
  final MergeFortressGame game;
  const _BottomBar({required this.gs, required this.game});

  @override
  Widget build(BuildContext context) {
    final manaPct = (gs.mana / GameConstants.maxMana).clamp(0.0, 1.0);
    final canSummon = gs.mana >= GameConstants.summonCost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameConstants.bgDark.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: GameConstants.accent.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Merge hint
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Tap a tower to select  ·  Tap same type/rank to merge  ·  Tap empty cell to move',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 9,
                    letterSpacing: 0.3),
                textAlign: TextAlign.center,
              ),
            ),
            // Mana bar
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: GameConstants.manaBlue, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          Container(color: const Color(0xFF1A2A3A)),
                          FractionallySizedBox(
                            widthFactor: manaPct,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    GameConstants.manaBlue,
                                    GameConstants.manaBlue.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${gs.mana.toInt()}/${GameConstants.maxMana}',
                  style: const TextStyle(
                      color: GameConstants.manaBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Summon button + wave status
            Row(
              children: [
                Expanded(child: _SummonButton(canSummon: canSummon, game: game)),
                const SizedBox(width: 12),
                _WaveStatus(gs: gs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summon button ────────────────────────────────────────────────────────────

class _SummonButton extends StatelessWidget {
  final bool canSummon;
  final MergeFortressGame game;
  const _SummonButton({required this.canSummon, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canSummon ? () => game.summonTower() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: canSummon
              ? const LinearGradient(
                  colors: [Color(0xFF2A5A8A), Color(0xFF1A3A6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canSummon ? null : const Color(0xFF1A2030),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canSummon
                ? GameConstants.accent.withOpacity(0.6)
                : const Color(0xFF2A3040),
          ),
          boxShadow: canSummon
              ? [
                  BoxShadow(
                    color: GameConstants.manaBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: canSummon ? Colors.white : Colors.white24, size: 20),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUMMON',
                  style: TextStyle(
                    color: canSummon ? Colors.white : Colors.white24,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${GameConstants.summonCost} mana',
                  style: TextStyle(
                    color: canSummon
                        ? GameConstants.manaBlue.withOpacity(0.8)
                        : Colors.white24,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wave status ──────────────────────────────────────────────────────────────

class _WaveStatus extends StatelessWidget {
  final GameState gs;
  const _WaveStatus({required this.gs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 52,
      decoration: BoxDecoration(
        color: GameConstants.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameConstants.accent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            gs.isWaveActive ? Icons.shield : Icons.hourglass_empty,
            color: gs.isWaveActive
                ? GameConstants.accentRed
                : Colors.white38,
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            gs.isWaveActive ? '${gs.enemiesRemainingInWave} left' : 'READY',
            style: TextStyle(
              color: gs.isWaveActive
                  ? Colors.white70
                  : GameConstants.accent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pause overlay ────────────────────────────────────────────────────────────

class PauseOverlay extends StatelessWidget {
  final MergeFortressGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: GameConstants.bgMid,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GameConstants.accent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: GameConstants.manaBlue.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline,
                  color: GameConstants.accent, size: 48),
              const SizedBox(height: 12),
              const Text(
                'PAUSED',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4),
              ),
              const SizedBox(height: 6),
              Text(
                'WAVE ${GameState().wave}  ·  ${GameState().health} HP',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 28),
              _menuButton(
                Icons.play_arrow_rounded,
                'RESUME',
                GameConstants.accent,
                () => game.togglePause(),
              ),
              const SizedBox(height: 12),
              _menuButton(
                Icons.refresh_rounded,
                'RESTART',
                const Color(0xFF884422),
                () {
                  game.togglePause(); // unpause first so resume works
                  game.restartGame();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.65)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Game over overlay ────────────────────────────────────────────────────────

class GameOverOverlay extends StatelessWidget {
  final MergeFortressGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final gs = GameState();
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: GameConstants.bgMid,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GameConstants.accentRed.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: GameConstants.accentRed.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.castle_outlined,
                  color: GameConstants.accentRed, size: 48),
              const SizedBox(height: 8),
              const Text(
                'FORTRESS FALLEN',
                style: TextStyle(
                    color: GameConstants.accentRed,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 20),
              _scoreRow('WAVE REACHED', '${gs.wave}'),
              const SizedBox(height: 6),
              _scoreRow('COINS EARNED', '${gs.coins}'),
              const SizedBox(height: 6),
              _scoreRow('SCORE', '${gs.score}'),
              const SizedBox(height: 24),
              _btn('PLAY AGAIN', GameConstants.accent,
                  () => game.restartGame()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, letterSpacing: 0.5)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}
