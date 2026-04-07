import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/player_component.dart';
import 'components/zombie_component.dart';
import 'systems/day_system.dart';
import 'systems/upgrade.dart';
import 'ui/game_over_overlay.dart';
import 'ui/hud_overlay.dart';
import 'ui/level_up_overlay.dart';

class ZombieSurvivalGame extends FlameGame with TapCallbacks {
  ZombieSurvivalGame() : random = Random();

  final Random random;
  late final PlayerComponent player;
  final List<ZombieComponent> zombies = [];

  int day = 1;
  int level = 1;
  int kills = 0;

  double exp = 0;
  double expToNextLevel = 20;

  bool isGameOver = false;
  bool isPausedForLevelUp = false;

  final DaySystem daySystem = DaySystem();
  double zombieSpawnTimer = 0;
  List<Upgrade> currentUpgradeChoices = [];

  static const double _baseSpawnInterval = 1.6;

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
      _spawnZombie();
    }

    _cleanupDeadZombies();

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

    final zombie = ZombieComponent(
      position: spawnPosition,
      player: player,
      maxHp: 20 + (day - 1) * 5,
      speed: 55 + (day - 1) * 2,
      contactDamage: 8 + (day - 1).toDouble(),
    );

    zombies.add(zombie);
    add(zombie);
  }

  void onZombieKilled(ZombieComponent zombie) {
    kills += 1;
    gainExp(8);
    zombies.remove(zombie);
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
        player.attackCooldown = (player.attackCooldown * 0.85).clamp(0.2, 2.0);
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
    exp = 0;
    expToNextLevel = 20;

    daySystem.reset();
    zombieSpawnTimer = 0;

    for (final zombie in zombies) {
      zombie.removeFromParent();
    }
    zombies.clear();

    player.resetStats();
    player.position = size / 2;

    overlays.remove(GameOverOverlay.id);
    overlays.remove(LevelUpOverlay.id);
    overlays.add(HudOverlay.id);

    resumeEngine();
  }

  void _cleanupDeadZombies() {
    zombies.removeWhere((zombie) => zombie.isRemoving || zombie.currentHp <= 0);
  }
}
