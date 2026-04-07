import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../systems/attack_system.dart';
import '../zombie_survival_game.dart';

class PlayerComponent extends CircleComponent
    with HasGameReference<ZombieSurvivalGame>, DragCallbacks {
  PlayerComponent({required super.position})
      : super(
          radius: 14,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF42A5F5),
        );

  double moveSpeed = 170;
  double maxHp = 100;
  double currentHp = 100;
  double damage = 15;
  double attackCooldown = 0.45;

  final AttackSystem _attackSystem = const AttackSystem();

  Vector2 _moveDirection = Vector2.zero();
  double _attackTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isGameOver || game.isPausedForLevelUp) return;

    position += _moveDirection * moveSpeed * dt;
    _clampToWorldBounds();

    _attackTimer += dt;
    if (_attackTimer >= attackCooldown) {
      _attackTimer = 0;
      _attackSystem.meleeHitNearest(
        player: this,
        zombies: game.zombies,
        range: 95,
        damage: damage,
      );
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final delta = event.localDelta;
    if (delta.length2 > 0) {
      _moveDirection = delta.normalized();
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _moveDirection = Vector2.zero();
  }

  void takeDamage(double amount) {
    currentHp = max(0, currentHp - amount);
  }

  void resetStats() {
    moveSpeed = 170;
    maxHp = 100;
    currentHp = 100;
    damage = 15;
    attackCooldown = 0.45;
    _moveDirection = Vector2.zero();
    _attackTimer = 0;
  }

  void _clampToWorldBounds() {
    final worldSize = game.size;
    position.x = position.x.clamp(radius, worldSize.x - radius);
    position.y = position.y.clamp(radius, worldSize.y - radius);
  }
}
