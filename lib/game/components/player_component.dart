import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../systems/armor.dart';
import '../systems/attack_system.dart';
import '../systems/weapon.dart';
import '../zombie_survival_game.dart';

class PlayerComponent extends PositionComponent with HasGameReference<ZombieSurvivalGame> {
  PlayerComponent({required super.position}) : super(anchor: Anchor.center, size: Vector2.all(34));

  static const double collisionRadius = 16;

  double moveSpeed = 170;
  double maxHp = 100;
  double currentHp = 100;
  double damage = 15;

  final AttackSystem _attackSystem = const AttackSystem();

  late final PolygonComponent _bodyVisual;
  late final RectangleComponent _weaponVisual;
  RectangleComponent? _armorVisual;

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

  double get radius => collisionRadius;
  double get agility => moveSpeed;
  double get vitality => maxHp;
  double get frenzy => _fireRateMultiplier;

  WeaponSpec get currentWeapon => weaponCatalog.firstWhere((w) => w.tier == _equippedWeapon);
  ArmorSpec? get equippedArmor =>
      _equippedArmor == null ? null : armorCatalog.firstWhere((a) => a.tier == _equippedArmor);
  List<WeaponSpec> get ownedWeapons =>
      weaponCatalog.where((w) => _ownedWeapons.contains(w.tier)).toList(growable: false);
  List<ArmorSpec> get ownedArmors =>
      armorCatalog.where((a) => _ownedArmors.contains(a.tier)).toList(growable: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: collisionRadius));

    _bodyVisual = PolygonComponent(
      [
        Vector2(0, -21),
        Vector2(16, -10),
        Vector2(16, 10),
        Vector2(0, 21),
        Vector2(-16, 10),
        Vector2(-16, -10),
      ],
      paint: Paint()..color = const Color(0xFF42A5F5),
      anchor: Anchor.center,
      priority: 2,
    );
    add(_bodyVisual);

    addAll([
      RectangleComponent(
        size: Vector2.all(4),
        position: Vector2(-5, -3),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.white,
        priority: 3,
      ),
      RectangleComponent(
        size: Vector2.all(4),
        position: Vector2(5, -3),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.white,
        priority: 3,
      ),
    ]);

    _weaponVisual = RectangleComponent(
      size: Vector2(18, 4),
      anchor: Anchor.centerLeft,
      position: Vector2(10, 0),
      paint: Paint()..color = const Color(0xFFFFB74D),
      priority: 3,
    );
    add(_weaponVisual);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isGameOver || game.isPausedForLevelUp) return;

    _animTimer += dt;

    position += _moveDirection * moveSpeed * dt;
    _clampToWorldBounds();

    final walkBob = sin(_animTimer * 8) * 1.8;
    _bodyVisual.position.y = walkBob;

    final facingDirection = _currentFacingDirection();
    _weaponVisual.angle = facingDirection.screenAngle();
    _weaponVisual.position = facingDirection * 10;
    _weaponVisual.scale = Vector2(1 + currentWeapon.damageMultiplier * 0.08, 1);

    _attackTimer += dt;
    if (_attackTimer >= currentWeapon.cooldown / _fireRateMultiplier) {
      _attackTimer = 0;
      _shoot();
    }

    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
      if (_damageFlashTimer <= 0) {
        _bodyVisual.paint.color = const Color(0xFF42A5F5);
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
    final weapon = currentWeapon;
    final bulletDirection = _aimDirection.length2 > 0.001 ? _aimDirection.normalized() : _autoAimDirection();
    if (bulletDirection.length2 <= 0.0001) return;

    final muzzlePosition = position + bulletDirection * (radius + 12);
    final bullet = _attackSystem.createBulletInDirection(
      origin: muzzlePosition,
      direction: bulletDirection,
      damage: damage * weapon.damageMultiplier,
      speed: weapon.bulletSpeed,
      radius: weapon.bulletRadius,
      splashRadius: weapon.splashRadius,
      pierce: weapon.pierce,
    );

    game.addBullet(bullet);
  }

  Vector2 _autoAimDirection() {
    final target = _attackSystem.findNearestZombie(player: this, zombies: game.zombies);
    if (target == null) {
      return Vector2.zero();
    }
    return (target.position - position).normalized();
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
    _updateArmorVisual();
    return true;
  }

  bool collectArmorDrop(ArmorTier tier) {
    final added = _ownedArmors.add(tier);
    _equippedArmor ??= tier;
    _recalculateStats();
    _updateArmorVisual();
    return added;
  }

  void _updateArmorVisual() {
    _armorVisual?.removeFromParent();
    if (_equippedArmor == null) return;
    _armorVisual = RectangleComponent(
      size: Vector2(24, 16),
      anchor: Anchor.center,
      position: Vector2.zero(),
      paint: Paint()..color = const Color(0x8855C0FF),
      priority: 1,
    );
    add(_armorVisual!);
  }

  Vector2 _currentFacingDirection() {
    if (_aimDirection.length2 > 0.001) {
      return _aimDirection.normalized();
    }
    final nearestZombie = _attackSystem.findNearestZombie(player: this, zombies: game.zombies);
    if (nearestZombie != null) {
      final toZombie = nearestZombie.position - position;
      if (toZombie.length2 > 0.0001) {
        return toZombie.normalized();
      }
    }
    return Vector2(1, 0);
  }

  void takeDamage(double amount) {
    final reduction = equippedArmor?.damageReduction ?? 0;
    final reducedDamage = amount * (1 - reduction);
    currentHp = max(0, currentHp - reducedDamage);
    _bodyVisual.paint.color = const Color(0xFFEF5350);
    _damageFlashTimer = 0.3;
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
    _armorVisual?.removeFromParent();
    _bodyVisual.paint.color = const Color(0xFF42A5F5);
  }

  void _recalculateStats() {
    final armor = equippedArmor;
    final hpRatio = maxHp <= 0 ? 1 : currentHp / maxHp;
    maxHp = 100 + (armor?.hpBonus ?? 0);
    currentHp = (maxHp * hpRatio).clamp(0, maxHp);
  }

  void _clampToWorldBounds() {
    final worldSize = game.worldSize;
    position.x = position.x.clamp(radius, worldSize.x - radius);
    position.y = position.y.clamp(radius, worldSize.y - radius);
  }
}
