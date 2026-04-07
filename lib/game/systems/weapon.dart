enum WeaponTier { pistol, smg, shotgun, launcher, bazooka, cannon }

class WeaponSpec {
  const WeaponSpec({
    required this.tier,
    required this.name,
    required this.cost,
    required this.damageMultiplier,
    required this.cooldown,
    required this.bulletSpeed,
    required this.bulletRadius,
    required this.splashRadius,
    required this.pierce,
  });

  final WeaponTier tier;
  final String name;
  final int cost;
  final double damageMultiplier;
  final double cooldown;
  final double bulletSpeed;
  final double bulletRadius;
  final double splashRadius;
  final int pierce;

  bool get isAoe => splashRadius > 0;
}

const List<WeaponSpec> weaponCatalog = [
  WeaponSpec(
    tier: WeaponTier.pistol,
    name: 'Pistol',
    cost: 0,
    damageMultiplier: 1,
    cooldown: 0.45,
    bulletSpeed: 460,
    bulletRadius: 4,
    splashRadius: 0,
    pierce: 1,
  ),
  WeaponSpec(
    tier: WeaponTier.smg,
    name: 'SMG',
    cost: 70,
    damageMultiplier: 0.85,
    cooldown: 0.2,
    bulletSpeed: 540,
    bulletRadius: 3,
    splashRadius: 0,
    pierce: 1,
  ),
  WeaponSpec(
    tier: WeaponTier.shotgun,
    name: 'Shotgun',
    cost: 160,
    damageMultiplier: 1.55,
    cooldown: 0.65,
    bulletSpeed: 430,
    bulletRadius: 5,
    splashRadius: 35,
    pierce: 1,
  ),
  WeaponSpec(
    tier: WeaponTier.launcher,
    name: 'Launcher',
    cost: 300,
    damageMultiplier: 2.4,
    cooldown: 1,
    bulletSpeed: 360,
    bulletRadius: 6,
    splashRadius: 70,
    pierce: 2,
  ),
  WeaponSpec(
    tier: WeaponTier.bazooka,
    name: 'Bazooka',
    cost: 460,
    damageMultiplier: 3.2,
    cooldown: 1.25,
    bulletSpeed: 330,
    bulletRadius: 7,
    splashRadius: 110,
    pierce: 3,
  ),
  WeaponSpec(
    tier: WeaponTier.cannon,
    name: 'Cannon',
    cost: 650,
    damageMultiplier: 4.3,
    cooldown: 1.5,
    bulletSpeed: 310,
    bulletRadius: 8,
    splashRadius: 145,
    pierce: 4,
  ),
];
