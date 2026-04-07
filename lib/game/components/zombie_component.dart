import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

import '../zombie_survival_game.dart';
import 'blood_splatter_component.dart';
import 'player_component.dart';

enum ZombieCategory { fast, regular, tough }

class ZombieComponent extends PositionComponent with HasGameReference<ZombieSurvivalGame> {
  ZombieComponent({
    required super.position,
    required this.player,
    required this.maxHp,
    required this.speed,
    required this.contactDamage,
    required this.category,
  }) : currentHp = maxHp,
       super(anchor: Anchor.center, size: Vector2.all(32));

  static const double collisionRadius = 14;

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

  double get radius => collisionRadius;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: collisionRadius));

    final zombieSvg = await Svg.load('svg/zombie.svg');
    _zombieVisual = SvgComponent(
      svg: zombieSvg,
      size: Vector2.all(40),
      anchor: Anchor.center,
      position: Vector2.zero(),
    );
    add(_zombieVisual);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final width = radius * 2.2;
    final hpPercent = (currentHp / maxHp).clamp(0, 1).toDouble();
    final barRect = Rect.fromLTWH(-width / 2, -radius - 10, width, 4);

    canvas.drawRect(barRect, Paint()..color = const Color(0x88000000));
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
    _zombieVisual.scale = Vector2(1 + sin(_animTimer * 10) * 0.08, 1 - sin(_animTimer * 10) * 0.04);

    final toPlayer = player.position - position;
    if (toPlayer.length2 > 0.0001) {
      position += toPlayer.normalized() * speed * dt;
    }

    _touchDamageCooldown -= dt;
    if (_touchDamageCooldown <= 0 &&
        position.distanceTo(player.position) <= radius + player.radius + 2) {
      player.takeDamage(contactDamage);
      _touchDamageCooldown = 0.5;
    }

    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
      if (_damageFlashTimer <= 0) {
        _zombieVisual.opacity = 1;
      }
    }
  }

  void takeDamage(double amount) {
    _zombieVisual.opacity = 0.65;
    _damageFlashTimer = 0.2;
    currentHp -= amount;
    game.add(BloodSplatterComponent(position: position.clone(), intensity: 4));
    if (currentHp <= 0) {
      game.add(BloodSplatterComponent(position: position.clone(), intensity: 10, bigBurst: true));
      game.onZombieKilled(this);
      removeFromParent();
    }
  }
}
