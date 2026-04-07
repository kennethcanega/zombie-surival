import '../components/player_component.dart';
import '../components/zombie_component.dart';

class AttackSystem {
  const AttackSystem();

  void meleeHitNearest({
    required PlayerComponent player,
    required List<ZombieComponent> zombies,
    required double range,
    required double damage,
  }) {
    ZombieComponent? nearest;
    double nearestDistance = double.infinity;

    for (final zombie in zombies) {
      final d = zombie.position.distanceTo(player.position);
      if (d < nearestDistance) {
        nearestDistance = d;
        nearest = zombie;
      }
    }

    if (nearest != null && nearestDistance <= range) {
      nearest.takeDamage(damage);
    }
  }
}
