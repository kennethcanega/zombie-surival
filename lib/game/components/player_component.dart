import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../systems/attack_system.dart';
import '../systems/weapon.dart';
import '../zombie_survival_game.dart';

class PlayerComponent extends CircleComponent with HasGameReference<ZombieSurvivalGame> {
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

  final AttackSystem _attackSystem = const AttackSystem();

  Vector2 _moveDirection = Vector2.zero();
  Vector2 _aimDirection = Vector2.zero();
  double _attackTimer = 0;
  int _weaponIndex = 0;
  double _fireRateMultiplier = 1;

  WeaponSpec get currentWeapon => weaponProgression[_weaponIndex];
  int get weaponIndex => _weaponIndex;

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
    if (_attackTimer >= currentWeapon.cooldown / _fireRateMultiplier) {
      _attackTimer = 0;
      _shoot();
    }
  }

  void setMoveDirection(Vector2 direction) {
    _moveDirection = direction;
  }

  void setAimDirection(Vector2 direction) {
    _aimDirection = direction;
  }

  void _shoot() {
    final target = _attackSystem.findNearestZombie(player: this, zombies: game.zombies);
    if (target == null) return;

    final weapon = currentWeapon;
    final bullet = _attackSystem.createBullet(
      player: this,
      target: target,
      damage: damage * weapon.damageMultiplier,
      speed: weapon.bulletSpeed,
      radius: weapon.bulletRadius,
      splashRadius: weapon.splashRadius,
      pierce: weapon.pierce,
    );

    if (_aimDirection.length2 > 0.001) {
      bullet.direction.setFrom(_aimDirection.normalized());
    }

    game.addBullet(bullet);
  }

  bool canUpgradeWeapon() => _weaponIndex < weaponProgression.length - 1;

  int nextWeaponCost() {
    if (!canUpgradeWeapon()) return 0;
    return weaponProgression[_weaponIndex + 1].cost;
  }

  void improveFireRate() {
    _fireRateMultiplier = (_fireRateMultiplier * 1.12).clamp(1, 2.5);
  }

  bool tryUpgradeWeapon() {
    if (!canUpgradeWeapon()) return false;
    _weaponIndex += 1;
    return true;
  }

  void takeDamage(double amount) {
    currentHp = max(0, currentHp - amount);
  }

  void resetStats() {
    moveSpeed = 170;
    maxHp = 100;
    currentHp = 100;
    damage = 15;
    _moveDirection = Vector2.zero();
    _aimDirection = Vector2.zero();
    _attackTimer = 0;
    _weaponIndex = 0;
    _fireRateMultiplier = 1;
  }

  void _clampToWorldBounds() {
    final worldSize = game.size;
    position.x = position.x.clamp(radius, worldSize.x - radius);
    position.y = position.y.clamp(radius, worldSize.y - radius);
  }
}
