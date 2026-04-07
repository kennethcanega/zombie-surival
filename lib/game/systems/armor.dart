enum ArmorTier { cloth, kevlar, titan }

class ArmorSpec {
  const ArmorSpec({
    required this.tier,
    required this.name,
    required this.cost,
    required this.hpBonus,
    required this.damageReduction,
  });

  final ArmorTier tier;
  final String name;
  final int cost;
  final double hpBonus;
  final double damageReduction;
}

const List<ArmorSpec> armorCatalog = [
  ArmorSpec(
    tier: ArmorTier.cloth,
    name: 'Cloth Vest',
    cost: 90,
    hpBonus: 18,
    damageReduction: 0.08,
  ),
  ArmorSpec(
    tier: ArmorTier.kevlar,
    name: 'Kevlar Suit',
    cost: 210,
    hpBonus: 35,
    damageReduction: 0.18,
  ),
  ArmorSpec(
    tier: ArmorTier.titan,
    name: 'Titan Plate',
    cost: 420,
    hpBonus: 60,
    damageReduction: 0.28,
  ),
];
