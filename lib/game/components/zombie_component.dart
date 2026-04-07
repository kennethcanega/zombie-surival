import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../zombie_survival_game.dart';
import 'player_component.dart';

enum ZombieCategory { fast, regular, tough }

class ZombieComponent extends CircleComponent with HasGameReference<ZombieSurvivalGame> {
  ZombieComponent({
    required super.position,
    required this.player,
    required this.maxHp,
    required this.speed,
    required this.contactDamage,
    required this.category,
  }) : currentHp = maxHp,
       super(
         radius: 14,
         anchor: Anchor.center,
         paint: Paint()..color = _colorForCategory(category),
       );

  final PlayerComponent player;
  final double speed;
  final double maxHp;
  final double contactDamage;
  final ZombieCategory category;

  double currentHp;
  double _touchDamageCooldown = 0;
  double _damageFlashTimer = 0;
  double _animTimer = 0;
  late final SvgComponent _zombieVisual;

  static Color _colorForCategory(ZombieCategory category) {
    switch (category) {
      case ZombieCategory.fast:
        return const Color(0xFFFFEE58);
      case ZombieCategory.regular:
        return const Color(0xFF66BB6A);
      case ZombieCategory.tough:
        return const Color(0xFFF5F5F5);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());

    final zombieSvg = await Svg.load('svg/zombie.svg');
    _zombieVisual = SvgComponent(
      svg: zombieSvg,
      size: Vector2.all(38),
      anchor: Anchor.center,
      position: Vector2.zero(),
    );
    add(_zombieVisual);
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1 + sin(_animTimer * 10) * 0.08;
    canvas.save();
    canvas.scale(pulse, 1 / pulse);
    super.render(canvas);
    canvas.restore();

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

    _animTimer += dt;
    _zombieVisual.scale = Vector2.all(1 + sin(_animTimer * 10) * 0.06);

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
        paint.color = _colorForCategory(category);
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
