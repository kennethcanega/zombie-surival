import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LootPopupComponent extends TextComponent {
  LootPopupComponent({
    required super.position,
    required int money,
    required double exp,
  }) : super(
          text: '+\$$money  +${exp.toStringAsFixed(0)} XP',
          anchor: Anchor.center,
          priority: 10,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFFF176),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

  double _lifetime = 0.9;
  static const double _moveSpeed = 22;

  @override
  void update(double dt) {
    super.update(dt);

    _lifetime -= dt;
    position.y -= _moveSpeed * dt;

    if (_lifetime <= 0) {
      removeFromParent();
    }
  }
}
