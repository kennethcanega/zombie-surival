import 'dart:math';

enum UpgradeType { damage, maxHp, moveSpeed, attackSpeed }

class Upgrade {
  const Upgrade({required this.type, required this.title, required this.description});

  final UpgradeType type;
  final String title;
  final String description;
}

class UpgradePool {
  static const List<Upgrade> all = [
    Upgrade(
      type: UpgradeType.damage,
      title: 'Damage Up',
      description: '+4 attack damage',
    ),
    Upgrade(
      type: UpgradeType.maxHp,
      title: 'Vitality Up',
      description: '+20 max HP and heal 20',
    ),
    Upgrade(
      type: UpgradeType.moveSpeed,
      title: 'Agility Up',
      description: '+25 movement speed',
    ),
    Upgrade(
      type: UpgradeType.attackSpeed,
      title: 'Frenzy Up',
      description: '15% faster attacks',
    ),
  ];

  static List<Upgrade> randomChoices(Random random, {int count = 3}) {
    final copy = [...all]..shuffle(random);
    return copy.take(count).toList();
  }
}
