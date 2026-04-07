import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../systems/armor.dart';
import '../systems/attack_system.dart';
import '../systems/weapon.dart';
import '../zombie_survival_game.dart';

class PlayerComponent extends CircleComponent with HasGameReference<ZombieSurvivalGame> {
  PlayerComponent({required super.position})
      : super(
          radius: 16,
          anchor: Anchor.center,
          paint: Paint()..color = Colors.transparent,
        );

  double moveSpeed = 170;
  double maxHp = 100;
  double currentHp = 100;
  double damage = 15;

  final AttackSystem _attackSystem = const AttackSystem();

  late final SvgComponent _bodyVisual;
  late final SvgComponent _weaponVisual;
  SvgComponent? _armorVisual;

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
  ArmorSpec? get equippedArmor =>
      _equippedArmor == null ? null : armorCatalog.firstWhere((a) => a.tier == _equippedArmor);
  List<WeaponSpec> get ownedWeapons =>
      weaponCatalog.where((w) => _ownedWeapons.contains(w.tier)).toList(growable: false);
  List<ArmorSpec> get ownedArmors =>
      armorCatalog.where((a) => _ownedArmors.contains(a.tier)).toList(growable: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());

    final playerSvg = await Svg.load('assets/svg/player.svg');
    _bodyVisual = SvgComponent(
      svg: playerSvg,
      size: Vector2.all(40),
      anchor: Anchor.center,
      position: Vector2.zero(),
    );
    add(_bodyVisual);

    final weaponSvg = await Svg.load('assets/svg/weapon.svg');
    _weaponVisual = SvgComponent(
      svg: weaponSvg,
      size: Vector2(30, 22),
      anchor: Anchor.centerLeft,
      position: Vector2(10, 0),
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

    final aimAngle = _aimDirection.length2 > 0.001 ? _aimDirection.screenAngle() : 0.0;
    _weaponVisual.angle = aimAngle;
    _weaponVisual.scale = Vector2.all(1 + currentWeapon.damageMultiplier * 0.08);

    _attackTimer += dt;
    if (_attackTimer >= currentWeapon.cooldown / _fireRateMultiplier) {
      _attackTimer = 0;
      _shoot();
    }

    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
      if (_damageFlashTimer <= 0) {
        opacity = 1;
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
    Svg.load('assets/svg/armor.svg').then((svg) {
      _armorVisual = SvgComponent(
        svg: svg,
        size: Vector2.all(42),
        anchor: Anchor.center,
        position: Vector2.zero(),
      );
      add(_armorVisual!);
    });
  }

  void takeDamage(double amount) {
    final reduction = equippedArmor?.damageReduction ?? 0;
    final reducedDamage = amount * (1 - reduction);
    currentHp = max(0, currentHp - reducedDamage);
    opacity = 0.5;
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
    opacity = 1;
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
