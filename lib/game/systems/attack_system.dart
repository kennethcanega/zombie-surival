import '../components/bullet_component.dart';
import '../components/player_component.dart';
import '../components/zombie_component.dart';

class AttackSystem {
  const AttackSystem();

  ZombieComponent? findNearestZombie({
    required PlayerComponent player,
    required List<ZombieComponent> zombies,
    double? withinRange,
  }) {
    ZombieComponent? nearest;
    double nearestDistance = double.infinity;

    for (final zombie in zombies) {
      final distance = zombie.position.distanceTo(player.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = zombie;
      }
    }

    if (nearest == null) {
      return null;
    }

    if (withinRange != null && nearestDistance > withinRange) {
      return null;
    }

    return nearest;
  }

  BulletComponent createBullet({
    required PlayerComponent player,
    required ZombieComponent target,
    required double damage,
    required double speed,
    required double radius,
    required double splashRadius,
    required int pierce,
  }) {
    final heading = (target.position - player.position).normalized();
    return BulletComponent(
      position: player.position.clone(),
      direction: heading,
      damage: damage,
      speed: speed,
      radius: radius,
      splashRadius: splashRadius,
      pierce: pierce,
    );
  }
}
