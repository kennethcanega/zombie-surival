import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ExplosionComponent extends PositionComponent {
  ExplosionComponent({required super.position, this.baseRadius = 12}) : super(anchor: Anchor.center, priority: 20);

  final double baseRadius;
  double _time = 0;
  static const double _duration = 0.28;

  @override
  void render(Canvas canvas) {
    final t = (_time / _duration).clamp(0, 1);
    final radius = baseRadius + t * 30;
    final alpha = (255 * (1 - t)).toInt();
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Color.fromARGB(alpha, 255, 193, 7),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.55,
      Paint()..color = Color.fromARGB((alpha * 0.6).toInt(), 255, 241, 118),
    );
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
