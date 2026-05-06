import 'dart:math';
import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../constants.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _floatAnim = Tween(begin: -6.0, end: 6.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.bgDark,
      body: Stack(
        children: [
          const _StarField(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: Listenable.merge([_floatAnim, _pulseAnim]),
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Transform.scale(
                      scale: _pulseAnim.value,
                      child: _buildLogo(),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                _buildPlayButton(),
                const SizedBox(height: 16),
                _buildHowToPlay(),
                const Spacer(flex: 1),
                const _VersionTag(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Tower icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                GameConstants.accent.withOpacity(0.3),
                GameConstants.bgDark.withOpacity(0),
              ],
            ),
          ),
          child: CustomPaint(painter: _TowerIconPainter()),
        ),
        const SizedBox(height: 16),
        const Text(
          'MERGE',
          style: TextStyle(
            color: GameConstants.accent,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            height: 1,
          ),
        ),
        const Text(
          'FORTRESS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 6,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tower Defense · Merge Strategy',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const GameScreen())),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [GameConstants.accent, Color(0xFF2A9D94)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: GameConstants.accent.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'PLAY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToPlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameConstants.bgLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GameConstants.accent.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOW TO PLAY',
                style: TextStyle(
                    color: GameConstants.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            _tip(Icons.add_circle_outline, 'Spend mana to summon random towers'),
            _tip(Icons.merge_type, 'Tap two matching towers to merge them'),
            _tip(Icons.shield_outlined, 'Towers auto-attack nearby enemies'),
            _tip(Icons.warning_amber_outlined, 'Boss appears every 5 waves'),
          ],
        ),
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _VersionTag extends StatelessWidget {
  const _VersionTag();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'v1.0  •  MVP',
        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
      ),
    );
  }
}

// Animated star background
class _StarField extends StatefulWidget {
  const _StarField();
  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _ctrl.addListener(() => setState(() {}));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(_ctrl.value),
      size: MediaQuery.of(context).size,
    );
  }
}

class _StarPainter extends CustomPainter {
  final double t;
  _StarPainter(this.t);
  static final _rng = Random(42);
  static final _stars = List.generate(80, (i) => Offset(
    _rng.nextDouble(), _rng.nextDouble()));
  static final _sizes = List.generate(80, (i) => _rng.nextDouble() * 1.5 + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < _stars.length; i++) {
      final twinkle = sin((t * 2 * pi * 3) + i * 1.7) * 0.5 + 0.5;
      paint.color = Colors.white.withOpacity(twinkle * 0.6 + 0.1);
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        _sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _TowerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = GameConstants.accent;

    // Simple tower shape
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 5), width: 28, height: 36), paint);
    paint.color = GameConstants.accent.withOpacity(0.8);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
          Rect.fromLTWH(cx - 14 + i * 11, cy - 24, 8, 12), paint);
    }
    // Cannon barrel
    paint.color = const Color(0xFF2D3748);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 10), width: 8, height: 20),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
