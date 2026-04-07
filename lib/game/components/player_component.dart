import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../systems/armor.dart';
import '../systems/attack_system.dart';
import '../systems/weapon.dart';
import '../zombie_survival_game.dart';

class PlayerComponent extends CircleComponent with HasGameReference<ZombieSurvivalGame> {
  static const Color _baseColor = Color(0xFF42A5F5);

  PlayerComponent({required super.position})
      : super(
          radius: 14,
          anchor: Anchor.center,
          paint: Paint()..color = _baseColor,
        );

  double moveSpeed = 170;
  double maxHp = 100;
  double currentHp = 100;
  double damage = 15;

  final AttackSystem _attackSystem = const AttackSystem();

  Vector2 _moveDirection = Vector2.zero();
  Vector2 _aimDirection = Vector2.zero();
  double _attackTimer = 0;
  double _damageFlashTimer = 0;
  double _fireRateMultiplier = 1;
  double _animTimer = 0;

  final Set<WeaponTier> _ownedWeapons = {WeaponTier.pistol};
  WeaponTier _equippedWeapon = WeaponTier.pistol;

  final Set<ArmorTier> _ownedArmors = {};
  ArmorTier? _equippedArmor;

  WeaponSpec get currentWeapon => weaponCatalog.firstWhere((w) => w.tier == _equippedWeapon);
  ArmorSpec? get equippedArmor => _equippedArmor == null
      ? null
      : armorCatalog.firstWhere((a) => a.tier == _equippedArmor);
  List<WeaponSpec> get ownedWeapons =>
      weaponCatalog.where((w) => _ownedWeapons.contains(w.tier)).toList(growable: false);
  List<ArmorSpec> get ownedArmors =>
      armorCatalog.where((a) => _ownedArmors.contains(a.tier)).toList(growable: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final walkBob = sin(_animTimer * 8) * 1.5;
    canvas.save();
    canvas.translate(0, walkBob);
    super.render(canvas);

    final gunLength = 14 + currentWeapon.damageMultiplier * 2;
    final angle = _aimDirection.length2 > 0.001 ? _aimDirection.screenAngle() : 0.0;
    canvas.save();
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(6, -2, gunLength, 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFB74D),
    );
    canvas.restore();

    if (equippedArmor != null) {
      canvas.drawCircle(
        Offset.zero,
        radius + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFB0BEC5),
      );
    }

    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isGameOver || game.isPausedForLevelUp) return;

    _animTimer += dt;

    position += _moveDirection * moveSpeed * dt;
    _clampToWorldBounds();

    _attackTimer += dt;
    if (_attackTimer >= currentWeapon.cooldown / _fireRateMultiplier) {
      _attackTimer = 0;
      _shoot();
    }

    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
      if (_damageFlashTimer <= 0) {
        paint.color = _baseColor;
      }
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

  bool isWeaponOwned(WeaponTier tier) => _ownedWeapons.contains(tier);

  bool buyWeapon(WeaponTier tier, int money) {
    final spec = weaponCatalog.firstWhere((w) => w.tier == tier);
    if (_ownedWeapons.contains(tier) || money < spec.cost) {
      return false;
    }
    _ownedWeapons.add(tier);
    return true;
  }

  bool equipWeapon(WeaponTier tier) {
    if (!_ownedWeapons.contains(tier)) return false;
    _equippedWeapon = tier;
    return true;
  }

  void improveFireRate() {
    _fireRateMultiplier = (_fireRateMultiplier * 1.12).clamp(1, 2.5);
  }

  bool isArmorOwned(ArmorTier tier) => _ownedArmors.contains(tier);

  bool buyArmor(ArmorTier tier, int money) {
    final spec = armorCatalog.firstWhere((a) => a.tier == tier);
    if (_ownedArmors.contains(tier) || money < spec.cost) {
      return false;
    }
    _ownedArmors.add(tier);
    return true;
  }

  bool equipArmor(ArmorTier tier) {
    if (!_ownedArmors.contains(tier)) return false;
    _equippedArmor = tier;
    _recalculateStats();
    return true;
  }

  bool collectArmorDrop(ArmorTier tier) {
    final added = _ownedArmors.add(tier);
    _equippedArmor ??= tier;
    _recalculateStats();
    return added;
  }

  void takeDamage(double amount) {
    final reduction = equippedArmor?.damageReduction ?? 0;
    final reducedDamage = amount * (1 - reduction);
    currentHp = max(0, currentHp - reducedDamage);
    paint.color = const Color(0xFFE53935);
    _damageFlashTimer = 0.5;
  }

  void resetStats() {
    moveSpeed = 170;
    maxHp = 100;
    currentHp = 100;
    damage = 15;
    _moveDirection = Vector2.zero();
    _aimDirection = Vector2.zero();
    _attackTimer = 0;
    _damageFlashTimer = 0;
    _fireRateMultiplier = 1;
    _animTimer = 0;
    _ownedWeapons
      ..clear()
      ..add(WeaponTier.pistol);
    _equippedWeapon = WeaponTier.pistol;
    _ownedArmors.clear();
    _equippedArmor = null;
    paint.color = _baseColor;
  }

  void _recalculateStats() {
    final armor = equippedArmor;
    final hpRatio = maxHp <= 0 ? 1 : currentHp / maxHp;
    maxHp = 100 + (armor?.hpBonus ?? 0);
    currentHp = (maxHp * hpRatio).clamp(0, maxHp);
  }

  void _clampToWorldBounds() {
    final worldSize = game.size;
    position.x = position.x.clamp(radius, worldSize.x - radius);
    position.y = position.y.clamp(radius, worldSize.y - radius);
  }
}
