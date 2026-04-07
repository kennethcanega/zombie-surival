import 'dart:async';

import 'package:flutter/material.dart';

import '../systems/armor.dart';
import '../systems/weapon.dart';
import '../zombie_survival_game.dart';

enum TopMenu { none, profile, shop, inventory }

class HudOverlay extends StatefulWidget {
  const HudOverlay({required this.game, super.key});

  static const String id = 'hud';
  final ZombieSurvivalGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  Timer? _refreshTimer;
  TopMenu _activeMenu = TopMenu.none;

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

  void _toggleMenu(TopMenu menu) {
    setState(() {
      _activeMenu = _activeMenu == menu ? TopMenu.none : menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          width: 360,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _menuButton('Profile', TopMenu.profile),
                  const SizedBox(width: 6),
                  _menuButton('Shop', TopMenu.shop),
                  const SizedBox(width: 6),
                  _menuButton('Inventory', TopMenu.inventory),
                ],
              ),
              if (_activeMenu != TopMenu.none) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: switch (_activeMenu) {
                      TopMenu.profile => _buildProfile(),
                      TopMenu.shop => _buildShop(),
                      TopMenu.inventory => _buildInventory(),
                      TopMenu.none => const SizedBox.shrink(),
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String label, TopMenu menu) {
    final selected = _activeMenu == menu;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _toggleMenu(menu),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.orange : const Color(0xFF263238),
          minimumSize: const Size.fromHeight(34),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildProfile() {
    final game = widget.game;
    final hpPercent = (game.player.currentHp / game.player.maxHp).clamp(0, 1).toDouble();
    final expPercent = (game.exp / game.expToNextLevel).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 6),
        Text('Damage: ${game.player.damage.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white70)),
        Text('Agility: ${game.player.agility.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
        Text('Vitality: ${game.player.vitality.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
        Text('Frenzy: x${game.player.frenzy.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
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
    );
  }

  Widget _buildShop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Buy Weapons', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ...weaponCatalog.map((weapon) {
          final owned = widget.game.player.isWeaponOwned(weapon.tier);
          return _shopRow(
            label: weapon.name,
            price: weapon.cost,
            owned: owned,
            onBuy: () {
              widget.game.buyWeapon(weapon.tier);
              setState(() {});
            },
          );
        }),
        const SizedBox(height: 8),
        const Text('Buy Armors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ...armorCatalog.map((armor) {
          final owned = widget.game.player.isArmorOwned(armor.tier);
          return _shopRow(
            label: armor.name,
            price: armor.cost,
            owned: owned,
            onBuy: () {
              widget.game.buyArmor(armor.tier);
              setState(() {});
            },
          );
        }),
      ],
    );
  }

  Widget _buildInventory() {
    final game = widget.game;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
