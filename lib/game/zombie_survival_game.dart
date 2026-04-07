import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/bullet_component.dart';
import 'components/explosion_component.dart';
import 'components/loot_popup_component.dart';
import 'components/player_component.dart';
import 'components/zombie_component.dart';
import 'systems/armor.dart';
import 'systems/day_system.dart';
import 'systems/upgrade.dart';
import 'systems/weapon.dart';
import 'ui/game_over_overlay.dart';
import 'ui/hud_overlay.dart';
import 'ui/level_up_overlay.dart';

class ZombieSurvivalGame extends FlameGame with TapCallbacks {
  ZombieSurvivalGame() : random = Random();

  final Random random;
  late final PlayerComponent player;
  final List<ZombieComponent> zombies = [];
  final List<BulletComponent> bullets = [];

  int day = 1;
  int level = 1;
  int kills = 0;
  int money = 0;

  double exp = 0;
  double expToNextLevel = 20;

  bool isGameOver = false;
  bool isPausedForLevelUp = false;

  final DaySystem daySystem = DaySystem();
  double zombieSpawnTimer = 0;
  List<Upgrade> currentUpgradeChoices = [];

  static const double _baseSpawnInterval = 1.6;
  static const int _zombieMoneyReward = 12;
  static const double _zombieExpReward = 8;

  @override
  Color backgroundColor() => const Color(0xFF1A1A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    player = PlayerComponent(position: size / 2);
    add(player);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver || isPausedForLevelUp) return;

    daySystem.update(dt);
    if (daySystem.didCompleteDay) {
      _advanceDay();
      daySystem.didCompleteDay = false;
    }

    zombieSpawnTimer += dt;
    final spawnInterval = (_baseSpawnInterval - (day - 1) * 0.08).clamp(0.35, 2.0);
    if (zombieSpawnTimer >= spawnInterval) {
      zombieSpawnTimer = 0;
      final spawnCount = (1 + (day - 1) ~/ 2).clamp(1, 8);
      for (var i = 0; i < spawnCount; i++) {
        _spawnZombie();
      }
    }

    _cleanupDeadEntities();

    if (player.currentHp <= 0 && !isGameOver) {
      gameOver();
    }
  }

  void _advanceDay() {
    day += 1;
    daySystem.startNewDay(day);
  }

  void _spawnZombie() {
    final spawnDistance = 430.0;
    final angle = random.nextDouble() * pi * 2;
    final spawnPosition = player.position + Vector2(cos(angle), sin(angle)) * spawnDistance;

    final categoryRoll = random.nextDouble();
    final category = categoryRoll < 0.2
        ? ZombieCategory.fast
        : categoryRoll > 0.85
        ? ZombieCategory.tough
        : ZombieCategory.regular;

    final dayFactor = 1 + (day - 1) * 0.14;

    final (hpMultiplier, speedMultiplier, damageMultiplier) = switch (category) {
      ZombieCategory.fast => (0.75, 1.45, 0.9),
      ZombieCategory.regular => (1.0, 1.0, 1.0),
      ZombieCategory.tough => (1.9, 0.72, 1.45),
    };

    final zombie = ZombieComponent(
      position: spawnPosition,
      player: player,
      category: category,
      maxHp: (20 * dayFactor + (day - 1) * 6) * hpMultiplier,
      speed: (55 + (day - 1) * 3.2) * speedMultiplier,
      contactDamage: (8 + (day - 1) * 1.35) * damageMultiplier,
    );

    zombies.add(zombie);
    add(zombie);
  }

  void onZombieKilled(ZombieComponent zombie) {
    kills += 1;
    money += _zombieMoneyReward;
    gainExp(_zombieExpReward);
    zombies.remove(zombie);

    add(ExplosionComponent(position: zombie.position.clone()));

    if (zombie.category == ZombieCategory.tough && random.nextDouble() < 0.28) {
      player.collectArmorDrop(ArmorTier.kevlar);
    } else if (zombie.category == ZombieCategory.regular && random.nextDouble() < 0.12) {
      player.collectArmorDrop(ArmorTier.cloth);
    }

    add(
      LootPopupComponent(
        position: zombie.position.clone(),
        money: _zombieMoneyReward,
        exp: _zombieExpReward,
      ),
    );
  }

  void addBullet(BulletComponent bullet) {
    bullets.add(bullet);
    add(bullet);
  }

  void setMoveDirection(Vector2 direction) {
    player.setMoveDirection(direction);
  }

  void setAimDirection(Vector2 direction) {
    player.setAimDirection(direction);
  }

  bool buyWeapon(WeaponTier tier) {
    final spec = weaponCatalog.firstWhere((w) => w.tier == tier);
    if (money < spec.cost || player.isWeaponOwned(tier)) return false;
    if (!player.buyWeapon(tier, money)) return false;
    money -= spec.cost;
    return true;
  }

  bool equipWeapon(WeaponTier tier) => player.equipWeapon(tier);

  bool buyArmor(ArmorTier tier) {
    final spec = armorCatalog.firstWhere((a) => a.tier == tier);
    if (money < spec.cost || player.isArmorOwned(tier)) return false;
    if (!player.buyArmor(tier, money)) return false;
    money -= spec.cost;
    return true;
  }

  bool equipArmor(ArmorTier tier) => player.equipArmor(tier);

  String get playerStatus {
    if (player.currentHp <= player.maxHp * 0.25) return 'Critical';
    if (player.currentHp <= player.maxHp * 0.55) return 'In Danger';
    return 'Combat Ready';
  }

  void gainExp(double amount) {
    exp += amount;
    while (exp >= expToNextLevel) {
      exp -= expToNextLevel;
      level += 1;
      expToNextLevel = (expToNextLevel * 1.2).roundToDouble();
      showLevelUp();
    }
  }

  void showLevelUp() {
    if (isGameOver) return;
    isPausedForLevelUp = true;
    pauseEngine();
    currentUpgradeChoices = UpgradePool.randomChoices(random, count: 3);
    overlays.add(LevelUpOverlay.id);
  }

  void applyUpgrade(Upgrade upgrade) {
    switch (upgrade.type) {
      case UpgradeType.damage:
        player.damage += 4;
      case UpgradeType.maxHp:
        player.maxHp += 20;
        player.currentHp += 20;
      case UpgradeType.moveSpeed:
        player.moveSpeed += 25;
      case UpgradeType.attackSpeed:
        player.improveFireRate();
    }

    overlays.remove(LevelUpOverlay.id);
    isPausedForLevelUp = false;
    resumeEngine();
  }

  void gameOver() {
    isGameOver = true;
    pauseEngine();
    overlays.add(GameOverOverlay.id);
  }

  void restart() {
    isGameOver = false;
    isPausedForLevelUp = false;
    day = 1;
    level = 1;
    kills = 0;
    money = 0;
    exp = 0;
    expToNextLevel = 20;

    daySystem.reset();
    zombieSpawnTimer = 0;

    for (final zombie in zombies) {
      zombie.removeFromParent();
    }
    zombies.clear();

    for (final bullet in bullets) {
      bullet.removeFromParent();
    }
    bullets.clear();

    player.resetStats();
    player.position = size / 2;

    overlays.remove(GameOverOverlay.id);
    overlays.remove(LevelUpOverlay.id);
    overlays.add(HudOverlay.id);

    resumeEngine();
  }

  void _cleanupDeadEntities() {
    zombies.removeWhere((zombie) => zombie.isRemoving || zombie.currentHp <= 0);
    bullets.removeWhere((bullet) => bullet.isRemoving);
  }
}
