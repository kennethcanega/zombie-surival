import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../zombie_survival_game.dart';

class BulletComponent extends CircleComponent with HasGameReference<ZombieSurvivalGame> {
  BulletComponent({
    required super.position,
    required this.direction,
    required this.damage,
    required this.speed,
    required super.radius,
    required this.splashRadius,
    required this.pierce,
  }) : super(
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFFFFEE58),
        );

  final Vector2 direction;
  final double damage;
  final double speed;
  final double splashRadius;
  int pierce;

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isGameOver || game.isPausedForLevelUp) {
      return;
    }

    position += direction * speed * dt;

    if (position.x < -20 ||
        position.y < -20 ||
        position.x > game.size.x + 20 ||
        position.y > game.size.y + 20) {
      removeFromParent();
      return;
    }

    for (final zombie in List.of(game.zombies)) {
      if (zombie.position.distanceTo(position) > zombie.radius + radius) {
        continue;
      }

      if (splashRadius > 0) {
        for (final splashZombie in List.of(game.zombies)) {
          if (splashZombie.position.distanceTo(position) <= splashRadius) {
            splashZombie.takeDamage(damage);
          }
        }
        removeFromParent();
        return;
      }

      zombie.takeDamage(damage);
      pierce -= 1;
      if (pierce <= 0) {
        removeFromParent();
      }
      return;
    }

    return;
  }
}
