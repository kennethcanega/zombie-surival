import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../zombie_survival_game.dart';
import 'player_component.dart';

class ZombieComponent extends CircleComponent with HasGameReference<ZombieSurvivalGame> {
  static const Color _baseColor = Color(0xFF66BB6A);

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
          paint: Paint()..color = _baseColor,
        );

  final PlayerComponent player;
  final double speed;
  final double maxHp;
  final double contactDamage;

  double currentHp;
  double _touchDamageCooldown = 0;
  double _damageFlashTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final width = radius * 2.2;
    final hpPercent = (currentHp / maxHp).clamp(0, 1).toDouble();
    final barRect = Rect.fromLTWH(-width / 2, -radius - 10, width, 4);

    canvas.drawRect(barRect, Paint()..color = Colors.black54);
    canvas.drawRect(
      Rect.fromLTWH(barRect.left, barRect.top, width * hpPercent, barRect.height),
      Paint()..color = const Color(0xFFE53935),
    );
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

    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
      if (_damageFlashTimer <= 0) {
        paint.color = _baseColor;
      }
    }
  }

  void takeDamage(double amount) {
    paint.color = const Color(0xFFE53935);
    _damageFlashTimer = 0.5;
    currentHp -= amount;
    if (currentHp <= 0) {
      game.onZombieKilled(this);
      removeFromParent();
    }
  }
}
