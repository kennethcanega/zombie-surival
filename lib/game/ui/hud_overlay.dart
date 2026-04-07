import 'dart:async';

import 'package:flutter/material.dart';

import '../systems/armor.dart';
import '../systems/weapon.dart';
import '../zombie_survival_game.dart';

class HudOverlay extends StatefulWidget {
  const HudOverlay({required this.game, super.key});

  static const String id = 'hud';
  final ZombieSurvivalGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  Timer? _refreshTimer;
  bool _showProfile = true;
  bool _showShop = true;
  bool _showInventory = true;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final hpPercent = (game.player.currentHp / game.player.maxHp).clamp(0, 1).toDouble();
    final expPercent = (game.exp / game.expToNextLevel).clamp(0, 1).toDouble();

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        width: 320,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _toggleHeader('Profile', _showProfile, () => setState(() => _showProfile = !_showProfile)),
              if (_showProfile) ...[
                Text('Day: ${game.day}', style: const TextStyle(color: Colors.white)),
                Text('Level: ${game.level}', style: const TextStyle(color: Colors.white)),
                Text('Kills: ${game.kills}', style: const TextStyle(color: Colors.white)),
                Text('Money: \$${game.money}', style: const TextStyle(color: Colors.amberAccent)),
                Text('Status: ${game.playerStatus}', style: const TextStyle(color: Colors.lightGreenAccent)),
                Text('Weapon: ${game.player.currentWeapon.name}', style: const TextStyle(color: Colors.white)),
                Text(
                  'Armor: ${game.player.equippedArmor?.name ?? 'None'}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text('HP', style: TextStyle(color: Colors.white)),
                LinearProgressIndicator(value: hpPercent, minHeight: 8),
                const SizedBox(height: 8),
                const Text('EXP', style: TextStyle(color: Colors.white)),
                LinearProgressIndicator(value: expPercent, minHeight: 8, color: Colors.amber),
                const SizedBox(height: 8),
                Text(
                  'Day Time Left: ${game.daySystem.timeLeft.clamp(0, 999).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              const SizedBox(height: 10),
              _toggleHeader('Shop', _showShop, () => setState(() => _showShop = !_showShop)),
              if (_showShop) ...[
                const Text('Buy Weapons', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ...weaponCatalog.map((weapon) {
                  final owned = game.player.isWeaponOwned(weapon.tier);
                  return _shopRow(
                    label: weapon.name,
                    price: weapon.cost,
                    owned: owned,
                    onBuy: () {
                      game.buyWeapon(weapon.tier);
                      setState(() {});
                    },
                  );
                }),
                const SizedBox(height: 8),
                const Text('Buy Armors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ...armorCatalog.map((armor) {
                  final owned = game.player.isArmorOwned(armor.tier);
                  return _shopRow(
                    label: armor.name,
                    price: armor.cost,
                    owned: owned,
                    onBuy: () {
                      game.buyArmor(armor.tier);
                      setState(() {});
                    },
                  );
                }),
              ],
              const SizedBox(height: 10),
              _toggleHeader('Inventory', _showInventory, () => setState(() => _showInventory = !_showInventory)),
              if (_showInventory) ...[
                const Text('Equip Weapon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: game.player.ownedWeapons.map((weapon) {
                    final selected = game.player.currentWeapon.tier == weapon.tier;
                    return ChoiceChip(
                      label: Text(weapon.name),
                      selected: selected,
                      onSelected: (_) {
                        game.equipWeapon(weapon.tier);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text('Equip Armor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (game.player.ownedArmors.isEmpty)
                  const Text('No armor yet. Defeat zombies for drops.', style: TextStyle(color: Colors.white70)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: game.player.ownedArmors.map((armor) {
                    final selected = game.player.equippedArmor?.tier == armor.tier;
                    return ChoiceChip(
                      label: Text(armor.name),
                      selected: selected,
                      onSelected: (_) {
                        game.equipArmor(armor.tier);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleHeader(String title, bool shown, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        IconButton(
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          onPressed: onTap,
          icon: Icon(shown ? Icons.visibility : Icons.visibility_off, color: Colors.white),
        ),
      ],
    );
  }

  Widget _shopRow({
    required String label,
    required int price,
    required bool owned,
    required VoidCallback onBuy,
  }) {
    final game = widget.game;
    final canAfford = game.money >= price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          if (owned)
            const Text('Owned', style: TextStyle(color: Colors.greenAccent))
          else
            ElevatedButton(
              onPressed: canAfford ? onBuy : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                backgroundColor: canAfford ? Colors.orange : Colors.grey,
              ),
              child: Text('Buy \$$price'),
            ),
        ],
      ),
    );
  }
}
