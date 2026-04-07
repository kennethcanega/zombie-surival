import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../zombie_survival_game.dart';
import 'player_component.dart';

class ZombieComponent extends CircleComponent with HasGameReference<ZombieSurvivalGame> {
  ZombieComponent({
    required super.position,
    required this.player,
    required this.maxHp,
    required this.speed,
    required this.contactDamage,
  })  : currentHp = maxHp,
        super(
          radius: 12,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF66BB6A),
        );

  final PlayerComponent player;
  final double speed;
  final double maxHp;
  final double contactDamage;

  double currentHp;
  double _touchDamageCooldown = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isGameOver || game.isPausedForLevelUp) {
      return;
    }

    final toPlayer = player.position - position;
    if (toPlayer.length2 > 0.0001) {
      position += toPlayer.normalized() * speed * dt;
    }

    _touchDamageCooldown -= dt;
    if (_touchDamageCooldown <= 0 && position.distanceTo(player.position) <= radius + player.radius + 2) {
      player.takeDamage(contactDamage);
      _touchDamageCooldown = 0.5;
    }
  }

  void takeDamage(double amount) {
    currentHp -= amount;
    if (currentHp <= 0) {
      game.onZombieKilled(this);
      removeFromParent();
    }
  }
}
