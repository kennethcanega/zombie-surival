import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class BloodSplatterComponent extends PositionComponent {
  BloodSplatterComponent({
    required super.position,
    required this.intensity,
    this.bigBurst = false,
  }) : super(anchor: Anchor.center, priority: 12);

  final int intensity;
  final bool bigBurst;
  final Random _random = Random();
  late final List<_Drop> _drops;

  double _time = 0;
  static const double _duration = 0.36;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final count = bigBurst ? intensity + 8 : intensity;
    _drops = List.generate(count, (_) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = (bigBurst ? 80 : 50) + _random.nextDouble() * (bigBurst ? 80 : 45);
      return _Drop(
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        size: (bigBurst ? 5.5 : 3.0) + _random.nextDouble() * 3.5,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    final t = (_time / _duration).clamp(0, 1);
    final alpha = (220 * (1 - t)).toInt();
    final paint = Paint()..color = Color.fromARGB(alpha, 183, 28, 28);
    for (final drop in _drops) {
      final p = drop.velocity * _time;
      canvas.drawOval(Rect.fromCenter(center: Offset(p.x, p.y), width: drop.size * 1.5, height: drop.size), paint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= _duration) {
      removeFromParent();
    }
  }
}

class _Drop {
  _Drop({required this.velocity, required this.size});

  final Vector2 velocity;
  final double size;
}
